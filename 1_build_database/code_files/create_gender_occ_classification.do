*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpose: defines female / male occupations classifications based on 
*		base_year
*===============================================================================


local base_year 	`1'
local occupation 	`2'

local sub=substr("`occupation'",1,3)

use  	"${data}/output/cleaned_census_`base_year'", clear			

do "code_files/classify_industries_occupations.do" `occupation'

*Definition of full-time workers
g		full_time=	wkswork>=40&hrswork>=35
replace l_hrwage=. 	if !full_time

keep if full_time & !missing(l_hrwage) & !missing(`occupation')

replace perwt=round(perwt)
*I compute employment female employment share at the national level by occupation
gcollapse (mean) female (count) perwt=year [fw=perwt], by(`occupation')


_pctile female [fweight=perwt], p(66)

g 	female_`sub'=	female>=`r(r1)'

_pctile female [pweight=perwt], p(33)
g	male_`sub'=	female<=`r(r1)'

keep `occupation' female female_`sub' male_`sub'

rename female female_share_base

save "output/gender_occ_classification_`base_year'_`occupation'", replace
