*CREATES TABLE WITH STATS ON VARIATION OF THE GENDER GAP ACROSS CZ

local year_list `0'

use "../1_build_database/output/czone_level_dabase_full_time", clear

local filter czone_pop/cz_area>1

local stat_list  mean sd p90 p75 p50 p25 p10
foreach stat in `stat_list' {
    local raw_list `raw_list' (`stat') `stat'_raw=wage_raw_gap
    *local res_list `res_list' (`stat') `stat'_res=wage_occ_gap
} 

gcollapse `raw_list' `res_list' if `filter', by(year)

expand 2

eststo clear
foreach year in `year_list'  {
    foreach stat in `stat_list' {
        eststo `stat'_raw_`year': reg `stat'_raw  if year==`year'
        *eststo `stat'_res_`year': reg `stat'_res if year==`year'
    }
}

local table_name "output/tables/cross_cz_statistics.tex"
local table_title "CZ-level gender gap statistics"
local table_options   nobaselevels label append booktabs f collabels(none) ///
	nomtitles plain  not par star b(%9.2fc) noobs
local space \hspace{0mm}

textablehead using `table_name', ncols(6) coltitles(`year_list') f(Statistic) drop sup("Census year") ///
    t(`table_title')
esttab mean*raw* using `table_name', `table_options' coeflabels(_cons "Average gap")
esttab sd*raw* using `table_name', `table_options' coeflabels(_cons "Standard deviation")
writeln `table_name' "\midrule\textbf{Distribution} \\"
esttab p90*raw* using `table_name', `table_options' coeflabels(_cons "\midrule`space'p90")
esttab p75*raw* using `table_name', `table_options' coeflabels(_cons "`space'p75")
esttab p50*raw* using `table_name', `table_options' coeflabels(_cons "`space'Median")
esttab p25*raw* using `table_name', `table_options' coeflabels(_cons "`space'p25")
esttab p10*raw* using `table_name', `table_options' coeflabels(_cons "`space'p10")
textablefoot using `table_name'


