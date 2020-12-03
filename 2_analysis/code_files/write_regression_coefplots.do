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


/*******************************************************************************************
*GRAPH 1: GRADIENT OVER THE WHOLE PERIOD
********************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time", clear
sort czone year
by czone: generate czone_pop_70=czone_pop[2]
by czone: generate l_czone_density_50=l_czone_density[1]
by czone: generate l_czone_density_70=l_czone_density[2]
generate l_czone_pop_70=log(czone_pop_70)

foreach variable in raw bas hum {
    sort czone year
    by czone: generate d_wage_`variable'_gap_70=wage_`variable'_gap-wage_`variable'_gap[2]
    by czone: generate d_wage_`variable'_gap=wage_`variable'_gap-wage_`variable'_gap[_n-2]
    
    
    eststo `variable': reg d_wage_`variable'_gap_70 l_czone_density_70 if year==2020
    eststo `variable'_w: reg d_wage_`variable'_gap_70 l_czone_density_70 [aw=czone_pop_70] if year==2020

    eststo `variable'p: reg d_wage_`variable'_gap_70 l_czone_pop_70 if year==2020
    eststo `variable'_wp: reg d_wage_`variable'_gap_70 l_czone_pop_70 [aw=czone_pop_70] if year==2020
}


tw  (scatter d_wage_raw_gap_70 l_czone_density_70 if year==2020, msymbol(o)) ///
    (lfit d_wage_raw_gap_70 l_czone_density_70 if year==2020),  legend(off) ///
    ytitle("Change in gender wage gap")  xtitle("log of population density in 1970")


graph export "output/figures/change_1970_2020.png", replace

*---------------------------------------------------------------------------------------------------
*Writting the graph
*---------------------------------------------------------------------------------------------------
*Graph absorbing the year
local figure_title "Change in gender wage gap, 1970-2020"
local figure_name "output/figures/change_1970_2020.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"


local figure_list change_1970_2020

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize(2/1) tiny key(figure:overall_change)

*---------------------------------------------------------------------------------------------------
*Writting the table
*---------------------------------------------------------------------------------------------------

local table_name 	"output/tables/change_regression_1970_2020.tex"
local col_titles   `""Raw gap""Net of basic controls""Net of human capital controls""'
local table_title 	"Gender wage gap vs density"
local key           table:overall_change
local table_note  	"changes based on unweighted estimated elasticities. Sample restricted to full-time year-round workers"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain  par star drop(_cons) se
	

textablehead using `table_name', ncols(3) coltitles(`col_titles') ///
	f("") title(`table_title') key(`key') drop


esttab raw bas hum	using `table_name', `table_options' noobs ///
	coeflab(_cons "Density elasticity $ (\beta ) $") b(%9.3fc) 
esttab rawp basp hump	using `table_name', `table_options' noobs ///
	coeflab(_cons "Density elasticity $ (\beta ) $") b(%9.3fc)

textablefoot using `table_name', notes(`table_note') dofile(`do_location')


/*******************************************************************************************
*GRAPH 1: GRADIENT WITHOUT ANY CONTROLS
********************************************************************************************/
cap drop indep_var
generate indep_var=l_czone_pop
eststo population: regress wage_raw_gap i.year#c.indep_var i.year if year>1950, vce(cl czone)
cap drop indep_var
generate indep_var=l_czone_density
eststo density: regress wage_raw_gap i.year#c.indep_var i.year if year>1950, vce(cl czone)
eststo density_bas: regress wage_bas_gap i.year#c.indep_var i.year if year>1950, vce(cl czone)



grscheme, ncolor(7) style(tableau)
*Creation of the graph
coefplot density population, keep(*indep*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
     base vert  xlabel(`year_label')  legend(order(2 "Regressor: log population density" 4 "Regressor: log of total population")) ///
    lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) level(90)
graph export "output/figures/baseline_`indiv_sample'.png", replace

coefplot density density_bas, keep(*indep*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
     base vert  xlabel(`year_label')  legend(order(2 "Raw wage gap" 4 "Gap net of basic controls")) ///
         lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) level(90)
graph export "output/figures/baseline_bas_`indiv_sample'.png", replace



*UNWEIGHTED GRAPH
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_gradients.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Alternative density measures""Alternative gender gap measures""'

local figure_list baseline_`indiv_sample' baseline_bas_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny key(figure:baseline_gradients)


/*******************************************************************************************
*CONTROLLING BY REGION AND STATE FE
********************************************************************************************/
eststo clear
eststo baseline: regress wage_raw_gap i.year#c.`indep_var' i.year if year>1950, vce(cl czone)
eststo region: regress wage_raw_gap i.year#c.`indep_var' i.year i.region if year>1950, vce(cl czone)
eststo state: regress wage_raw_gap i.year#c.`indep_var' i.year i.state if year>1950, vce(cl czone)

coefplot baseline region state , keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
     base vert  xlabel(`year_label')  legend(order(2 "No f.e." 4 "Region f.e." 6 "State f.e.") ring(0) pos(2)) ///
    lwidth(*2) ciopts(recast(rcap)) recast(connected) level(90)

graph export "output/figures/region_fe_`indiv_sample'.png", replace

*UNWEIGHTED GRAPH
local figure_title "Density gradient is robust to adding region and state fixed-effects"
local figure_name "output/figures/region_fe_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list region_fe_`indiv_sample'.png

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny key(figure:baseline_gradients)



/*******************************************************************************************
*LIMITING TO BIG CZ
********************************************************************************************/
eststo clear
generate big_CZ=(l_czone_density_50>2.5)
eststo baseline: regress wage_raw_gap i.year#c.`indep_var' i.year if year>1950, vce(cl czone)
eststo baseline_bas: regress wage_bas_gap i.year#c.`indep_var' i.year  if year>1950, vce(cl czone)
eststo bigCZraw: regress wage_raw_gap i.year#c.`indep_var' i.year  if year>1950&big_CZ, vce(cl czone)
eststo bigCZbas: regress wage_bas_gap i.year#c.`indep_var' i.year  if year>1950&big_CZ, vce(cl czone)

coefplot baseline bigCZraw , keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
     base vert  xlabel(`year_label')  legend(order(2 "All" 4 "Big CZ") ring(0) pos(2)) ///
    lwidth(*2) ciopts(recast(rcap)) recast(connected) level(90)
graph export "output/figures/baseline_big_`indiv_sample'.png", replace

coefplot baseline_bas bigCZbas , keep(*`indep_var'*) yline(0)   ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
     base vert  xlabel(`year_label')  legend(order(2 "All" 4 "Big CZ") ring(0) pos(2)) ///
    lwidth(*2) ciopts(recast(rcap)) recast(connected) level(90)
graph export "output/figures/basic_big_`indiv_sample'.png", replace


local figure_title "Density gradient is robust to adding region and state fixed-effects"
local figure_name "output/figures/big_CZ_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Big CZ are defined as those having a density of at least 2 people per square km in 1950. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_labs `""Raw wages""Net of age/race""'
local figure_list baseline_big_`indiv_sample' basic_big_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs')  ///
    title(`figure_title')  dofile(`do_location') tiny key(fig:big_CZ)


*Table of size accounted by big CZ
preserve
*Table with population accounted by big CZ
log using "output/log_files/size_big_CZ.txt", text replace
*This is the share of the US population (in the relevant age range) that is accounted by CZ I selected
gcollapse (sum) czone_pop, by(year big_CZ)
table year [aw=czone_pop], c(mean big_CZ)
log close
restore


/*****************************************************************************************************
*GRAPH WITH ALL THE GRADIENTS
**************************************************************************************************/
eststo clear
eststo  gap:      reg wage_raw_gap c.`indep_var'#ib1970.year i.year if year>1950,           vce(cl czone) 	
eststo  gap_1:    reg wage_bas_gap c.`indep_var'#ib1970.year i.year if year>1950,       vce(cl czone) 	
eststo  gap_2:    reg wage_hum_gap c.`indep_var'#ib1970.year i.year if year>1950,     vce(cl czone) 
eststo  gap_3:    reg wage_ind_gap c.`indep_var'#ib1970.year i.year if year>1950,        vce(cl czone) 	
eststo  gap_4:    reg wage_ful_gap c.`indep_var'#ib1970.year i.year if year>1950,       vce(cl czone) 	


coefplot gap_*, keep(*`indep_var'*) yline(0)   ytitle("Gender gap gradient ({&beta}{sub:t})")  ///
    base vert  xlabel(`year_label')  legend(order(2 "Net of age/rage" 4 "+ education" 6 "+ industry" 8 "+ occ") ring(0) pos(2)) ///
    lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
    level(90)


graph export "output/figures/with_control_gradients_individual_`indep_var'_`indiv_sample'.pdf", replace

local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Bars show 90\% robust confidence intervals.  Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"

local figure_list with_control_gradients_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny key(fig:controls)



/*******************************************************************************************
*LOOKING AT THE WAGE PREMIUM BY GENDER
********************************************************************************************/
foreach gender in male female {
    eststo  `gender':     reg `gender'_l_wage c.`indep_var'#ib1970.year i.year if year>1950,           vce(cl czone) 	
    eststo `gender'_1:    reg `gender'_l_wage_bas c.`indep_var'#ib1970.year i.year if year>1950,       vce(cl czone) 	
    eststo `gender'_2:    reg `gender'_l_wage_human c.`indep_var'#ib1970.year i.year if year>1950,     vce(cl czone) 
    eststo `gender'_3:    reg `gender'_l_wage_ind c.`indep_var'#ib1970.year i.year if year>1950,        vce(cl czone) 	
    eststo `gender'_4:    reg `gender'_l_wage_full c.`indep_var'#ib1970.year i.year if year>1950,       vce(cl czone) 	
}


/*******************************************************************************************
*DRIFT IN THE URBAN WAGE PREMIUM BY GENDER AND EDUCATION LEVEL
********************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time_by_education", clear

eststo clear

local filter high_education & l_czone_density_50>0
eststo male_average: regress male_cz_educsh ibn.year if  `filter', vce(cl czone) nocons
eststo female_average: regress female_cz_educsh ibn.year if `filter', vce(cl czone) nocons

coefplot male_average female_average, keep(*year) yline(0)   ytitle("Average CZ share of college graduates")  ///
    base vert  xlabel(`year_label')  legend(order(2 "Male" 4 "Female")) ///
    lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
    level(90)
graph export "output/figures/education_share_average.png", replace


*I create a graph showing the share of high education people in the CZ
eststo male_high: regress male_cz_educsh i.year i.year#c.`indep_var' if `filter', vce(cl czone)
eststo female_high: regress female_cz_educsh i.year i.year#c.`indep_var' if `filter', vce(cl czone)

coefplot male_high female_high, keep(*`indep_var'*) yline(0)   ytitle("College education gradient ({&beta}{sub:t})")  ///
    base vert  xlabel(`year_label')  legend(order(2 "Raw wage gap" 4 "Gap net of basic controls")) ///
    lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
    level(90)
graph export "output/figures/education_share_gradients.png", replace

*UNWEIGHTED GRAPH
local figure_title "Educational attainment by gender"
local figure_name "output/figures/education_share_gradients.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Average share college graduates""College share-density gradient""'

local figure_list education_share_average education_share_gradients

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  key(figure:education_shares)



eststo clear
eststo high: regress wage_raw_gap c.`indep_var'#ib1970.year i.year if year>1950&high_education,           vce(cl czone) 	
eststo low: regress wage_raw_gap c.`indep_var'#ib1970.year i.year if year>1950&!high_education,           vce(cl czone) 	

eststo high_bas: regress wage_bas_gap c.`indep_var'#ib1970.year i.year if year>1950&high_education,           vce(cl czone) 	
eststo low_bas: regress wage_bas_gap c.`indep_var'#ib1970.year i.year if year>1950&!high_education,           vce(cl czone) 	


eststo male_high: regress male_l_wage_bas c.`indep_var'#ib1970.year i.year if year>1950&high_education,           vce(cl czone) 	
eststo male_low: regress male_l_wage_bas c.`indep_var'#ib1970.year i.year if year>1950&!high_education,           vce(cl czone) 	
eststo female_high: regress female_l_wage_bas c.`indep_var'#ib1970.year i.year if year>1950&high_education,           vce(cl czone) 	
eststo female_low: regress female_l_wage_bas c.`indep_var'#ib1970.year i.year if year>1950&!high_education,           vce(cl czone) 


*Gender gap by education level
coefplot high low, keep(*`indep_var'*) vert base yline(0) ///
  xlabel(`year_label')  legend(order(2 "With bachelor degree" 4 "Without bachelor degree")) ///
  lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
  level(90)
graph export "output/figures/education_gap_full_time.png", replace

*Gender gap by education level
coefplot high_bas low_bas, keep(*`indep_var'*) vert base yline(0) ///
  xlabel(`year_label')  legend(order(2 "With bachelor degree" 4 "Without bachelor degree")) ///
  lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
  level(90)
graph export "output/figures/education_gap_bas_full_time.png", replace


*Urban premium by gender, high education
coefplot male_high female_high, keep(*`indep_var'*) vert base ///
  xlabel(`year_label')  legend(order(2 "Men" 4 "Women"))  ///
  lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
  level(90)
graph export "output/figures/education_high_premium_full_time.png", replace

*Urban premium by gender, low education
coefplot male_low female_low, keep(*`indep_var'*) vert base  ///
  xlabel(`year_label')  legend(order(2 "Men" 4 "Women"))  ///
  lwidth(*2) ciopts(recast(rline) lpattern(dash)) recast(connected) ///
  level(90)
graph export "output/figures/education_low_premium_full_time.png", replace

*Graph absorbing the year
local figure_title "The density gradient by education level"
local figure_name "output/figures/education_gradient_full_time.tex"
local figure_note "figure restricts to CZ with more than 1 people per km$^2$. Dashed lines represent 90\% confidence intervals."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Gender gap gradient""Gender gap gradient, age and race adjusted""Urban wage premium (age/race adjusted), with bachelor degree""Urban wage premium (age/race adjusted), without bachelor degree""'

local figure_list education_gap_full_time  education_gap_bas_full_time education_high_premium_full_time  education_low_premium_full_time

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location')  tiny key(figure:education) ///
    rowsize(2)



*See what can I kill here

/*******************************************************************************************
*GRAPH 1: CONTRAST BINSCATTER
********************************************************************************************/
/*
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

*/

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
     base vert  xlabel(`year_label') ciopts(recast(rline) lpattern(dash)) recast(connected) ///
  level(90)

graph export "output/figures/baseline_race_gradients_`indep_var'_`indiv_sample'.pdf", replace


*Writing the coefplot
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/baseline_race_gradients_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level. The figure restricts to year-round full time men workers."
local figure_path "../2_analysis/output/figures"

local figure_list baseline_race_gradients_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/6))  tiny  key(fig:race_gradient)
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
