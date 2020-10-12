
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"
/*
foreach year in `year_list' {
    di "Processing `year'", as result
    qui {
        tempfile `year'_file
        use if year==`year' using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

        reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone) savefe

        rename __hdfe1__ baseline_fe
        cap drop *hdfe*

        reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.nchild) savefe

        rename __hdfe1__ basic_controls_fe
        cap drop *hdfe*

        
        reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.nchild i.education) savefe

        rename __hdfe1__ with_education_fe
        cap drop *hdfe*

            
        reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.nchild i.education i.ind1950) savefe

        rename __hdfe1__ with_ind_fe
        cap drop *hdfe*

        reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant ///
            i.nchild i.education i.ind1950 i.occ1950) savefe

        rename __hdfe1__ with_occ_fe
        cap drop *hdfe*

        if year>1970 {
            reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.nchild i.education i.ind1950 i.occ1950) savefe

            rename __hdfe1__ with_trantime_fe
            cap drop *hdfe*
        }
        collapse (mean) *fe, by(czone year female)

        reshape wide *fe, i(czone year) j(female)
        
        save ``year'_file'
    }
}

clear
foreach year in `year_list'{
    append using ``year'_file'
}

foreach specification in baseline basic_controls with_education with_ind with_occ with_trantime  {
    g `specification'_gap=`specification'_fe0-`specification'_fe1
}


merge 1:1 czone year using `czone_chars_file', nogen  ///
    keepusing(l_czone_density czone_pop cz_area czone_pop_50) keep(3)

save "temporary_files/individual_level_regressions_`indiv_sample'", replace
*/







use "../1_build_database/output/czone_level_dabase_full_time", replace
drop if year==1950
regress wage_raw_gap c.`indep_var'#ib1970.year i.year, 			                             vce(cl czone) 	
estimates save "output/regressions/baseline_individual_`indiv_sample'", 			         replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(region)                        vce(cl czone) 	
estimates save "output/regressions/baseline_region_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(state)                         vce(cl czone) 	
estimates save "output/regressions/baseline_state_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#region)                         vce(cl czone) 	
estimates save "output/regressions/baseline_region_trend_individual_`indiv_sample'", 			     replace 

reghdfe wage_raw_gap c.`indep_var'#ib1970.year i.year, absorb(year#state)                         vce(cl czone) 	
estimates save "output/regressions/baseline_state_trend_individual_`indiv_sample'", 			     replace 

/*
regress basic_controls_gap c.`indep_var'#ib1970.year i.year,  							    vce(cl czone) 	
estimates save "output/regressions/with_basic_controls_individual_`indiv_sample'",	        replace
regress with_education_gap c.`indep_var'#i.year i.year ,						            vce(cl czone)
estimates save "output/regressions/with_educ_controls_individual_`indiv_sample'",       	replace
regress with_ind_gap c.`indep_var'#i.year i.year ,						                    vce(cl czone)
estimates save "output/regressions/with_ind_controls_individual_`indiv_sample'", 	        replace
regress with_occ_gap c.`indep_var'#i.year i.year ,						                    vce(cl czone)
estimates save "output/regressions/with_occ_controls_individual_`indiv_sample'", 	        replace
regress with_trantime_gap c.`indep_var'#i.year i.year ,						                vce(cl czone)
estimates save "output/regressions/with_trantime_controls_individual_`indiv_sample'", 	    replace



/**********************************************************************************************
GRAPH 4: CONTROLLING FOR CZ LEVEL CHARACTERISTICS
**********************************************************************************************/
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"


merge 1:1 year czone using `czone_chars_file', nogen 

xtset czone year, delta(10)
generate d_high_education=d.high_education
generate d_overall_ineq=d.high_education


eststo clear
eststo baseline: regress with_occ_gap c.`indep_var'#i.year  c.high_education#i.year i.year ,	///
        vce(cl czone)

eststo controls1: regress with_occ_gap c.`indep_var'#i.year  c.d_high_education#i.year i.year ,	///
        vce(cl czone)

eststo controls2: regress with_occ_gap c.`indep_var'#i.year  c.high_education#i.year              ////
         i.year ,				                    vce(cl czone)
eststo controls3: regress with_occ_gap c.`indep_var'#i.year  c.high_education#i.year              ////
        c.labforce_gap#i.year i.year ,				                    vce(cl czone)
eststo controls4: regress with_occ_gap c.`indep_var'#i.year  c.high_education#i.year              ////
         c.in_labforce1#i.year c.in_labforce0#i.year c.overall_ineq#i.year   i.year ,	          ///
         vce(cl czone)
eststo controls5: regress with_occ_gap c.`indep_var'#i.year  c.high_education#i.year              ////
         c.in_labforce1#i.year c.in_labforce0#i.year c.d_overall_ineq#i.year  c.migrant#i.year  i.year  ,	///
         vce(cl czone)

*Share in high paying occupations


coefplot baseline controls*, keep(*density*) yline(0) ///
    legend(order(2 "No controls" 4 "+ basic demographics" 6 "+ education" 8 "+ Industry fe" ///
    10 "+ Occupation fe" 12 "+ commuting time" ) ring(0) pos(2)) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label')

