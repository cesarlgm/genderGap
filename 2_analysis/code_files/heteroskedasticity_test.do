*==================================================================================
*Here I perform a quick test for whether I should weight the regressions
*==================================================================================
*The answer is mostly no. I follow the suggestion from Solon et al (2015)


gettoken 	indep_var 		0: 0
gettoken 	indiv_sample	0: 0
gettoken 	density_filter	0: 0

use  "temporary_files/aggregate_regression_file_final_`indiv_sample'", clear

*Add dataset that includes celss sizes
merge 1:1 czone year using   "../1_build_database/output/czone_level_dabase_`indiv_sample'", ///
	nogen 
*Unweighted regression
*---------------------------------------------------------------
local filter if czone_pop_50/cz_area>`density_filter'&year>1950
local year_label   1 "1970" 2 "1980" 3 "1990" 4 "2000" 5 "2010" 6 "2020"


*Regression specification
local controls i.year#c.`indep_var' i.year 

*I first regress by OLS
qui eststo unweighted: 	reg l_hrwage_gap `controls' `filter', vce(cl czone) 

*Predict the OLS residuals
predict e_residuals if e(sample), residuals
generate sq_residuals=e_residuals*e_residuals

*I regress the square of the resuals on the appropriate regresison weight

log using "output/log_files/heteroskedasticity_test.txt", text replace
regress sq_residuals reg_weight
log close

/*
*The bottom line is that the constant is more important than the possible heteros 
 kedasticity induced by the regression.

      Source |       SS           df       MS      Number of obs   =     3,750
-------------+----------------------------------   F(1, 3748)      =      0.99
       Model |  .000034607         1  .000034607   Prob > F        =    0.3203
    Residual |  .131305385     3,748  .000035033   R-squared       =    0.0003
-------------+----------------------------------   Adj R-squared   =   -0.0000
       Total |  .131339993     3,749  .000035033   Root MSE        =    .00592

------------------------------------------------------------------------------
sq_residuals |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
  reg_weight |  -2.74e-08   2.76e-08    -0.99   0.320    -8.14e-08    2.66e-08
       _cons |   .0035209    .000103    34.17   0.000     .0033188    .0037229
------------------------------------------------------------------------------
*/




