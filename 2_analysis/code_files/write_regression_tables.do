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


*AGGREGATE LEVEL MODELS
*----------------------------------------------------------------------------------------
local model_list baseline with_basic_controls with_educ_controls with_ind_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_aggregate_`indiv_sample'" 
    eststo `model'

    clear
    regsave 
    keep  if regexm(var, "l_czone_density")
    g year=1960+10*_n
    g source="`model'"
    tempfile `model'_est
    save ``model'_est'
}
clear
foreach model in `model_list' {
    append using ``model'_est'
}
/*
sort source year
by source: g gradient_diff=coef[_n]-coef[1]

sort year source


generate dist_from_flat=abs(gradient_diff)
sort  year source
by year: generate share_baseline=1-abs(dist_from_flat)/abs(dist_from_flat[1])
 




separate gradient_diff, by(source)

tw line `r(varlist)' year, recast(connected) ///
    legend(order(1 "No controls" 2 "+ basic demographics" ///
     3 "+ education" 4 "+ industry shares")) yline(0, lcolor(red)) ///
     ytitle("Gradient in t - gradient in 1970 ({&beta}{sub:t}-{&beta}{sub:1970})") ///
     xtitle(year)

graph export "output/figures/gradient_change_`indep_var'_`indiv_sample'.pdf", replace





local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Cross-sectional gradient""Change in the gradient""'

local figure_list with_control_gradients_`indep_var'_`indiv_sample' gradient_change_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize(2)





*INDIVIDUAL LEVEL MODELS
*----------------------------------------------------------------------------------------
local model_list baseline with_basic_controls with_educ_controls with_ind_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'

    clear
    regsave 
    keep  if regexm(var, "l_czone_density")
    g year=1960+10*_n
    g source="`model'"
    tempfile `model'_est
    save ``model'_est'
}
clear
foreach model in `model_list' {
    append using ``model'_est'
}

sort source year
by source: g gradient_diff=coef[_n]-coef[1]

sort year source


generate dist_from_flat=abs(gradient_diff)
sort  year source
by year: generate share_baseline=1-abs(dist_from_flat)/abs(dist_from_flat[1])
 




separate gradient_diff, by(source)

tw line `r(varlist)' year, recast(connected) ///
    legend(order(1 "No controls" 2 "+ basic demographics" ///
     3 "+ education" 4 "+ industry shares")) yline(0, lcolor(red)) ///
     ytitle("Gradient in t - gradient in 1970 ({&beta}{sub:t}-{&beta}{sub:1970})") ///
     xtitle(year)

graph export "output/figures/gradient_change_individual_`indep_var'_`indiv_sample'.pdf", replace





local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Basic individual level controls include full set of: race, age, marital status and foreign born dummies. Education is measured using a 4-level education dummies: HS dropout, HS graduate, some college and bachelor +. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Cross-sectional gradient""Change in the gradient""'

local figure_list with_control_gradients_individual_`indep_var'_`indiv_sample' ///
    gradient_change_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize(2)


