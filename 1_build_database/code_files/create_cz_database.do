*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates CZ level database
*===============================================================================}

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"

*Working directory
cd "C:\Users\thecs\Dropbox\Boston University\7-Research\LLMM\1_build_database"



*Database type 0=gender 1=race
*Execution parameters
local data_type=	4
local industry 		ind1950
local occupation 	occ1950
local year_list 1950 1970 1980 1990 2000 2010 2020


foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  	"${data}/output/cleaned_census_`year'", clear
		
		*Classification of industris
		do "code_files/classify_industries_occupations.do" `occupation'

		replace year=2010 if year==2009
		
		g	wage_tilde=.

		*If I create a race detabase, then I absorb gender from the wage
		if `data_type'==0 {
			local name		gender
			local collapse_var female
			local absorb_var race
		}
		else if `data_type'==1 {
			local name 		race
			local collapse_var race
			local absorb_var female
		}	
		else if `data_type'==2 {
			g	  educ_level=.
			replace educ_level=1 if education<3
			replace educ_level=2 if inlist(education,3,4)
			
			label define educ_level 1 "Low-education" 2 "High-education"
			label values educ_level educ_level
			
			local name 		by_education
			local collapse_var female 
			local add_var	educ_level
			local absorb_var race
		}
		else if `data_type'==4 {
			*Here I restrict to full time workers
			*I don't want to mess the population figures, I replace the real 
			*hourly wage to missing for people that do not work full time
			local name			full_time
			local absorb_var	race
			local collapse_var	female
			
			*Definition of full-time workers
			g	full_time=wkswork>=40&hrswork>=35
			replace l_hrwage=. if !full_time
		}
		
		
		qui reghdfe 	  l_hrwage if !missing(l_hrwage)  [pw=perwt], ///
			absorb(i.`absorb_var' i.age i.statefip) resid
		predict	  	  temp_var, residuals
		g 	  wage_basic=temp_var if e(sample)
		drop temp_var
		
		qui reghdfe 	  l_hrwage if !missing(l_hrwage)  [pw=perwt], ///
			absorb(i.`absorb_var' i.age i.statefip i.education) resid
		predict	  	  temp_var, residuals
		g 	  wage_educ=temp_var if e(sample)
		drop temp_var
		
		qui reghdfe 	  l_hrwage if !missing(l_hrwage)  [pw=perwt], ///
			absorb(i.`absorb_var' i.age i.statefip i.education i.`industry') resid
		predict	  	  temp_var, residuals
		g 	  wage_ind=temp_var if e(sample)
		drop temp_var
	
		qui reghdfe 	  l_hrwage if !missing(l_hrwage)  [pw=perwt], ///
			absorb(i.`absorb_var' i.age i.statefip i.education i.`occupation' i.`occupation') resid
		predict	  	  temp_var, residuals
		g 	  wage_occ=temp_var if e(sample)
		drop temp_var
		
		g married=			inlist(marst, 1,2)
		g high_education=	inlist(education, 3,4)
		g migrant=bpl>=150 	if !missing(bpl)
		g native_migrant=	bpl!=statefip if bpl<150
		
		g female_migrant=	native_migrant if female
		g male_migrant=		native_migrant if !female
		
		di "Starting collapsing of the database", as result

		preserve
			*I compute the number of observations that I have by gender and czone
			tempfile observations_file
			gcollapse (count) observations=l_hrwage [pw=afact], ///
				by(`collapse_var' `add_var' czone year)
			save 	 `observations_file'
		restore

		preserve
			*In this line of code I compute czone level measures
			tempfile czone_vars
			gcollapse (mean) ind_* occ_* married high_education *migrant ///
				(p90) p90=l_hrwage 	(p50) p50=l_hrwage (p10) p10=l_hrwage ///
				[pw=perwt], by(year czone)
			
			*I compute some measures of inequality here
			g top_tail_ineq=	p90-p50
			g bot_tail_ineq=	p50-p10
			g overall_ineq=		p90-p10
			save `czone_vars'
		restore
		
		gcollapse (count) population=age (mean) in_labforce (mean) ///
			wage_* l_hrwage [pw=perwt], ///
			by(`collapse_var' `add_var' czone year)
		
		merge m:1 czone using `czone_vars', nogen	

		merge m:1 czone year `collapse_var' `add_var'  using  `observations_file', nogen
		
		foreach variable of varlist occ* ind* {
			replace `variable'=0 if missing(`variable')
		}
		
		tempfile collapsed`year'
		save `collapsed`year''
	}
}

clear
foreach year in  `year_list' {
	append using `collapsed`year''
}


merge m:1 	czone using "../1_build_database/output/czone_area", nogen
egen 	   	czone_pop=sum(population), by(czone year)

g			l_czone_density=log(czone_pop)-log(cz_area)
label var 	l_czone_density "ln(czone density)"

sort czone year
g 			t_population50=czone_pop if year==1950
egen 		czone_pop_50=max(t_population50), by(czone)
g			l_czone_pop=log(czone_pop)

drop population

reshape wide wage_* in_labforce observations  l_hrwage , i(czone year `add_var') j(`collapse_var')

if inlist(`data_type',0,2,3,4) {
	g 		reg_weight= 			1/ (1/observations0 + 1/observations1)
	g		wage_raw_gap=			l_hrwage0-l_hrwage1
	g 		labforce_gap=			in_labforce1/in_labforce0
	
	foreach type in basic educ ind occ {
		g	 wage_`type'_gap=		wage_`type'0-wage_`type'1
	}
}
else if `data_type'==1 {
	g	 wage_basic_gap=			wage_tilde1-wage_tilde2
	label var wage_gap "log(white wage)-log(black wage) (residualized)"
	g	 labforce_gap=		in_labforce1/in_labforce2

	g	 wage_raw_gap=			l_hrwage1-l_hrwage2
	label var wage_gap "log(white wage)-log(black wage) (raw)"
}	

cap drop wage_tilde*

order occ* ind*, after(year)

replace year=2020 if year==2018
replace year=2010 if year==2011
drop t_population50
save "output/czone_level_dabase_`name'", replace
