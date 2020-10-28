


*===============================================================================
*DESCRIPTIVE STATISTICS
*===============================================================================

local nquantiles=10
local filter if l_czone_density_50>0



*Some preliminary fixes to the map database
tempfile map_tomerge
	use "../1_build_database/input/cz1990_data", clear
	use "../1_build_database/input/cz1990_data", clear
	rename cz czone
	rename cz_id _ID
	drop *_center
save `map_tomerge'




use "../1_build_database/output/czone_level_dabase_full_time", clear


sort czone year
by czone: generate l_czone_density_50=l_czone_density[1]s

*I separate labor markets across cizes. Let's start with three tiers. 

*Without any population weighting
*--------------------------------------------------------------------------------
gegen density_quantile=xtile(l_czone_density) `filter', by(year) ///
    nq(`nquantiles')

by czone: generate density_quantile_70=density_quantile[2]


*With population weights
gegen density_quantile_w=xtile(l_czone_density) [aw=czone_pop] `filter', by(year) ///
    nq(`nquantiles')

by czone: generate density_quantile_70_w=density_quantile_w[2]


reg wage_raw_gap i.year 
predict wage_raw_dev, residuals
*Gender gaps in 1970 and 2020.
separate wage_raw_dev, by(year)

grscheme, ncolor(7) style(tableau)

label var density_quantile "Population density tercile"


*GRAPH 1: QUICK REPRESENTATION OF THE GRADIENT BY POPULATION DENSITY
*================================================================================
*Note: I am not weighting by population in this graph. The buckets are defined
*in each year. It would be the analogous of the regression I have.
graph bar (mean) wage_raw_dev1970 wage_raw_dev2000 wage_raw_dev2020, over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "2000" 3 "2020") ring(0) pos(11)) ///
    ytitle("Male wage advantage (log-points)") ///
    b1title("Decile of population density") ///
    title(Gender wage gap and CZ population density)

graph export "output/figures/bar_graph_deviation_from_mean.png", replace


*GRAPH 2: GEOGRAPHICAL VARIATION OF POPULATION DENSITY
*================================================================================
merge m:1 czone using `map_tomerge', keep(3) nogen
*85% of the population is always concentrated in the top 4 categories fo the graph
spmap density_quantile_70 if year==1970  using "../1_build_database/input/cz1990_coor", ///
		id(_ID) fcolor(Blues2) clbreaks(1 3 6 7 8 9 10) clmethod(custom) ///
        legtitle("Population density decile")
graph export "output/figures/densest_cz_USA.png", replace


*GRAPH 3: POPULATION SHARE
*================================================================================

*The top 250 CZ accumulate about 85% of the population
egen total_population=sum(czone_pop) `filter', by(year)
generate cz_pop_share=czone_pop/total_population

sort czone year
by czone: generate d_cz_pop_share=cz_pop_share-cz_pop_share[2]
separate cz_pop_share, by(year)


graph bar (sum) cz_pop_share1990 cz_pop_share2020, over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "2020") ring(0) pos(2)) ///
    ytitle("Change in population share (since 1970)") ///
    b1title("Tercile of population density in 1970 (log-points)")


graph export "output/figures/bar_graph_pop_share.png", replace


*GRAPH 4: POPULATION GROWTH
*================================================================================
separate d_cz_pop_share, by(year)

graph bar (sum) d_cz_pop_share1990 d_cz_pop_share2020, over(density_quantile_70) ///
    yline(0) legend(order(1 "1970" 2 "2020") ring(0) pos(2)) ///
    ytitle("Change in population share (since 1970)") ///
    b1title("Tercile of population density in 1970 (log-points)")


graph export "output/figures/bar_graph_pop_share_growth.png", replace


*GRAPH 5-6: HOW DO MALE AND FEMALE WAGES SHAPE UP IN THIS CZ
*================================================================================
reg      male_l_wage i.year
predict dev_male_l_wage, residuals

reg     female_l_wage i.year
predict dev_female_l_wage, residuals


separate dev_male_l_wage, by(year)
separate dev_female_l_wage, by(year)


*Graph for  men 
graph bar (mean) dev_male_l_wage1970  dev_male_l_wage1990 dev_male_l_wage2000 dev_male_l_wage2020  , over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "1990" 3 "2000" 4 "2020") ring(0) pos(11)) ///
    ytitle("Average log real hourly wage (demeaned)") ///
    b1title("Decile of population density") ///
    title(Male wages)
graph export "output/figures/bar_graph_wages_men.png", replace

*Graph for women
graph bar (mean) dev_female_l_wage1970  dev_female_l_wage1990 dev_female_l_wage2000 dev_female_l_wage2020, over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "1990" 3 "2000" 4 "2020") ring(0) pos(11)) ///
    ytitle("Average log real hourly wage (demeaned)") ///
    b1title("Decile of population density") ///
    title(Female wages)

graph export "output/figures/bar_graph_wages_women.png", replace



*TABLE: AVERAGE POPULATION BY DECILES
*================================================================================
cap log close
log using "output/log_files/average_population_by_decile.txt", text replace

*Average population in the czone in 2020, by population density quantile

*Deciles 1-6 are relatively small places with 10-110k average total population
table density_quantile if year==2020, c(mean czone_pop)  format(%9.0fc)
log close


*GRAPH 7: LABOR FORCE PARTICIPATION BY GENDER
*================================================================================
reg     male_lfp i.year 
predict dev_male_lfp, residuals 

reg     female_lfp i.year 
predict dev_female_lfp, residuals



separate dev_male_lfp, by(year)
separate dev_female_lfp, by(year)

*Graph for  men 
graph bar (mean) dev_male_lfp1970  dev_male_lfp1990  dev_male_lfp2020  , over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "1990" 3 "2020") ring(0) pos(11)) ///
    ytitle("LFP (demeaned)") ///
    b1title("Decile of population density") ///
    title("Men LFP")

graph export "output/figures/bar_graph_lfp_male.png", replace

*Absolute values
local to_graph  male_lfp 

separate `to_graph', by(year)


sort czone year
by czone: generate d_male_lfp=male_lfp-male_lfp[2]
by czone: generate d_female_lfp=female_lfp-female_lfp[2]

*Changes
local to_graph  d_male_lfp 

separate `to_graph', by(year)


graph bar (mean) `to_graph'1990 `to_graph'2020  , over(density_quantile) ///
    yline(0)  legend(order(1 "1990-1970"  2 "2020-1970")  ring(0) pos(11)) ///
    ytitle("LFP") ///
    b1title("Decile of population density") ///
    title("Changes in male LFP")


local to_graph  d_female_lfp 

separate `to_graph', by(year)

graph bar (mean) `to_graph'1990 `to_graph'2020  , over(density_quantile) ///
    yline(0)  legend(order(1 "1990-1970"  2 "2020-1970")  ring(0) pos(11)) ///
    ytitle("LFP") ///
    b1title("Decile of population density") ///
    title("Changes in male LFP")




*Absolute values
local to_graph  female_lfp 

separate `to_graph', by(year)


*THEY HAVE A STRUCTURE MORE CONCENTRATED IN FINANCE, UTILITIES AND ENTERTAINMENT
graph bar (mean) `to_graph'1970 `to_graph'1990 `to_graph'2020  , over(density_quantile) ///
    yline(0)  legend(order(1 "1970" 2 "1990" 3 "2020")  ring(0) pos(11)) ///
    ytitle("LFP") ///
    b1title("Decile of population density") ///
    title("Male LFP")





*Graph for  women 
graph bar (mean) dev_female_lfp1970 dev_female_lfp1990 dev_female_lfp2020  , over(density_quantile) ///
    yline(0) legend(order(1 "1970" 2 "1990" 3 "2020") ring(0) pos(11)) ///
    ytitle("Average real hourly wage (demeaned)") ///
    b1title("Decile of population density") ///
    title("Women LFP")

graph export "output/figures/bar_graph_lfp_women.png", replace

*Men vs women 1970
graph bar (mean) dev_male_lfp1970 dev_female_lfp1970  , over(density_quantile) ///
    yline(0) legend(order(1 "Men" 2 "Women") ring(0) pos(11)) ///
    ytitle("Average real hourly wage (demeaned)") ///
    b1title("Decile of population density")  ///
    title("Men vs Women LFP, 1970")

graph export "output/figures/bar_graph_lfp_1970.png", replace


*Men vs women 1990
graph bar (mean) dev_male_lfp1990 dev_female_lfp1990  , over(density_quantile) ///
    yline(0) legend(order(1 "Men" 2 "Women") ring(0) pos(11)) ///
    ytitle("Average real hourly wage (demeaned)") ///
    b1title("Decile of population density")  ///
    title("Men vs Women LFP, 1990")

graph export "output/figures/bar_graph_lfp_1990.png", replace


graph bar (mean) dev_male_lfp2000 dev_female_lfp2000  , over(density_quantile) ///
    yline(0) legend(order(1 "Men" 2 "Women") ring(0) pos(11)) ///
    ytitle("Average real hourly wage (demeaned)") ///
    b1title("Decile of population density")  ///
    title("Men vs Women LFP, 2000")

graph export "output/figures/bar_graph_lfp_2000.png", replace

*Graph for  men 
graph bar (mean) dev_male_lfp2020 dev_female_lfp2020  , over(density_quantile) ///
    yline(0) legend(order(1 "Men" 2 "Women") ring(0) pos(11)) ///
    ytitle("Average real hourly wage (demeaned)") ///
    b1title("Decile of population density")   ///
    title("Men vs Women LFP, 2020")

graph export "output/figures/bar_graph_lfp_2020.png", replace




*INDUSTRIAL STRUCTURE OF THESE PLACES
*=================================================================================
reg     ind_manufacturing i.year, nocons
predict dev_ind_manufacturing, residuals 

reg     ind_ret_services i.year, nocons
predict dev_ind_ret_services, residuals

reg     ind_oth_services i.year, nocons
predict dev_ind_oth_services, residuals


local to_graph  dev_ind_manufacturing
separate `to_graph', by(year)


*THEY HAVE A STRUCTURE MORE CONCENTRATED IN FINANCE, UTILITIES AND ENTERTAINMENT
graph bar (mean) `to_graph'1970 `to_graph'1990 `to_graph'2020  , over(density_quantile) ///
    yline(0)  legend(order(1 "1970" 2 "1990" 3 "2020")  ring(0) pos(11)) ///
    ytitle("Employment share (demeaned by year)") //    b1title("Decile of population density") ///
    title("Manufacturing share")

graph export "output/figures/bar_deciles_manufacturing.png", replace



local to_graph  dev_ind_oth_services
separate `to_graph', by(year)

*THEY HAVE A STRUCTURE MORE CONCENTRATED IN FINANCE, UTILITIES AND ENTERTAINMENT
graph bar (mean) `to_graph'1970 `to_graph'1990 `to_graph'2020  , over(density_quantile) ///
    yline(0)  legend(order(1 "1970" 2 "1990" 3 "2020")  ring(0) pos(11)) ///
    ytitle("Employment share (demeaned by year)") ///
    b1title("Decile of population density") ///
    title("Finance, trasnportation and recreation share")


graph export "output/figures/bar_deciles_oth_sevices.png", replace


*There is no interesting gradient in the other variables that I have


*=================================================================================
*/
use  "../1_build_database/output/etp_file_full_time", replace

sort czone female year 
by czone female: generate l_czone_density_50=l_czone_density[1]

gegen density_quantile=xtile(l_czone_density) `filter', by(year) ///
    nq(`nquantiles')



reg etp_high i.year#i.female `filter'
predict dev_etp_high, residuals

reg etp_low i.year#i.female `filter'
predict dev_etp_low, residuals

local to_graph dev_etp_high
separate `to_graph', by(female)



foreach year in 1970 1990 2020 {
    graph bar (mean) `to_graph'0 `to_graph'1  if year==`year', over(density_quantile) ///
        yline(0)  legend(order(1 "Men" 2 "Women")  ring(0) pos(11)) ///
        ytitle("Employment share (demeaned by year)") ///
        b1title("Decile of population density") ///
        title("Employment to population ratio `year', high skill ")
    graph export "output/figures/etp_deciles_`year'_high.png", replace
}


local to_graph dev_etp_low
separate `to_graph', by(female)


foreach year in 1970 1990 2020 {
    graph bar (mean) `to_graph'0 `to_graph'1  if year==`year', over(density_quantile) ///
        yline(0)  legend(order(1 "Men" 2 "Women")  ring(0) pos(11)) ///
        ytitle("Employment share (demeaned by year)") ///
        b1title("Decile of population density") ///
        title("Employment to population ratio `year', low_skill ")
    graph export "output/figures/etp_deciles_`year'_low.png", replace
}


*=============================================================================================
*WHICH SECTORS ARE MEN AND WOMEN EMPLOYED
*=============================================================================================


