*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates figures with gender gap regressions
*===============================================================================

local do_location "2\_analysis/code\_files/create\_gender\_gap\_regressions.do"

use "../1_build_database/output/czone_level_dabase", clear

local year_list 1950 1970 1980 1990 2000 2010
local var_list	wage_gap raw_wage_gap  l_czone_density

local filter &l_czone_density>0
foreach variable in `var_list' {
	g `variable'_sd=.
	foreach year in `year_list' {
		summ `variable' if year==`year'
		replace `variable'_sd=`variable'/`r(sd)'
	}
}

foreach year in `year_list' {
	foreach variable in  wage_gap raw_wage_gap {
		eststo `variable'`year': reg `variable'_sd l_czone_density_sd if year==`year'`filter', ///
			vce(r)
	}
}



local table_name "output/tables/gender_gap_regressions.tex"
local table_title "Relationship between gender gap an population density"
local table_note "robust standard errors in parenthesis. Coefficents are interpreted as the change in sd in the gender wage for an increase in czone density of 1 sd. I exclude CZ with less than 10 people per km$^2$. Wages are residualized separately by year. The regressions control for a full set of education, age, occupation, race and state dummies"
local tableOptions drop(_cons) label append booktabs f collabels(none) ///
	nomtitles plain b(%9.3fc) se(%9.3fc) par star  ///
		stats(r2 N, ///
		label("\midrule $ R^2$" "Observations") ///
		fmt(%9.3fc %9.2fc %9.0fc))
textablehead using `table_name', ncols(6) coltitles(`year_list') drop col(c) ///
	title(`table_title') f("Dependent variable")

label var l_czone_density_sd "Raw gender gap"
esttab raw_wage_gap* using `table_name', `tableOptions'

label var l_czone_density_sd "\midrule Residualized gender gap"
esttab wage_gap* using `table_name', `tableOptions'

textablefoot using `table_name', notes(`table_note') dofile(`do_location')
