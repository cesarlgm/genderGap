*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: 	creates graphs fixing the wage gap at the 1950 level and see
*					how much bite do I get from just the sectoral reallocation of
*					employment
*===============================================================================


local base_year 70

gettoken sep_var 0: 0
local year_list `0'

local cz_filter 1

gettoken first_year: year_list

local do_location "2\_analysis/code\_files/decomposition\_exercise.do"

local census_location "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data\output"

/*
qui {
	*This computes the overall gender gap
	foreach year in `year_list' {
		use hrwage czone year l_hrwage female education ind1950 occ1990 empstat perwt using "`census_location'\cleaned_census_`year'", clear
		
		*Step 1: create aggregated sep_var indicators.
		do "../1_build_database/code_files/classify_industries_occupations.do"
		
		
		*This indicators use only observations with positive wage and non-missing sep_var
		g	industry_type=.
		replace	industry_type=2 if 	ind_manufacturing
		replace	industry_type=3 if 	ind_services
		replace	industry_type=1 if  !(ind_manufacturing|ind_services)&!missing(ind1950)

		label define industry_type 1 "Agriculture and Construction" 2 "Manufacturing" 3 "Services"
		label values industry_type industry_type
		
		g	ind1950_OD=floor(ind1950/100) if !missing(ind1950)
		
		preserve
		*Step 2: create aggreate sep_var employment shares
			gcollapse (count) people=l_hrwage [pw=perwt] if !missing(`sep_var'), by(czone year female `sep_var')
			egen total_people=sum(people), by(czone year female)
			g empshare=people/total_people
			
			tempfile empshare`year'
			save 	 `empshare`year''
		restore
		
		gcollapse (mean) l_hrwage if !missing(`sep_var'), by(year `sep_var' female czone)
		
		merge 1:1 czone year female `sep_var' using  `empshare`year'', nogen
		
		drop people total_people
		
		tempfile final_file`year'
		save `final_file`year''		
	}
}

clear 
foreach year in `year_list' {
	append using `final_file`year''
}

save "temporary_files/appended_fixed_gap_database_`sep_var'", replace
*/

use "temporary_files/appended_fixed_gap_database_`sep_var'", clear
*Completing the panel
fillin czone female `sep_var' year
rename _fillin added_observation

foreach variable in l_hrwage empshare {
	replace `variable'=0 if missing(`variable')
}


replace year=2020 if year==2018
replace year=2010 if year==2011

sort 	czone female `sep_var' year
egen 	period=group(year)

egen 	panelid=group(czone female `sep_var')
xtset 	panelid period

*I opted to change the code into a between within decomposition
sort panelid period
g	 within=	0.5*(l.empshare+empshare)*d.l_hrwage
g	 between=	0.5*(l.l_hrwage+l_hrwage)*d.empshare
g    total=		empshare*l_hrwage
g	 d_total=	d.total

gcollapse (sum) within between total d_total, by(czone female year period)

egen panelid=group(czone female)
fillin panelid period
drop _fillin

xtset panelid period
g	coun_between=	l.total+between
g	coun_within=	l.total+within
g	actual=			l.total+d_total

drop total d_total panelid
reshape wide actual coun_* between within, i(czone period) j(female)


g	actual_gap=				actual0-actual1
g	coun_between=			coun_between0-coun_between1
g	coun_within=			coun_within0-coun_within1

foreach variable in coun_between coun_within {
	 replace `variable'=actual_gap if year==1970
}

merge 1:1 		czone year using "../1_build_database/output/czone_level_dabase", keep(3) nogen

local filter if czone_pop_50/cz_area>1&year
	
xtset czone period
sort czone period

eststo clear

eststo actual: 				reg actual_gap i.year 		c.l_czone_density#i.year `filter', vce(r)
eststo between: 			reg coun_between i.year 	c.l_czone_density#i.year `filter', vce(r)
eststo within: 				reg coun_within i.year 		c.l_czone_density#i.year `filter', vce(r)


grscheme, ncolor(4) style(tableau)

local year_labs 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"
coefplot actual between within , vert drop(_cons *year) yline(0) base ///
	xlabel(`year_labs') ///
	legend(order(2 "Actual" 4 "Between" 6 "Within")) ///
	ytitle("log(Wm/Wf)- log(CZ pop-density) gradient") ///
	ciopt(recast(rcap)) ytick(-.03(.01).06, tlcolor(gs0) grid)

graph export "output/figures/cz_`sep_var'_ratio_gradient.pdf", replace

/*
local figure_title "Gender gaps are fixed at 1970-levels"
local figure_name "output/figures/cz_counterfactual_gaps.tex"
local figure_note "figure restricts to CZ with more than 1 people per km$^2$."
local figure_path "../2_analysis/output/figures"

local figure_labs `""Within-industry""Within-occupation""'
local figure_list cz_ind1950_OD_ratio_gradient cz_occ1990_agg_ratio_gradient

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs' `figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize(2)



*This bit creates the per-year graphs but they are not that useful. The 
*regression coefficients look much better
/*
local year_list  1950 1970 1980 1990 2000 2010 2020
foreach year in `year_list' {
	local filter if year==`year'&czone_pop_50/cz_area>1
	local fit linetype(lfit)
	local scatter_options nq(35) xtitle("log(czone density) -base 10-")  ///
		absorb(year) yscale(range(-.2 .2)) ylabels(-.2(.05).2)

	cap drop yvar50
	cap drop yvar
	
	qui reg raw_gap `filter'
	qui predict yvar `filter', residuals
	
	qui reg raw_gap50 `filter'
	qui predict yvar50 `filter', residuals
	
	
	binscatter  yvar yvar50 l_czone_density  `filter', `scatter_options' ///
		ytitle("log(male wage)-log(female wage)") `fit' ///
		legend(order(1 "Actual gap" 2 "Fixed gap shares"))
	graph export "output/figures/fixed_gap`year'_`sep_var'.png", replace
	
	cap drop yvar50
	cap drop yvar
	
	qui reg raw_gap `filter'
	qui predict yvar `filter', residuals
	
	qui reg raw_gap_share50 `filter'
	qui predict yvar50 `filter', residuals
	
	binscatter  yvar yvar50 l_czone_density  `filter', `scatter_options' ///
		ytitle("log(male wage)-log(female wage)") `fit' ///
		legend(order(1 "Actual gap" 2 "Fixed shares"))
	graph export "output/figures/fixed_share`year'_`sep_var'.png", replace
}


