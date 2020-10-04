gettoken 	indep_var 		0: 0
local year_list `0'
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"
local errors vce(cl czone)


foreach year in `year_list' {
    local census_name "${data}/cleaned_census_`year'"
    use `census_name', clear


    *Fixing the census years if needed
    replace year=2010 if year==2011
    replace year=2020 if year==2018

    generate full_time=		    wkswork>=40&hrswork>=35
    generate married=           inlist(marst,1,2)
    generate single=            inrange(marst,3,6)
    generate college=           inlist(education,3,4)
    generate no_college=        inlist(education,1,2)
    generate no_children=       nchild==0
    generate male=!female

    merge m:1 czone year using `czone_chars_file', nogen ///
        keepusing(l_czone_density czone_pop cz_area czone_pop_50 ) keep(3)
    
    drop if czone_pop_50/cz_area<=1  
    
    generate l_czone_pop=		log(czone_pop)
    
    
    qui {     
        eststo model_`year'_all: reghdfe 	l_hrwage c.`indep_var' i.male#c.`indep_var'    ///
            [pw=perwt] ,  absorb(i.year i.age i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_all",           replace
    
        eststo model_`year'_ft: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var'    ///
           [pw=perwt] if full_time, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_ft",            replace
        
        eststo model_`year'_married: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if full_time&married, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_ft_married",    replace

        eststo model_`year'_single: reghdfe 	l_hrwage  c.`indep_var' i.female#c.`indep_var' ///
           [pw=perwt] if full_time&single, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_ft_single",     replace

        eststo model_`year'_single: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var' ///
            [pw=perwt] if full_time&college, absorb(i.year i.age  i.male i.race ) `errors'
        estimates save "output/regressions/model_`year'_ft_college",    replace

        eststo model_`year'_single: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if full_time&no_college, absorb(i.year i.age  i.male i.race ) `errors'
        estimates save "output/regressions/model_`year'_ft_no_college", replace

        eststo model_`year'_child: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if full_time& nchild==0, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_ft_child",      replace

        eststo model_`year'_no_child: reghdfe 	l_hrwage  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if full_time& !nchild==0, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_ft_no_child",   replace
	
        eststo model_`year'_lf: reghdfe 	in_labforce  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] , absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_lf",            replace
        
        eststo model_`year'_lf: reghdfe 	in_labforce  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if married, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_lf_married",    replace

        eststo model_`year'_lf: reghdfe 	in_labforce  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if single , absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_lf_single",     replace
        
        eststo model_`year'_lf: reghdfe 	in_labforce  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if nchild==0, absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_lf_no_ch",      replace

        eststo model_`year'_lf: reghdfe 	in_labforce  c.`indep_var' i.male#c.`indep_var' ///
           [pw=perwt] if nchild!=0 , absorb(i.year i.age  i.male i.race i.education) `errors'
        estimates save "output/regressions/model_`year'_lf_ch",         replace
        
    }
}

eststo clear
foreach year in `year_list' {
    local model_list  model_`year'_all model_`year'_ft model_`year'_ft_married  ///
		model_`year'_ft_single model_`year'_ft_college model_`year'_ft_no_college ///
		model_`year'_ft_child model_`year'_ft_no_child model_`year'_lf ///
		model_`year'_lf_single model_`year'_lf_married model_`year'_lf_no_ch model_`year'_lf_ch
		
		
    foreach model in `model_list' {
        di "`model'"
        estimates use "output/regressions/`model'"
        matrix define est_b=J(1,2,.)
        matrix define est_se=J(1,2,.)
        matrix colnames est_b = women men
        matrix colnames est_se = women men
        
        matrix est_b[1,1]=_b[1.male#c.l_czone_density]
        matrix est_se[1]=_se[1.male#c.l_czone_density]

        *Here I compute the coefficient for men in the model
        lincom `indep_var'+1.male#c.`indep_var'
        matrix est_b[1,2]=r(estimate)
        matrix est_se[1]= r(se)
      
        estadd matrix b_sex=est_b
        estadd matrix se_sex=est_b

        estimates store `model'
    }
}



