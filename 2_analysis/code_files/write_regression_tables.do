*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap wage gradient by CZ
*===============================================================================
gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0
local 		year_list `0'


local year_label 1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


eststo clear

grscheme, ncolor(7) style(tableau)



*INDIVIDUAL LEVEL MODELS
*----------------------------------------------------------------------------------------
local model_list baseline with_basic_controls with_educ_controls with_ind_controls
foreach model in `model_list' {
    estimates use "output/regressions/`model'_individual_`indiv_sample'" 
    eststo `model'

    clear
    regsave 
    keep  if regexm(var, "l_czone_density")
    g year=1960+10*_n
    g source="`model'"
    tempfile `model'_est
    save ``model'_est'
}
clear
foreach model in `model_list' {
    append using ``model'_est'
}

sort source year
by source: g gradient_diff=coef[_n]-coef[1]

sort year source


generate dist_from_flat=abs(gradient_diff)
sort  year source
by year: generate share_baseline=1-abs(dist_from_flat)/abs(dist_from_flat[1])
 




separate gradient_diff, by(source)

tw line `r(varlist)' year, recast(connected) ///
    legend(order(1 "No controls" 2 "+ basic demographics" ///
     3 "+ education" 4 "+ industry shares")) yline(0, lcolor(red)) ///
     ytitle("Gradient in t - gradient in 1970 ({&beta}{sub:t}-{&beta}{sub:1970})") ///
     xtitle(year)

graph export "output/figures/gradient_change_individual_`indep_var'_`indiv_sample'.pdf", replace





local figure_title "Coefficient on population density $ \beta_t $ controlling for worker characteristics"
local figure_name "output/figures/with_controls_gradients_individual_`indep_var'_`indiv_sample'.tex"
local figure_note "figure restricts to CZ with more than `density_filter' people per km$^2$. The regressions are done on data aggregated at the CZ level. Basic individual level controls include full set of: race, age, marital status and foreign born dummies. Education is measured using a 4-level education dummies: HS dropout, HS graduate, some college and bachelor +. Bars show 95\% robust confidence intervals."
local figure_path "../2_analysis/output/figures"
local figure_labs `""Cross-sectional gradient""Change in the gradient""'

local figure_list with_control_gradients_individual_`indep_var'_`indiv_sample' ///
    gradient_change_individual_`indep_var'_`indiv_sample'

latexfigure using `figure_name', path(`figure_path') figurelist(`figure_list') ///
    note(`figure_note') figlab(`figure_labs') ///
    title(`figure_title') nodate  dofile(`do_location') rowsize(2)


*Computing interquantile ranges
preserve
    tempfile pctile_gaps
        use "temporary_files/aggregate_regression_file_final_`indiv_sample'", clear

        local pctile_list
        foreach pct in 5 10 15 20 25 75 80 85 90 95 {
            local pctile_list  `pctile_list' (p`pct') p`pct'=l_czone_density
        }

        gcollapse `pctile_list' (mean) mean_gap=l_hrwage_gap (sd) sd_gap=l_hrwage_gap, by(year)

        generate gap95_5=p95-p5
        generate gap90_10=p90-p10
        generate gap85_15=p85-p15
        generate gap75_25=p75-p25

    save `pctile_gaps'
restore

merge m:1 year using `pctile_gaps', nogen 

foreach variable of varlist gap* {
    generate implied_`variable'=coef*`variable'
    generate pct_mean_`variable'=implied_`variable'/mean_gap
}

generate effect_size=coef/sd_gap

order implied* pct*, after(mean_gap)

sort source year


expand 3
eststo clear
foreach year in `year_list' {
	if `year'>1950 {
        local filter if year==`year' & source=="baseline"
		eststo coef`year':  	    reg coef            `filter'
        eststo mean`year':  	    reg mean_gap        `filter'
        eststo sd`year':  	        reg sd_gap        `filter'
        eststo effect_size`year': 	reg effect_size     `filter'
		eststo gap75_25`year': 	reg implied_gap75_25    `filter'
		eststo gap90_10`year': 	reg implied_gap90_10    `filter'
        eststo pct_gap75_25`year': 	reg pct_mean_gap75_25    `filter'
		eststo pct_gap90_10`year': 	reg pct_mean_gap90_10    `filter'
        
	}
}


local table_name 	"output/tables/interpretaion_table_`indiv_sample'.tex"
local col_titles   1970 1980 1990 2000 2010 2020
local table_title 	"Male advantange changes implied by estimated elasticities"
local key tab:IC
local table_note  	"changes based on unweighted estimated elasticities. Sample restricted to full-time year-round workers"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain  not par star 
	

textablehead using `table_name', ncols(6) coltitles(`col_titles') ///
	f("") title(`table_title') key(`key') drop

local space \hspace{3mm}

esttab coef* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "Density elasticity $ (\beta ) $") b(%9.3fc)
esttab sd* 	using `table_name', `table_options' noobs ///
	coeflab(_cons  " `space' s.d. wage gap ") b(%9.3fc)
esttab effect_size* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "$ `space'\beta / sd $") b(%9.3fc)

esttab gap75_25* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "\midrule IC range") b(%9.3fc)
esttab pct_gap75_25* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "`space' (\% mean gap) ") b(%9.3fc)

esttab gap90_10* 	using `table_name', `table_options' noobs ///
	coeflab(_cons " \midrule 90 - 10 pctile range  ") b(%9.3fc)

esttab pct_gap90_10* 	using `table_name', `table_options' noobs ///
	coeflab(_cons "`space' (\% mean gap)") b(%9.3fc)

	
textablefoot using `table_name', notes(`table_note') dofile(`do_location')
