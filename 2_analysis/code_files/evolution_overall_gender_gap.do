*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap wage gradient by CZ
*===============================================================================

local analysis_type `1'

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
	local add_note "full-time year-round workers."
}

use "../1_build_database/output/czone_level_dabase_`name'", clear

sort czone year
egen period=group(year)

xtset czone period

*Overall evolution of the gap
local filter czone_pop_50/cz_area>1

cap rename raw_wage_gap wage_raw_gap
grscheme, ncolor(1) style(Reds) 
*What do I see: dispersion has reduced over time, but it remains large
graph box wage_raw_gap if year>1950&`filter' , over(year) noout ///
	ytitle("log(male wage)-log(female wage)")
	
graph export "output/figures/cz_gap_dispersion_`name'.pdf", replace

local figure_title "Evolution of raw gender gap across CZ"
local figure_name "output/figures/cz_gap_dispersion_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$ and `add_note'."
local figure_path "../2_analysis/output/figures"

local figure_list cz_gap_dispersion_`name'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 

	
*How persistent is the wage gap
eststo clear
foreach gap in raw basic educ ind occ {
	egen sd_`gap'=		sd(wage_`gap'_gap) if  year>1950&`filter', by(year) 
	egen mean_`gap'=	mean(wage_`gap'_gap) if  year>1950&`filter', by(year) 
	replace wage_`gap'_gap=(wage_`gap'_gap-mean_`gap')/sd_`gap'
	by czone: g wage_`gap'_gap1970=wage_`gap'_gap[2]
	
	cap drop indep_var
	g	indep_var=wage_`gap'_gap1970
	eststo `gap': reg wage_`gap'_gap c.indep_var#i.year  if  year>1970&`filter'
}



*Differences in the gender gap are persistent, but persistence has decreased over
*time

*My conclusion here: regional variation in the gender gap matters. 
*It is persistent and it is relatively big.
local year_label  1 "1980" 2 "1990" 3 "2000" 4 "2010" 5 "2020"

coefplot raw basic educ, vert drop(_cons *year) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Raw wages" 4 "+ age, race, stafe f.e." ///
		6 "+ education f.e.") ///
		ring(0) pos(2)) ///
	ytitle("Regression coefficient") ///
	ciopt(recast(rcap)) ytick(0(.1).7, tlcolor(gs0) grid)

graph export "output/figures/cz_gender_gap_persistence_`name'.pdf", replace

local figure_title ""
local figure_name "output/figures/cz_gender_gap_persistence_`name'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$ and `add_note'. Bars show 95\% robust confidence intervals. Both dependent and inpendent variables are standardized."
local figure_path "../2_analysis/output/figures"

local figure_list cz_gender_gap_persistence_`name'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 
