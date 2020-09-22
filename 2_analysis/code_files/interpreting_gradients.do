local do_location "2\_analysis/code\_files/create\_gender\_gap\_gradient\_graphs.do"

gettoken analysis_type 	0: 0
gettoken absorb 		0: 0
gettoken indep_var		0: 0
di "`absorb'"

local year_list `0'

local density_filter 1


if `absorb'==0 {
	local take_out
}
else if `absorb'==1 {
	local take_out control(year) noadd 
	local take_out_name "_gradient_only" 
}

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


replace year=2020 if year==2018
replace year=2010 if year==2011
grscheme, ncolor(7) style(tableau)

*===============================================================================
*This first part of the code computes gradients by year
*===============================================================================

cap rename raw_wage_gap wage_raw_gap

eststo clear
local filter  if czone_pop_50 /cz_area>1
qui eststo raw_gap: 		reg wage_raw_gap i.year#c.`indep_var' i.year `filter', vce(r)

*preserve
tempfile diff_dense
local ptile_list
foreach ptile in 5 10 15 25 75 85 90 95 {
	local ptile_list `ptile_list' (p`ptile') p`ptile'=`indep_var'
}
gcollapse `ptile_list' (mean) mean=wage_raw_gap (sd) sd=wage_raw_gap ///
	if czone_pop_50 /cz_area>1, by(year)
save `diff_dense'


*restore

foreach ptile in 5 10 15 25 75 85 90 95{
	cap drop `indep_var'
	g	`indep_var'=p`ptile' 
	predict gap`ptile', 
}

g	gap7525=gap75-gap25
g	gap8515=gap85-gap15
g	gap9010=gap90-gap10
g	gap9505=gap95-gap5

g	gap_sd7525=gap7525/sd
g	gap_sd8515=gap8515/sd
g	gap_sd9010=gap9010/sd
g	gap_sd9505=gap9505/sd

g	gap_mean8515=gap8515/mean
g	gap_mean9010=gap9010/mean
g	gap_mean9505=gap9505/mean


tw line gap_mean* year if year>1950, recast(connected) ytitle("Gap size relative to the mean")
tw line gap_sd* year if year>1950, recast(connected) ytitle("Gap size in standar deviations")
