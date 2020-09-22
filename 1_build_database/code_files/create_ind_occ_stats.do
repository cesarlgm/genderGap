*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates CZ level database
*===============================================================================
*Database type 0=gender 1=race
local data_type=	0
local industry 		ind1950
local occupation 	occ1950

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"


*Fix this and send a mail to daniele
cd "C:\Users\thecs\Dropbox\Boston University\7-Research\LLMM\1_build_database"

local year_list 1950 1970 1980 1990 2000 2010 2020

foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  czone age perwt year ind* occ* l_hrwage female wkswork hrswork using	"${data}/output/cleaned_census_`year'", clear
		
		do "code_files/classify_industries_occupations.do" `occupation'
		
		replace year=2010 if year==2009
		
		g	wage_tilde=.

		*Definition of full-time workers
		g	full_time=wkswork>=40&hrswork>=35
		replace l_hrwage=. if !full_time
		

		foreach collapse_var in `industry' `occupation' {
			preserve
			tempfile `collapse_var'_vars
			*Industry concentration 		
			gcollapse (count) ind_employment=age [pw=perwt], ///
				by(`collapse_var' female czone year) fast
			
			egen total_employment=sum(ind_employment), by(female czone year)
			
			g	 gender_ind_empshare=ind_employment/total_employment
			
			egen hh_index_`collapse_var'=sum(gender_ind_empshare*gender_ind_empshare), by(female czone year)
			keep gender* hh* female czone year `collapse_var'
			reshape wide gender* hh*, i(czone `collapse_var' year) j(female)
		
			foreach variable of varlist gender_ind_empshare* {
				replace `variable'=0 if missing(`variable')
			}
			
			g	emp_dist_`collapse_var'=0.5*abs(gender_ind_empshare0-gender_ind_empshare1)
			
			gcollapse (sum) emp_dist (mean) hh*, by(czone year) fast
			save ``collapse_var'_vars'
			restore
		}

		
		use ``industry'_vars', clear
		merge 1:1 czone using ``occupation'_vars', nogen
		
		
		tempfile file`year'
		save `file`year''
	}
}

clear

foreach year in  `year_list' {
	append using `file`year''
}

replace year=2010 if year==2011
replace year=2020 if year==2018

save "output/occ_ind_statsfile", replace
