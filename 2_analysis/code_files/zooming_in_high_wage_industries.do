gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0



grscheme, ncolor(7) style(tableau)
use "../1_build_database/output/ind_fe_file_full_time", clear


gcollapse (sum) male_ind_emp female_ind_emp (mean) ind_fe, by(ind1950 year)


sort ind1950 year
by ind1950: generate ind_fe_70=ind_fe[2]


foreach gender in male female {
	egen `gender'_total_emp=sum(`gender'_ind_emp), by(year)
	generate `gender'_ind_empshare=`gender'_ind_emp/`gender'_total_emp
}

eststo male: 	reg male_ind_empshare i.year#c.ind_fe i.year if year>1950, vce(cl ind1950)
eststo female: 	reg female_ind_empshare i.year#c.ind_fe i.year if year>1950, vce(cl ind1950)

local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


coefplot male female,  keep(*ind_fe*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Men" 4 "Women"))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 

graph export "output/figures/gender_ind_empshares.png", replace


local figure_title "Industry employment share by gender"
local figure_name "output/figures/gender_ind_empshares.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Average share college graduates""College share-density gradient""'

local figure_list gender_ind_empshares

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  key(figure:ind_gender_shares)

*An alternative way to see this:
tw (lowess male_ind_empshare ind_fe_70, lwidth(1)) ///
	(lowess female_ind_empshare ind_fe_70, lwidth(1)) ///
	if inlist(year, 1970, 1990, 2020), by(year, rows(1)) ///
	legend(order(1 "Men" 2 "Women") ring(0) pos(1))   ///
	xtitle("Relative pay in 1970") ytitle("Employment share")
graph export "output/figures/gender_empshare_distribution.png", replace

*An alternative way to see this:
tw (lowess male_ind_empshare ind_fe, lwidth(1)) ///
	(lowess female_ind_empshare ind_fe, lwidth(1)) ///
	if inlist(year, 1970, 1990, 2020), by(year, rows(1)) ///
	legend(order(1 "Men" 2 "Women") ring(0) pos(1))   ///
	xtitle("Year-specific relative pay") ytitle("Employment share")
graph export "output/figures/gender_empshare_distribution_year_ranking.png", replace


local figure_title "Industry employment distribution by gender"
local figure_name "output/figures/gender_empshare_distribution.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Ranking fixed in 1970""Varying the ranking""'

local figure_list gender_empshare_distribution gender_empshare_distribution_year_ranking

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  key(fig:gender_distribution)


*----------------------------------------------------------
egen total_emp=rowtotal(male_ind_emp female_ind_emp)

egen year_emp=sum(total_emp), by(year)

generate ind_empshare=total_emp/year_emp

gegen high_pay=xtile(ind_fe) [aw=ind_empshare], by(year) nq(3)

sort ind1950 year
by ind1950: generate high_pay_70=high_pay[2]

tempfile high_pay_class
keep ind1950 year high_pay high_pay_70
save `high_pay_class'

use "../1_build_database/output/ind_fe_file_full_time", clear

merge m:1 ind1950 year using  `high_pay_class', nogen 

generate in_high_pay=high_pay==3
generate in_high_pay_70=high_pay_70==3

egen ind_emp=rowtotal(male_ind_emp female_ind_emp)


*---------------------------------------------------------------------------------
*Which are these high-pay industries?
*---------------------------------------------------------------------------------
preserve
gcollapse (sum) ind_emp *_ind_emp (mean) ind_fe high_pay high_pay_70, by(ind1950 year)

generate male_share=male_ind_emp/ind_emp


gegen high_male_ind=xtile(male_share) [aw=ind_emp], nq(3) by(year)

tempfile complete
save `complete'

keep ind1950 year high_pay high_male_ind
tempfile high_male_classification
save `high_male_classification'

use `complete', clear
xtset ind1950 year, delta(10)

tw (scatter ind_fe l5.ind_fe, msymbol(o)) (lfit l5.ind_fe l5.ind_fe, lwidth(.5)) ///
	if year==2020, xline(0, lp(dash)) yline(0, lp(dash)) yscale(range(-1 .5)) xscale(range(-1 .5)) ///
	ylabel(-1(.25).5) xlabel(-1(.25).5) legend(order(2 "45º degree line") ring(0) pos(11)) ///
	xtitle("Relative pay in 1970") ytitle("Relative pay in 2020")

graph export "output/figures/ranking_persistence.png", replace


*Classification of industris
cap replace ind1950=. 		if ind1950>=980
cap replace ind1950=. 		if ind1950==0		

g ind_mining_cons=		inrange(ind1950,206,246) 		`employed'
g ind_manufacturing=	inrange(ind1950,306,499) 		`employed'
g ind_pers_services=	inrange(ind1950,826,849) 		`employed'
g ind_prof_services=	inrange(ind1950,868,899) 		`employed'
g ind_ret_services=		inrange(ind1950,606,699) 		`employed'
g ind_oth_services=		inrange(ind1950,506,598) | 	inrange(ind1950,716,817)|	///
	inrange(ind1950,856,859) `employed'
g ind_public_adm=		inrange(ind1950,906,946)  		`employed'
g ind_agriculture=		inrange(ind1950,105,126) 		`employed'

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


gcollapse (mean) ind_mining_cons-ind_agriculture [aw=ind_emp] ///
	, by(high_pay year)

tw connected ind_manufacturing ind_prof_services ind_mining_cons ind_oth_services ///
 	year if high_pay==3&year>1950, lwidth(*2) ///
	 legend(order(1 "Manufacturing" 2 "Professional services" ///
	 3 "Mining and construction" 4 "Trasportation, business and utilities") ring(0) pos(2)) ///
	 ytitle("Employment share within high-pay industries") 

graph export "output/figures/high_pay_by_type.png", replace

local figure_title "Industries and relative pay"
local figure_name "output/figures/industries_ranking.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Relative pay in 2020 vs 1970""High-pay industries by industry-group""'

local figure_list ranking_persistence high_pay_by_type


latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  key(fig:which_pay)


restore

preserve
gcollapse (mean) in_high_pay in_high_pay_70 l_czone_density  ///
	 [aw=ind_emp], by(czone year)

sort czone year 
by czone: generate l_czone_density_50=l_czone_density[1]

eststo clear
drop if year==1950
eststo fixed:		reg in_high_pay_70 i.year#c.l_czone_density i.year if l_czone_density_50>0, vce(cl l_czone_density)
eststo moving: 		reg in_high_pay i.year#c.l_czone_density i.year if l_czone_density_50>0, vce(cl l_czone_density)


coefplot fixed moving,  keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Fixed ranking" 4 "Variable ranking"))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/high_wage_ind_city_coefplot.png", replace

tw (scatter in_high_pay l_czone_density, msize(.8) msymbol(o) legend(off)) ///
	(lfit in_high_pay l_czone_density, legend(off)) if year>1950, ///
	by(year,legend(off)) xtitle("Log of population density") ///
	ytitle("Share of employment in high-wage industries") 
graph export "output/figures/high_wage_ind_city_scatter.png", replace


local figure_title "High wage industries and population density"
local figure_name "output/figures/high_wage_ind_cities.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Scatterplots by year""Density gradient""'

local figure_list high_wage_ind_city_scatter high_wage_ind_city_coefplot

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  ///
	key(fig:ind_cities)

restore

sort czone ind1950  year
by czone ind1950: generate ind_fe_70=ind_fe[2]


egen male_cz_emp=sum(male_ind_emp), by(czone year)
egen female_cz_emp=sum(female_ind_emp), by(czone year)

generate female_in_high_pay=in_high_pay*male_ind_emp/male_cz_emp
generate male_in_high_pay=in_high_pay*female_ind_emp/female_cz_emp

generate female_in_high_pay_70=in_high_pay_70*male_ind_emp/male_cz_emp
generate male_in_high_pay_70=in_high_pay_70*female_ind_emp/female_cz_emp


generate female_in_high_pay_w=female_in_high_pay*ind_fe
generate male_in_high_pay_w=male_in_high_pay*ind_fe

generate female_in_high_pay_70_w=female_in_high_pay_70*ind_fe
generate male_in_high_pay_70_w=male_in_high_pay_70*ind_fe

gcollapse (sum) *male_in_high_pay* (mean)	l_czone_density , by(czone year)

sort czone year 
by czone: generate l_czone_density_50=l_czone_density[1]


drop if year==1950


eststo clear
eststo male: reg male_in_high_pay i.year#c.l_czone_density  i.year if l_czone_density_50>0, ///
	vce(cl czone)
eststo female: reg female_in_high_pay i.year#c.l_czone_density i.year if l_czone_density_50>0, ///
	vce(cl czone)

coefplot male female,  keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Men" 4 "Women") ring(0) pos(2))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/high_pay_gender_gradient.png", replace

eststo male_70: reg male_in_high_pay_70 i.year#c.l_czone_density  i.year if l_czone_density_50>0, ///
	vce(cl czone)
eststo female_70: reg female_in_high_pay_70 i.year#c.l_czone_density i.year if l_czone_density_50>0, ///
	vce(cl czone)



coefplot male_70 female_70,  keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Men" 4 "Women") ring(0) pos(2))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/high_pay_gender_gradient_70.png", replace


local figure_title "High wage industries by gender"
local figure_name "output/figures/high_pay_gender_gradient.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Variable industry ranking""Industry ranking fixed at 1970""'

local figure_list high_pay_gender_gradient high_pay_gender_gradient_70

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  ///
	key(fig:gender_ind_cities)

merge 1:1 czone year using "../1_build_database/output/czone_level_dabase_full_time", nogen


*Suppose I control for the share in high wage industries at the aggregate level. This kills more than half the coeffient in the 1990s
eststo clear

generate high_pay_gap=male_in_high_pay_w-female_in_high_pay_w
generate high_pay_gap_70=male_in_high_pay_70_w-female_in_high_pay_70_w

eststo no_control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year c.high_pay_gap#i.year i.year if year>1950


coefplot no_control control ,  keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "No controls" 4 "+ employment gap" 6 "+ employment share") ring(0) pos(2))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/gender_bas_gap_gradient_high_share.png", replace

eststo no_control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year c.high_pay_gap#i.year  i.year if year>1950

coefplot no_control control ,  keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "No controls" 4 "+ employment gap" 6 "+ employment share") ring(0) pos(2))  ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/gender_hum_gap_gradient_high_share.png", replace

/*


coefplot control, keep(*c.male_in_high_pay*) bylabel(Men) xlabel(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) yscale(range(0 .9)) ylabel(0(.2).9)
graph export "output/figures/high_wage_ind_men.png", replace

coefplot control, keep(*c.female_in_high_pay*) bylabel(Men) xlabel(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) yscale(range(-.9 0)) ylabel(-.9(.2)0)
graph export "output/figures/high_wage_ind_women.png", replace
*The point is more subtle. The key to explaining the gradient is the access to suceesful manufacturing industries.



local figure_title "High wage industries by gender"
local figure_name "output/figures/high_wage_coefficients.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Net-of race/age gender gap and high-wage industry share""Net-of-education gap and high-wage industry share""Men's high-wage industry employment, men""Women's high-wage industry employment""'

local figure_list  gender_bas_gap_gradient_high_share gender_hum_gap_gradient_high_share  high_wage_ind_men high_wage_ind_women

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  ///
	key(fig:high_wage_gradients) rowsize(2)


clear
use "../1_build_database/output/ind_fe_file_full_time", clear

merge m:1 ind1950 year using `high_male_classification'

drop if missing(ind1950)

local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


g ind_mining_cons=		inrange(ind1950,206,246) 		`employed'
g ind_manufacturing=	inrange(ind1950,306,499) 		`employed'
g ind_pers_services=	inrange(ind1950,826,849) 		`employed'
g ind_prof_services=	inrange(ind1950,868,899) 		`employed'
g ind_ret_services=		inrange(ind1950,606,699) 		`employed'
g ind_oth_services=		inrange(ind1950,506,598) | 	inrange(ind1950,716,817)|	///
	inrange(ind1950,856,859) `employed'
g ind_public_adm=		inrange(ind1950,906,946)  		`employed'
g ind_agriculture=		inrange(ind1950,105,126) 		`employed'

preserve
gcollapse (sum) male_ind_emp female_ind_emp, by(czone year ind_manufacturing)

foreach gender in male female {
	egen total_`gender'=sum(`gender'_ind_emp), by(czone year)
	generate `gender'_man_share=`gender'_ind_emp/ total_`gender'
}
keep if ind_manufacturing


merge 1:1 czone year using "../1_build_database/output/czone_level_dabase_full_time", nogen

sort czone year 
by czone: generate l_czone_density_50=l_czone_density[1]



eststo clear
eststo no_control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year c.male_man_share#i.year  c.female_man_share#i.year i.year if year>1950
coefplot no_control control, keep(*density*) bylabel(Men) xlabel(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 

graph export "output/figures/gender_bas_gap_gradient_manufacturing_share.png", replace



eststo clear
eststo no_control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year c.male_man_share#i.year  c.female_man_share#i.year i.year if year>1950
coefplot no_control control, keep(*density*) bylabel(Men) xlabel(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 

graph export "output/figures/gender_hum_gap_gradient_manufacturing_share.png", replace


local figure_title "High wage industries by gender"
local figure_name "output/figures/manufacturing_coefficients.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Net-of race/age gender gap and high-wage industry share""Net-of-education gap and high-wage industry share""'

local figure_list  gender_bas_gap_gradient_manufacturing_share gender_hum_gap_gradient_manufacturing_share 

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title')  dofile(`do_location') tiny  ///
	key(fig:manufacturing_gradients) rowsize(2)
restore

sort ind1950 year
by ind1950: generate high_male_ind_70=high_male_ind[2]
by ind1950: generate high_pay_70=	high_pay[2]

generate in_high_pay=high_pay_70==3

gcollapse (sum) male_ind_emp female_ind_emp , by(czone year in_high_pay)

*Industry gender ratio
generate ind_gender_ratio=male_ind_emp/female_ind_emp
egen industry_size=rowtotal(male_ind_emp female_ind_emp)
egen total_emp=sum(industry_size), by(czone year)

generate high_pay_share=industry_size/total_emp

keep if in_high_pay


merge 1:1 czone year using "../1_build_database/output/czone_level_dabase_full_time", nogen

sort czone year 
by czone: generate l_czone_density_50=l_czone_density[1]

eststo no_control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year c.high_pay_share#i.year c.ind_gender_ratio#i.year i.year if year>1950

coefplot no_control control, keep(*density*) label(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 

/*
foreach gender in male female {
	egen total_`gender'=sum(`gender'_ind_emp), by(czone year)
	generate `gender'_hm_share=`gender'_ind_emp/ total_`gender'
}

egen ind_emp=rowtotal(male_ind_emp female_ind_emp)
egen total_ind_emp=sum(ind_emp), by(czone year)
generate total_hm_share=ind_emp/ total_ind_emp

keep if high_male


merge 1:1 czone year using "../1_build_database/output/czone_level_dabase_full_time", nogen



eststo clear
eststo no_control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_bas_gap i.year c.l_czone_density#i.year c.male_hm_share#i.year c.female_hm_share#i.year i.year if year>1950

coefplot no_control control, keep(*density*) label(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 
graph export "output/figures/gender_hum_gap_gradient_hm_share.png", replace



eststo clear
eststo no_control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year i.year if year>1950
eststo control: 	reg 	wage_hum_gap i.year c.l_czone_density#i.year c.male_hm_share#i.year c.female_hm_share#i.year i.year if year>1950

coefplot no_control control, keep(*density*) label(`year_label')   ///
  yline(0) base   vert legend(off) ///
  lwidth(*2) ciopts(recast(rcap)) recast(connected) ///
  level(90) 

