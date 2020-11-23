	*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: average wages by industry
*===============================================================================}

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\boston_university\7-Research\NSAM\1_build_data"

*Working directory
cd "C:\Users\thecs\Dropbox\boston_university\7-Research\genderGap\1_build_database"

local industry 		ind1950
local occupation 	occ1950
local year_list  	1950 1970 1980 1990 2000 2010 2020
/*
foreach year in  `year_list' {
	di 		"Processing `year'", as result
		use  	"${data}/output/cleaned_census_`year'", clear
		
		g full_time=		wkswork>=40&hrswork>=35
		
		*Classification of industris
		qui do "code_files/classify_industries_occupations.do" `occupation'
		
        gcollapse (mean) l_hrwage  (count) observations=l_hrwage [pw=perwt], by(czone year ind_type female)
		tempfile ind_`year'
		save `ind_`year''
		
}

clear 
foreach year in `year_list' {
	append using `ind_`year''
}

merge m:1 czone year using "output/czone_level_dabase_full_time", ///
	keepusing(wage*gap l_czone_density l_czone_pop) nogen keep(3)

save "output/ind_average_wages_full_time", replace


use "output/ind_average_wages_full_time", clear
drop if missing(ind_type)
reshape wide l_hrwage observations, i(czone year ind_type) j(female)

generate ind_wage_gap=l_hrwage0-l_hrwage1

rename l_hrwage0 male_l_hrwage
rename l_hrwage1 female_l_hrwage

rename observations0 male_employment
rename observations1 female_employment

save "output/ind_average_wages_full_time", replace

/***************************************************************************************************************
*HERE I DIVDE INTO MANUFACTURING AND THE REST
*****************************************************************************************************************/
*/
local year_list  	1950 1970  1980 1990 2000 2010 2020
foreach year in  `year_list' {
	di 		"Processing `year'", as result
		use  	"${data}/output/cleaned_census_`year'", clear
		
		g full_time=		wkswork>=40&hrswork>=35
		
		*Classification of industris
		qui do "code_files/classify_industries_occupations.do" `occupation'
		
		generate simp_ind=0
		replace  simp_ind=1 if inlist(ind_type,1,2)

		label define simp_ind 0 "Rest" 1 "Manufacturing and mining" 2 "Other services"
		label values simp_ind

        gcollapse (mean) l_hrwage  (count) observations=l_hrwage [pw=perwt], by(czone year simp_ind female)
		tempfile ind_`year'
		save `ind_`year''
		
}

clear 
foreach year in `year_list' {
	append using `ind_`year''
}

merge m:1 czone year using "output/czone_level_dabase_full_time", ///
	keepusing(wage*gap l_czone_density l_czone_pop) nogen keep(3)

reshape wide l_hrwage observations, i(czone year simp_ind) j(female)

generate ind_wage_gap=l_hrwage0-l_hrwage1

rename l_hrwage0 male_l_hrwage
rename l_hrwage1 female_l_hrwage

rename observations0 male_employment
rename observations1 female_employment

sort czone simp_ind year
by czone simp_ind: generate l_czone_density_50=l_czone_density[1]


save "output/ind_average_wages_full_time", replace