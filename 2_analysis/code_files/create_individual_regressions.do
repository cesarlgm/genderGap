
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"

foreach year in `year_list' {
    tempfile `year'_file
	use if year==`year' using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

    reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone) savefe

    rename __hdfe1__ baseline_fe
    cap drop *hdfe*

    reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant) savefe

    rename __hdfe1__ basic_controls_fe
    cap drop *hdfe*

    
    reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.education) savefe

    rename __hdfe1__ with_education_fe
    cap drop *hdfe*

        
    reghdfe l_hrwage [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age i.race i.marst i.migrant i.education i.ind1950) savefe

    rename __hdfe1__ with_ind_fe
    cap drop *hdfe*

    collapse (mean) *fe, by(czone year female)

    reshape wide *fe, i(czone year) j(female)
	
	save ``year'_file'
}

clear
foreach year in `year_list'{
    append using ``year'_file'
}

foreach specification in baseline basic_controls with_education with_ind {
    g `specification'_gap=`specification'_fe0-`specification'_fe1
}
drop *fe*

merge 1:1 czone year using `czone_chars_file', nogen  ///
    keepusing(l_czone_density czone_pop cz_area czone_pop_50) keep(3)

save "temporary_files/individual_level_regressions_`indiv_sample'", replace
*/
use "temporary_files/individual_level_regressions_`indiv_sample'", replace
regress baseline_gap c.`indep_var'#ib1970.year i.year, 			                        vce(r) 	
estimates save "output/regressions/baseline_individual_`indiv_sample'", 							replace 
regress basic_controls_gap c.`indep_var'#ib1970.year i.year,  							vce(r) 	
estimates save "output/regressions/with_basic_controls_individual_`indiv_sample'",	replace
regress with_education_gap c.`indep_var'#i.year i.year ,						        vce(r)
estimates save "output/regressions/with_educ_controls_individual_`indiv_sample'", 	replace
regress with_ind_gap c.`indep_var'#i.year i.year ,						                vce(r)
estimates save "output/regressions/with_ind_controls_individual_`indiv_sample'", 	replace
