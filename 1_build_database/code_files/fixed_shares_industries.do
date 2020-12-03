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
local year_list  	1950 1970  1980 1990 2000 2010 2020


foreach year in  `year_list' {
	di 		"Processing `year'", as result
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
		
		local filter if full_time
		
        gcollapse (mean) l_hrwage (count) people=l_hrwage `filter' [pw=perwt], by(czone year ind1950 female) fast

        reshape wide l_hrwage people, i(czone year ind1950) j(female)

        forvalues j=0/1 {
            egen total`j'=sum(people`j'), by(czone year)
            gen empshare`j'=people`j'/total`j'
        }

        foreach variable in l_hrwage0 people0 l_hrwage1 people1 total0 empshare0 total1 empshare1 {
            replace `variable'=0 if missing(`variable')
        }

		tempfile collapsed`year'
		save `collapsed`year''	

	
}

clear
foreach year in  `year_list' {
	append using `collapsed`year''
}

drop if year==1950


save "output/fixed_ind_shares_database_full_time", replace