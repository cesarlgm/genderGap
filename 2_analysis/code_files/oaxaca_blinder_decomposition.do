*OAXACA-BLINDER DECOMPOSITION
*--------------------------------------------------------------------------------------------
*This do file performs a Oaxaca-Blinder decompostion. 

local year_list `0'
global data "../../NSAM/1_build_data/output"
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"

set matsize 11000

foreach year in `year_list' {
    di "Processing `year' census", as result
    qui {
    local census_name "${data}/cleaned_census_`year'"

    use `census_name', clear
    merge m:1 czone year using `czone_chars_file', nogen  ///
        keepusing(l_czone_density czone_pop cz_area czone_pop_50) keep(3)
    
    *Fixing the census years if needed
    replace year=2010 if year==2011
    replace year=2020 if year==2018

    generate foreign_born=      bpl>=150
    generate age_sq=            age*age
    
    egen    grouped_race=       cut(race), at(1,2,3,9)
    label   define  grouped_race 1 "White" 2 "Black" 3 "Other"
    label   values grouped_race grouped_race
 
    generate full_time=		    wkswork>=40&hrswork>=35
    generate married=           inlist(marst,1,2)
    generate single=            inrange(marst,3,6)
    generate college=           inlist(education,3,4)
    generate no_college=        inlist(education,1,2)
    generate no_children=       nchild==0


    *Off-the-shelf Oaxaca command takes too long. Manual decomposition below
    local human_capital_vars age age_sq i.education i.grouped_race i.foreign_born
    local filter if czone_pop_50/cz_area>1&full_time


    *Human capital specification
    *-----------------------------------------------------------------------------------------
    preserve
        qui eststo male_regression: reg l_hrwage `human_capital_vars' `filter'& !female [pw=perwt]

        generate male_sample=e(sample)

        predict  w_m if male_sample, xb

        qui eststo female_regression: reg l_hrwage `human_capital_vars' `filter'& female [pw=perwt]
        
        generate female_sample=e(sample)

        predict  w_f if female_sample, xb

        estimates restore male_regression
        predict  w_fm if female_sample, xb

        gcollapse (mean) w_m w_f w_fm  [pw=perwt], by(year)

        generate explained=     w_m-w_fm
        generate unexplained=   w_fm-w_f
        generate total_gap=     w_m-w_f
        generate specification= "human_capital"

        tempfile `year'_human
        save ``year'_human'
    restore 
    
    *Adding location variables
    *-----------------------------------------------------------------------------------------
    preserve
        eststo clear
        qui eststo male_regression: reg l_hrwage `human_capital_vars' i.czone `filter'& !female [pw=perwt]

        generate male_sample=e(sample)

        predict  w_m if male_sample, xb

        qui eststo female_regression: reg l_hrwage `human_capital_vars' i.czone `filter'& female [pw=perwt]
        
        generate female_sample=e(sample)

        predict  w_f if female_sample, xb

        estimates restore male_regression
        predict  w_fm if female_sample, xb

        gcollapse (mean) w_m w_f w_fm [pw=perwt], by(year)

        generate explained=     w_m-w_fm
        generate unexplained=   w_fm-w_f
        generate total_gap=     w_m-w_f
        generate specification= "location"
        tempfile `year'_location
        save ``year'_location'
    restore

    *Adding industry variables
    *-----------------------------------------------------------------------------------------
    preserve
        eststo clear
        qui eststo male_regression: reg l_hrwage `human_capital_vars' i.czone i.ind1950 ///
            i.occ1950  `filter'& !female [pw=perwt]

        generate male_sample=e(sample)

        predict  w_m if male_sample, xb

        qui eststo female_regression: reg l_hrwage `human_capital_vars' i.czone i.ind1950 ///
            i.occ1950  `filter'& female [pw=perwt]
        
        generate female_sample=e(sample)

        predict  w_f if female_sample, xb

        estimates restore male_regression
        predict  w_fm if female_sample, xb

        gcollapse (mean) w_m w_f w_fm [pw=perwt], by(year)

        generate explained=     w_m-w_fm
        generate unexplained=   w_fm-w_f
        generate total_gap=     w_m-w_f
        generate specification= "industry and occupation"
        tempfile `year'_industry
        save ``year'_industry'
    restore

    *Adding marital status and number of children
    *-----------------------------------------------------------------------------------------
    preserve
        eststo clear
        qui eststo male_regression: reg l_hrwage `human_capital_vars' i.czone i.ind1950 ///
            i.occ1950  i.married i.nchild `filter'& !female [pw=perwt]

        generate male_sample=e(sample)

        predict  w_m if male_sample, xb

        qui eststo female_regression: reg l_hrwage `human_capital_vars' i.czone i.ind1950 ///
            i.occ1950  `filter'& female [pw=perwt]
        
        generate female_sample=e(sample)

        predict  w_f if female_sample, xb

        estimates restore male_regression
        predict  w_fm if female_sample, xb
      

        gcollapse (mean) w_m w_f w_fm [pw=perwt], by(year)

        generate explained=     w_m-w_fm
        generate unexplained=   w_fm-w_f
        generate total_gap=     w_m-w_f
        generate specification= "family variables"
        tempfile `year'_family
        save ``year'_family'
    restore

    clear
    use ``year'_human'
    append using ``year'_location'
    append using ``year'_industry'
    append using ``year'_family'
    
    tempfile `year'_file
    save ``year'_file'
    }
    
}

di "Appending datasets", as result

clear
foreach year in `year_list' {
    append using ``year'_file'
}

save "output/dta/oaxaca_decomposition", replace