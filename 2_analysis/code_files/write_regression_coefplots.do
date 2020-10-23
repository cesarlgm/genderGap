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
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'
local       do_location         "2\_analysis/code\_files/write\_regression\_coefplots.do"

local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


eststo clear

grscheme, ncolor(7) style(tableau)


/*******************************************************************************************
*GRAPH 1: GRADIENT WITHOUT ANY CONTROLS
********************************************************************************************/

*Graph by gender
*--------------------------------------------------------------------------------------------
local model_list baseline baseline_region baseline_state  baseline_region_trend // baseline_state_trend
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}


*Creation of the graph
coefplot `model_list', keep(*`indep_var'*) yline(0) ///
    legend(order(2 "No controls" 4 "Census division f.e" 6 "State f.e." 8 "Census division x year f.e." ) ///
    ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/baseline_gradients_`indep_var'_`indiv_sample'.pdf", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list baseline_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny 



*Graph by race
*--------------------------------------------------------------------------------------------
local model_list    baseline_race  
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

*Creation of the graph
coefplot `model_list', keep(*`indep_var'*) yline(0) ///
    legend(off) ///
    ytitle("w{sup:white}-w{sup:black} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/baseline_race_gradients_`indep_var'_`indiv_sample'.pdf", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_race_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level. The figure restricts to year-round full time men workers."
local figure_path "../2_analysis/output/figures"

local figure_list baseline_race_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny 




/*


*GRAPH 2: ADDING GAP BETWEEN MEN AND WOMEN CHARACTERISTICS
********************************************************************************************

eststo clear

*Models in differences
local model_list baseline with_bas_controls with_hum_controls with_ful_controls with_fam_controls with_trantime_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_aggregate_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ basic demographics" 6 "+ education" 8 "Industry shares" )) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_control_gradients_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize((10/6))  tiny


*GRAPH 3: RESULTS OF INDIVIDUAL LEVEL REGRESSIONS
*------------------------------------------------------------------------------------------
eststo clear
*Models in differences
local model_list baseline_region_trend with_hum_controls with_ful_controls with_ffu_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ human capital controls" 6 "+ industry and occupation"  8 "+ family variables") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_control_gradients_individual_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Regression includes census division $\times $ year fixed-effects. Additional controls include number of children, marital status and being a female head of household. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny

/**********************************************************************************************
GRAPH 4: CONTROLLING FOR CZ LEVEL CHARACTERISTICS
**********************************************************************************************/
*/
eststo clear
*Models in differences
local model_list controls0 controls1 controls2 controls3 controls4
foreach model in `model_list' {
    estimates use "output/regressions/`model'_czone_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*year#c.`indep_var') yline(0) ///
    legend(order(2 "No controls" 4 "+ sh. high educ." 6 "+ wage inequality"  8 "+ lfp gap" 10 "+ sh manufacturing") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_control_gradients_czone_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_czone_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Regression includes census division $\times $ year fixed-effects. Additional controls include number of children, marital status and being a female head of household. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_czone_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny


/**********************************************************************************************
GRAPH 5: WITH WITHOUT CHILDREN
**********************************************************************************************/


eststo clear
*Models in differences
local model_list baseline human basic full full_c full_c
foreach model in `model_list' {
    *People without children
    estimates use "output/regressions/`model'0_czone_`indiv_sample'" 
    eststo `model'0

    *People with children
    estimates use "output/regressions/`model'1_czone_`indiv_sample'" 
    eststo `model'1
}

coefplot  full0 full_c0   full1  full_c1 , keep(*year#c.`indep_var') yline(0) ///
    legend(order(2 "No children" 4 "No children, controls" 6 "With children" 8 "With children, controls") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/by_children_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ conditional conditional on having children"
local figure_name "output/figures/by_children_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Regression includes census division fixed-effects. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list by_children_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny

/*
/**********************************************************************************************
GRAPH 5: GRAPH MARRIED / SINGLE
**********************************************************************************************/
eststo clear
*Models in differences
local model_list baseline //basic human
foreach model in `model_list' {
    *People without children
    estimates use "output/regressions/`model'0_married_czone_`indiv_sample'" 
    eststo `model'0

    *People with children
    estimates use "output/regressions/`model'1_married_czone_`indiv_sample'" 
    eststo `model'1
}

coefplot baseline0 baseline1, keep(*year#c.`indep_var') yline(0) ///
    legend(order(2 "Single" 4 "Married") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/by_married_czone_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/by_married_czone_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Regression includes census division. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list  by_married_czone_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny


