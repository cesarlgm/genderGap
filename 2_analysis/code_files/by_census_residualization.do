
*------------------------------- At this point aggregate level regressions have been accounted for---------------------------------------



/*
coefplot gap_raw gap_raw_2, vert drop(_cons *year *female* *male* *labforce_gap *ineq  *education *ind* *migrant *occ* *l_sh_routine33a*) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "No controls" 4 "+ CZ male and female quality - base `base_year'" ) ///
		)  ///
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'

graph export "output/figures/selection_graph_`indep_var'_`name'_basic`sd_name'_controls_`base_year'.pdf", replace

local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/selection_graph_`indep_var'_`name'_basic`sd_name'_controls_`base_year'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list selection_graph_`indep_var'_`name'_basic`sd_name'_controls_`base_year'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 


	
	
coefplot male female, vert keep(*density) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "Male" 4 "Female" ))  ///
	ytitle("Average worker quality (base year=`base_year')") ///
	ciopt(recast(rcap)) xline(3)

graph export "output/figures/quality_gradient_`indep_var'_`name'`sd_name'_controls_`base_year'.pdf", replace

local figure_title "Worker quality on population density gradient (base year `base_year')"
local figure_name "output/figures/quality_gradient_`indep_var'_`name'_basic`sd_name'_controls_`base_year'.tex"
local figure_note "worker quality index based in a saturaded model on education, age, born abroad, marital status and age. Worker quality indexes are computed separately for men and women. Figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list quality_gradient_`indep_var'_`name'`sd_name'_controls_`base_year'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 




coefplot *raw*, vert keep(*density*) yline(0) base ///
	xlabel(`year_label') ///
	legend(order(2 "No controls" 4 "+ CZ male and female quality - base `base_year'" ///
	6 "+ routine share of employment"  ) ///
		) xline(3, lpattern(dash)) /// 
	ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) `ytick'


graph export "output/figures/selection_graph_`indep_var'_`name'`sd_name'_controls_`base_year'.pdf", replace

local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/selection_graph_`indep_var'_`name'`sd_name'_controls_`base_year'.tex"
local figure_note "CZ-level controls are added sequentially to the regression. Each regression includes all the previous variables as controls. Figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 95\% robust confidence intervals. `add_note'"
local figure_path "../2_analysis/output/figures"

local figure_list selection_graph_`indep_var'_`name'`sd_name'_controls_`base_year'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize((10/6)) 

use `raw', clear

merge 1:1 parm using `raw_quality', nogen
merge 1:1 parm using `raw_routine', nogen

split parm, parse(#)
sort parm2 parm1
keep parm2 parm1 raw quality routine
keep if parm2=="c.`indep_var'"
split parm1, parse(".")
rename parm11 year
replace year=regexr(year,"b","")
destring year, replace
keep year raw quality routine

sort year
foreach variable in raw quality routine {
	g	d_`variable'=`variable'-`variable'[1]
	g share_`variable'=(d_raw-d_`variable')/d_raw
}
