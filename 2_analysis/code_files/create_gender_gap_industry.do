*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: gender gaps by industry
*===============================================================================


local year_list `0'


local census_location "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data\output"

eststo clear

*This computes the overall gender gap
foreach year in `year_list' {
	use hrwage l_hrwage female education ind1950 occ1990 empstat perwt using "`census_location'\cleaned_census_`year'", clear
	
	do "../1_build_database/code_files/classify_industries_occupations.do"
		
	
	g male=!female
	
	qui eststo raw_`year'_agg: reg 		l_hrwage i.female if !(ind_manufacturing|ind_services) [pw=perwt], vce(r) 
	qui eststo raw_`year'_man: reg 		l_hrwage i.female if ind_manufacturing [pw=perwt], vce(r) 
	qui eststo raw_`year'_ser: reg 		l_hrwage i.female if ind_service [pw=perwt], vce(r) 
}

