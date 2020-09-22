*===============================================================================
*		Project: Local labor markets and the gender wage gap<
*		Author: César Garro-Marín
*		Date: July 6th
*		Purpuse: translates CZ shapefiles creates area of the polygons
*===============================================================================

*Data location
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data\output"


cd "C:\Users\thecs\Dropbox\Boston University\7-Research\LLMM\1_build_database"

*STEP 1:
*-----------------------------------------------------------------
*I get the czones that are in the mainland
use "$data/cleaned_census_1950", clear
keep czone
gduplicates drop czone, force

tempfile mainland_cz
save `mainland_cz'


*STEP 2:
*-----------------------------------------------------------------
*Converting shp to dta
shp2dta using "input/cz1990.shp", database("input/cz1990_data") ///
	coor("input/cz1990_coor") replace genc(center) genid(cz_id)

use "input/cz1990_coor", clear

*STEP 3:
*-----------------------------------------------------------------
*Here I compute the are of commuting zones
fieldarea _X _Y, generate(cz_area) id(_ID) unit(sqkm)

rename _ID cz_id

tempfile czone_area
save `czone_area'

use "input/cz1990_data", clear
merge m:1 cz_id using `czone_area', nogen 
rename cz czone

*STEP 4
*-----------------------------------------------------------------
*I keep only czones in the mainland
merge m:1 czone using `mainland_cz', nogen keep(3)


label var cz_area "Area in sqkm"

spmap cz_area using "input/cz1990_coor", id(cz_id) fcolor(Blues)

drop cz_id *_center

save "output/czone_area", replace
