*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: 	creates box plot showing variation across years in gender gaps
*					CZ
*===============================================================================

local do_location "2\_analysis/create\_gender\_gap\_dispersion\_graphs.do"

local year_list `0'

local density_filter 1

use "../1_build_database/output/czone_level_dabase_gender", clear
	
grscheme, ncolor(6) style(fire)

label var raw_wage_gap  "log(male wage)-log(female wage)"
graph box raw_wage_gap if czone_pop_50>100000, over(year) noout

graph export "output/figures/cz_variation_gender_gap.pdf", replace

local figure_name "output/figures/cz_variation_gender_gap.tex"
local figure_title "The gender wage gap across US CZ, 1960-2020"
local figure_note "includes CZ with population densities above 1 person per square kilometer"
local figure_path	"../2_analysis/output/figures"

latexfigure using `figure_name', path(`figure_path') ///
	figurelist(cz_variation_gender_gap) title(`figure_title') ///
	note(`figure_note') key(fig:cz_dispersion)
