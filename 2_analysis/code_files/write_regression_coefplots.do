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
/*
/*******************************************************************************************
*GRAPH 1: CONTRAST BINSCATTER
********************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time", clear
sort czone year
by czone: generate czone_pop_70=czone_pop[2]
by czone: generate l_czone_density_50=l_czone_density[1]


grscheme, ncolor(7) style(tableau)

binscatter wage_raw_gap `indep_var'   if inlist(year, 2020), nq(25) by(year) ///
    legend(off)  xtitle(log population density) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau) absorb(year)

graph export  "output/figures/`indep_var'_2020.png", replace



*Graph absorbing the year
local figure_title "Gender wage gap and population density in 2020"
local figure_name "output/figures/`indep_var'_2020.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Each point represents about 25 CZ. Year fixed effects are absorbed."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_2020

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


*---------------------------------------------------------
*LIMITING TO THE LARGEST CZ
binscatter wage_raw_gap `indep_var'   if inlist(year, 2020)&l_czone_density_50>2, nq(25) by(year) ///
    legend(off)  xtitle(log population density)   yscale(range(.1 .22)) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau) absorb(year) 

graph export  "output/figures/`indep_var'_2020_big_CZ.png", replace



local figure_title "Gender wage gap and population density in the largest CZ"
local figure_name "output/figures/`indep_var'_2020_big_CZ.tex"
local figure_note "figure restricts to CZ with more than 1 people per km$^2$. Each point represents about 13 CZ."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_2020_big_CZ

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


*WEIGHTING BY POPULATION
binscatter wage_raw_gap `indep_var'   if inlist(year, 2020) [aw=czone_pop], nq(25) by(year) ///
    legend(off)  xtitle(log population density) yscale(range(.1 .22)) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau) absorb(year) 

graph export  "output/figures/`indep_var'_2020_w.png", replace

*Graph absorbing the year
local figure_title "Gender wage gap and population density in 2020 (population weighted)"
local figure_name "output/figures/`indep_var'_2020_w.tex"
local figure_note "figure restricts to CZ with more than 1 people per km$^2$. Each point represents about 4 percent of the working age population."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_2020_w

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 

*CONTROLLING FOR HUMAN CAPITAL
binscatter wage_raw_gap wage_hum_gap `indep_var'   if inlist(year, 2020), nq(25) by(year) ///
    xtitle(log population density) yscale(range(.1 .22)) ///
    legend(order(1 "Raw gap" 2 "Residualized gap") pos(7) ring(0)) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau) absorb(year) 

graph export  "output/figures/`indep_var'_2020_hum.png", replace

*Graph absorbing the year
local figure_title "Gender wage gap and population density in 2020 (population weighted)"
local figure_name "output/figures/`indep_var'_2020_hum.tex"
local figure_note "figure restricts to CZ with more than 1 people per km$^2$. Each point represents about 4 percent of the working age population."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_2020_hum

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny


binscatter wage_raw_gap `indep_var'   if inlist(year, 1970,2020), nq(25) by(year) ///
    legend(ring(0) pos(11) order(1 "1970" 2 "2020"))  xtitle(log population density) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau) absorb(year)

graph export  "output/figures/`indep_var'_1970_vs_2020.png", replace

binscatter wage_raw_gap `indep_var' if inlist(year, 1970,2020), nq(25) by(year) ///
    legend(ring(0) pos(11) order(1 "1970" 2 "2020"))  xtitle(log population density) ///
    ytitle("log(male wages) - log(female wages)") colors(tableau)

graph export  "output/figures/`indep_var'_1970_vs_2020_level.png", replace


*Graph absorbing the year
local figure_title "Gender wage gap and population density"
local figure_name "output/figures/`indep_var'_1970_vs_2020.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Each point represents about 25 CZ. Year fixed effects are absorbed."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_1970_vs_2020

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


*Without absorbing the year
local figure_title "Gender wage gap and population density"
local figure_name "output/figures/`indep_var'_1970_vs_2020_level.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Each point represents about 2.5 percent of full-time workers in the relevant year. Year fixed effects are absorbed."
local figure_path "../2_analysis/output/figures"


local figure_list `indep_var'_1970_vs_2020_level

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


/*******************************************************************************************
*GRAPH 1: GRADIENT WITHOUT ANY CONTROLS
********************************************************************************************/
*/
*Graph by gender
*--------------------------------------------------------------------------------------------
local model_list baseline //baseline_region baseline_state  baseline_region_trend // baseline_state_trend
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'

    estimates use "output/regressions/`model'_individual_`indiv_sample'_w" 
    eststo `model'_w
}

grscheme, ncolor(7) style(tableau)
*Creation of the graph
coefplot baseline, keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') 
graph export "output/figures/baseline_`indep_var'_`indiv_sample'.png", replace


*-------------------------------------------------------------------------------------------------
*UNWEIGHTED GRAPH
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list baseline_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny 

*-------------------------------------------------------------------------------------------------
*WEIGHTED GRAPH
grscheme, ncolor(7) style(tableau)
*Creation of the graph
coefplot baseline_w, keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') 

graph export "output/figures/baseline_w_`indep_var'_`indiv_sample'.png", replace

local figure_title "Coefficient on population density $ \beta_t $ (population weighted)"
local figure_name "output/figures/baseline_w_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to more than 1 people per km$^2$ in 1950. Regressions weighted by the CZ population in 1970. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list baseline_w_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny 

*-------------------------------------------------------------------------------------------------
*LARGEST COMMUTING CZONES
*-------------------------------------------------------------------------------------------------

local model_list baseline_large 
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

*WEIGHTED GRAPH
grscheme, ncolor(7) style(tableau)
*Creation of the graph
coefplot baseline_large, keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') 

graph export "output/figures/baseline_large_`indep_var'_`indiv_sample'.png", replace

local figure_title "Coefficient on population density $ \beta_t $ for largest CZ"
local figure_name "output/figures/baseline_large_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to more than 2 people per km$^2$ in 1950. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list baseline_large_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny 

*-------------------------------------------------------------------------------------------------
*ABORBING WITHIN REGION VARIATION
*-------------------------------------------------------------------------------------------------
local model_list baseline baseline_region baseline_state  baseline_region_trend // baseline_state_trend
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

coefplot  baseline baseline_region baseline_state  baseline_region_trend, ///
    keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') ///
    legend(order(2 "Baseline" 4 "Region f.e." 6 "State f.e." 8 "Region x time f.e.") ///
    ring(0) pos(2))

graph export "output/figures/baseline_fe_`indep_var'_`indiv_sample'.png", replace

local figure_title "Coefficient on population density $ \beta_t $ adding fixed effects"
local figure_name "output/figures/baseline_fe_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to more than 1 people per km$^2$ in 1950. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list baseline_fe_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny 

*-------------------------------------------------------------------------------------------------
*CONTROLLING FOR INDIVIDUAL CHARACTERISTICS
*-------------------------------------------------------------------------------------------------
local model_list baseline with_hum_controls 
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ human capital controls") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_control_gradients_individual_`indep_var'_`indiv_sample'.pdf", replace


local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny


local model_list baseline with_hum_controls with_ful_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'
}

coefplot `model_list', keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ human capital controls" 6 "+ ind and occ") ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

graph export "output/figures/with_ind_gradients_individual_`indep_var'_`indiv_sample'.pdf", replace



local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_ind_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_ind_gradients_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny


/*
/********************************************************************************************************
CHANGE IN URBAN WAGE GRADIENT
********************************************************************************************************/
local model_list male_urban_premium  female_urban_premium 
foreach model in `model_list' {
    estimates use "output/regressions/`model'_`indiv_sample'" 
    eststo `model'

    estimates use "output/regressions/`model'_w_`indiv_sample'" 
    eststo `model'_w
}

coefplot `model_list' , keep(*`indep_var'*) yline(0) ///
    legend(order(2 "Men" 4 "Women" ) ///
    ring(0) pos(2)) ///
    ytitle("Average wage")  ///
    ciopt(recast(rcap)) base vert  ///
    xlabel(`year_label') ///
    yscale(range(0 .1)) ylabel(0(.02).1)  

graph export "output/figures/premium_by_gender_`indiv_sample'.png", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/premium_by_gender_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list premium_by_gender_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')   tiny 



local model_list d_male_l_wage  d_female_l_wage 
foreach model in `model_list' {
    estimates use "output/regressions/`model'_`indiv_sample'" 
    eststo `model'
}


local year_label   1 "1990" 2 "2000" 3 "2010" 4 "2020"


coefplot `model_list' , keep(*`indep_var'*) yline(0) ///
    legend(order(2 "Men" 4 "Women" ) ///
    ring(0) pos(2)) ///
    ytitle("Bi-decadal change in log average wage")  ///
    ciopt(recast(rcap)) base vert  ///
    xlabel(`year_label')

graph export "output/figures/two_decade_changes_`indiv_sample'.pdf", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/two_decade_changes_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list two_decade_changes_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 

/*********************************************************************************
    LABOR FORCE PARTICIPATION
**********************************************************************************/


local model_list lfp_gap d_male_lfp  d_female_lfp 
foreach model in `model_list' {
    estimates use "output/regressions/`model'_`indiv_sample'" 
    eststo `model'
}


local year_label  1 "1970" 2 "1990" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


coefplot lfp_gap , keep(*`indep_var'*) yline(0) ///
    ytitle("Men's lfp - womens' lfp")  ///
    ciopt(recast(rcap)) base vert  ///
    xlabel(`year_label')

graph export "output/figures/lfp_gap_`indiv_sample'.pdf", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/two_decade_changes_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list lfp_gap_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


local year_label  1 "1990" 2 "2000" 3 "2010" 4 "2020"


coefplot d_male_lfp d_female_lfp , keep(*`indep_var'*) yline(0) ///
    ytitle("Bi-decadal change in LFP")  ///
    legend(order(2 "Men" 4 "Women") ring(0) pos(11)) ///
    ciopt(recast(rcap)) base vert  ///
    xlabel(`year_label')


graph export "output/figures/d_lfp_gender_`indiv_sample'.pdf", replace



*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/change_lfp_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"


local figure_list d_lfp_gender_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny 


/*

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


