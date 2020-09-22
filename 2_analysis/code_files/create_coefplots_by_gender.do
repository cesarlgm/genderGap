*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: classifies industries into manufacturing and services
*==============================================================================


*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap wage gradient by CZ
*===============================================================================

local do_location "2\_analysis/code\_files/create\_gender\_gap\_gradient\_graphs.do"

gettoken analysis_type 	0: 0
gettoken indep_var		0: 0
gettoken standardize	0: 0


local density_filter 1

di "`take_out'"

if `analysis_type'==0 {
	local name gender
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
}
else if `analysis_type'==1 {
	local name race
	local y1 2
	local y2 1
	local legend order( 2 "Black" 1 "White")
	local y_title_gap "log(white wage)-log(black wage)"
}
else if `analysis_type'==2 {
	local name by_education
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
}
else if `analysis_type'==4 {
	local name full_time
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
	local add_note "Sample is restricted to full-time year-round workers."
}


if "`indep_var'"=="l_czone_density" {
	local scatter_options nq(35)  xtitle("log(czone density) -base 10-") ///
		xscale(range(0 2.5)) xlabel(0(.5)2.5)
		
	local ytick ytick(0(.02).2, tlcolor(gs0) grid)
	
	local tex_title CZ population density
}
else if "`indep_var'"=="l_czone_pop" {
	local scatter_options nq(35)  xtitle("log(czone population)") ///
		xscale(range(8 15)) xlabel(8(1)15)
	local ytick ytick(-.02(.05).02, tlcolor(gs0) grid)
	
	local tex_title CZ population 
}

use "../1_build_database/output/czone_level_dabase_`name'", clear

*I add the state indicator
merge m:1 czone using "input/cw_czone_state", keep(1 3) nogen
merge m:1 czone year using ///
	"../1_build_database/output/gender_occ_empshares_database_1950_ind1950", keep(1 3) ///
	nogen keepusing(male*share female*share)

merge m:1 czone year using ///
	"temporary_files/selection_observables", keep(1 3) nogen
	

replace year=2020 if year==2018
replace year=2010 if year==2011

merge m:1 czone year using ///
	"../1_build_database/output/occ_ind_statsfile", keep(1 3) nogen
	

grscheme, ncolor(10) style(tableau)


*===============================================================================
*This first part of the code computes gradients by year
*===============================================================================
cap rename raw_wage_gap wage_raw_gap

*===============================================================================
*STACKED REGRESSIONS WITH OTHER COVARIATES
*===============================================================================
local filter if czone_pop_50/cz_area>`density_filter'&year>1950
local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

*===============================================================================
*REGRESSION OF GENDER GAP ON POPULATION DENSITY
*===============================================================================

*Here I standardize the dependent and independent variables by year
if `standardize'==1 {
	local sd_name _std
	local ytick ytick(-1(.25)1, tlcolor(gs0) grid)
	foreach type in raw basic educ ind occ {
		egen tempsd=	sd(wage_`type'_gap) `filter', by(year)
		egen tempmean=	sd(wage_`type'_gap) `filter', by(year)
		replace wage_`type'_gap=	(wage_`type'_gap-tempmean)/tempsd
		cap drop tempsd
		cap drop tempmean
	}
	
	ds ind_* occ_*
	
	foreach variable in high_education labforce_gap married `r(varlist)' {
		egen tempsd=	sd(`variable') `filter', by(year)
		egen tempmean=	sd(`variable') `filter', by(year)
		replace `variable'=	(`variable'-tempmean)/tempsd
		cap drop tempsd
		cap drop tempmean
	}
}

eststo clear

sort czone year
egen period=group(year)

xtset czone period


local controls i.year#c.`indep_var' i.year 
local y_var l_hrwage

qui eststo male_wage_raw: 	reg `y_var'0 `controls' `filter', vce(r) 
qui eststo female_wage_raw: reg `y_var'1 `controls' `filter', vce(r) 

local y_var wage_basic
qui eststo male_wage_basic: 	reg `y_var'0 `controls' `filter', vce(r) 
qui eststo female_wage_basic: 	reg `y_var'1 `controls' `filter', vce(r) 

local y_var in_labforce
qui eststo male_labforce: 		reg `y_var'0 `controls' `filter', vce(r) 
qui eststo female_labforce: 	reg `y_var'1 `controls' `filter', vce(r) 

qui eststo male_migrant: 		reg  male_migrant `controls' `filter', vce(r) 
qui eststo female_migrant: 		reg  female_migrant `controls' `filter', vce(r) 


local y_var hh_index_occ1950
qui eststo male_concentration: 		reg  `y_var'0 `controls' `filter', vce(r) 
qui eststo female_concentration: 	reg  `y_var'1 `controls' `filter', vce(r) 

qui eststo emp_dist: 		reg  emp_dist_ind1950 `controls' `filter', vce(r) 

*There are two clear and distinct periods:
*1970-1980s: urban wage premia is rising faster for women.
*1990-2000s: faster urban wage premia decline for men

coefplot *raw, vert  ///
	drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ*) base ///
	xline(3) ///
	xlabel(`year_label') ///
	legend(order(2 "Men" 4 "Women") ///
		ring(0) pos(2))  ///
	ytitle("wage - on population density ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'

graph export "output/figures/wage_gradient_`indep_var'_`name'`sd_name'.pdf", replace

*local figure_title "Wage on population density gradient by gender"
local figure_name "output/figures/wage_gradient_`indep_var'_`name'`sd_name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list wage_gradient_`indep_var'_`name'`sd_name'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 

*Accounting for people's characteristics
coefplot *basic, vert  ///
	drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ*) base ///
	xline(3) ///
	xlabel(`year_label') ///
	legend(order(2 "Men" 4 "Women") ///
		ring(0) pos(2))  ///
	ytitle("wage - on population density ({&beta}{sub:t})") ///
	ciopt(recast(rcap))  ytick(0(.04).12, tlcolor(gs0) grid)

	

coefplot *labforce, vert  ///
	drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ*) base ///
	xline(3) yline(0) ///
	xlabel(`year_label') ///
	legend(order(2 "Men" 4 "Women") ///
		ring(0) pos(2))  ///
	ytitle("LFP - on population density ({&beta}{sub:t})") ///
	ciopt(recast(rcap))


	

coefplot *migrant, vert  ///
	drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ*) base ///
	xline(3) yline(0) ///
	xlabel(`year_label') ///
	legend(order(2 "Men" 4 "Women") ///
		ring(0) pos(2))  ///
	ytitle("LFP - on population density ({&beta}{sub:t})") ///
	ciopt(recast(rcap))

	

coefplot *concentration, vert  ///
	drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ*) base ///
	xline(3) yline(0) ///
	xlabel(`year_label') ///
	legend(order(2 "Men" 4 "Women") ///
		ring(0) pos(2))  ///
	ytitle("LFP - on population density ({&beta}{sub:t})") ///
	ciopt(recast(rcap))

