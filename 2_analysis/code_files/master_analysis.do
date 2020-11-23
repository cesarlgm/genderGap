*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: master do file of census analysis.
*===============================================================================
*Setting the path
cd "C:\Users\thecs\Dropbox\boston_university\7-Research\genderGap\2_analysis"
set graphics on


*Execution parameters
local occupation ind1950
local base_year  1990
local analysis_type 4 //4=full time 1=all men and women
local absorb_year	1
local indep_type	0
local standardize	0

*List of year fir the execution
local year_list 1970 1980 1990 2000 2010 2020

if `indep_type'==0 {
	local indep_var l_czone_density
}
else if `indep_type'==1 {
	local indep_var l_czone_pop
}


*===============================================================================
*DESCRIPTIVE STATISTICS
*===============================================================================
/*
do "code_files/descriptive_cross_cz_stats.do"
*/
*===============================================================================
*CREATE MAP WITH GEOGRAPHY OF THE GENDER GAP IN THE US
*===============================================================================

*do "code_files/create_gender_gap_maps.do" 		`analysis_type'

*do "code_files/create_misc_wage_graphs.do" 		`year_list'

*do "code_files/gap_level_variation.do" 		`year_list'

*do "code_files/gap_level_variation.do" 		`year_list'

*do "code_files/output_average_stats.do" 		`analysis_type'  2020


*===============================================================================
*GEOGRAPHY MATTERS FOR THE GENDER GAP
*===============================================================================
*do "code_files/oaxaca_blinder_decomposition.do" `year_list'

*===============================================================================
*MOVEMENT HIGH-VS LOW DENSITY CZONES
*===============================================================================
*do "code_files/kernel_density_movement.do"  	l_czone_density full_time ///
*	1   `year_list'
*===============================================================================
*WHAT DRIVES THE DIFFERENCES IN THE WEIGHTING?
*===============================================================================
*Here I want to answer two questions: why do the results appear to be so
*depending on how I weight.

*Answer: behavior of high versus mid-density places
/*
do "code_files/compare_weighting" 	`analysis_type' `indep_var'

do "code_files/heteroskedasticity_test.do" 	 l_czone_density full_time 1

*/


*===============================================================================
*POTENTIAL EXPLANATIONS
*===============================================================================
/*
do "code_files/graphs_by_demographic_groups.do" 	l_czone_density full_time ///
	1 aggregate   `year_list'


do "code_files/graphs_by_demographic_groups.do" 	l_czone_density full_time ///
	1 individual   `year_list'
*/

*do "code_files/control_observable_characteristics.do" `analysis_type' ///
*	`indep_var' `standardize'  `base_year'

/*
timer on 	1
do "code_files/create_aggregate_regressions.do" 		l_czone_density full_time ///
	1   `year_list'
timer ofbr

*Create regressions on czone density
do "code_files/create_individual_regressions.do" 		l_czone_density full_time ///
	1   `year_list'

*/

do "code_files/write_regression_coefplots.do" 			l_czone_density full_time ///
	1   `year_list'

	
/*	


*Create regressions on czone population 	
do "code_files/create_individual_regressions.do" 		l_czone_pop full_time ///
	1   `year_list'

do "code_files/write_regression_coefplots.do" 			l_czone_pop full_time ///
	1   `year_list'

	
/*
do "code_files/write_regression_tables.do" 	l_czone_density full_time ///
	1   `year_list'


do "code_files/check_industry_stories.do" 	l_czone_density full_time ///
	1   `year_list'


do "code_files/zooming_in_high_wage_industries.do" 	l_czone_density full_time ///
	1   `year_list'
*===============================================================================
*INDIVIDUAL LEVEL REGRESSIONS
*===============================================================================
do "code_files/individual_level_regressions.do" `analysis_type'  ///
	`indep_var' `standardize'  `year_list'


do "code_files/create_coefplots_with_individual_controls.do" `analysis_type' ///
	`indep_var' `standardize' `year_list'

*===============================================================================
*STEP 1> CREATE TABLE WITH RAW GENDER GAP AND VARIATION AT CZ.
*===============================================================================
/*
*This code file creates 
	- Box plot with evolution of gender gap across CZ
	- Regressions of persistence of the gender wage gap
*/



*This code file creates 
	- Maps of evolution of the gender gap by year.
	- Maps of population density by year.
	- Maps of employment share of male industries by year
*/


*do "code_files/stats_on_gendered_industries" `indep_var' `occupation'

*do "code_files/explore_selection_measures" `analysis_type' `base_year'  `year_list'

*===============================================================================
*ELASTICITY TABLES
*===============================================================================
/*
do "code_files/create_elasticity_table.do" `analysis_type' ///
	`indep_var' `standardize' `year_list'



