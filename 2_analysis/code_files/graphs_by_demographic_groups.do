gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
gettoken    reg_type        0: 0
local 		year_list `0'

*Location of census files
global data "../../NSAM/1_build_data/output"
local 	czone_chars_file "../1_build_database/output/czone_level_dabase_full_time"



grscheme, ncolor(7) style(tableau)

* Execution parameters
*Variables to extract from the census
local 		do_file "code_files/by_census_residualization"
clear 

if "`reg_type'"=="aggregate" {
    do "code_files/graphs_by_demographic_groups_aggregate.do" `year_list'

    *Add czone characteristcs
    merge 1:1 czone year using `czone_chars_file', nogen ///
        keepusing(l_czone_density czone_pop cz_area czone_pop_50 ) keep(3)
    
    generate l_czone_pop=		log(czone_pop)

    *Regressions at czone level
    eststo clear
    local indep_var l_czone_density
    foreach variable of varlist *fe* {
       qui eststo `variable'  : regress `variable' i.year i.year#c.`indep_var' if czone_pop_50/cz_area>1, ///
            vce(cl czone)   
    }

    local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"

    local coefplot_options vert yline(0)  keep(*`indep_var'*) base  ciopt(recast(rcap))  ///
        xlabel(`year_label') ytitle("Coefficient on population density")
    coefplot ft_fe_gap ft_no_child_fe_gap ft_child_fe_gap, `coefplot_options' ///
        legend(order(2 "All" 4 "No children" 6 "Children") 	ring(0) pos(2))
    graph export "output/figures/ft_children.png", replace

    coefplot ft_fe_gap ft_married_fe_gap ft_no_married_fe_gap, `coefplot_options' ///
        legend(order(2 "All" 4 "Married" 6 "Single") 	ring(0) pos(2))
    graph export "output/figures/ft_married.png", replace

    coefplot ft_fe_gap ft_college_fe_gap ft_no_college_fe_gap, `coefplot_options' ///
        legend(order(2 "All" 4 "College" 6 "No college") 	ring(0) pos(2))
    graph export "output/figures/ft_college.png", replace
     
    local coefplot_options `coefplot_options' yscale(range(0 .10))
    coefplot ft_fe0 ft_fe1,  `coefplot_options'  ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/ft_men_women.png", replace
    
    coefplot ft_child_fe0 ft_child_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/ft_men_women_child.png", replace

    coefplot ft_no_child_fe0 ft_no_child_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/ft_men_women_no_child.png", replace
    
    coefplot ft_college_fe0 ft_college_fe1,  `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/ft_men_women_college.png", replace

    coefplot ft_no_college_fe0 ft_no_college_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/ft_men_women_no_college.png", replace

    local coefplot_options vert yline(0)  keep(*`indep_var'*) base  ciopt(recast(rcap))  ///
        ytitle("Coefficient on population density")  xlabel(`year_label')
    coefplot lf_fe0 lf_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/lf_men_women.png", replace

    coefplot lf_married_fe0 lf_married_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/lf_men_women_married.png", replace

    coefplot lf_single_fe0 lf_single_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/lf_men_women_single.png", replace

    coefplot lf_c_m_fe0 lf_c_m_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/lf_men_women_married_college.png", replace

    coefplot lf_no_c_m_fe0 lf_no_c_m_fe1, `coefplot_options' ///
        legend(order(2 "Men" 4 "Women") 	ring(0) pos(2))
    graph export "output/figures/lf_men_women_married_nc_college.png", replace
}
else if "`reg_type'"=="individual" {
    do "code_files/graphs_by_demographic_groups_individual.do" `indep_var' `year_list'

    local year_label  1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"
    foreach year in `year_list' {
		if `year'==1970 {
			local model_all             model_`year'_all
            local model_ft              model_`year'_ft
            local model_ft_married      model_`year'_ft_married 
            local model_ft_single       model_`year'_ft_single 
            local model_ft_child        model_`year'_ft_child
            local model_ft_no_child     model_`year'_ft_no_child 
            local model_ft_college      model_`year'_ft_college 
            local model_ft_no_college   model_`year'_ft_no_college 
			local model_lf_child   		model_`year'_lf_ch
			local model_lf_no_child   	model_`year'_lf_no_ch
		}
		else {
		    local model_all             `model_all'             ||      model_`year'_all
            local model_ft              `model_ft'              ||      model_`year'_ft
            local model_ft_married      `model_ft_married'      ||      model_`year'_ft_married 
            local model_ft_single       `model_ft_single'       ||      model_`year'_ft_single 
            local model_ft_child        `model_ft_child'        ||      model_`year'_ft_child
            local model_ft_no_child     `model_ft_no_child'     ||      model_`year'_ft_no_child 
            local model_ft_college      `model_ft_college'      ||      model_`year'_ft_college 
            local model_ft_no_college   `model_ft_no_college'   ||      model_`year'_ft_no_college 
			local model_lf_child   		`model_lf_child'   		||      model_`year'_lf_ch
			local model_lf_no_child   	`model_lf_no_child'   	||    	model_`year'_lf_no_ch
		}
		
	}
    
    
    local coefplot_options vert yline(0)  keep(1.male*`indep_var') base  ciopt(recast(rcap))  ///
        xlabel(`year_label') ytitle("Coefficient on population density") bycoefs yline(0) ///
        yscale(range(-.05 .02))
    
    coefplot `model_all',               `coefplot_options'  ///
        title("All workers")
    graph export "output/figures/individual_all.png",           replace

    coefplot `model_ft',                `coefplot_options' ///
        title("Full-time workers")
    graph export "output/figures/individual_ft.png",            replace

    coefplot `model_ft_married',         `coefplot_options' ///
        title("Full-time married workers")
    graph export "output/figures/individual_ft_married.png",    replace

    coefplot `model_ft_single',         `coefplot_options' ///
        title("Full-time single workers")
    graph export "output/figures/individual_ft_single.png",     replace
    
    coefplot `model_ft_child',           `coefplot_options' ///
        title("Full-time workers with children")
    graph export "output/figures/individual_ft_child.png",      replace
    
    coefplot `model_ft_no_child',       `coefplot_options' ///
        title("Full-time workers without children")
    graph export "output/figures/individual_ft_no_child.png",   replace
    
    coefplot `model_ft_college',        `coefplot_options' ///
        title("Full-time workers with college education")
    graph export "output/figures/individual_ft_college.png",    replace

    coefplot `model_ft_no_college',     `coefplot_options' ///
        title("Full-time workers without college education")
    graph export "output/figures/individual_ft_no_college.png", replace

    local coefplot_options vert yline(0)  base  ciopt(recast(rcap))  ///
        xlabel(`year_label') ytitle("Coefficient on population density") yline(0) ///
        yscale(range(0 .10)) b(b_sex) se(se_sex) bycoefs legend(order(2 "Women" 1 "Men"))
    
    coefplot `model_all',               `coefplot_options'  ///
        title("All workers")
    graph export "output/figures/individual_all_women.png",           replace

    coefplot `model_ft',                `coefplot_options' ///
        title("Full-time workers")
    graph export "output/figures/individual_ft_women.png",            replace

    coefplot `model_ft_married',         `coefplot_options' ///
        title("Full-time married workers")
    graph export "output/figures/individual_ft_married_women.png",    replace

    
    coefplot `model_ft_single',         `coefplot_options' ///
        title("Full-time single workers")
    graph export "output/figures/individual_ft_single_women.png",     replace
    
    coefplot `model_ft_child',           `coefplot_options' ///
        title("Full-time workers with children")
    graph export "output/figures/individual_ft_child_women.png",      replace
    
    coefplot `model_ft_no_child',       `coefplot_options' ///
        title("Full-time workers without children")
    graph export "output/figures/individual_ft_no_child_women.png",   replace

    coefplot `model_ft_college',        `coefplot_options' ///
        title("Full-time workers with college education")
    graph export "output/figures/individual_ft_college_women.png",    replace

    coefplot `model_ft_no_college',     `coefplot_options' ///
        title("Full-time workers without college education")
    graph export "output/figures/individual_ft_no_college_women.png", replace

}










