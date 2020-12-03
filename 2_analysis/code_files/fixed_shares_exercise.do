
use "../1_build_database/output/fixed_ind_shares_database_full_time", clear

sort czone year ind1950


drop total*

fillin czone  ind1950 year

foreach variable in l_hrwage0 l_hrwage1 empshare0 empshare1 {
    replace `variable'=0 if missing(`variable')
    by czone ind1950: generate `variable'_1970=`variable'[1]
}



generate male_actual=empshare0*l_hrwage0
generate female_actual=empshare1*l_hrwage1

generate male_fixed=empshare0_1970*l_hrwage0
generate female_fixed=empshare1_1970*l_hrwage1


generate actual_gap=empshare0*l_hrwage0-empshare1*l_hrwage1
generate fixed_share_gap=   empshare0_1970*l_hrwage0-empshare1_1970*l_hrwage1

gcollapse (sum) actual_gap fixed_share_gap male* female*, by(czone year)

tempfile tomerge
save `tomerge'

use  "../1_build_database/output/czone_level_dabase_full_time"

grscheme, ncolor(7) style(tableau)

sort czone year 
by czone: generate l_czone_density_50=l_czone_density[1]


merge 1:1 czone year using `tomerge', nogen 
by czone: generate actual_gap_70=actual_gap[2]




eststo male_actual:             regress male_actual      i.year#c.l_czone_density i.year     if l_czone_density_50>0

preserve
tempfile male_actual
regsave
keep var coef
rename coef male_actual 
save  `male_actual'
restore

eststo female_actual:           regress female_actual i.year#c.l_czone_density i.year     if l_czone_density_50>0
preserve
tempfile female_actual
regsave 
keep var coef
rename coef female_actual 
save `female_actual'
restore


eststo male_fixed:             regress male_fixed      i.year#c.l_czone_density i.year     if l_czone_density_50>0
preserve
tempfile male_fixed
regsave 
keep var coef
rename coef male_fixed 
save `male_fixed'
restore


eststo female_fixed:           regress female_fixed i.year#c.l_czone_density i.year     if l_czone_density_50>0
preserve
tempfile female_fixed
regsave 
keep var coef
rename coef female_fixed 
save `female_fixed'
restore

clear 
use `male_actual', clear
merge 1:1 var using `male_actual', nogen 
merge 1:1 var using `female_actual', nogen 
merge 1:1 var using `male_fixed', nogen 
merge 1:1 var using `female_fixed', nogen 

keep if regexm(var, "density")
sort var
generate year=1970+(_n-1)*10
drop var
order year, first

generate d_male_shares=male_actual-male_fixed
generate d_female_share=female_actual-female_fixed

generate d_male_wage=male_fixed-male_actual[1]
generate d_female_wage=female_fixed-female_actual[1]

/*
local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


coefplot female_actual female_fixed , keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Actual evolution" 4 "Fixed shares" 6 "") ring(0) pos(2))  ///
  lwidth(*2) noci recast(connected) level(90) 
graph export "output/figures/fixed_shares_exercise.png", replace
/*

coefplot fixed fixed_wage, keep(*l_czone_density*) vert yline(0) base   ///
  xlabel(`year_label')  legend(order(2 "Fixed industry shares" 4 "Fixed industry wages") ring(0) pos(2))  ///
  lwidth(*2) ciopts(recast(rline) lp( dash)) recast(connected) ///
  level(90) 
graph export "output/figures/fixed_shares_exercise_wage.png", replace


*UNWEIGHTED GRAPH
local figure_title "Coefficient on population density $ \beta_t $"
local figure_name "output/figures/fixed_shares_gradient.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. Bars show 90\% confidence intervals. Standard errors clustered at the CZ level."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Fixed employment shares""Fixed employment shares vs fixed wages""'
local figure_list fixed_shares_exercise fixed_shares_exercise_wage

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') rowsize(2) ///
    title(`figure_title')  dofile(`do_location') tiny key(figure:fixed_shares)


