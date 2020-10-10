*OAXACA BLINDER DECOMPOSITION

local year_list `0'
global data "../../NSAM/1_build_data/output"
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"


foreach year in `year_list' {
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
    local human_capital_vars i.age i.education i.race i.foreign_born ibn.czone
    local filter if czone_pop_50/cz_area>1&full_time

    eststo male_regression: reg l_hrwage `human_capital_vars' `filter'& !female [pw=perwt], ///
        nocons

    generate male_sample=e(sample)

    predict  w_m if male_sample, xb

    eststo female_regression: reg l_hrwage `human_capital_vars' `filter'& female [pw=perwt], ///
        nocons
    
    generate female_sample=e(sample)

    predict  w_f if female_sample, xb

    estimates restore male_regression
    predict  w_fm if female_sample, xb

    reg l_hrwage i.female [pw=perwt] if male_sample|female_sample

    gcollapse (mean) w_m w_f w_fm [pw=perwt], by(year)

    generate explained=     w_m-w_fm
    generate unexplained=   w_fm-w_f


    gcollapse (mean) w_m w_f w_fm
    
}


