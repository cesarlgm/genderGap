*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: create female empshare classification
*===============================================================================

gettoken base_year 	0: 0
gettoken occupation 0: 0

local sub=substr("`occupation'",1,3)

local year_list `0'

foreach year in `year_list' {
		di "Processing `year'", as result
		use czone year female `occupation' ind1950 ind1990 occ1990 occ1950 l_hrwage perwt wkswork hrswork using ///
			"${data}/output/cleaned_census_`year'", clear
			
		do "code_files/classify_industries_occupations.do" `occupation'
		
		*Definition of full-time workers
		g		full_time=	wkswork>=40&hrswork>=35
		replace l_hrwage=. 	if !full_time
		
		keep if !missing(l_hrwage) & !missing(`occupation')
		
		keep  year `occupation' czone perwt  female l_hrwage
		merge m:1 `occupation' using ///
			"temporary_files/gender_occ_classification_`base_year'", nogen keep(1 3)
			
		g male_`sub'_share=		male_`sub'*perwt
		g female_`sub'_share=	female_`sub'*perwt
		
		
		preserve
			tempfile `year'_database
			gcollapse (sum) total_emp=perwt male_`sub'_share female_`sub'_share, by(czone year)
			
			foreach gender in male female {
				replace `gender'_`sub'_share=`gender'_`sub'_share/total_emp
			}
	
			save ``year'_database'
		restore
		
		
		*What I wanted to compute was employment share in high - wage gap occupations
		tempfile `year'_`sub'_highwage
			gcollapse (mean) l_hrwage, by(czone female)
			
			reshape wide l_hrwage, i(czone) j(female)
			
			g wage_raw_gap=l_hrwage0-l_hrwage1
			keep czone wage_raw_gap
		save ``year'_`sub'_highwage'
			
		use ``year'_database', clear
		merge 1:1 czone using ``year'_`sub'_highwage'
		
		save ``year'_database', replace
	
}

clear
foreach year in `year_list' {
	append using ``year'_database'
}
