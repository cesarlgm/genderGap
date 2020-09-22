*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: explores measures of selection
*===============================================================================
*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"

gettoken analysis_type 	0:0
gettoken base_year 		0:0 
local year_list			`0'

di "`year_list'"

local controls 		marst education race age 
foreach variable in `controls' {
	local control_list `control_list' i.`variable'
}

use  "${data}/output/cleaned_census_`base_year'", clear

*I compute the dummies only for the employed 	
cap replace occ1950=. 		if occ1950>=980
cap replace ind1950=. 		if ind1950>=980
cap replace ind1950=. 		if ind1950==0
cap replace occ1990=.		if occ1990>=991

g migrant=bpl>=150 if !missing(bpl)


*Definition of full-time workers
g	full_time=wkswork>=40&hrswork>=35
replace l_hrwage=. if !full_time

eststo clear
qui eststo male_regression: reg l_hrwage `control_list' i.migrant if !female&full_time
qui g	male_regression=e(sample)
qui eststo female_regression: reg l_hrwage `control_list' i.migrant if female&full_time
qui g	female_regression=e(sample)

qui eststo male_ind: reg l_hrwage `control_list' i.ind1950 i.migrant if !female&full_time
qui g	male_ind=e(sample)
qui eststo female_ind: reg l_hrwage `control_list' i.ind1950 i.migrant if female&full_time
qui g	female_ind=e(sample)


clear
foreach year in `year_list' {
	tempfile quality_`year'
	use  czone year female bpl wkswork hrswork perwt l_hrwage ind1950 `controls' using ///
		"${data}/output/cleaned_census_`year'", clear
	
	*I compute the dummies only for the employed 	
	cap replace occ1950=. 		if occ1950>=980
	cap replace ind1950=. 		if ind1950>=980
	cap replace ind1950=. 		if ind1950==0
	cap replace occ1990=.		if occ1990>=991
	
	g migrant=bpl>=150 if !missing(bpl)


	*Definition of full-time workers
	g	full_time=wkswork>=40&hrswork>=35
	replace l_hrwage=. if !full_time
	
	*Quality without industry
	qui reg l_hrwage `control_list' i.migrant if !female&full_time
	g male_regression=e(sample)
	
	qui reg l_hrwage `control_list' i.migrant if female&full_time
	g female_regression=e(sample)
	
	*Quality with industry
	qui reg l_hrwage `control_list' i.ind1950 i.migrant if !female&full_time
	g male_ind=		e(sample)
	
	qui reg l_hrwage `control_list' i.ind1950 i.migrant if female&full_time
	g female_ind=	e(sample)
	
	*Let me start with the assumption that women were paid the same as men 
	*in 1970
	qui est 	restore male_regression
	qui predict male_quality 	if male_regression
	qui est 	restore female_regression
	qui predict female_quality 	if female_regression
	
	qui g	average_quality=male_quality if male_regression
	qui replace average_quality=female_quality if female_regression

	qui est 	restore male_ind
	qui predict male_ind_quality 	if male_ind
	qui est 	restore female_ind
	qui predict female_ind_quality 	if female_ind
	
	qui g	average_quality_ind=male_ind_quality 	if male_ind
	qui replace average_quality=female_ind_quality 	if female_ind

	gcollapse (mean) *quality [pw=perwt], by(czone year) fast
	save `quality_`year'', replace
	
}

clear
foreach year in `year_list' {
	append using `quality_`year''
}

replace year=2020 if year==2018
replace year=2010 if year==2011

foreach variable of varlist *quality {
	egen tempsd=	sd(`variable'), by(year)
	egen tempmean=	mean(`variable'), by(year)
	replace `variable'=(`variable'-tempmean)/tempsd
	cap drop tempsd
	cap drop tempmean
}

save "temporary_files/selection_observables_`base_year'", replace
