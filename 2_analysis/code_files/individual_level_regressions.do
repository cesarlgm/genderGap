
*Database type 0=gender 1=race
gettoken 	analysis_type 	0: 0
gettoken 	indep_var		0: 0
gettoken 	standardize		0: 0
local 		year_list		`0'
local 	  	variance		vce(cl czone)

*List of variables I am extracting from the census
local 		var_list		l_hrwage age education marst czone ///	
							race occ* ind* year female wkswork hrswork perwt ///
							statefip empstat
							
*Observations I am using
local 		filter 			!missing(l_hrwage)&full_time&czone_pop_50/cz_area>0

*Basic DID specification.

*Basic specification uses a hard density threshold
local 		basic_spec		i.male l_czone_density i.male#c.l_czone_density

*This uses a moving density tercile threshold
local 		moving_spec		i.male l_czone_density i.male#c.l_czone_density


local 		basic_prem		c.l_czone_density
local 		moving_prem		c.l_czone_density



*===============================================================================
*SOME PRELIMINARY TWEAKS
*===============================================================================

tempfile czone_chars
use "../1_build_database/output/czone_level_dabase_full_time", clear
	
	*I create a variable indicating the top tercile in czone density every year.
	g	density_tier_year=.	
	foreach year in `year_list' {
	
		xtile temp=l_czone_density if year==`year'& ///
			czone_pop_50/cz_area>1, nq(3)
	
		replace density_tier_year=temp if year==`year'
		
		drop temp
	}
	
	
	sort czone year
	by czone: g density_tier=density_tier_year[2]
	
			
	label define density_tier 2 "Mid tercile" 3 "Top tercile"

	label values density_tier 		density_tier
	label values density_tier_year 	density_tier

save `czone_chars'

*===============================================================================
*CREATE THE REGRESSIONS
*===============================================================================

foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  `var_list' using	"${data}/output/cleaned_census_`year'", clear
		
		do "../1_build_database/code_files/classify_industries_occupations.do" occ1950

		replace year=2010 if year==2011
		replace year=2020 if year==2018
			
			
		*Definition of full-time workers
		g	full_time=wkswork>=40&hrswork>=35

		cap drop _merge
		merge m:1 czone year using  `czone_chars', nogen keep(1 3)
		
		g male=!female
		
		foreach spec_type in moving {
			*Creating the regressions
			
			*Raw model with no controls
			eststo model_`year'_0_`spec_type' : reg 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance'
			
			estimates save "output/regressions/model_`year'_0_`spec_type'", replace
			*===================================================================
			*Constant return across geographies
			*===================================================================
			/*
			eststo model_`year'_1_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance' absorb(age)
			estimates save "output/regressions/model_`year'_1_`spec_type'", replace
				
			eststo model_`year'_2_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance' absorb(age marst)
			estimates save "output/regressions/model_`year'_2_`spec_type'", replace
			
			eststo model_`year'_3_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance' absorb(age marst race)
			estimates save "output/regressions/model_`year'_3_`spec_type'", replace
			
			eststo model_`year'_4_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance' absorb(age marst race education)
			estimates save "output/regressions/model_`year'_4_`spec_type'", replace
			
			eststo model_`year'_5_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				[pw=perwt] if `filter', `variance' absorb(age marst race education ind_type)
			estimates save "output/regressions/model_`year'_5_`spec_type'", replace
			*/

			eststo model_`year'_6_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' 	///
				[pw=perwt] if `filter', `variance' 										///
				absorb(age marst race education ind1950)
			estimates save "output/regressions/model_`year'_6_`spec_type'", replace
			
			*===================================================================
			*Differencial return of education
			*===================================================================
			eststo model_`year'_7_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				``spec_type'_prem'#ib1.education  ``spec_type'_prem'#i.male  [pw=perwt]  						///
				if `filter', `variance' absorb(age marst race ind1950)
			estimates save "output/regressions/model_`year'_7_`spec_type'", replace


			eststo model_`year'_8_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' ///
				``spec_type'_prem'#ib1.education ``spec_type'_prem'#i.male  [pw=perwt]  						///
				if `filter', `variance' absorb(age marst race ind1950)
			estimates save "output/regressions/model_`year'_7_`spec_type'", replace
			/*
			eststo model_`year'_8_`spec_type': reghdfe 	  l_hrwage ``spec_type'_spec' 	///
				``spec_type'_prem'##ib1.education##i.male              					///
				``spec_type'_prem'##ib1.race##i.male      	[pw=perwt] 	 				///
				if `filter', `variance' absorb(age marst)
			estimates save "output/regressions/model_`year'_8_`spec_type'", replace
			
			eststo female_`year'_0_`spec_type': reg 	  l_hrwage ``spec_type'_prem' if `filter' ///
				[pw=perwt] , `variance'
			estimates save "output/regressions/female_`year'_0_`spec_type'", replace
			
			eststo male_`year'_0_`spec_type': reg 	  l_hrwage ``spec_type'_prem' if `filter' ///
				[pw=perwt], `variance'	
			estimates save "output/regressions/male_`year'_0_`spec_type'", replace
			*/	
		}
	}
}

*===============================================================================
*CREATE GRAPHS AND TABLES
*===============================================================================
clear 
eststo clear
*Loading estimates
foreach year in `year_list' {
	foreach spec_type in moving {
		foreach j in 0 6 7 8 { 
			estimates use  "output/regressions/model_`year'_`j'_`spec_type'"	
			estimates store model_`year'_`j'_`spec_type'
		}
	}
}


/*

local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

foreach spec_type in basic moving {
	foreach year in `year_list' {
		forvalues j=0/6 {
			if `year'==1970 {
				local model_list_`j'_`spec_type' model_`year'_`j'_`spec_type'
			}
			else {
				local model_list_`j'_`spec_type' `model_list_`j''_`spec_type' || model_`year'_`j'_`spec_type'
			}
		}
	}
}


*Creating graphs
coefplot `model_list_0_basic', vert  yline(0) base keep(1.male*tier*) ///
	xlabel(`year_label')  bycoefs ///
	legend(order(2 "No controls") ring(0) pos(2))  ///
	ytitle("Male x density wage advantage") ///
	ciopt(recast(rcap)) plotlabels("Mid tercile" "Top tercile")

graph export "output/discrete_density_coefs_basic.pdf", replace

coefplot `model_list_0_moving', vert  yline(0) base keep(1.male*tier*) ///
	xlabel(`year_label')  bycoefs ///
	legend(order(2 "No controls") ring(0) pos(2))  ///
	ytitle("Male x density wage advantage") ///
	ciopt(recast(rcap)) plotlabels("Mid tercile" "Top tercile")

graph export "output/discrete_density_coefs_moving.pdf", replace



coefplot `model_list_0_basic', vert  yline(0) base keep(1.male*3.*tier*) ///
	xlabel(`year_label')  bycoefs ///
	ytitle("Male x density wage advantage") ///
	ciopt(recast(rcap))

graph export "output/discrete_density_coefs_top_basic.pdf", replace


coefplot `model_list_0_moving', vert  yline(0) base keep(1.male*3.*tier*) ///
	xlabel(`year_label')  bycoefs ///
	ytitle("Male x density wage advantage") ///
	ciopt(recast(rcap))

graph export "output/discrete_density_coefs_top_moving.pdf", replace

*===============================================================================
*Finally I create a table
*===============================================================================
local table_name "output/tables/indiv_regressions_table.tex"
local table_title "Male x density tercile wage advantage"
local table_options  nobaselevels append booktabs f collabels(none) ///
	nomtitles plain b(%9.3fc) se(%9.3fc) par star noobs
	
textablehead using `table_name', ncols(6) coltitles(`year_list') f(Controls) ///
	title(`table_title') sup(Census year)

esttab `model_list_0_moving' using `table_name', `table_options' keep(*male*3*tier*) ///
	coeflabels(1.male#3.density_tier_year "No controls")

esttab `model_list_1_moving' using `table_name',`table_options' keep(*male*3*tier*) ///
	coeflabels(1.male#3.density_tier_year "+ age FE")
	
esttab `model_list_2_moving' using `table_name', `table_options' keep(*male*3*tier*) ///
	coeflabels(1.male#3.density_tier_year "+ marital status FE")
	
esttab `model_list_3_moving' using `table_name',`table_options'  keep(*male*3*tier*) ///
	coeflabels(1.male#3.density_tier_year "+ race FE")
	
esttab `model_list_4_moving' using `table_name', `table_options' keep(*male*3*tier*) ///
	coeflabels(1.male#3.density_tier_year "+ education FE")
	
textablefoot using `table_name'
