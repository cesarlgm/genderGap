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



*First I extract 1950 density for the filter form the aggregate file I already have
tempfile aggregate_1950
    use "output/czone_level_dabase_full_time", clear
    keep if year==1950
    keep czone l_czone_pop l_czone_density 
    rename l_czone_pop      l_czone_pop_50
    rename l_czone_density  l_czone_density_50
save `aggregate_1950'

tempfile aggregate_vars
    use "output/czone_level_dabase_full_time", clear
    keep czone year l_czone_pop l_czone_density 
    rename l_czone_pop      l_czone_pop
    rename l_czone_density  l_czone_density
save `aggregate_vars'


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
		
		generate l_hrwage_full=l_hrwage 	if missing(full_time)|full_time==0
			
        *Add CZ level information
        merge m:1 czone using `aggregate_1950', nogen 

		local filter if full_time==1& (l_czone_density_50>0) 
				
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.high_education, savefe) nocons
		rename  __hdfe1__ l_wage_baseline

		cap drop __*__
		
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female#i.high_education i.age i.grouped_race i.migrant, savefe) nocons
		rename  __hdfe1__ l_wage_basic

		cap drop __*__


		gcollapse (mean) l_wage* (count)  population=age (count) with_wage=l_hrwage (mean) ///
			in_labforce [pw=perwt], by(female high_education czone year) fast
		
		reshape wide l_wage_* with_wage population in_labforce, i(czone high_education year) j(female)
		
		rename (population0 population1 in_labforce0 in_labforce1 with_wage0 with_wage1) ///
			(male_pop female_pop male_lfp female_lfp male_with_wage female_with_wage)
	

		*Renaming variables
		rename  l_wage_baseline0 male_l_wage 	
		rename  l_wage_baseline1 female_l_wage 	

		rename  l_wage_basic0 male_l_wage_basic
		rename  l_wage_basic1 female_l_wage_basic
		
		generate wage_raw_gap=			male_l_wage-female_l_wage
		generate wage_bas_gap=			male_l_wage_basic-female_l_wage_basic
		
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

cap drop l_czone_density_50
cap drop l_czone_pop_50
cap drop l_czone_pop
cap drop l_czone_density
cap drop total*
cap drop *_cz_educsh*

merge m:1 czone year using `aggregate_vars', nogen keep(1 3)

*This computes the total share of women with college education
egen total_female=sum(female_pop), by(czone year)
egen total_male=sum(male_pop), by(czone year)

generate female_cz_educsh=female_pop/total_female
generate  male_cz_educsh=male_pop/total_male

*This compute the total share of women with college education with non-zero wage
egen total_male_with_wage=sum(male_with_wage), by(czone year)
egen total_female_with_wage=sum(female_with_wage), by(czone year)

generate female_cz_educsh_ww=male_with_wage/total_male_with_wage
generate male_cz_educsh_ww=female_with_wage/total_female_with_wage

merge m:1 czone using `aggregate_1950', keep(1 3) nogen

save "output/czone_level_dabase_full_time_by_education", replace
