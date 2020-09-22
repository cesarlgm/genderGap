*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap wage gradient by CZ
*===============================================================================

local do_location "2\_analysis/code\_files/create\_IC\_table.do"

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


replace year=2020 if year==2018
replace year=2010 if year==2011
grscheme, ncolor(7) style(tableau)


*===============================================================================
*THIS SECOND PART OF THE CODE CREATES STACKED REGRESSIONS
*===============================================================================

eststo clear

local filter if czone_pop_50/cz_area>1&year>1950
local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

eststo clear


qui eststo wage_raw_gap_uw: 		reg wage_raw_gap i.year#c.`indep_var' i.year  ///
	`filter' , vce(r)
qui eststo wage_raw_gap_we: 		reg wage_raw_gap i.year#c.`indep_var' i.year ///
	`filter' [aw=observations], vce(r)


local ptiles 5 10 15 25 75 85 90 95
	
foreach ptile in `ptiles' {
	local ptile_list  `ptile_list' (p`ptile') p`ptile'=l_czone_density
}
gcollapse (mean) wage_raw_gap `ptile_list' `filter', by(year) fast

est restore wage_raw_gap_uw
foreach ptile in `ptiles' {
	g l_czone_density=p`ptile'
	predict gap_p`ptile'
	replace  gap_p`ptile'=exp( gap_p`ptile')
	cap drop l_czone_density
}

merge m:1 year using "../1_build_database/output/average_full_time_woman_wage"

g IC=gap_p75-gap_p25
g dollarIC=l_hrwage*IC

g change_85_15=gap_p85-gap_p15
g dollar_85_15=l_hrwage*change_85_15

g change_90_10=gap_p90-gap_p10
g dollar_90_10=l_hrwage*change_90_10


expand 3
eststo clear
foreach year in `year_list' {
	if `year'>1950 {
		eststo IC`year': reg IC if year==`year'
		eststo dollarIC`year': reg dollarIC if year==`year'
		
		
		eststo change_85_15`year':	reg change_85_15 if year==`year'
		eststo dollar_85_15`year': 	reg dollar_85_15 if year==`year'
	
		
		eststo change_90_10`year': 	reg change_90_10 if year==`year'
		eststo dollar_90_10`year': 	reg dollar_90_10 if year==`year'
		
		eststo mean`year': 			reg wage_raw_gap if year==`year'
	}
}

local table_name 	"output/tables/IC_table_`name'.tex"
local col_titles   1970 1980 1990 2000 2010 2020
local table_title 	"Male advantange changes implied by estimated elasticities"
local key tab:IC
local table_note  	"changes based on unweighted estimated elasticities in table \ref{tab:elast}. Sample restricted to full-time year-round workers. I compute the dollar figures using the wage of the average full-time year-round woman in my sample, assuming she worked 40 hrs a week during 40 weeks. All figures are in 2018 dollars"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain  not par star 
	

textablehead using `table_name', ncols(6) coltitles(`col_titles') ///
	f("p.p. change in male advantage") title(`table_title') key(`key') drop

esttab mean* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "Average male advantage") b(%9.2fc)
esttab IC* 				using `table_name', `table_options' noobs ///
	coeflab(_cons "\midrule p75-p25") b(%9.2fc)
esttab dollarIC* 				using `table_name', `table_options' noobs ///
	coeflab(_cons "Relative male gain (\\$ USD)")	b(%9.0fc)
	
esttab change_85_15* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "\midrule p85-p15") b(%9.2fc)
esttab dollar_85_15* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "Relative male gain (\\$ USD)")	b(%9.0fc)
	
esttab change_90_10* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "\midrule p90-p10")  b(%9.2fc)
esttab dollar_90_10* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "Relative male gain (\\$ USD)")	b(%9.0fc)
	
textablefoot using `table_name', notes(`table_note') dofile(`do_location')
