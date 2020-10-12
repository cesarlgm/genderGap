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



*Database type 0=gender 1=race
*Execution parameters
local data_type=	4
local industry 		ind1950
local occupation 	occ1950
local year_list 1950 1970 1980 1990 2000 2010 2020


foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  	"${data}/output/cleaned_census_`year'", clear
		
		*Quick fix of variables
		egen    grouped_race=       cut(race), at(1,2,3,9)
		label   define  grouped_race 1 "White" 2 "Black" 3 "Other"
		label   values grouped_race grouped_race

		g married=			inlist(marst, 1,2)
		g high_education=	inlist(education, 3,4)
		g migrant=bpl>=150 	if !missing(bpl)
		g native_migrant=	bpl!=statefip if bpl<150
		
		g female_migrant=	native_migrant if female
		g male_migrant=		native_migrant if !female
		g full_time=		wkswork>=40&hrswork>=35
		
		*Classification of industris
		do "code_files/classify_industries_occupations.do" `occupation'
		
		tempfile census
		save `census'
		
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


		*STEP 2> computing population counts by czone-gender
		gcollapse (count) population=age (count) observations=l_hrwage (mean) in_labforce [pw=perwt], ///
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
			absorb(i.czone#i.female, savefe)
		rename  __hdfe1__ l_wage_baseline

		cap drop __*__

		gcollapse (mean) l_wage*, by(female czone year) fast
		reshape wide l_wage_*, i(czone year) j(female)

		*Renaming variables
		rename  l_wage_baseline0 male_l_wage 	
		rename  l_wage_baseline1 female_l_wage 	

		merge m:1 czone year using `aggregate_vars_`year'', nogen keep(1 3)
		merge m:1 	czone using "../1_build_database/output/czone_area", nogen keep(1 3)
		
		generate l_czone_pop=		log(czone_pop)
		generate l_czone_density=	log(czone_pop/cz_area)
		
		generate wage_raw_gap=male_l_wage-female_l_wage
		
		tempfile collapsed`year'
		save `collapsed`year''
		
		
	}
}

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