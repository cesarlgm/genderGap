	*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates CZ level database
*===============================================================================}

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\boston_university\7-Research\NSAM\1_build_data"

*Working directory
cd "C:\Users\thecs\Dropbox\boston_university\7-Research\genderGap\1_build_database"

local industry 		ind1950
local occupation 	occ1950
local year_list  	1950 1970 1980 1990 2000 2010 2020


foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui{ 
		use  	"${data}/output/cleaned_census_`year'", clear
		
		*Quick fix of variables
		egen    grouped_race=       cut(race), at(1,2,3,9)
		label   define  grouped_race 1 "White" 2 "Black" 3 "Other"
		label   values grouped_race grouped_race

		g married=			inlist(marst, 1,2)
		g high_education=	inlist(education, 4)
		g migrant=bpl>=150 	if !missing(bpl)
		g native_migrant=	bpl!=statefip if bpl<150
		
		g female_migrant=	native_migrant if female
		g male_migrant=		native_migrant if !female
		g full_time=		wkswork>=40&hrswork>=35
		g female_head=		relate==1&female
		g employed=			empstat==1
		
		*Classification of industris
		do "code_files/classify_industries_occupations.do" `occupation'
		
		tempfile census
		save `census'
		
		generate l_hrwage_full=l_hrwage 	if missing(full_time)|full_time==0

	
		*STEP 1> computing czone level variables
		preserve
			*In this line of code I compute czone level measures
			*I restrict wage level computation to only full-time workers
			replace l_hrwage=. if missing(full_time)|full_time==0
			
			tempfile czone_vars
			gcollapse (mean) ind_* occ_* married high_education *migrant ///
				(p90) p90=l_hrwage 	(p50) p50=l_hrwage (p10) p10=l_hrwage ///
				[pw=perwt], by(year czone)
			
			*I compute some measures of inequality here
			g top_tail_ineq=	p90-p50
			g bot_tail_ineq=	p50-p10
			g overall_ineq=		p90-p10
			save `czone_vars'
		restore

		*Replacing afact to count the observations correctly
		replace afact=. if missing(l_hrwage)|!full_time
		
		
		*STEP 2> compute employment to population ratio by education
		preserve
			tempfile etp_education_`year'
			gcollapse (sum) labforce_educ=in_labforce (count) population=age, ///
				by(year czone female  high_education) fast
			generate  etp=labforce_educ/population
			
			reshape wide  etp labforce_educ population, i(czone year female) j(high_education)

			label var etp1 "Employment to population ratio high education" 
			label var etp0 "Employment to population ratio low education"
			
			rename etp1 etp_high
			rename etp0 etp_low
			
			save `etp_education_`year''
		restore
		
		*STEP 3> compute employment to population ratio by marital status
		preserve
			tempfile etp_`year'
			gcollapse (sum) labforce_marst=in_labforce (count) population=age, ///
				by(year czone female  married) fast
			generate  etp=labforce_marst/population
			
			
			reshape wide etp labforce_marst population, i(czone year female) j(married)
			
			label var etp1 "Employment to population ratio married" 
			label var etp0 "Employment to population ratio single"
			
			rename etp1 etp_married
			rename etp0 etp_single
			
			merge 1:1 czone year female using  `etp_education_`year'', nogen
			save `etp_`year''
		restore
		
		*STEP 3> computing population counts by czone-gender
		gcollapse (count) population=age (count) observations=l_hrwage (mean) ///
			in_labforce [pw=perwt], ///
			by(female czone year)
		
		egen czone_pop=sum(population), by(czone year)
		
		
		reshape wide population in_labforce observations, i(czone year) j(female)
		
		rename (population0 population1 in_labforce0 in_labforce1 observations0 observations1) ///
			(male_pop female_pop male_lfp female_lfp male_observations female_observations)
	
			
		merge m:1 czone using `czone_vars', nogen
		
		tempfile 	aggregate_vars_`year'
		drop 		ind_type
		save		`aggregate_vars_`year''
	
		use `census', clear
		merge m:1   czone  using `aggregate_vars_1950', nogen  keep(1 3)
		merge m:1 	czone  using "../1_build_database/output/czone_area", nogen keep(1 3)
		
		rename czone_pop czone_pop_50
		
		local filter if full_time==1& (czone_pop_50/cz_area>1) 
		
		*Extracting gender specific premiums		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female, savefe) nocons
		rename  __hdfe1__ l_wage_baseline

		cap drop __*__

		*Extracting gender specific premiums		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.high_education, savefe) nocons
		rename  __hdfe1__ l_wage_by_education
		cap drop __*__
		
		/*
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant, savefe) nocons
		rename  __hdfe1__ l_wage_basic

		cap drop __*__

		*Basic human capital proxies
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education, savefe) nocons
		rename  __hdfe1__ l_wage_human

		cap drop __*__

		*Adding occupation and industry fixed effects
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education i.ind1950 i.occ1950, savefe) nocons
		rename  __hdfe1__ l_wage_full

		cap drop __*__

		*Family structure variables
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education i.ind1950 i.occ1950 i.married i.nchild, savefe) nocons
		rename  __hdfe1__ l_wage_fam

		cap drop __*__

		*Female head dummy
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education i.ind1950 i.occ1950 i.married i.nchild i.female_head, savefe) nocons
		rename  __hdfe1__ l_wage_fam_full

		cap drop __*__

		cap drop *hdfe*
		

		*Transportation time
        if `year'>1970 {
            reghdfe l_hrwage trantime [pw=perwt]  `filter' , absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education i.ind1950 ///
				 i.occ1950 i.married i.nchild i.female_head) savefe

            rename __hdfe1__ l_wage_ttime
            cap drop *hdfe*
		}
		*/
		*Here I take the opportunity to output the wages by education group
		preserve
			tempfile by_education_`year'
				gcollapse (mean) l_wage_by_education ind_* occ_* (count) observations=l_wage_by_education  `filter' [pw=perwt], ///
					by(female czone high_education year) fast
				
				reshape wide l_wage_by_education ind_*  occ_* observations, ///
					i(czone year high_education) j(female)
				
				rename l_wage_by_education0 male_l_wage_by_educ
				rename l_wage_by_education1 female_l_wage_by_educ
				
				drop ind_type*
				
				generate gap_by_educ=male_l_wage_by_educ-female_l_wage_by_educ
			save `by_education_`year''
		restore
		/*
		preserve
			tempfile by_gender_ind_`year'
				gcollapse (mean) ind_* occ_* if full_time [pw=perwt], by(female czone year) fast
				
				reshape wide ind_* occ_*, i(czone year) j(female)
				
				drop ind_type*
				
			save `by_gender_ind_`year''
		restore
		
		
		gcollapse (mean) l_wage* , by(female czone year) fast
		
		reshape wide l_wage_*, i(czone year) j(female)
		
		*Renaming variables
		rename  l_wage_baseline0 male_l_wage 	
		rename  l_wage_baseline1 female_l_wage 	

		rename  l_wage_basic0 male_l_wage_basic
		rename  l_wage_basic1 female_l_wage_basic

		rename  l_wage_human0 male_l_wage_human
		rename  l_wage_human1 female_l_wage_human

		rename  l_wage_full0 male_l_wage_full
		rename  l_wage_full1 female_l_wage_full

		rename  l_wage_fam0 male_l_wage_fam
		rename  l_wage_fam1 female_l_wage_fam	
		
		rename  l_wage_fam_full0 male_l_wage_fam_full
		rename  l_wage_fam_full1 female_l_wage_fam_full	

		cap rename  l_wage_ttime0 male_l_wage_tti
		cap rename  l_wage_ttime1 female_l_wage_tti	
		
		merge m:1 czone year using `aggregate_vars_`year'', nogen keep(1 3)
		merge m:1 	czone using "../1_build_database/output/czone_area", nogen keep(1 3)
		
		generate l_czone_pop=		log(czone_pop)
		generate l_czone_density=	log(czone_pop/cz_area)
		
		generate wage_raw_gap=male_l_wage-female_l_wage
		generate wage_bas_gap=male_l_wage_basic-female_l_wage_basic
		generate wage_hum_gap=male_l_wage_human-female_l_wage_human
		generate wage_ful_gap=male_l_wage_full-female_l_wage_full
		generate wage_fam_gap=male_l_wage_fam-female_l_wage_fam
		generate wage_ffu_gap=male_l_wage_fam_full-female_l_wage_fam_full
		cap generate wage_tti_gap=male_l_wage_tti-female_l_wage_tti

		tempfile collapsed`year'
		save `collapsed`year''	
	*/
	}
	
}
/*
clear
foreach year in  `year_list' {
	append using `collapsed`year''
}


sort czone year
g 			t_population50=czone_pop if year==1950
egen 		czone_pop_50=max(t_population50), by(czone)

order occ* ind*, after(year)

replace year=2020 if year==2018
replace year=2010 if year==2011
drop t_population50

local name full_time
save "output/czone_level_dabase_`name'", replace



local name full_time
use "output/czone_level_dabase_`name'", clear
merge m:1   czone using "../1_build_database/input/cw_czone_state", nogen keep(1 3)
merge m:1   czone using "../1_build_database/input/cw_czone_division", nogen keep(1 3)

generate region=.
local region_list reg_neweng reg_midatl reg_encen reg_wncen reg_satl reg_escen reg_wscen reg_mount reg_pacif
local counter=1
foreach region in `region_list' {
	replace  region=`counter' if `region'
	local ++counter
}

drop reg_*

save "output/czone_level_dabase_`name'", replace


*===============================================================================
*APPENDING EMPLOYMENT TO POPULATION RATIO FILES
*===============================================================================
*/
clear
foreach year in `year_list' {
	append using  `etp_`year''
}
merge m:1 year czone using  "output/czone_level_dabase_full_time", nogen
drop if missing(male_l_wage)
save "output/etp_file_full_time", replace



*APPENDING BY EDUCATION DATASET
clear
foreach year in `year_list' {
	append using  `by_education_`year''
}
merge m:1 year czone using "output/czone_level_dabase_full_time", nogen keep(3)
drop if missing(male_l_wage)
save "output/by_education_file_full_time", replace
/*
*APPENDING GENDER INDUSTRY SHARES DATASET
clear
foreach year in `year_list' {
	append using  `by_gender_ind_`year''
}
merge m:1 year czone using "output/czone_level_dabase_full_time", nogen keep(3)
drop if missing(male_l_wage)
save "output/by_gender_ind_file_full_time", replace

