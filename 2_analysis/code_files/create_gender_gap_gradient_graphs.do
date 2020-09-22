*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap wage gradient by CZ
*===============================================================================

local do_location "2\_analysis/code\_files/create\_gender\_gap\_gradient\_graphs.do"

gettoken analysis_type 	0: 0
gettoken absorb 		0: 0
gettoken indep_var		0: 0
gettoken standardize	0: 0
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


replace year=2020 if year==2018
replace year=2010 if year==2011
grscheme, ncolor(7) style(tableau)

*===============================================================================
*This first part of the code computes gradients by year
*===============================================================================
cap rename raw_wage_gap wage_raw_gap

foreach year in `year_list' {
	local filter if year==`year'&czone_pop_50/cz_area>`density_filter'
	local fit linetype(lfit)

	*Wages
	if `absorb'==0 {
		cap drop 		yvar1
		g				yvar1= l_hrwage`y1' `filter'
		cap drop		yvar2
		g				yvar2= l_hrwage`y2' `filter'
		
	}
	else if `absorb'==1 {
		reg 		 l_hrwage`y1' `filter'
		cap drop 	yvar1
		predict 	yvar1 `filter', residuals
		
		reg 		 l_hrwage`y2' `filter'
		cap drop 	yvar2
		predict 	yvar2 `filter', residuals
	}
	
	binscatter yvar1 yvar2  `indep_var' `filter', `scatter_options' ///
		 ytitle("Average wage") legend(`legend') `fit' yscale(range(-.2 .3)) ylabel(-.2(.1).3)
	graph export "output/figures/`name'`take_out_name'_`indep_var'_city_raw_wage_gradient`year'.png", replace
	

	*Wages
	if `absorb'==0 {
		cap drop 		yvar1
		g				yvar1= wage_tilde`y1' `filter'
		cap drop 		yvar2
		g				yvar2= wage_tilde`y2' `filter'
		
	}
	else if `absorb'==1 {
		reg 		 wage_tilde`y1' `filter'
		cap drop 	yvar1
		predict 	yvar1 `filter', residuals
		
		reg 		 wage_tilde`y2' `filter'
		cap drop 	yvar2
		predict 	yvar2 `filter', residuals
	}
	
	*Residualized wages
	binscatter yvar1 yvar2  `indep_var' `filter', `scatter_options' ///
		 ytitle("Residualized average wage") `fit'  yscale(range(-.2 .2)) ylabel(-.2(.05).2) legend(`legend')
	graph export "output/figures/`name'`take_out_name'_`indep_var'_city_wage_gradient`year'.png", replace
	
	*Labor force participation
	if `absorb'==0 {
		local range 	0 .5
		local y_label 	0(.1).5
		cap drop 		yvar
		g				yvar=labfore_gap `filter'
		
	}
	else if `absorb'==1 {
		local range -.1 .1
		local 		y_label -.15(.05).15
		reg 		labfore_gap `filter'
		cap drop 	yvar
		predict 	yvar `filter', residuals
	}
	
	
	*Labor force
	cap binscatter yvar `indep_var'  `filter', `scatter_options' ///
		ytitle("female LFP / male LFP") `fit' yscale(range(`range')) ylabel(`y_label') 
	cap graph export "output/figures/`name'`take_out_name'_`indep_var'_labforce_gap`year'.png", replace
	
	*Raw wage gap
	if `absorb'==0 {
		local range 	0 .5
		local y_label 	0(.1).5
		cap drop 		yvar
		g				yvar=raw_wage_gap `filter'
		
	}
	else if `absorb'==1 {
		local range -.1 .1
		local 	y_label -.1(.02).1
		reg 	raw_wage_gap `filter'
		cap drop 	yvar
		predict 	yvar `filter', residuals
	}
	
	binscatter yvar `indep_var'  `filter', `scatter_options' ///
		ytitle(`y_title_gap')  yscale(range(`range')) ylabel(`y_label') 
	graph export "output/figures/`name'`take_out_name'_`indep_var'_raw_wage_gap`year'.png", replace
	
	*Residualized wage gap
	binscatter wage_gap `indep_var'  `filter', `scatter_options'  ///
		ytitle(`y_title_gap') yscale(range(0 .5)) ylabel(0(.1).5) 
	graph export "output/figures/`name'`take_out_name'_`indep_var'_wage_gap`year'.png", replace
				
	*Top tail inequality
	binscatter top_tail_ineq `indep_var'  `filter', `scatter_options'  ///
		ytitle(`y_title_gap') yscale(range(0 1)) ylabel(0(.1)1)  `fit' 
	graph export "output/figures/`name'`take_out_name'_`indep_var'_top_tail_ineq`year'.png", replace
	
	*Bottom tail inequality
	binscatter bot_tail_ineq `indep_var'  `filter', `scatter_options'  ///
		ytitle(`y_title_gap') yscale(range(0 1)) ylabel(0(.1)1)  `fit'
	graph export "output/figures/`name'`take_out_name'_`indep_var'_bot_tail_ineq`year'.png", replace
	
	*Overal inequality
	binscatter overall_ineq `indep_var'  `filter', `scatter_options'  ///
		ytitle(`y_title_gap') yscale(range(0 2)) ylabel(0(.2)2)  `fit' 
	graph export "output/figures/`name'`take_out_name'_`indep_var'_overall_ineq`year'.png", replace
		
	*Manufacturing share
	binscatter ind_manufacturing `indep_var'  `filter', `scatter_options' ///
		ytitle("Share in manufacturing") yscale(range(0 .5)) ylabel(0(.1).5) `fit' 
	graph export "output/figures/`year'_`indep_var'_manufacturing.png", replace
	
	*Service industry share
	binscatter ind_services `indep_var'  `filter', `scatter_options' ///
		ytitle("Share in services") yscale(range(0 .5)) ylabel(0(.1).5) `fit'
	graph export "output/figures/`year'_`indep_var'_services.png", replace
}


*===============================================================================
*COMPARISON URBAN WAGE PREMIUM BETWEEN MEN AND WOMEN SLIDES
*===============================================================================
*COMPARISON OF 1950 VS 2010

*RAW WAGE GAP
*===============================================================================
local figure_title "Average wages by `tex_title'"
local figure_name "output/figures/urban_wage_premium_`name'_`indep_var'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. For visualization purpuses, the across CZ average wage if substracted from the levels for each gender separately."
local figure_path "../2_analysis/output/figures"
local figure_labs 1970 2020

local figure_list
foreach year in `figure_labs' {
	local figure_list `figure_list' `name'`take_out_name'_`indep_var'_city_raw_wage_gradient`year'
}



local figure_labs `""1970: raw wage""2020: raw wage""'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	rowsize(2) note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location')

	
*RESIDUALIZED WAGE GAP
*===============================================================================
local figure_title "Average wages by `tex_title'"
local figure_name "output/figures/urban_wage_residual_premium_`name'_`indep_var'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. For visualization purpuses, the across CZ average wage if substracted from the levels for each gender separately.  Residualized wages net out state, age and race fixed effects."
local figure_path "../2_analysis/output/figures"
local figure_labs 1970 2020


local figure_list
foreach year in `figure_labs' {
	local figure_list `figure_list' `name'`take_out_name'_`indep_var'_city_wage_gradient`year'
}



local figure_labs `""1970: residualized""2020: residualized""'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	rowsize(2) note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location')

	
*RESIDUALIZED WAGE GAP
*===============================================================================
local figure_title "Gender wage gap by `tex_title'"
local figure_name "output/figures/urban_gender_gap_`name'_`indep_var'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. For visualization purpuses, the across CZ average wage if substracted from the levels for each gender separately."
local figure_path "../2_analysis/output/figures"
local figure_labs 1970 2020


local figure_list
foreach year in `figure_labs' {
	local figure_list `figure_list' `name'`take_out_name'_`indep_var'_raw_wage_gap`year'
}



local figure_labs `""1970""2020""'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	rowsize(2) note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location')
