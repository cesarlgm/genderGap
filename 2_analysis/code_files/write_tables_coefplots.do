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


local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


eststo clear

grscheme, ncolor(7) style(tableau)

/*
*Models in levels
*----------------------------------------------------------------------------------------
local model_list baseline
foreach model in `model_list' {
    estimates use "output/regressions/`model'_aggregate_`indiv_sample'" 
    eststo `model'
}

*GRAPH 1: GRADIENT WITHOUT ANY CONTROLS
*------------------------------------------------------------------------------------------
coefplot `model_list', keep(*density*) yline(0) ///
    legend(off) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/baseline_gradients_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"

local figure_list baseline_gradient_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 


*GRAPH 2: ADDING GAP BETWEEN MEN AND WOMEN CHARACTERISTICS
*------------------------------------------------------------------------------------------
eststo clear

*Models in differences
local model_list baseline with_basic_controls with_educ_controls with_ind_controls
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
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 
*/

*GRAPH 3: RESULTS OF INDIVIDUAL LEVEL REGRESSIONS
*------------------------------------------------------------------------------------------
eststo clear
*Models in differences
local model_list baseline with_basic_controls with_educ_controls with_ind_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ basic demographics" 6 "+ education" 8 "Industry shares" )) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_control_gradients_individual_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 

/*
*GRAPH 3: IN DIFFERENCES
*------------------------------------------------------------------------------------------

*Models in differences
local model_list d_baseline d_with_basic_controls d_with_educ_controls 
eststo clear
foreach model in `model_list' {
    estimates use "output/regressions/`model'_aggregate_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ basic demographics" 6 "+ education" )) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/difference_gradients_`indep_var'_`indiv_sample'.pdf", replace

local figure_title "Coefficient on population density $ \beta_t $ (difference regressions)"
local figure_name "output/figures/difference_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"

local figure_list difference_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 


*--------------------------------------------------------------------------------------------