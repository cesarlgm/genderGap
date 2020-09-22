*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: 	decomposes changes in the gender gap into within / 
*					between sep_var components
*===============================================================================


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

*Completing the panel
fillin czone female `sep_var' year
rename _fillin added_observation

foreach variable in l_hrwage empshare {
	replace `variable'=0 if missing(`variable')
}



replace year=2020 if year==2018
replace year=2010 if year==2009

sort czone female `sep_var' year
egen period=group(year)

egen panelid=group(czone female `sep_var')
xtset panelid period

g delta_share	=d.empshare
g delta_wage	=d.l_hrwage
g l_share=	  .5*(l.empshare+empshare)
g l_wage=	  .5*(l.l_hrwage+l_hrwage)

g w_comp=	 l_share*delta_wage
g b_comp=	 l_wage*delta_share
g total_wage =	 empshare*l_hrwage

save "temporary_files/gender_level_dataset_`sep_var'", replace

*===============================================================================
*BETWEEN/WITHIN DECOMPOSITION
*===============================================================================

gcollapse (sum) w_comp b_comp total_wage, by(czone year female period) 

reshape wide w_comp b_comp total_wage, i(czone year) j(female)

xtset czone period
g	raw_gap=total_wage0-total_wage1
g 	d_raw_gap=d.raw_gap
g	w_comp=w_comp0-w_comp1
g	b_comp=b_comp0-b_comp1


merge 1:1 czone year using "../1_build_database/output/czone_level_dabase", keep(3) nogen

drop raw_wage_gap wage_tilde* wage_gap

sort czone period
g 	gap_w=l.raw_gap+w_comp
g	gap_b=l.raw_gap+b_comp
replace gap_w=raw_gap if year==`first_year'
replace gap_b=raw_gap if year==`first_year'
g	l_raw_gap=l.raw_gap
replace l_raw_gap=raw_gap if period==1

drop period
save "output/decomposition_exercise_`sep_var'", replace

grscheme, ncolor(7) style(tableau)
use "output/decomposition_exercise_`sep_var'", clear

gettoken first_year year_list: year_list
eststo clear

*Here I standardize the c-zone density
g 	l_czone_density_sd=.

foreach year in `year_list' {
	local filter if year==`year'&czone_pop_50/cz_area>1
	local fit linetype(lfit)
	local scatter_options nq(35) xtitle("log(czone density) -base 10-")
	
	summ l_czone_density `filter'
	replace l_czone_density_sd=l_czone_density/`r(sd)' `filter'
	
	qui eststo change`year': 	reg d_raw_gap l_czone_density_sd `filter',vce(r)
	qui eststo within`year': 	reg b_comp l_czone_density_sd `filter',vce(r)
	qui eststo between`year': 	reg w_comp l_czone_density_sd `filter',vce(r)

	
	/*binscatter raw_gap gap_w gap_b l_raw_gap l_czone_density  `filter', `scatter_options' ///
		ytitle("log(male wage)-log(female wage)") yscale(range(0 .5)) ylabel(0(.1).5) `fit' ///
		legend(order(1 "Final gap" 2 "Within `sep_var'" 3 "Between `sep_var'" 4 "Initial gap"))
	graph export "output/figures/decomposition_gap`year'_`sep_var'.png", replace
	*/
}

if "`sep_var'"=="occ1990_agg" {
	local name "occupation"
}
else if "`sep_var'"=="ind1950_OD" {
	local name "industry"
}

local ncols: word count of `year_list'
local --ncols

local table_name "output/tables/decomposition_regressions_`sep_var'.tex"
local table_title "Between/within `name' decomposition exercise"
local table_note "robust standard errors in parenthesis. The first column shows the change 1950-1970 change. The rest of the columns show decadal changes. I limit to cz with more than `cz_filter' people per sqkm. Coefficients are interpreted as the change in the gender wage gap for a 1 sd change in the log CZ population density"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain b(%9.3fc) se(%9.3fc)  par  noobs drop(_cons) star

textablehead using `table_name', ncols(`ncols') coltitles(`year_list') ///
	title(`table_title')

esttab change* using `table_name', `table_options' coef(l_czone_density_sd "Total change")
esttab between* using `table_name', `table_options' coef(l_czone_density_sd "Between change")
esttab within* using `table_name', `table_options' coef(l_czone_density_sd "Within change")

textablefoot using `table_name', notes(`table_note') dofile(`do_location')

*/
*===============================================================================
*DIFFERENCE IN DISTRIBUTIONS
*===============================================================================
use "temporary_files/gender_level_dataset_`sep_var'", clear
keep year `sep_var' female czone empshare
reshape wide empshare, i(czone `sep_var' year) j(female)
fillin czone `sep_var' year

g	empshare_gap=abs(empshare0-empshare1)
collapse (mean) empshare_gap, by(year czone)

sort czone year
egen period=group(year)

xtset czone period


merge 1:1 czone year using "../1_build_database/output/czone_level_dabase", keep(3) nogen

local filter if czone_pop_50/cz_area>1&year>1950

eststo clear
eststo diff_dist: reg empshare_gap i.year c.l_czone_density#i.year `filter', vce(r)


coefplot diff_dist, vert drop(_cons *year) yline(0) base ///
	xlabel( 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020") ///
	legend(off) ///
	ytitle("log(Wm/Wf) gradient ({&beta}{sub:t})") ///
	ciopt(recast(rcap)) ytick(-.015(.005)-.006, tlcolor(gs0) grid)
	
	
graph export "output/figures/cz_distribution_diff_`sep_var'.pdf", replace

*===============================================================================
*OUTPUTTING THE GRAPH
*===============================================================================
local figure_title "Distance between male-female employment distributions"
local figure_name "output/figures/cz_diff_empshare.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Occupational employment""Industrial employment""'

local figure_list  cz_distribution_diff_ind1950_OD cz_distribution_diff_occ1990_agg  

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
	note(`figure_note') figlab(`figure_labs') ///
	title(`figure_title') nodate  dofile(`do_location') rowsize(2) 




/*
g l_czone_density_sd=.

sort czone period
foreach year in `year_list' {
	local filter if year==`year'&czone_pop_50/cz_area>1
	local fit linetype(lfit)
	local scatter_options nq(35) xtitle("employment distribution difference -base 10-")
	
	summ l_czone_density `filter'
	replace l_czone_density_sd=l_czone_density/`r(sd)' `filter'

	cap eststo level`year': 	reg empshare_gap l_czone_density `filter',vce(r)
	if `year'==1950 {
		eststo diff`year': 		reg empshare_gap `filter',vce(r)
	}
	else {
		eststo diff`year': 		reg d.empshare_gap l_czone_density `filter',vce(r)
	}
}

if "`sep_var'"=="occ1990_agg" {
	local name "occupational"
}
else if "`sep_var'"=="ind1950_OD" {
	local name "industrial"
}

local ncols: word count of `year_list'
local --ncols

local table_name "output/tables/employment_distribution_difference_`sep_var'.tex"
local table_title "Male-female average gap in  `name' employment distribution"
local table_note "robust standard errors in parenthesis. The dependent variable is defined as $1/J \sum | empshare_{male}- empshare_{female}| $, where $ J $ denotes either the number of occupations or industries. I limit to cz with more than `cz_filter' people per sqkm"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain b(%9.3fc) se(%9.3fc)  par  noobs drop(_cons) star

textablehead using `table_name', ncols(`ncols') coltitles(`year_list') ///
	title(`table_title')

esttab level* using `table_name', `table_options' coef(l_czone_density "Levels")
esttab diff* using `table_name', `table_options' coef(l_czone_density "Differences")

textablefoot using `table_name', notes(`table_note') dofile(`do_location')
