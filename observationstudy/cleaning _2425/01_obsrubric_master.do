clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2024-2025 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy/cleaning"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"
qui include ${programs}/mvgstudy.ado

mkf   obsrubric 
frame obsrubric : import excel "${root}/${rawdata}/Crowdsource Science Observation Form 2024-2025_June 11, 2025_13.46.xlsx", sheet("Sheet0") firstrow case(lower) clear
frame obsrubric : qui drop startdate enddate status ipaddress progress durationinseconds
frame obsrubric : qui do ${code}/02_obsrubric_stringcleaning.do
frame obsrubric : qui do ${code}/03_obsrubric_ids.do
frame obsrubric : qui do ${code}/04_obsrubric_reshape.do
*frame obsrubric : codebook 
frame obsrubric : save "${root}/${cleandata}/obsrubric2425.dta" , replace 




