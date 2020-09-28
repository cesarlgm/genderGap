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



eststo clear

grscheme, ncolor(7) style(tableau)

local do_location "code\_files/kernel\_density\_movement.do"

use "temporary_files/aggregate_regression_file_final_`indiv_sample'", clear

generate high_density=.
foreach year in `year_list' {
    cap drop temp
    xtile temp=l_czone_density  if year==`year', nq(3)
    replace high_density=0 if temp==1
    replace high_density=3 if temp==3
}

tw (kdensity l_hrwage_gap if !high_density , lwidth(medthick)) ///
     (kdensity l_hrwage_gap if high_density,  lwidth(medthick)), ///
    by(year) ytitle("Density") xtitle("Gender wage gap") ///
    legend(order(1 "Low density (bottom tercile)" 2 "High density (top tercile)") ring(0) pos(2))

graph export "output/figures/distribution_gap_movement_`indiv_sample'.png", replace



local figure_title ""
local figure_name "output/figures/distribution_gap_movement_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_list distribution_gap_movement_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs' `figure_labs') ///
    title(`figure_title')  dofile(`do_location') rowsize((10/8)) 


    