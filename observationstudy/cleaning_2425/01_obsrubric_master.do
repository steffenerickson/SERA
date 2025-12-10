clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2024-2025 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy/cleaning_2425"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"
qui include ${programs}/mvgstudy.ado

mkf  obsrubric 
mkf  obsrubric_lesson_list

//frame obsrubric : import excel "${root}/${rawdata}/Crowdsource Science Observation Form 2024-2025_June 11, 2025_13.46.xlsx", sheet("Sheet0") firstrow case(lower) clear
frame obsrubric : import excel "${root}/${rawdata}/2024-25 Observation Data Checking_September 19, 2025_14.30.xlsx", sheet("Sheet0") firstrow case(lower) clear
frame obsrubric : drop startdate enddate status ipaddress progress durationinseconds
frame obsrubric : do ${code}/02_obsrubric_stringcleaning.do
frame obsrubric : do ${code}/03_obsrubric_ids.do
frame obsrubric : do ${code}/04_obsrubric_reshape.do
*frame obsrubric : codebook 
frame obsrubric : save "${root}/${cleandata}/obsrubric2425.dta" , replace 




// Merge with direct observation list

frame obsrubric {
	split i15 , parse(-)
	rename (i12 i13 i151  i17) (sitename  observer  teacher obsround)
	replace i152 = "M" if i152 == ""
	rename i152 gradeformerge
}
frame obsrubric_lesson_list {
	do ${code}/00_direct_observation_list.do
	tempfile data 
	save `data'
}
frame obsrubric : merge m:1 sitename  observer teacher obsround gradeformerge using `data' 

frame obsrubric : preserve
frame obsrubric : collapse _merge , by(sitename  observer teacher obsround gradeformerge lesson)  
frame obsrubric : sort sitename teacher obsround observer 
frame obsrubric : list if _merge != 3
frame obsrubric : restore

frame obsrubric : drop if _merge == 2
frame obsrubric : drop _merge
frame obsrubric : save "${root}/${cleandata}/obsrubric_lessonsids_2425.dta" , replace 



