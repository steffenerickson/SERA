clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy/cleaning"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"
qui include ${programs}/mvgstudy.ado

mkf   obsrubric 
mkf  obsrubric_lesson_list
//frame obsrubric : import excel "${root}/${rawdata}/CrowdSource: Science Observation Form_January 22, 2025_10.42.xlsx", sheet("Sheet0") firstrow case(lower) clear
frame obsrubric : import excel "${root}/${rawdata}/23-24 Observation Data Checking_September 9, 2025_10.12.xlsx", sheet("Sheet0")firstrow case(lower) clear
frame obsrubric : drop startdate enddate status ipaddress progress durationinseconds
frame obsrubric : do ${code}/02_obsrubric_stringcleaning.do
frame obsrubric : do ${code}/03_obsrubric_ids.do
frame obsrubric : do ${code}/04_obsrubric_reshape.do
*frame obsrubric : codebook 
frame obsrubric : save "${root}/${cleandata}/obsrubric2324.dta" , replace 


frame obsrubric {
	split i15 , parse(-)
	rename (i12 i13 i151  i17) (sitename  observer  teacher obsround)
	replace i152 = "M" if i152 == ""
	rename i152 gradeformerge
	gen date = daily(i20, "MDY")
	format date %td
	//preserve
	//collapse a, by(sitename  observer teacher obsround gradeformerge date)  
	//egen id1 = group(sitename  observer teacher obsround gradeformerge)
	//sort id1 date
	//by id1 : gen n =  _n
	//list if n == 2
	//restore
	replace obsround = "4" if (sitename == "Brigham Young University"& observer == "02" & teacher == "0101" & gradeformerge == "M"  & date == td(11apr2024)) | ///
	                          (sitename == "Brigham Young University"& observer == "02" & teacher == "0201" & gradeformerge == "M"  & date == td(03apr2024))
													 
	replace obsround = "4" if (sitename == "Brigham Young University"& observer == "01" & teacher == "0101" & gradeformerge == "M"  & date == td(11apr2024)) | ///
	                          (sitename == "Brigham Young University"& observer == "01" & teacher == "0201" & gradeformerge == "M"  & date == td(03apr2024))
												  
   	replace observer = "02" if (sitename == "Brigham Young University" & teacher == "0201" & gradeformerge == "M" & observer == "01" & obsround == "2" ) 


}
frame obsrubric_lesson_list {
	do ${code}/00_direct_observation_list.do
	//replace obsround = "3" if obsround == "4"
	tempfile data 
	save `data'
}

frame obsrubric : merge m:1 sitename  observer teacher obsround gradeformerge using `data' 

frame obsrubric : preserve
frame obsrubric : collapse _merge , by(sitename  observer teacher obsround gradeformerge lesson)  
frame obsrubric : sort sitename teacher obsround observer 
frame obsrubric : list if _merge != 3
frame obsrubric : restore

frame obsrubric : drop if _merge == 2 // Need to fix this later 
frame obsrubric :  replace partnersite = "13" if partnersite == "" & sitename == "Brigham Young University"
frame obsrubric :  replace partnersite = "16" if partnersite == "" & sitename == "University of Missouri"
frame obsrubric: drop _merge 
frame obsrubric : save "${root}/${cleandata}/obsrubric_lessonsids_2324.dta" , replace 






