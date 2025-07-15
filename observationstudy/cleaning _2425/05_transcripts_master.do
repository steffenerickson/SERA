//----------------------------------------------------------------------------//
// Stores text as stata dataset. Preserving all line breaks and text structure
//----------------------------------------------------------------------------//
clear all 
version 18

* Set up directories 
local office 0
if `office' == 1 {
	global root 	"C:/Users/cns8vg"
	global code 	"GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results"

}
if `office' == 0 {
	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 
}

//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Pulling txt files into stata 
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

* List of transcripts with a corresponding direct observation
do "${root}/${code}/cleaning/00_direct_observation_list.do"

* Text processing function 
include "${programs}/import_text_files_mata_function.ado"

* structure text data for import
cd "${root}/${data}/${transcripts}"
capture erase "${root}/${output}/transcripts_freeformat_outputfile.txt"
mata: driver("*.txt","${root}/${output}/transcripts_freeformat_outputfile.txt") // text processing function 

* Import to stata
mkf transcripts
frame transcripts: infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile.txt"
frame transcripts: save "${root}/${data}/${cleandata}/transcripts.dta" , replace

* Split by line and clean 
frame transcripts: do "${root}/${code}/cleaning/06_clean_transcripts.do"
frame transcripts: save "${root}/${data}/${cleandata}/transcripts_byline.dta" , replace

* Merge observation Scores 
mkf obsrubric 
frame obsrubric : use "${root}/${data}/${cleandata}/obsrubric.dta" , clear 
frame copy transcripts transcripts_obsrubric , replace
frame transcripts_obsrubric: do "${root}/${code}/cleaning/07_merge_directobs.do"
frame transcripts_obsrubric: save "${root}/${data}/${cleandata}/transcripts_obsrubric.dta" , replace

* Tokenize transcripts for text analysis 














