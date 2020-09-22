*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: some basic stats on gendered industries
*===============================================================================

local indep_var 	`1'
local occupation 	`2'

use "../1_build_database/output/gender_naclevel_classification_1950_`occupation'", clear


*These occupations are still male dominated
reg female_share i.male_ind


*On average only 15% of women work in these occupations
graph bar female_share if year>1950, over(male_ind) noout

*They account for about 20% of full-time employment at the national level
graph bar (sum) empshare, over(male_ind) noout


