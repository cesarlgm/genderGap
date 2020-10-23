*
*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\boston_university\7-Research\NSAM\1_build_data"

local n_quantiles=4

tempfile density_quartiles
    use "../1_build_database/output/czone_level_dabase_full_time", clear
    keep if czone_pop_50/cz_area>1 //&year==1970
    drop if year==1950
    sort czone year
    by czone: gen l_czone_density_1970=l_czone_pop[1]
    by czone: gen d_wage_raw_gap=wage_raw_gap-wage_raw_gap[_n-2]
    by czone: gen l_l_czone_pop=l_czone_pop[_n-2]

    xtile density_quartile=l_czone_density_1970, nq(`n_quantiles')

 *   keep czone  density_quartile
save `density_quartiles'

local year_list  1970 1980 1990 2000 2010 2020



/*
foreach year in  `year_list' {
	di 		"Processing `year'", as result
	qui {
		use  	"${data}/output/cleaned_census_`year'", clear
		
		*Quick fix of variables
		egen    grouped_race=       cut(race), at(1,2,3,9)
		label   define  grouped_race 1 "White" 2 "Black" 3 "Other"
		label   values grouped_race grouped_race

		g married=			inlist(marst, 1,2)
		g high_education=	inlist(education, 3,4)
		g migrant=bpl>=150 	if !missing(bpl)
		g native_migrant=	bpl!=statefip if bpl<150
		
		g female_migrant=	native_migrant if female
		g male_migrant=		native_migrant if !female
		g full_time=		wkswork>=40&hrswork>=35
		g female_head=		relate==1&female

        replace l_hrwage=. if !full_time

        gegen    nac_average=mean(l_hrwage) [pw=perwt] , by(female year)
	
        merge m:1 czone using `density_quartiles', keep(3) nogen
    	*STEP 2> computing population counts by czone-gender
		gcollapse (count) observations=l_hrwage (mean) l_hrwage in_labforce nac_average [pw=perwt] , ///
			by(female density_quartile year) fast
    
        reshape wide l_hrwage* observations* in_labforce* nac_average, i(density_quartile year) j(female)

		tempfile collapsed`year'
		save `collapsed`year''	
	}
	
}


clear
foreach year in  `year_list' {
	append using `collapsed`year''
}


separate l_hrwage0, by(density_quartile)
separate l_hrwage1, by(density_quartile)


xtset density_quartile year, delta(10)

generate d_l_hrwage0=d.l_hrwage0
generate d_l_hrwage1=d.l_hrwage1



grscheme, ncolor(7) style(tableau)

separate d_l_hrwage0, by(density_quartile)
separate d_l_hrwage1, by(density_quartile)


local n_quantiles=4
tw line l_hrwage01 l_hrwage0`density_quartiles' l_hrwage11 l_hrwage1`density_quartiles' year if year>1950, recast(connected)

tw line d_l_hrwage01 d_l_hrwage0`density_quartiles' d_l_hrwage11 d_l_hrwage1`density_quartiles' year if year>1950, recast(connected)


sort year density_quartile
by year: g urban_premium0=l_hrwage0-l_hrwage0[1]
by year: g urban_premium1=l_hrwage1-l_hrwage1[1]


separate urban_premium0, by(density_quartile)
separate urban_premium1, by(density_quartile)


tw line urban_premium0`density_quartiles'  urban_premium1`density_quartiles' year if year>1950, recast(connected)

separate in_labforce0, by(density_quartile)
separate in_labforce1, by(density_quartile)


tw line in_labforce01 in_labforce0`density_quartiles' in_labforce11 in_labforce1`density_quartiles' year if year>1950, recast(connected)
