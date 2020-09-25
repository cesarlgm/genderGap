*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: master do file of census analysis.
*===============================================================================	
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0


grscheme, ncolor(7) style(tableau)

*WOMEN OVER TIME SHIFT TO HIGHER PAID INDUSTRIES. AT THE START OF THE PERIOD THEY ARE
*CONCENTRATED IN INDUSTRIES THAT GIVE A LOWER PAY
*---------------------------------------------------------------------------------------
use year female ind1950 perwt l_hrwage using ///
     "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

*table year female if !missing(l_hrwage), c(sum perwt) format(%14.0fc)
*There 1970-2000 sees a big jump of female employment
*The change reduces from 1990 onwards
*---------------------------------------------------------------------------------
/*
Year	Male	% change	Female	% change
1970	30,678,889		13,298,448.00	
1980	39,303,456	28%	21,834,481.00	64%
1990	43,329,343	10%	28,641,263.00	31%
2000	50,188,021	16%	35,664,979.00	25%
2010	51,713,742	3%	38,812,815	9%
2020	55,682,751	8%	42,201,861	9%
*/

*Whare are these new women entering
preserve
tempfile sex_shares
gcollapse (count) employment=perwt  if !missing(l_hrwage)&!missing(ind1950), ///
    by(year ind1950 female) fast


egen  total_sex_employment=sum(employment), by(year female)
generate  employment_sex_share=employment/total_sex_employment

drop total_sex_employment employment
reshape wide employment_sex_share, i(year ind1950) j(female)
save    `sex_shares'
restore 

gcollapse (mean) l_hrwage  if !missing(l_hrwage)&!missing(ind1950), ///
    by(year ind1950) fast

merge 1:1 year ind1950 using     `sex_shares'


sort year l_hrwage

by year: g accum_share0=sum(employment_sex_share0)
by year: g accum_share1=sum(employment_sex_share1)

*HERE I SHOW A AN DENSITY BY PAY OF THE INDUSTRY. WOMEN ARE MORE CONCENTRATED IN LOW PAY INDUSTRIES AT THE START 
*OF THE PERIOD
tw line ac* l_hrwage, by(year) xtitle("Industry's average log(hourly wage)") ///
    ytitle("Accumulated employment share") legend(order(1 "Men" 2 "Women"))
graph export "output/figures/employment_distribution_gender_`indiv_sample'.png", replace


*************************************************************************************************************
*IS IT A STORY OF ACCESS TO HIGHLY PAID OCUPATIONS?
*************************************************************************************************************

use if year==1970&!missing(l_hrwage) using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

*First I extract industry's fixed effects
reghdfe l_hrwage [pw=perwt] if year==1970, vce(cl czone)  ///
    absorb(i.ind1950 i.age i.race i.female i.marst i.migrant i.education ) savefe

rename __hdfe1__ with_ind_fe
cap drop *hdfe*

gcollapse (mean) with_ind_fe (sum) employment=perwt, by(year ind1950)

keep ind1950 with_ind_fe employment
drop if with_ind_fe==.

*I should weight here by the employment share of the industry

*Divide industry's fe into quartiles
*I weight occupations by its size when computing the quartiles.
xtile       pay_quartile=with_ind_fe [pw=employment], nq(4)

*Define a high wage industry as those in the top quartile
generate    high_pay_industry=pay_quartile==4


save "temporary_files/high_pay_industry_classification", replace


use  if !missing(l_hrwage) using    "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 
merge  m:1 ind1950 using "temporary_files/high_pay_industry_classification", nogen keep(1 3)

gcollapse (sum) perwt if !missing(l_hrwage), by(czone year high_pay_industry) fast

drop if missing(high_pay_industry)


reshape wide perwt, i(czone year) j(high_pay_industry)


merge 1:1 czone year using   "temporary_files/aggregate_regression_file_final_`indiv_sample'"

generate high_pay_share=perwt1/(perwt1+perwt0)

eststo clear
eststo baseline:        regress l_hrwage i.year#c.l_czone_density  i.year
eststo dissimilarity:   regress l_hrwage i.year#c.l_czone_density  i.year#c.high_pay_share  i.year

local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


*Once I control for the employment share of the highly paid occupations => drop of the gradient goes 
*away from 1970-1990
coefplot  baseline  dissimilarity, keep(*density*) yline(0) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') ///
    xlabel(`year_label') ///
    legend(order(1 "Baseline" 3 "+ share in high-pay industries"))

graph export "output/figures/controlling_high_wage_industries_`indiv_sample'.png", replace

save "temporary_files/file_high_wage_industries_`indiv_sample'", replace

/*
*=============================================================================================================
*ZOOMING IN ON HIGH-PAY INDUSTRIES
*=============================================================================================================
use if year<=1990 using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

*Which industries are the highly paid industries.
reghdfe l_hrwage [pw=perwt] if year==1970, vce(cl czone)  ///
    absorb(i.ind1950#i.female i.age i.race i.marst i.migrant i.education ) savefe

rename __hdfe1__ with_ind_fe
cap drop *hdfe*

gcollapse (mean) with_ind_fe (sum) employment=perwt if !missing(l_hrwage), by(year ind1950 female)
drop if missing(with_ind_fe)& missing(employment)

reshape wide with_ind_fe employment, i(year ind1950) j(female)

generate industry_wage_gap=with_ind_fe0-with_ind_fe1
generate female_empshare=employment1/(employment1+employment0)

merge m:1 ind1950  using "temporary_files/high_pay_industry_classification"


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


xtset ind1950 year, delta(10)

g d_female_empshare=d.female_empshare

*High pay industries are disproportinately concentrated in manufacturing and they tend to have low baseline female employment.

*Three statements here:

*High-pay industries tend to have lower female employment share.
*Note that the coefficient on the the industry fe is very constant across years.
reg female_empshare  i.year#c.with_ind_fe i.year

*There is no differential increase in access of women to these industries at the national level.
reg d_female_empshare  i.year#c.with_ind_fe i.year

*Moreover, high pay is not significantly associated with a lower wage gap
reg industry_wage_gap   with_ind_fe


*So it has to be that the specialization of CZ in thes high-pay industries give women 
*disproportionate access to better employment opportunities
*========================================================================================================

*========================================================================================================
*KILLING SOME ALTERNATIVE STORIES
*========================================================================================================
*it doesn't appear to be a story about specialization in low gap industries.

use  if year==1970 using "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 

keep if year==1970

*I extraact the gender wage gap in 1970
*Here I check which industries have high gender gaps at the national level
reghdfe l_hrwage [pw=perwt] if year==1970, vce(cl czone)  ///
    absorb(i.ind1950#i.female i.age i.race i.marst i.migrant i.education ) savefe

rename __hdfe1__ with_ind_fe
cap drop *hdfe*

gcollapse (mean) *fe (sum) perwt if !missing(l_hrwage), by(ind1950 ind_type female) fast

egen total_employment=sum(perwt)
egen total_ind_employment=sum(perwt), by(ind1950 ind_type)
generate emp_share=total_ind_employment/total_employment

drop perwt
drop total*

reshape wide *fe, i(ind1950 ind_type) j(female)

drop if missing(ind_type)

*Computing industrial wage gap in 1970
generate ind_wage_gap=with_ind_fe0-with_ind_fe1


xtile gap_quantile= ind_wage_gap [aw=emp_share], nq(3)

generate high_gap_industry=gap_quantile==3

keep ind1950 ind_type ind_wage_gap high_gap_industry

tempfile industry_gaps
save `industry_gaps'

clear
use  if !missing(l_hrwage) using    "temporary_files/file_for_individual_level_regressions_`indiv_sample'", clear 
merge  m:1 ind1950 using `industry_gaps', nogen keep(1 3)

drop if missing(ind1950)

gcollapse (sum) perwt, by(czone year high_gap_industry) fast
drop if missing(high_gap_industry)
reshape wide perwt, i(czone year) j(high_gap_industry)

generate high_gap_empshare=perwt1/(perwt1+perwt0)

merge 1:1 czone year using   "temporary_files/aggregate_regression_file_final_`indiv_sample'"


eststo clear
eststo baseline:        regress l_hrwage i.year#c.l_czone_density  i.year
eststo high_gap:        regress l_hrwage i.year#c.l_czone_density  i.year#c.high_gap_empshare  i.year


local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

*away from 1970-1990
coefplot  baseline  high_gap, keep(*density*) yline(0) ///
    ytitle("w{sup:male}-w{sup:female} gradient ({&beta}{sub:t})")  ///
    ciopt(recast(rcap)) base vert  xlabel(`year_label') ///
    legend(order(1 "Baseline" 3 "+ share in high-gap industries")) 


graph export "output/figures/controlling_high_gap_industries_`indiv_sample'.png", replace
*Take away... it not about gap differences across industries. I has to be differences in employment allocation
*across industries.

*Although there could be sth for the end of the period