*Location of cleaned census files
global data "C:\Users\thecs\Dropbox\Boston University\7-Research\NSAM\1_build_data"

*Fix this and send a mail to daniele
cd "C:\Users\thecs\Dropbox\Boston University\7-Research\LLMM\1_build_database"



*Computes average wage income of women by year

local year_list 1970 1980 1990 2000 2010 2020

foreach year in `year_list' {
		tempfile average_`year'
		use year perwt female l_hrwage wkswork hrswork if female using ///
			"${data}/output/cleaned_census_`year'", clear
	
		*Definition of full-time workers
		g	full_time=wkswork>=40&hrswork>=35
		replace l_hrwage=. if !full_time
		
		replace l_hrwage=exp(l_hrwage)*40*40
		
		gcollapse (mean) l_hrwage, by(year) fast
		
		save `average_`year''
}

clear
foreach year in `year_list' {
	append using `average_`year''
}

replace year=2020 if year==2018
replace year=2010 if year==2011

save "output/average_full_time_woman_wage", replace
