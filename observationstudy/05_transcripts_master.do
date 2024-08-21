//----------------------------------------------------------------------------//
// Stores text as stata dataset. Preserving all line breaks and text structure
//----------------------------------------------------------------------------//
clear all 
* Set up directories 
global root 	"/Users/steffenerickson"
global code 	"Documents/GitHub/SERA/observationstudy"
global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data/transcripts"
global output 	"Desktop"
* Text processing function 
include ${root}/${code}/00_import_text_files_mata_function.do

* structure text data for import
cd "${root}/${data}"
capture erase "${root}/${output}/transcripts_freeformat_outputfile.txt"
mata: driver("*.txt","${root}/${output}/transcripts_freeformat_outputfile.txt") // text processing function 

*import to stata
clear
infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile.txt"

* example 
mata a = st_sdata(37,"text")	 
mata printf(a)
