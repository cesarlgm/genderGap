
local do_location "2\_analysis/code\_files/create\_elasticity\_table.do"

gettoken analysis_type 	0: 0
gettoken indep_var		0: 0
gettoken standardize	0: 0
di "`absorb'"

local year_list `0'

local density_filter 1

di "`take_out'"

*===============================================================================
*PREAMBLE
*===============================================================================
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


*===============================================================================
*PREAMBLE
*===============================================================================

use "../1_build_database/output/czone_level_dabase_`name'", clear

*I put the variables in terms of logs to actually have a direct elasticity
*interpretation
replace l_czone_density=log(10^l_czone_density)

replace year=2020 if year==2018
replace year=2010 if year==2011
grscheme, ncolor(7) style(tableau)


*===============================================================================
*THIS SECOND PART OF THE CODE CREATES STACKED REGRESSIONS
*===============================================================================

eststo clear

local filter if czone_pop_50/cz_area>1&year>1950
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

eststo clear
foreach year in `year_list' {
	if `year'>1950 {
		qui eststo wage_raw_gap_`year'_uw: 		reg wage_raw_gap `indep_var'  ///
			`filter'&year==`year' , vce(r)
		qui eststo wage_raw_gap_`year'_we: 		reg wage_raw_gap `indep_var'  ///
			`filter'&year==`year' [aw=observations], vce(r)
	}
}


local table_name 	"output/tables/elasticities_table_`name'`sd_name'.tex"
local col_titles   1970 1980 1990 2000 2010 2020
if `standardize'==0 {
	local table_title 	"Elasticities of male wage advantage to population density"
	local key tab:elast
}
else if `standardize'==1 {
	local table_title 	"$\beta_t$ on standardized data"
	local key tab:elast_std
}
local table_note  	"Robust standard errors in parenthesis. Sample restricts to full-time year-round workers."
local table_options drop(_cons)  nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain b(%9.3fc) se(%9.3fc) par star 
	

textablehead using `table_name', ncols(6) coltitles(`col_titles') ///
	f("Regression specification") title(`table_title') key(`key') drop

label var l_czone_density "Unweighted OLS"
esttab *uw using `table_name', `table_options' noobs
label var l_czone_density "Weighted by population"
esttab *we using `table_name', `table_options' stats( N, ///
		label( "\midrule Observations") ///
		fmt(%9.0fc))
	
textablefoot using `table_name', notes(`table_note')
