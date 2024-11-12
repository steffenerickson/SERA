clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy/calibration"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"
qui include ${programs}/mvgstudy.ado

mkf   obsrubric 
frame change obsrubric
frame obsrubric : import excel "${root}/${rawdata}/Crowdsource Science Observation Form - CALIBRATION MODULES 2024-2025_October 22, 2024_07.05.xlsx", sheet("Sheet0") firstrow case(lower) clear

frame obsrubric : drop startdate enddate status ipaddress progress durationinseconds
frame obsrubric : do ${code}/02_calibration_stringcleaning.do
frame obsrubric : do ${code}/03_calibration_ids.do
frame obsrubric : do ${code}/04_calibration_reshape.do

*frame obsrubric : codebook 
frame obsrubric : save "${root}/${cleandata}/obsrubric24.dta" , replace 




