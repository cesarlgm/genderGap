*===============================================================================
*WHAT DRIVES THE DIFFERENCES IN THE WEIGHTING?
*===============================================================================

gettoken analysis_type 	0: 0
gettoken indep_var		0: 0

local year_list 1970 1980 1990 2000 2010 2020

local density_filter 1

di "`take_out'"

*Handling of types of samples I use
if `analysis_type'==0 {
	local name gender
}
else if `analysis_type'==1 {
	local name race
}
else if `analysis_type'==2 {
	local name by_education
}
else if `analysis_type'==4 {
	local name full_time
}


use "../1_build_database/output/czone_level_dabase_`name'", clear

generate czone_density=exp(l_czone_density)

order czone year czone_pop  czone_density l_czone_density obs*, first

*I add the state indicator
merge m:1 czone using "input/cw_czone_state", keep(1 3) nogen
merge m:1 czone year using ///
	"../1_build_database/output/gender_occ_empshares_database_1950_ind1950", keep(1 3) ///
	nogen keepusing(male*share female*share)

*Adding data from Autor and Dorn
preserve
*Cities part of the data
tempfile autor_cities
use "input/workfile2012", clear
keep czone statefip city
duplicates drop
save `autor_cities'
restore

merge m:1 czone using `autor_cities', nogen

grscheme, ncolor(10) style(tableau)

cap rename raw_wage_gap wage_raw_gap

*Part 1: I start with a weighted vs unweighted graph
*--------------------------------------------------------------

*Regression specification
local controls i.year#c.`indep_var' i.year 

*Unweighted regression
*---------------------------------------------------------------
local filter if czone_pop/cz_area>`density_filter'&year>1950
local year_label   1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

local type raw
*Unweighted
qui eststo gap_`type'_u: 			reg wage_`type'_gap `controls' `filter', vce(r) 
*Weighted using czone population
qui eststo gap_`type'_wp: 			reg wage_`type'_gap `controls' `filter' [aw=czone_pop], vce(r) 
*Weighted using the "appropriate weight by gender"
qui eststo gap_`type'_wg: 			reg wage_`type'_gap `controls' `filter' [aw=reg_weight], vce(r) 


coefplot gap_raw_* , vert keep(*#*``indep_'var') yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Unweighted" 4 "Population weighted" 6 "Weighted by cell-size" ) ///
		)  ///
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'

/*
graph export "output/figures/comparison_by_weight_`name'_``indep_'var'.png", replace

*Writing the files for the graphs
local figure_name  	"output/figures/comparison_by_weight_`name'.tex"
local figure_title 	"CZ level regressions under different weighting"
local figure_list   comparison_by_weight_`name'_l_czone_density  comparison_by_weight_`name'_l_czone_pop
local labels		`""Gradient on population density""Gradient on total population""'

latexfigure using `figure_name', path(../2_analysis/output/figures) figurelist(`figure_list') ///
	title(`figure_title') figlab(`labels')


*Interpretation of the coefficients
*----------------------------------------------------------------
*I create quantile fo density by year
levelsof year
generate density_quantile=.
foreach year in `year_list' {
    xtile temp=``indep_'var'  `filter'&year==`year', nq(3)
    replace density_quantile=temp  `filter'&year==`year'
    cap drop temp
}

eststo clear
*Regression specification
local controls ib1950.year#ib1.density_quantile i.year 

local type raw


*Unweighted
qui eststo gap_`type'_u: 			reg wage_`type'_gap `controls' `filter', vce(r) 
*Weighted using czone population
qui eststo gap_`type'_wp: 			reg wage_`type'_gap `controls' `filter' [aw=czone_pop], vce(r) 
*Weighted using the "appropriate weight by gender"
qui eststo gap_`type'_wg: 			reg wage_`type'_gap `controls' `filter' [aw=reg_weight], vce(r) 


*There is a clear non-lineary in the relationship between the gender gap and the 
coefplot gap_raw_u gap_raw_wp gap_raw_wg, vert keep( *#3*quantile*) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Unweighted" 4 "Weighted by population" 6 "Weighted by cell-size" ) ///
		)  ///
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'


graph export "output/figures/tercile_difference_by_weight_`name'_``indep_'var'.png", replace


*Writing the files for the graphs
local figure_name  	"output/figures/tercile_difference_by_weight_`name'.tex"
local figure_title 	"Gap difference between top and bottom terciles"
local figure_list   tercile_difference_by_weight_`name'_l_czone_density  tercile_difference_by_weight_`name'_l_czone_pop
local labels		`""Gradient on population density""Gradient on total population""'

latexfigure using `figure_name', path(../2_analysis/output/figures) figurelist(`figure_list') ///
	title(`figure_title') figlab(`labels')

*===============================================================================================
*Graphs in changes
*===============================================================================================
*Regression in changes
sort czone year
egen period=group(year)
xtset czone period

by czone: generate d_wage_`type'_gap_70=wage_`type'_gap-wage_`type'_gap[2]
by czone: generate l_czone_density_1970=l_czone_density[2]

tw (scatter d_wage_`type'_gap_70 l_czone_density_1970 [aw=czone_pop]) ///
	(lfit d_wage_`type'_gap_70 l_czone_density_1970 [aw=czone_pop])  ///
	 if year>2010, xtitle("log(population density) in 1970")  ///
	 ytitle("Change in male wage advantance (2020-1970)") ///
	 legend(off)

graph export "output/figures/change_in_gap.png", replace

foreach year in `year_list' {
	reg	wage_`type'_gap if year==`year'
	predict yvar, residuals

	tw (scatter yvar l_czone_density_1970 [aw=czone_pop] if year==`year') ///
		(lfit yvar l_czone_density_1970  if year==`year')  ///
		, xtitle("log(population density) in 1970")  ///
		ytitle("Male wage advantange `year'") ///
		legend(off) 

	graph export "output/figures/density_gap_in_`year'.png", replace
	drop yvar
}

foreach year in `year_list' {
	reg	d.wage_`type'_gap if year==`year'
	predict yvar, residuals

	tw (scatter yvar l_czone_density_1970 [aw=czone_pop] if year==`year') ///
		(lfit yvar l_czone_density_1970 if year==`year')  ///
		, xtitle("log(population density) in 1970")  ///
		ytitle("Decadal change in male wage advantange `year'") ///
		legend(off) 

	graph export "output/figures/d_density_gap_in_`year'.png", replace
	drop yvar
}




*Writing the files for the graphs
local figure_name  	"output/figures/changes_in_gap_`name'.tex"
local figure_title 	"Change in male wage advantage in US CZ"
local figure_list   change_in_gap

latexfigure using `figure_name', path(../2_analysis/output/figures) figurelist(`figure_list') ///
	title(`figure_title') figlab(`labels') rowsize((4/3))



