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
	qui {
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
		
		merge m:1   czone  using `aggregate_1950', nogen  keep(1 3)
		
		local filter if full_time==1& (l_czone_density_50>0) 
		
		*Adding occupation and industry fixed effects
		reghdfe l_hrwage  `filter' [pw=perwt], ///
			absorb(i.czone#i.female i.age i.grouped_race i.migrant i.education i.ind1950, savefe) nocons
		rename  __hdfe6__ ind_fe

		cap drop __*__

		gcollapse (mean) ind_fe (count) ind_emp=l_hrwage [pw=perwt], by(female czone ind1950 year) fast
		
		egen temp=mean(ind_fe), by(ind1950 year)
	
		drop ind_fe
		
		rename temp ind_fe
		
		reshape wide ind_emp*, i(ind1950 czone year) j(female)
		
		rename ind_emp0 male_ind_emp
		rename ind_emp1	female_ind_emp
		
		egen   male_czone_emp=sum(male_ind_emp), by(czone year)
		egen   female_czone_emp=sum(female_ind_emp), by(czone year)
		
		g 	   male_ind_empshare=male_ind_emp/male_czone_emp
		g 	   female_ind_empshare=female_ind_emp/female_czone_emp
		
		tempfile collapsed`year'
		save `collapsed`year''	
	}
}

clear
foreach year in  `year_list' {
	append using `collapsed`year''
}

merge m:1 czone year using `aggregate_vars', nogen keep(1 3)

save "output/ind_fe_file_full_time", replace


