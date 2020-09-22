*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: defines female / male occupations
*===============================================================================

local occupation ind1950
local base_year 1950
local year_list 1950  1970  1980 1990 2000 2010 2020

cd "C:\Users\thecs\Dropbox\Boston University\7-Research\LLMM\1_build_database"

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"
/*
di "Creating gender classification", as result
qui do "code_files/create_gender_occ_classification" 	`base_year' `occupation'
*/
di "Computing national-level employment shares and wages", as result
qui do "code_files/create_gender_occ_gender_gap.do" 	 `occupation' `year_list'
/*
di "Creating gender employment shares", as result
qui do "code_files/create_gender_occ_empshares"			`base_year' `occupation' `year_list'

replace year=2010 if year==2011
replace year=2020 if year==2018
save "output/gender_occ_empshares_database_`base_year'_`occupation'", replace
