
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"



/*************************************************************************************************************************************
GENDER REGRESSIONS
*************************************************************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time", clear
drop if year==1950
regress wage_raw_gap c.`indep_var'#ib1970.year i.year,                                  vce(cl czone) 	
estimates save "output/regressions/baseline_individual_`indiv_sample'", 		replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(region)                   vce(cl czone) 	
estimates save "output/regressions/baseline_region_individual_`indiv_sample'", 		replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(state)                    vce(cl czone) 	
estimates save "output/regressions/baseline_state_individual_`indiv_sample'", 		replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#region)              vce(cl czone) 	
estimates save "output/regressions/baseline_region_trend_individual_`indiv_sample'", 	replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#state)               vce(cl czone) 	
estimates save "output/regressions/baseline_state_trend_individual_`indiv_sample'", 	replace 


/*************************************************************************************************************************************
RACE REGRESSIONS
*************************************************************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time_race", clear
drop if year==1950
regress wage_raw_gap c.`indep_var'#ib1970.year i.year, 			                             vce(cl czone) 	
estimates save "output/regressions/baseline_race_individual_`indiv_sample'", 			         replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(region)                        vce(cl czone) 	
estimates save "output/regressions/baseline_race_region_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(state)                         vce(cl czone) 	
estimates save "output/regressions/baseline_race_state_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#region)                         vce(cl czone) 	
estimates save "output/regressions/baseline_race_region_trend_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#state)                         vce(cl czone) 	
estimates save "output/regressions/baseline_race_state_trend_individual_`indiv_sample'", 			     replace 



/*************************************************************************************************************************************
REGRESSIONS CONTROLLING FOR INDIVIDUAL CHARACTERISTICS
*************************************************************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time", clear
drop if year==1950
local fixed_effects i.region#i.year
reghdfe wage_bas_gap c.`indep_var'#i.year i.year ,	    absorb(`fixed_effects')		                    vce(cl czone)
estimates save "output/regressions/with_bas_controls_individual_`indiv_sample'",       	    replace
reghdfe wage_hum_gap c.`indep_var'#i.year i.year ,	    absorb(`fixed_effects')	                           vce(cl czone)
estimates save "output/regressions/with_hum_controls_individual_`indiv_sample'",            replace
reghdfe wage_ful_gap c.`indep_var'#i.year i.year ,		 absorb(`fixed_effects')						        vce(cl czone)
estimates save "output/regressions/with_ful_controls_individual_`indiv_sample'", 	        replace
reghdfe wage_fam_gap c.`indep_var'#i.year i.year ,		 absorb(`fixed_effects')						        vce(cl czone)
estimates save "output/regressions/with_fam_controls_individual_`indiv_sample'", 	        replace
reghdfe wage_ffu_gap c.`indep_var'#i.year i.year ,		 absorb(`fixed_effects')						        vce(cl czone)
estimates save "output/regressions/with_ffu_controls_individual_`indiv_sample'", 	        replace
reghdfe wage_tti_gap c.`indep_var'#i.year i.year ,		 absorb(`fixed_effects')				        vce(cl czone)
estimates save "output/regressions/with_trantime_controls_individual_`indiv_sample'", 	    replace



/********************************************************************************************************************************
GRAPH 4: CONTROLLING FOR CZ LEVEL CHARACTERISTICS
*************************************************************************************************************************************/
use "../1_build_database/output/czone_level_dabase_full_time", clear
generate lfp_gap=male_lfp-female_lfp
drop if year==1950

eststo clear
local fixed_effects  year 

eststo baseline: reghdfe wage_ful_gap c.`indep_var'#i.year i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls0_czone_`indiv_sample'",       	    replace

eststo control1: reghdfe wage_ful_gap c.`indep_var'#i.year  c.high_education#i.year i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls1_czone_`indiv_sample'",       	    replace

eststo control2: reghdfe wage_ful_gap c.`indep_var'#i.year  c.high_education#i.year ///
         c.overall_ineq#i.year i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls2_czone_`indiv_sample'",       	    replace

eststo control3: reghdfe wage_ful_gap c.`indep_var'#i.year  c.high_education#i.year ///
         c.overall_ineq#i.year c.lfp_gap#i.year i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls3_czone_`indiv_sample'",       	    replace

eststo control4: reghdfe wage_ful_gap c.`indep_var'#i.year  c.high_education#i.year ///
         c.overall_ineq#i.year c.lfp_gap#i.year c.ind_manufacturing#i.year  i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls4_czone_`indiv_sample'",       	    replace

eststo control5: reghdfe wage_ful_gap c.`indep_var'#i.year  c.high_education#i.year c.high_education#c.`indep_var'#i.year ///
         c.overall_ineq#i.year c.lfp_gap#i.year c.ind_manufacturing#i.year  i.year ,	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/controls5_czone_`indiv_sample'",       	    replace



/********************************************************************************************************************************
REGRESSIONS FOR PEOPLE WITH / WITHOUT CHILDREN
*********************************************************************************************************************************/
use "../1_build_database/output/czone_level_dabase_has_children_full_time", clear
drop if year==1950

eststo clear 
local fixed_effects i.year i.region 
loca  additional_controls  

local filter &l_czone_density_50>0
eststo baseline0: reghdfe human_gap c.`indep_var'#i.year `additional_controls' if !has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/baseline0_czone_`indiv_sample'",       	        replace

eststo baseline1: reghdfe human_gap c.`indep_var'#i.year `additional_controls' if has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/baseline1_czone_`indiv_sample'",       	        replace

eststo basic0: reghdfe basic_gap c.`indep_var'#i.year  `additional_controls'   if !has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/basic0_czone_`indiv_sample'",       	                replace

eststo basic1: reghdfe basic_gap c.`indep_var'#i.year  `additional_controls'  if  has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/basic1_czone_`indiv_sample'",       	                replace

eststo human0: reghdfe human_gap c.`indep_var'#i.year   `additional_controls'  if !has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human0_czone_`indiv_sample'",       	                replace

eststo human1: reghdfe human_gap c.`indep_var'#i.year   `additional_controls'  if has_children`filter',	///
       vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human1_czone_`indiv_sample'",       	                replace

eststo full0: reghdfe full_gap c.`indep_var'#i.year   `additional_controls'  if !has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/full0_czone_`indiv_sample'",       	                replace

eststo full1: reghdfe full_gap c.`indep_var'#i.year   `additional_controls'  if has_children`filter',	///
       vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/full1_czone_`indiv_sample'",       	                replace

local  additional_controls  i.year#c.high_education i.year#c.ind_manufacturing // i.year#c.overall_ineq
eststo full0_c: reghdfe full_gap c.`indep_var'#i.year   `additional_controls'  if !has_children`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/full_c0_czone_`indiv_sample'",       	                replace

eststo full1_c: reghdfe full_gap c.`indep_var'#i.year   `additional_controls'  if has_children`filter',	///
       vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/full_c1_czone_`indiv_sample'",       	replace

/*
/********************************************************************************************************************************
REGRESSIONS FOR PEOPLE MARRIED / SINGLE
*********************************************************************************************************************************/

use "../1_build_database/output/czone_level_dabase_married_full_time", clear
drop if year==1950

eststo clear 
local fixed_effects i.region i.year 
local filter &l_czone_density_50>0
loca  additional_controls  


eststo baseline0: reghdfe baseline_gap c.`indep_var'#i.year `additional_controls' if !married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/baseline0_married_czone_`indiv_sample'",       	    replace

eststo baseline1: reghdfe baseline_gap c.`indep_var'#i.year  `additional_controls' if married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/baseline1_married_czone_`indiv_sample'",       	    replace



eststo basic0: reghdfe basic_gap c.`indep_var'#i.year     if !married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/basic0_married_czone_`indiv_sample'",       	    replace

eststo basic1: reghdfe basic_gap c.`indep_var'#i.year    if  married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/basic1_married_czone_`indiv_sample'",       	    replace

eststo human0: reghdfe human_gap c.`indep_var'#i.year     if !married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human0_married_czone_`indiv_sample'",       	    replace

eststo human1: reghdfe human_gap c.`indep_var'#i.year     if married`filter',	///
       vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human1_married_czone_`indiv_sample'",       	    replace


eststo full0: reghdfe full_gap c.`indep_var'#i.year     if !married`filter',	///
        vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human0_married_czone_`indiv_sample'",       	    replace

eststo full1: reghdfe full_gap c.`indep_var'#i.year     if married`filter',	///
       vce(cl czone) absorb(`fixed_effects')
estimates save "output/regressions/human1_married_czone_`indiv_sample'",       	    replace