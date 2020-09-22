*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: classifies industries into manufacturing and services
*==============================================================================
local occupation `1'

local employed 			if empstat==1&!missing(ind1950)

*I compute the dummies only for the employed 	
cap replace occ1950=. 		if occ1950>=980
cap replace ind1950=. 		if ind1950>=980
cap replace ind1950=. 		if ind1950==0
cap replace occ1990=.		if occ1990>=991


g ind_mining_cons=		inrange(ind1950,206,246) 		`employed'
g ind_manufacturing=	inrange(ind1950,306,499) 		`employed'
g ind_pers_services=	inrange(ind1950,826,849) 		`employed'
g ind_prof_services=	inrange(ind1950,868,899) 		`employed'
g ind_ret_services=		inrange(ind1950,606,699) 		`employed'
g ind_oth_services=		inrange(ind1950,506,598) | 	inrange(ind1950,716,817)|	///
	inrange(ind1950,856,859) `employed'
g ind_public_adm=		inrange(ind1950,906,946)  		`employed'
g ind_agriculture=		inrange(ind1950,105,126) 		`employed'

local counter=1

local ind_list mining_cons manufacturing pers_services prof_services ///
	ret_services oth_services public_adm agriculture

g	ind_type=.	
foreach industry in `ind_list' {
	replace ind_type=`counter' if ind_`industry'==1
	local ++counter
}

capture label define ind_type 	1 "Mining and construction" ///
								2 "Manufacturing" ///
								3 "Personal services" ///
								4 "Professional services" ///
								5 "Retail services" ///
								6 "Other services" ///
								7 "Public administration"  ///
								8 "Agriculture"
label values ind_type ind_type


if !inlist("`occupation'","ind1990","ind1950") {
	*Classifying occupations
	if "`occupation'"=="occ1990" {
		g occ_manager_prof=		inrange(`occupation',003,200)		`employed'
		g occ_sales_clerical=	inrange(`occupation',203,389)		`employed'
		g occ_service=			inrange(`occupation',405,469)		`employed'
		g occ_farming=			inrange(`occupation',473,498)		`employed'
		g occ_skilled=			inrange(`occupation',503,699)		`employed'
		g occ_operator=			inrange(`occupation',703,889)		`employed'


		label define occ1990_agg 	1 "Managers and professionals" ///
									2 "Sales and clerical" ///
									3 "Service occupations" ///
									4 "Farming occupations" ///
									5 "Skilled occupations" ///
									6 "Operators"							
	}
	else if "`occupation'"=="occ1950" {
		g occ_prof_serv=		inrange(`occupation',000,099)		`employed'
		g occ_farm=				inrange(`occupation',100,123) | inrange(`occupation',810,979)	`employed'
		g occ_manag=			inrange(`occupation',200,290)		`employed'
		g occ_clerical=			inrange(`occupation',300,390)		`employed'
		g occ_sales=			inrange(`occupation',400,490)		`employed'
		g occ_craft=			inrange(`occupation',500,595)		`employed'
		g occ_oper=				inrange(`occupation',600,690)		`employed'
		g occ_service=			inrange(`occupation',700,790)		`employed'

		label define occ1950_agg 	1 "Professional services" ///
									2 "Farmers and farm laborers" ///
									3 "Managers" ///
									4 "Clerical occupations" ///
									5 "Sales" ///
									6 "Craftmen / skilled occupations" ///
									7 "Operatives" ///
									8 "Non professional service occupations"
	}

	g 		`occupation'_agg=.
	local counter=1
	ds occ_*
	foreach code in `r(varlist)' {
		replace `occupation'_agg=`counter' `employed'&!missing(`occupation')&`code'
		local ++counter
	}

	label values `occupation'_agg `occupation'_agg
}
