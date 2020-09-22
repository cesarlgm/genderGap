*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: defines female / male occupations classifications based on 
*		base_year
*===============================================================================

gettoken occupation 0: 0
local year_list `0'


foreach year in `year_list' {
	tempfile file_`year'
	use  	"${data}/output/cleaned_census_`year'", clear			

	do "code_files/classify_industries_occupations.do" `occupation'

	*Definition of full-time workers
	g		full_time=	wkswork>=40&hrswork>=35
	replace l_hrwage=. 	if !full_time

	keep if full_time & !missing(l_hrwage) & !missing(`occupation')

	g	empshare=1
	
	replace perwt=round(perwt)
	preserve
		tempfile empshare
		gcollapse (count) empshare (mean) l_hrwage (mean) female_share=female ///
			[fw=perwt], by(`occupation' year)
		egen 	total=	sum(empshare)
		g		people=	empshare
		replace empshare=	empshare/total
		drop total
		save `empshare'
	restore
	
	*I compute employment female employment share at the national level by occupation
	gcollapse (mean) l_hrwage [fw=perwt], by(female `occupation' year)
	
	
	reshape wide l_hrwage, i(year `occupation') j(female )

	g wage_raw_gap=l_hrwage0-l_hrwage1
	keep year `occupation' wage_raw_gap
	
	merge 1:1 `occupation' using `empshare', nogen keep(1 3)
	save   `file_`year''
}

clear
foreach year in `year_list' {
	append using `file_`year''
}

merge m:1 `occupation' using "output/gender_occ_classification_1950_`occupation'", ///
	nogen keep(1 3)


save "output/gender_naclevel_classification_1950_`occupation'", replace	
	
*Add high gender wage gap occupation.
