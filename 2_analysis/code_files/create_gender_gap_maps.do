*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates map with gender gap by cz
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
	local add_note " and full-time year-round workers."
}


local do_location "2\_analysis/code\_files/create\_gender\_gap\_maps.do"
local year_list 1970 1980 1990 2000 2010 2020



*Some preliminary fixes to the map database
tempfile map_tomerge
	use "../1_build_database/input/cz1990_data", clear
	use "../1_build_database/input/cz1990_data", clear
	rename cz czone
	rename cz_id _ID
	drop *_center
save `map_tomerge'

grscheme, ncolor(7) style(tableau)

use "../1_build_database/output/czone_level_dabase_`name'", clear

merge m:1 czone year using ///
	"../1_build_database/output/gender_occ_empshares_database_1950_ind1950", keep(1 3) nogen
	
g czone_density=exp(l_czone_density)

sort czone year
by czone: g czone_density1950=czone_density[1]
g		  l_czone_density1950=log10(czone_density1950)


*-------------------------------------------------------------------------------
*Scatter plot in density
*-------------------------------------------------------------------------------
local filter if year==2020
tw scatter l_czone_density l_czone_density1950 `filter', msymbol(O) msize(1) || ///
	lfit l_czone_density l_czone_density1950 `filter' , xtitle(log of population density in 1950) ///
	ytitle(log of population density in 2010) legend(off)
	
graph export "output/figures/persistence_population_density.png", replace

foreach variable in wage_raw_gap{
	replace `variable'=. if czone_density1950<1
}

merge m:1 czone using `map_tomerge', keep(3) nogen

/*

foreach year in `year_list' {
	local filter if year==`year'
	replace czone_density=round(czone_density,.01)
	
	
	*Map of population density
	spmap czone_density `filter' using "../1_build_database/input/cz1990_coor", ///
		id(_ID) fcolor(Blues2) legtitle("People per square km")   clnumber(7) 
	graph export "output/figures/czone_density`year'.png", replace
	
	replace wage_raw_gap=round(wage_raw_gap,.01)
	
	*Map of raw gender wage gap
	spmap wage_raw_gap `filter'  using "../1_build_database/input/cz1990_coor", ///
		id(_ID) fcolor(Reds) legtitle("Raw gender wage gap") clnumber(7)
	graph export "output/figures/raw_wage_map`year'_`name'.png", replace
	
	*Map of share of employment of male-intensive industries
	spmap male_ind_share `filter'  using "../1_build_database/input/cz1990_coor", ///
		id(_ID) fcolor(Reds) legtitle("Raw gender wage gap") clnumber(7)
	graph export "output/figures/male_ind_share`year'_`name'.png", replace
}

*/
local figure_title "The geography of population density and its persistence"
local figure_name "output/figures/density_geography.tex"
local figure_note "Figure restricts to czones with population densities above 1 person per km$^2$"
local figure_list czone_density2020 persistence_population_density
local figure_lab `""Population density in 2020""Density in 2020 vs 1950""'
local figure_path "../2_analysis/output/figures"
latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	rowsize(2) note(`figure_note') dofile(`do_location') figlab(`figure_lab') ///
	title(`figure_title') tiny key(fig:map)


local figure_title "The gender gap in the US in 2020"
local figure_name "output/figures/raw_gender_wage_gap_map_`name'.tex"
local figure_note "darker colors denote higher relative wages for men. Figure restricts to czones with population densities above 1 person per km$^2$`add_note'"
local year_list 	2020
local figure_list
foreach year in `year_list' {
	local figure_list `figure_list' raw_wage_map`year'_`name'
}
local figure_lab  `year_list'
local figure_path "../2_analysis/output/figures"
latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') dofile(`do_location') figlab(`figure_lab') ///
	title(`figure_title') nodate key(fig:gap_map2020) tiny


*Adding main cities
preserve
	tempfile city
	use "input/workfile2012", clear
	keep czone city state
	duplicates drop
	save `city'
restore
cap drop _merge
merge m:1 czone  using `city', nogen
merge m:1 statefip using "input/state_fips", nogen 

*Extracting data from population density
gegen ptile_density=xtile(l_czone_density) if czone_density1950>1, nq(100) by(year)

keep if year==2020

/*
CREATION OF THE TABLE
*/
local table_name "output/tables/CZ_example_table.tex"
local table_title "Examples of CZ at different percentiles of population density in 2020"
local table_foot  "\textbf{Note:} figure restricts to czones with population densities above 1 person per km$^2$"

label var ptile_density "Percentile"
label var city "Main city"
label var state_name "State"
label var czone_density "Population density"
label var l_czone_density "log of population density"
label var czone_pop "Total population"

gsort ptile_density -l_czone_density
preserve
by 	 ptile_density: keep if _n<3
keep if inlist(ptile_density,1,5,10,25,50,75,90,95,99,100)

replace czone_pop=round(czone_pop)
replace czone_density=round(czone_density,.01)
replace l_czone_density=round(l_czone_density,.01)
*textablehead using `table_name', ncols(4) f("Percentile") coltitles(`coltitles')
texsave ptile_density city state_name l_czone_density czone_density czone_pop using `table_name', ///
	replace varlabels frag headlines(`coltitles') autonumber footnote(`table_foot') nofix ///
	title(`table_title') marker(tab:cz_examples)
restore

*Summary statistics table 
local table_name "output/tables/density_gap_summary_stats.tex"
local table_title "Summary statistics for selected variables, 2020"


estpost tabstat l_czone_density wage_raw_gap if l_czone_density1950>0&year==2020, ///
	statistics(count p10 p25 p50 p75 p90) columns(statistics) listwise
esttab . using `table_name', ///
	cells("count p10 p25 p50 p75 p90") nostar unstack   noobs nonote label tex replace nonumber
