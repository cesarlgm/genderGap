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
di "`absorb'"

local year_list `0'

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
		
	local ytick ytick(-.04(.01).06, tlcolor(gs0) grid)
	
	local tex_title CZ population density
}
else if "`indep_var'"=="l_czone_pop" {
	local scatter_options nq(35)  xtitle("log(czone population)") ///
		xscale(range(8 15)) xlabel(8(1)15)
	local ytick ytick(-.02(.05).02, tlcolor(gs0) grid)
	
	local tex_title CZ population 
}

use "../1_build_database/output/czone_level_dabase_`name'", clear

g	density_tier_year=.	
foreach year in `year_list' {

	xtile temp=l_czone_density if year==`year', nq(3)

	replace density_tier_year=temp if year==`year'
	
	drop temp
}


replace year=2020 if year==2018
replace year=2010 if year==2011
grscheme, ncolor(7) style(tableau)


*===============================================================================
*THIS SECOND PART OF THE CODE CREATES STACKED REGRESSIONS
*===============================================================================

eststo clear

local filter if year>0
local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

*===============================================================================
*REGRESSION OF GENDER GAP ON POPULATION DENSITY
*===============================================================================

if `standardize'==1 {
	local sd_name _std
	local ytick ytick(-.5(.25).5, tlcolor(gs0) grid)
	foreach type in raw basic educ ind occ {
		egen tempsd=	sd(wage_`type'_gap) `filter', by(year)
		egen tempmean=	sd(wage_`type'_gap) `filter', by(year)
		replace wage_`type'_gap=	(wage_`type'_gap-tempmean)/tempsd
		cap drop tempsd
		cap drop tempmean
	}
	
	egen tempsd=	sd(`indep_var') `filter', by(year)
	egen tempmean=	sd(`indep_var') `filter', by(year)
	replace `indep_var'=	(`indep_var'-tempmean)/tempsd
	cap drop tempsd
	cap drop tempmean
}



qui eststo raw_gap: 		reg wage_raw_gap i.year#c.`indep_var' i.year `filter', vce(r)

foreach type in basic educ ind occ {
	qui eststo gap_`type': 			reg wage_`type'_gap i.year#c.`indep_var' i.year `filter', vce(r) 
	qui eststo gap_`type'_het: 		reg wage_`type'_gap i.year i.year#i.density_tier i.year#i.density_tier#c.`indep_var' i.year `filter', vce(r) 
}

/*

coefplot raw_gap gap_basic, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Raw wages" 4 "+ age, race, stafe f.e.") ///
		ring(0) pos(2))  ///
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'

graph export "output/figures/cz_gender_gap_gradient_`indep_var'_`name'_basic`sd_name'.pdf", replace

*local figure_title "Gender gap and CZ density gradient"
local figure_name "output/figures/cz_gender_gap_gradient_`name'_`indep_var'`sd_name'_bare.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list cz_gender_gap_gradient_`indep_var'_`name'_basic`sd_name'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 


coefplot raw_gap gap*, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Raw wages" 4 "+ age, race, stafe f.e." ///
		6 "+ education f.e." 8 "+ industry f.e." 10 "+ occupation f.e.") ///
		ring(0) pos(2)) ///
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'

graph export "output/figures/cz_gender_gap_gradient_`indep_var'_`name'`sd_name'.pdf", replace

*local figure_title "Gender gap and CZ density gradient"
local figure_name "output/figures/cz_gender_gap_gradient_`name'_`indep_var'`sd_name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list cz_gender_gap_gradient_`indep_var'_`name'`sd_name'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 

/*

*===============================================================================
*EXPLORING EXPLANATIONS
*===============================================================================

*===============================================================================
*INCREASE IN INEQUALITY
qui eststo overall_ineq: 	reg overall_ineq i.year#c.l_czone_density i.year `filter', vce(r)	

coefplot overall_ineq, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Raw wages" 4 "Residualized wages")) ///
	ytitle("p{sup:90}-p{sup:10} gradient") ///
	ciopt(recast(rcap)) ytick(-.1(.1).1, tlcolor(gs0) grid)

graph export "output/figures/cz_inequality_gradient.pdf", replace


local figure_title "p90-p10 and population density gradient"
local figure_name "output/figures/cz_inequality_gradient_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_list cz_inequality_gradient

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((4/3)) 
*===============================================================================

*===============================================================================
*INCREASE IN LABOR FORCE PARTICIPATION

qui eststo labforce: 	reg labfore_gap i.year#c.l_czone_density i.year `filter', vce(r)	

coefplot labforce, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(off) ///
	ytitle("LFP{sup:female}/LFP{sup:male} gradient") ///
	ciopt(recast(rcap)) ytick(-.02(.02).04, tlcolor(gs0) grid)

graph export "output/figures/cz_labforce_ratio_gradient.pdf", replace


local figure_title "Labor force participation gradient"
local figure_name "output/figures/cz_labforce_gradient_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_list cz_labforce_ratio_gradient

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((4/3))
*===============================================================================
	
*===============================================================================
*DEINDUSTRIALIZATION
qui eststo ind_manufacturing: 	reg ind_manufacturing i.year#c.l_czone_density i.year `filter', vce(r)	

coefplot ind_manufacturing, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(off) ///
	ytitle("Manufacturing share gradient") ///
	ciopt(recast(rcap)) ytick(-.05(.05).2, tlcolor(gs0) grid)

graph export "output/figures/cz_manufacturing_gradient.pdf", replace


local figure_title "Manufacturing share gradient"
local figure_name "output/figures/cz_manufacturing_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_list cz_manufacturing_gradient

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((4/3)) 
*===============================================================================
}
else {
*===============================================================================
*RISE OF COLLEGE EDUCATED WOMEN

qui eststo high_skill: 	reg raw_wage_gap i.year#c.l_czone_density i.year ///
	`filter'&educ_level==2, vce(r)	
qui eststo low_skill: 	reg raw_wage_gap i.year#c.l_czone_density i.year ///
	`filter'&educ_level==1, vce(r)	


coefplot high_skill low_skill, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "High-education" 4 "Low education")) ///
	ytitle("w{sup:male}-w{sup:female} gradient") ///
	ciopt(recast(rcap)) ytick(-.05(.05).1, tlcolor(gs0) grid)

graph export "output/figures/cz_by_education_gradient.pdf", replace


local figure_title "Gradient by education level"
local figure_name "output/figures/cz_by_education_gradient_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_list cz_by_education_gradient

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((4/3))
*===============================================================================
}

*/
