clear all 
version 18

* Set up directories 
local office 0
if `office' == 1 {
	global root 	"C:/Users/cns8vg"
	global code 	"GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data/transcripts"
	global programs "GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results"

}
if `office' == 0 {
	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data/transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global cleandata "Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Clean Data"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 
}


import delimited using "${root}/${output}/df_tokens.csv" ,clear
frame put line_str filename person timestamp , into(line)
frame put sent_str filename person timestamp , into(sent)
foreach f in line sent {
	frame `f' : bysort filename `f'_str: gen n = _n 
	frame `f' : keep if n == 1
	frame `f' : drop n 
}


frame change sent 


list sent_str person timestamp in 159/182 

frame change line 
gen time = clock(timestamp,"ms")
split filename , parse(_)
drop filename5 filename6
replace filename4 = substr(filename4,1,3)
gen teacher = filename1 + filename2





bysort teacher filename4: gen obsround = _n

tab teacher filename4

mkf obsrubric
frame obsrubric : use "${root}/${cleandata}/obsrubric.dta" , clear 
frame change obsrubric 
gen site = ""

replace site = "01" if i12 == "University of Virginia"
replace site = "02" if i12 == "University of Texas Austin"
replace site = "03" if i12 == "Delaware State University"
replace site = "04" if i12 == "Michigan State University"
replace site = "05" if i12 == "SUNY Buffalo State University"
replace site = "06" if i12 == "University of Arkansas Pine Bluff"
replace site = "07" if i12 == "University of California Riverside"
replace site = "08" if i12 == "University of Nevada Las Vegas"
replace site = "09" if i12 == "University of North Carolina Wilmington"
replace site = "10" if i12 == "University of Pittsburgh"
replace site = "11" if i12 == "University of Utah"
replace site = "12" if i12 == "Wichita State University"
replace site = "13" if i12 == "Brigham Young University"
replace site = "14" if i12 == "Washington State University"
replace site = "16" if i12 == "University of Missouri"
replace site = "18" if i12 == "Texas Christian University"
gen teacher = site + i15


















