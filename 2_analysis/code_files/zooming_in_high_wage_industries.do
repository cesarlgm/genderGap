gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0



grscheme, ncolor(7) style(tableau)

*QUESTION 1
*DO HIGH WAGE INDUSTRIES CONTINUE BEING HIGH WAGE IN THE 2000?
*============================================================================================
/*
use if !missing(l_hrwage)&!missing(l_hrwage) ///
	using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

*First I extract industry's fixed effects
reghdfe l_hrwage [pw=perwt], vce(cl czone)  ///
    absorb(i.ind1950#i.year i.age#i.year i.race#i.year ///
	i.female#i.year i.marst#i.year i.migrant#i.year i.education#i.year) savefe

rename __hdfe1__ with_ind_fe
cap drop *hdfe*

gcollapse (mean) with_ind_fe, by(year ind1950)

drop if ind1950==.
save "temporary_files/industry_premia_by_year_`indiv_sample'", replace
*/
use "temporary_files/industry_premia_by_year_`indiv_sample'", clear

xtset ind1950 year, delta(10)


levelsof year
generate pay_quartile=.
foreach year in `r(levels)' {
	cap drop temp
	xtile 	temp=with_ind_fe if year==`year', nq(4)
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
