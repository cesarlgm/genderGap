gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0



grscheme, ncolor(7) style(tableau)
/*
use if !missing(l_hrwage)&!missing(l_hrwage) ///
	using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

*First I extract industry's fixed effects
reghdfe l_hrwage [pw=perwt], vce(cl czone)  ///
    absorb(i.ind1950#i.year i.age#i.year i.race#i.year ///
	i.female#i.year i.marst#i.year i.migrant#i.year i.education#i.year) savefe

rename __hdfe1__ with_ind_fe
cap drop *hdfe*

gcollapse (mean) with_ind_fe (sum) employment=perwt if !missing(with_ind_fe), by(year ind1950)


xtset ind1950 year, delta(10)

levelsof year
generate pay_quartile=.
foreach year in `r(levels)' {
	cap drop temp
	*Here I weight observations using the its size / equivalent to weighting by employment share
	xtile 	temp=with_ind_fe [pw=employment] if year==`year', nq(4)
	replace pay_quartile=temp 			if year==`year'
}

*I keep 1970's clasification fixed
sort ind1950 year
by ind1950: generate pay_quartile_1970=pay_quartile[1]

label var pay_quartile 		"Year specific pay quartile"
label var pay_quartile_1970 "1970's specific pay quartile"

drop if ind1950==.

cap drop temp
egen temp=sum(employment), by(year)
generate empshare=employment/temp

drop temp

save "temporary_files/industry_premia_by_year_`indiv_sample'", replace


*QUESTION 1> ARE THESE INDUSTRIES IN DECLINE AT THE NATIONAL LEVEL?
*Yes. these industries are declining at the national level
*---------------------------------------------------------------------------------------
use "temporary_files/industry_premia_by_year_`indiv_sample'", clear


gcollapse (sum) empshare (sum) employment, by(pay_quartile_1970 year) fast

xtset pay_quartile_1970 year, delta(10)
generate dp_employment=d.employment/l.employment
generate dp_empshare=d.empshare/l.empshare

separate empshare, by(pay_quartile_1970)

tw line `r(varlist)' year, ///
	legend(order(1 "Lowest pay quartile" 2 "Second quartile" ///
	3 "Third quartile" 4 "Highest pay quartile")) ///
	recast(connected) yscale(range(0 .3)) ylab(0(.1).3) ///
	ytitle("Employment share (national)")

graph export "output/figures/employment_share_quartile_by_year_`indiv_sample'.png", replace



*QUESTION 2> WHAT ARE THE INDUSTRIES THAT I ASSIGN AS BEING HIGH PAY
use  "temporary_files/industry_premia_by_year_`indiv_sample'", clear

generate high_pay_industry=pay_quartile_1970==4

g ind_mining_cons=		inrange(ind1950,206,246) 	
g ind_manufacturing=	inrange(ind1950,306,499) 	
g ind_pers_services=	inrange(ind1950,826,849) 	
g ind_prof_services=	inrange(ind1950,868,899) 
g ind_ret_services=		inrange(ind1950,606,699) 	
g ind_oth_services=		inrange(ind1950,506,598) | 	inrange(ind1950,716,817)| inrange(ind1950,856,859)
g ind_public_adm=		inrange(ind1950,906,946)  	
g ind_agriculture=		inrange(ind1950,105,126) 	

local counter=1

local ind_list mining_cons manufacturing pers_services prof_services ///
	ret_services oth_services public_adm agriculture

g	ind_type=.	
foreach industry in `ind_list' {
	replace ind_type=`counter' if ind_`industry'==1
	local ++counter
}

capture label define ind_type 	1 "Mining and construction" ///
								2 "Manufacturing" ///
								3 "Personal services" ///
								4 "Professional services" ///
								5 "Retail services" ///
								6 "Other services" ///
								7 "Public administration"  ///
								8 "Agriculture"
label values ind_type ind_type


log using "output/log_files/high_pay_industries.txt", text replace
tab ind1950 if pay_quartile_1970==4&year==1970

*Unweighted by industry size
table high_pay_industry if year==1970 , c(mean ind_manufacturing)

*Weighted by industry size
table high_pay_industry if year==1970 [pw=empshare], c(mean ind_manufacturing)
log close

save "temporary_files/industry_classification_by_year_`indiv_sample'", replace 

*QUESTION 3> IS IT BECAUSE WOMEN GET MORE ACCESS TO THESE INDUSTRIES IN DENSER PLACES
******************************************************************************************************
use perwt czone ind1950 l_hrwage female year if !missing(l_hrwage)&!missing(l_hrwage)&!missing(ind1950) ///
	using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

gcollapse (sum) employment=perwt, by(female czone ind1950 year) fast


merge m:1 ind1950 year using  "temporary_files/industry_classification_by_year_`indiv_sample'"

gcollapse (sum) employment, by(female czone year high_pay_industry)

reshape wide employment, i(czone year high_pay_industry) j(female)


egen total_male_emp=sum(employment0), by(czone year)
egen total_female_emp=sum(employment1), by(czone year)

generate total_female_empshare=total_female_emp/(total_female_emp+total_male_emp)



generate female_empshare=employment1/(employment0+employment1)

generate female_empshare_ex=female_empshare-total_female_empshare

merge m:1 czone year using   "temporary_files/aggregate_regression_file_final_`indiv_sample'"


separate female_empshare_ex, by(high_pay_industry)


tw scatter `r(varlist)' l_czone_density, ///
	by(year) msize(.3 .3 .3) legend(order(1 "Low pay industries"  ///
	2 "High pay industries")) ytitle("Female employment share")

graph export "output/figures/within_industry_female_empshare.png", replace


generate male_ind_type_share=employment0/total_male_emp
generate female_ind_type_share=employment1/total_female_emp

tw scatter female_ind_type_share male_ind_type_share l_czone_density ///
	if high_pay_industry, by(year)  msize(.3 .3) legend(order(1 "Female"  ///
	2 "Male")) ytitle("Employment share in high pay industries")

graph export "output/figures/within_gender_high_pay_empshare.png", replace


*Women are more heavily concentrated in low-pay industries at the start of the period
	
	
********************************************************************************	
/*


*QUESTION 2> ARE THESE INDUSTRIES IN DECLINE DISPROPORTIONATELY IN DENSER PLACES LEVEL?
*--------------------------------------------------------------------------------------------------
*answer they are
use if !missing(l_hrwage)&!missing(l_hrwage)&!missing(ind1950) ///
	using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

merge m:1  ind1950 year using "temporary_files/industry_premia_by_year_`indiv_sample'"


generate high_pay_industry=pay_quartile_1970==4

gcollapse (sum) employment=perwt, by(czone year high_pay_industry) fast

reshape wide employment, i(czone year) j(high_pay_industry)

generate high_pay_empshare=employment1/(employment0+employment1)


cap drop _merge
merge 1:1 czone year using ///
	"temporary_files/aggregate_regression_file_final_`indiv_sample'",  nogen

xtset czone year, delta(10)

sort czone year

by czone: generate d_high_empshare_1970=high_pay_empshare-high_pay_empshare[1]

levelsof year
foreach year in 1980 1990 2000 2010 2020 {
	tw (scatter d_high_empshare_1970 l_czone_density  [aw=czone_pop]) ///
		 (lfit  d_high_empshare_1970 l_czone_density) ///
		 if year==`year', yscale(range(-.3 .3)) ylab(-.3(.1).3) ///
		 ytitle("`year'-1970 change") ///
		 legend(off) ///
		 title("Change in share of employment in high pay industries")
	graph export "output/figures/change_empshare_highpay_`year'_`indiv_sample'.png", replace
}



*QUESTION 3> ARE THESE INDUSTRIES IN DECLINE DISPROPORTIONATELY IN DENSER PLACES LEVEL?
*--------------------------------------------------------------------------------------------------


*QUESTION 1> ARE THESE INDUSTRIES IN DECLINE
*---------------------------------------------------------------------------------------
/*
use "temporary_files/industry_premia_by_year_`indiv_sample'", clear

xtset ind1950 year, delta(10)


levelsof year
generate pay_quartile=.
foreach year in `r(levels)' {
	cap drop temp

	*Here I weight observations using the its size / equivalent to weighting by employment share
	xtile 	temp=with_ind_fe [pw=perwt] if year==`year', nq(4)
	replace pay_quartile=temp if year==`year'
}



/*
tw scatter with_ind_fe l5.with_ind_fe if year==2020

sort ind1950 year
by ind1950: generate with_ind_fe_1970=with_ind_fe[1]
generate   d_with_ind_fe=with_ind_fe-with_ind_fe_1970

binscatter d_with_ind_fe with_ind_fe_1970, by(year) line(qfit)

/*





use "temporary_files/file_high_wage_industries_`indiv_sample'", clear
cap drop _merge
cap drop _est*
preserve
*Some preliminary fixes to the map database
tempfile map_tomerge
	use "../1_build_database/input/cz1990_data", clear
	use "../1_build_database/input/cz1990_data", clear
	rename cz czone
	rename cz_id _ID
	drop *_center
save `map_tomerge'
restore
merge m:1 czone using `map_tomerge', keep(2 3) nogen

preserve
replace high_pay_share=round(high_pay_share,.01)
replace l_hrwage_gap=round(l_hrwage_gap,.01)


*Map of population density
spmap high_pay_share  if year==1970 using "../1_build_database/input/cz1990_coor", ///
    id(_ID) fcolor(Reds2) legtitle("Share in high-pay industries")   clnumber(7) 

graph export "output/figures/high_pay_ind_map_1970_full_time.png", replace

spmap l_hrwage_gap  if year==1970 using "../1_build_database/input/cz1990_coor", ///
    id(_ID) fcolor(Reds2) legtitle("Gender wage gap")   clnumber(7) 

graph export "output/figures/pay_gap_map_1970_full_time.png", replace
restore 

tw scatter high_pay_share l_czone_density if year==1970, m(o) ///
    xtitle("log(CZ density)") ytitle(Employment share in high-pay industries)
graph export "output/figures/high_pay_ind_density_full_time.png", replace


tw scatter l_hrwage_gap high_pay_share if year==1970, m(o) ///
    xtitle("log(CZ density)") ytitle(Male wage advantage)
graph export "output/figures/pay_gap_density_full_time.png", replace


xtset czone year, delta(10)
sort czone year

by czone: generate high_pay_share_1970=	high_pay_share[1]
by czone: generate d_high_pay_share=		high_pay_share-high_pay_share[1]

*These are industries in declie 
tw scatter d_high_pay_share high_pay_share_1970 if year==1990, ///
	xtitle("1970 share in high-pay industries") ///
	ytitle("Change in high-pay industries share (1990-1970)") ///
	m(o)

**

preserve
	tempfile  share_female_high
	use year czone female ind1950 perwt l_hrwage if !missing(l_hrwage)&!missing(ind1950) using ///
		"temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

	merge m:1 ind1950 using  "temporary_files/high_pay_industry_classification", nogen keep(1 3)

	gcollapse (sum) perwt , by(year czone female high_pay_industry) fast

	reshape wide perwt, i(czone year female) j(high_pay_industry)

	generate high_pay_share=perwt1/(perwt1+perwt0)

	drop perwt*
	
	reshape wide high_pay_share, i(czone year) j(female)

	save `share_female_high'
restore

merge 1:1 czone year using `share_female_high', nogen

by czone: generate d_high_pay_share0=		high_pay_share0-high_pay_share0[1]
by czone: generate d_high_pay_share1=		high_pay_share1-high_pay_share1[1]

tw scatter  d_high_pay_share0 high_pay_share_1970, by(year)
tw scatter  d_high_pay_share1 high_pay_share_1970 , by(year)
