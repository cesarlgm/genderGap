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
local year_list  	1950  1970 1980 1990 2000 2010 2020


foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  	"${data}/output/cleaned_census_`year'", clear
		
		*Quick fix of variables
		egen    grouped_race=       cut(race), at(1,2,3,10)
		label   define  grouped_race 1 "White" 2 "Black" 3 "Other"
		label   values grouped_race grouped_race

        *I keep only men and white and black individual

		g married=			inlist(marst, 1,2)
		g high_education=	inlist(education, 3,4)
		g migrant=bpl>=150 	if !missing(bpl)
		g native_migrant=	bpl!=statefip if bpl<150
		
		g full_time=		wkswork>=40&hrswork>=35
		g female_head=		relate==1&female
		
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


		*STEP 2> computing population counts by czone-race
		gcollapse (count) population=age (count) observations=l_hrwage (mean) in_labforce [pw=perwt], ///
			by(grouped_race czone year)
		
		egen czone_pop=sum(population), by(czone year)

		reshape wide population in_labforce observations, i(czone year) j(grouped_race)
		
		rename   (population1 population2 population3  in_labforce1 in_labforce2 in_labforce3 ///
                 observations1 observations2  observations3 ) ///
			(white_pop black_pop other_pop white_lfp black_lfp other_lfp ///
            white_observations black_observations other_observations)

			
		merge m:1 czone using `czone_vars', nogen
		
		tempfile 	aggregate_vars_`year'
		drop 		ind_type
		save		`aggregate_vars_`year''
	
		use `census', clear
		merge m:1   czone  using `aggregate_vars_1950', nogen  keep(1 3)
		merge m:1 	czone  using "../1_build_database/output/czone_area", nogen keep(1 3)
		
		rename czone_pop czone_pop_50

		local filter if full_time==1& (czone_pop_50/cz_area>1) & !female & inlist(grouped_race, 1, 2)
		
		*Extracting gender specific premiums		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race, savefe)
		rename  __hdfe1__ l_wage_baseline

		cap drop __*__
		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race i.age  i.migrant, savefe)
		rename  __hdfe1__ l_wage_basic

		cap drop __*__

		*Basic human capital proxies
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race i.age  i.migrant i.education, savefe)
		rename  __hdfe1__ l_wage_human

		cap drop __*__

		*Adding occupation and industry fixed effects
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race i.age i.migrant i.education i.ind1950 i.occ1950, savefe)
		rename  __hdfe1__ l_wage_full

		cap drop __*__

		*Family structure variables
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race i.age i.migrant i.education i.ind1950 i.occ1950 i.married i.nchild, savefe)
		rename  __hdfe1__ l_wage_fam

		cap drop __*__

		*Female head dummy
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.grouped_race i.age i.migrant i.education i.ind1950 i.occ1950 i.married i.nchild i.female_head, savefe)
		rename  __hdfe1__ l_wage_fam_full

		cap drop __*__

		cap drop *hdfe*
		

		*Transportation time
        if `year'>1970 {
            reghdfe l_hrwage trantime [pw=perwt]  `filter' , absorb(i.czone#i.grouped_race i.age i.migrant i.education i.ind1950 ///
				 i.occ1950 i.married i.nchild i.female_head) savefe

            rename __hdfe1__ l_wage_ttime
            cap drop *hdfe*
        }
		gcollapse (mean) l_wage*, by(grouped_race czone year) fast
    
		reshape wide l_wage_*, i(czone year) j(grouped_race)
		
		*Renaming variables
		rename  l_wage_baseline1 white_l_wage 	
		rename  l_wage_baseline2 black_l_wage 	

		rename  l_wage_human1 white_l_wage_human
		rename  l_wage_human2 black_l_wage_human

		rename  l_wage_full1 white_l_wage_full
		rename  l_wage_full2 black_l_wage_full

		rename  l_wage_fam1 white_l_wage_fam
		rename  l_wage_fam2 black_l_wage_fam	
		
		rename  l_wage_fam_full1 white_l_wage_fam_full
		rename  l_wage_fam_full2 black_l_wage_fam_full	

		cap rename  l_wage_ttime0 white_l_wage_tti
		cap rename  l_wage_ttime1 black_l_wage_tti	
		
		merge m:1   czone year using `aggregate_vars_`year'', nogen keep(1 3)
		merge m:1 	czone using "../1_build_database/output/czone_area", nogen keep(1 3)
		
		generate l_czone_pop=		log(czone_pop)
		generate l_czone_density=	log(czone_pop/cz_area)
		
		generate wage_raw_gap=white_l_wage-black_l_wage
		generate wage_hum_gap=white_l_wage_human-black_l_wage_human
		generate wage_ful_gap=white_l_wage_full-black_l_wage_full
		generate wage_fam_gap=white_l_wage_fam-black_l_wage_fam
		generate wage_ffu_gap=white_l_wage_fam_full-black_l_wage_fam_full
		cap generate wage_tti_gap=white_l_wage_tti-black_l_wage_tti

        drop l_wage*3

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

local name full_time_race
save "output/czone_level_dabase_`name'", replace

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
