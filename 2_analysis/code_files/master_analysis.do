*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: master do file of census analysis.
*===============================================================================
*Setting the path
cd "C:\Users\thecs\Dropbox\boston_university\7-Research\LLMM\2_analysis"
set graphics on


*Execution parameters
local occupation ind1950
local base_year  1990
local analysis_type 4 //4=full time 1=all men and women
local absorb_year	1
local indep_type	0
local standardize	0

*List of year fir the execution
local year_list  1970  1980 1990 2000 2010 2020

if `indep_type'==0 {
	local indep_var l_czone_density
}
else if `indep_type'==1 {
	local indep_var l_czone_pop
}


*===============================================================================
*CREATE MAP WITH GEOGRAPHY OF THE GENDER GAP IN THE US
*===============================================================================
*do "code_files/create_gender_gap_maps.do" 		`analysis_type'

*do "code_files/output_average_stats.do" 		`analysis_type'  2020

*===============================================================================
*WHAT DRIVES THE DIFFERENCES IN THE WEIGHTING?
*===============================================================================
*Here I want to answer two questions: why do the results appear to be so
*depending on how I weight.

*Answer: behavior of high versus mid-density places
/*
do "code_files/compare_weighting" 	`analysis_type' `indep_var'
*/
*===============================================================================
*POTENTIAL EXPLANATIONS
*===============================================================================

*do "code_files/control_observable_characteristics.do" `analysis_type' ///
*	`indep_var' `standardize'  `base_year'd

/*
timer on 	1
do "code_files/create_aggregate_regressions.do" 		l_czone_density full_time ///
	1   `year_list'
timer off 1

do "code_files/create_individual_regressions.do" 		l_czone_density full_time ///
	1   `year_list'

do "code_files/write_regression_coefplots.do" 	l_czone_density full_time ///
	1   `year_list'

do "code_files/write_regression_tables.do" 	l_czone_density full_time ///
	1   `year_list'


do "code_files/check_industry_stories.do" 	l_czone_density full_time ///
	1   `year_list'
*/	
do "code_files/zooming_in_high_wage_industries.do" 	l_czone_density full_time ///
	1   `year_list'
*===============================================================================
*INDIVIDUAL LEVEL REGRESSIONS
*===============================================================================
/*do "code_files/individual_level_regressions.do" `analysis_type'  ///
	`indep_var' `standardize'  `year_list'


do "code_files/create_coefplots_with_individual_controls.do" `analysis_type' ///
	`indep_var' `standardize' `year_list'
*/
/*


*===============================================================================
*STEP 1> CREATE TABLE WITH RAW GENDER GAP AND VARIATION AT CZ.
*===============================================================================
/*
*This code file creates 
	- Box plot with evolution of gender gap across CZ
	- Regressions of persistence of the gender wage gap
*/
*do "code_files/evolution_overall_gender_gap.do"  	`analysis_type' 
/*
*This code file creates 
	- Maps of evolution of the gender gap by year.
	- Maps of population density by year.
	- Maps of employment share of male industries by year


*/


/*


do "code_files/stats_on_gendered_industries" `indep_var' `occupation'
*/
*do "code_files/explore_selection_measures" `analysis_type' `base_year'  `year_list'
/*
*===============================================================================
*ELASTICITY TABLES
*===============================================================================

do "code_files/create_elasticity_table.do" `analysis_type' ///
	`indep_var' `standardize' `year_list'

do "code_files/create_IC_table.do" `analysis_type' ///
	`indep_var' `year_list'	



*===============================================================================
*CREATION OF COEFPLOTS
*===============================================================================


do "code_files/create_coefplots_by_gender.do" `analysis_type' ///
	`indep_var' `standardize' 
/*
*With individual level controls

do "code_files/create_coefplots_with_indiidual_controls.do" `analysis_type' ///
	`indep_var' `standardize' 
/*


*===============================================================================
*BINNED SCATTERPLOTSd
*===============================================================================


*/
*do "code_files/create_gender_gap_dispersion_graph.do" `year_list'

*do "code_files/create_gender_gap_gradient_graphs.do" `analysis_type' ///
	`absorb_year' `indep_var' `standardize' `year_list' 
/*
do "code_files/interpreting_gradients.do" `analysis_type' ///
	`absorb_year' `indep_var' `year_list'
*/
	
/*
do "code_files/create_fixed_gaps_graphs" ind1950_OD `year_list'

*do "code_files/decomposition_exercise" occ1990_agg `year_list'
