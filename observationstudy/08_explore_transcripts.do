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


frame change line 

frame change sent 


list sent_str person timestamp in 159/182 
