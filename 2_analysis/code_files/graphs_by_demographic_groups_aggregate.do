local year_list `0'


foreach year in `year_list' {
   di "Processing census `year'", as result
      qui {
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

        reghdfe no_children [pw=perwt] , vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ sh_nch_fe
        cap drop *hdfe*

        reghdfe no_children [pw=perwt] if full_time , vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_sh_nch_fe
        cap drop *hdfe*
       
        *###############################################################################################
        *HOURLY WAGE FOR FULL TIME WORKERS
        *###############################################################################################
        *Full time workers    
        reghdfe l_hrwage [pw=perwt] if full_time , vce(cl czone) absorb(i.female#i.czone i.age) savefe

        rename __hdfe1__ ft_fe
        cap drop *hdfe*
        
        *Full time without children
        reghdfe l_hrwage [pw=perwt] if full_time & nchild==0, vce(cl czone) absorb(i.female#i.czone) savefe    
        rename __hdfe1__ ft_no_child_fe
        cap drop *hdfe*

        *Full time workers with children
        reghdfe l_hrwage [pw=perwt] if full_time & nchild!=0, vce(cl czone) absorb(i.female#i.czone) savefe
        rename __hdfe1__ ft_child_fe
        cap drop *hdfe*
        
        *Full time married workers
        reghdfe l_hrwage [pw=perwt] if full_time & married, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_married_fe
        cap drop *hdfe*

        *Full time married single workers
        reghdfe l_hrwage [pw=perwt] if !full_time & single, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_no_married_fe
        cap drop *hdfe*
        
        *Full time white workers
        reghdfe l_hrwage [pw=perwt] if full_time & race==1, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_white_fe
        cap drop *hdfe*

        *Full time black workers
        reghdfe l_hrwage [pw=perwt] if full_time & race==2, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_black_fe
        cap drop *hdfe*

        *Full time no college
        reghdfe l_hrwage [pw=perwt] if full_time & no_college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_no_college_fe
        cap drop *hdfe*

        *Full time with college
        reghdfe l_hrwage [pw=perwt] if  full_time & college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ ft_college_fe
        cap drop *hdfe*

        *###############################################################################################
        *HOURLY WAGE FOR PART TIME WORKERS
        *###############################################################################################
        *Part time workers
        reghdfe l_hrwage [pw=perwt] if !full_time , vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ pt_fe
        cap drop *hdfe*

        *Part time without children
        reghdfe l_hrwage [pw=perwt] if !full_time & nchild==0, vce(cl czone) absorb(i.female#i.czone) savefe
        rename __hdfe1__ pt_no_child_fe
        cap drop *hdfe*
        
        *Part time workers with children
        reghdfe l_hrwage [pw=perwt] if !full_time & nchild!=0, vce(cl czone) absorb(i.female#i.czone) savefe
        rename __hdfe1__ pt_child_fe
        cap drop *hdfe*
        
        *###############################################################################################
        *LABOR FORCE PARTICIPATION
        *###############################################################################################
        reghdfe in_labforce [pw=perwt], vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if single, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_single_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if married, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_married_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if married&college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_c_m_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if single&college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_c_s_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if married&no_college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_no_c_m_fe
        cap drop *hdfe*

        reghdfe in_labforce [pw=perwt] if single&no_college, vce(cl czone) absorb(i.female#i.czone i.age) savefe
        rename __hdfe1__ lf_no_c_s_fe
        cap drop *hdfe*
        
        *###############################################################################################
        *CREATING OBSERVATION COUNTS
        *###############################################################################################

        local count_list
        foreach variable of varlist *fe {
            local count_list `count_list' count_`variable'=`variable'
        }
        
        ds *fe
        local var_list `r(varlist)'

        di "`count_list'"

        collapse (mean) *fe (count)  `count_list' , by(czone year female) fast


        reshape wide *fe , i(czone year) j(female)
        
        tempfile `year'_file
        save ``year'_file'
    }
}


di "Censuses have been processed. Appending the datasets", as result

*#####################################
*Appending the datasets
clear
foreach year in `year_list'{
    append using ``year'_file'
}

foreach variable in `var_list' {
    if !inlist("`variable'","year","female","czone") {
        generate `variable'_gap=`variable'0-`variable'1
    }
}



