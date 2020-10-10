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
local 		append_census 1

gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'
di "`year_list'"

*Location of census files
global data "../../NSAM/1_build_data/output"
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"



*List of variables I am extracting from the census
local 		var_list		l_hrwage age education marst czone bpl ///	
							race occ* ind* year female wkswork hrswork perwt ///
							statefip empstat nchild 

* Execution parameters
*Variables to extract from the census
local 		do_file "code_files/by_census_residualization"
clear 

if "`append_census'"=="1" {
	*STEP 1: APPEND ALL THE CENSUSES
	*-----------------------------------------------------------------------------------
	foreach year in `year_list' {
		if `year'>1970 {
			local trantime trantime
		}
		di "Appending `year' census", as result
		local census_name "${data}/cleaned_census_`year'"
		qui append using `census_name', keep(`var_list' `trantime')
	}

	qui {	
		*STEP 2: ADD CZONE LEVEL CHARACTERISTICS
		*----------------------------------------------------------------------------------
		parallel initialize 4
		replace year=2010 if year==2011
		replace year=2020 if year==2018
		
		sort year

		parallel, by(year): merge m:1 czone year using `czone_chars_file', nogen ///
			keepusing(l_czone_density cz_area czone_pop_50 czone_pop) keep(1 3)


		*STEP 3: DECIDE THE SAMPLE UPON WHICH THE REGRESSIONS ARE RUN + COMPUTE SOME CONTROLS
		*-----------------------------------------------------------------------------------
		if "`indiv_sample'"=="full_time" {
			qui	generate full_time=		wkswork>=40&hrswork>=35
			qui	replace l_hrwage=. if full_time!=1
		}

		*I also erase wages for any place with very low population density in 1950
		replace l_hrwage=. if !(!missing(l_hrwage)&czone_pop_50/cz_area>`density_filter')

		*STEP 4: CREATE MISSING CONTROL VARIABLES
		*-----------------------------------------------------------------------------------
		sort year
		*Classify industries
		parallel, by(year): do "../1_build_database/code_files/classify_industries_occupations.do" occ1950

		*Flag migrant individuals
		generate migrant= bpl >= 150

		recode marst (6=1) (3/5=2) (1/2=3), g(marst_grouped)
		drop 	marst
		rename 	marst_grouped marst


		recode race (1=1) (2=2) (3/9=3), g(race_grouped)
		drop race
		rename race_grouped race

		recode education (1/2=1) (3/4=2), g(educ_grouped)

		save "temporary_files/file_for_individual_level_regressions_`indiv_sample'", replace 
	}
}
else {
	use  "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 
}	

local cont_controls     age migrant 

parallel initialize 4
parallel, by(year): xi  i.marst  i.race i.ind_type i.education i.educ_grouped, prefix(dum_)


gcollapse (mean) l_hrwage `cont_controls' dum* [pw=perwt] if !missing(l_hrwage), by(czone year female) fast

save "temporary_files/aggregate_regression_file_`indiv_sample'", replace

use "temporary_files/aggregate_regression_file_`indiv_sample'", clear

ds czone year female, not

local variable_list `r(varlist)'

reshape wide `r(varlist)', i(czone year) j(female)

*Computes gap between men and women characteristics
foreach variable in `variable_list' {
	generate `variable'_gap=`variable'0-`variable'1
}

drop *0 *1

*Add czone characteristcs 
merge 1:1 czone year using `czone_chars_file', nogen keepusing(l_czone_density czone_pop cz_area czone_pop_50 ) keep(3)

*Compute  czone level regressions
ds age_gap migrant_gap dum*marst* dum*race*
foreach variable in `r(varlist)' {
	local control_list 			`control_list' 			c.`variable'#i.year
	local d_control_list 		`d_control_list' 		c.d.`variable'#i.year
}

local educ_control_list
ds age_gap migrant_gap age_gap   dum*marst* dum*race* dum*educa*
foreach variable in `r(varlist)' {
	local educ_control_list 	`educ_control_list' 	c.`variable'#i.year
	local d_educ_control_list `d_educ_control_list' 	c.d.`variable'#i.year
}

local ind_control_list
ds age_gap migrant_gap   dum*marst* dum*race* dum*educa*  dum*ind*
foreach variable in `r(varlist)' {
	local ind_control_list 	`ind_control_list' 	c.`variable'#i.year
	local d_ind_control_list `d_ind_control_list' 	c.d.`variable'#i.year
}



save  "temporary_files/aggregate_regression_file_final_`indiv_sample'", replace

/*
regress l_hrwage_gap c.`indep_var'#ib1970.year i.year,  										vce(r) 	
estimates save "output/regressions/baseline_aggregate_`indiv_sample'", 							replace 
regress l_hrwage_gap c.`indep_var'#ib1970.year i.year `control_list',  							vce(r) 	
estimates save "output/regressions/with_basic_controls_aggregate_`indiv_sample'",	replace
regress l_hrwage_gap c.`indep_var'#i.year i.year `educ_control_list',						vce(r)
estimates save "output/regressions/with_educ_controls_aggregate_`indiv_sample'", 	replace
regress l_hrwage_gap c.`indep_var'#i.year i.year `ind_control_list',						vce(r)
estimates save "output/regressions/with_ind_controls_aggregate_`indiv_sample'", 	replace

xtset czone year, delta(10)
regress d.l_hrwage_gap c.`indep_var'#i.year i.year,  										vce(r)
estimates save "output/regressions/d_baseline_aggregate_`indiv_sample'", 			replace
regress l_hrwage_gap c.`indep_var'#i.year i.year `d_control_list',  						vce(r)
estimates save "output/regressions/d_with_basic_controls_aggregate_`indiv_sample'",	replace
regress l_hrwage_gap c.`indep_var'#i.year i.year `d_educ_control_list',					vce(r)
estimates save "output/regressions/d_with_educ_controls_aggregate_`indiv_sample'", 	replace
regress l_hrwage_gap c.`indep_var'#i.year i.year `d_ind_control_list',					vce(r)
estimates save "output/regressions/d_with_ind_controls_aggregate_`indiv_sample'",	replace
*------------------------------- At this point aggregate level regressions have been accounted for---------------------------------------

*/