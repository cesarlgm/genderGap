*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: creates map with gender gap by cz
*===============================================================================

local analysis_type     `1'
local year              `2'

*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"

*List of variables I am extracting from the census
local 		var_list		l_hrwage age education marst czone ///	
							race occ* ind* year female wkswork hrswork perwt ///
							statefip empstat
*Observations I am using
local 		filter 			!missing(l_hrwage)&full_time&czone_pop_50/cz_area>0


if `analysis_type'==0 {
	local name gender
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
}
else if `analysis_type'==1 {
	local name race
	local y1 2
	local y2 1
	local legend order( 2 "Black" 1 "White")
	local y_title_gap "log(white wage)-log(black wage)"
}
else if `analysis_type'==2 {
	local name by_education
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
}
else if `analysis_type'==4 {
	local name full_time
	local y1 1
	local y2 0
	local legend order( 1 "Females" 2 "Males")
	local y_title_gap "log(male wage)-log(female wage)"
	local add_note " and full-time year-round workers."
}



*==================================================================================================================================
*COMPUTATION OF AVERAGE GAP IN THE WHOLE OF THE US
*==================================================================================================================================

use  `var_list' using	"${data}/output/cleaned_census_`year'", clear		

replace year=2010 if year==2011
replace year=2020 if year==2018
    
    
*Definition of full-time workers
g	full_time=wkswork>=40&hrswork>=35

g male=!female

*Compute unconditional gender wage gap
eststo wage_gap: reg l_hrwage i.male [pw=perwt], vce(cl czone)

local gap = round(100*_b[1.male],1)
local gap_se=round(100*_se[1.male],0.1)

*Writing stats on a tex file
local average_name  "output/scalars/averate_US_gap.tex"
local sd_name       "output/scalars/sd_US_gap.tex"


cap rm `average_name'
cap rm `se_name'

writenewln "`average_name'"  "`gap'"
writenewln "`sd_name'"  "`gap_se'"

*==================================================================================================================================
*COMPUTATION OF STANDARD DEVIATION OF THE GAP ACROSS CZ
*==================================================================================================================================

use "../1_build_database/output/czone_level_dabase_`name'", clear

local 		filter 		czone_pop_50/cz_area>1


summ wage_raw_gap if `filter'&year==`year'

local sd_cz_gap=round(`r(sd)'*100)
local sd_percent=round(`sd_cz_gap'/`gap'*100)

local sd_cz_name               "output/scalars/sd_US_gap.tex"
local percent_name          "output/scalars/percent_US_mean.tex"


writenewln "`sd_cz_name'"  "`sd_cz_gap'"
writenewln "`percent_name'"  "`sd_percent'\%"
