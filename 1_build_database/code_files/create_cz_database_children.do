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

local sep_var      married

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
		g female_head=		relate==1&female
        g has_children=     nchild>0
		
		merge m:1 czone year using "output/czone_level_dabase_full_time", nogen keep(1 3)

		local filter if full_time==1& (czone_pop_50/cz_area>1) 
		
		*Extracting gender specific premiums		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.`sep_var', savefe)
		rename  __hdfe1__ baseline

		cap drop __*__
		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.`sep_var' i.age i.grouped_race i.migrant, savefe)
        rename  __hdfe1__ basic

		cap drop __*__

		*Basic human capital proxies
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.`sep_var' i.age i.grouped_race i.migrant i.education, savefe)
		rename  __hdfe1__ human
   		cap drop __*__


        *Basic human capital proxies
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.`sep_var' i.age i.grouped_race i.ind1950 i.occ1950 i.migrant i.education, savefe)
		rename  __hdfe1__ full
   		cap drop __*__


		gcollapse (mean) baseline* basic* human* full*, by(female `sep_var' czone year) fast
		reshape wide baseline* basic* human* full*, i(czone `sep_var' year) j(female)

        foreach variable in baseline basic human full {
            generate `variable'_gap=`variable'0-`variable'1
        }

		tempfile collapsed`year'
		save `collapsed`year''	
	}
	
}

clear
foreach year in  `year_list' {
	append using `collapsed`year''
}


replace year=2020 if year==2018
replace year=2010 if year==2011

local name full_time
save "output/czone_level_dabase_`sep_var'_`name'", replace


local name full_time
use "output/czone_level_dabase_`sep_var'_`name'", clear
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

merge  m:1 czone year using "output/czone_level_dabase_full_time", nogen keep(1 3)
sort czone  `variable' year

by czone `variable': generate l_czone_density_50=l_czone_density[1]



save "output/czone_level_dabase_`sep_var'_`name'", replace


