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

* Text processing function 
include "${programs}/import_text_files_mata_function.do"

* structure text data for import
cd "${root}/${data}"
capture erase "${root}/${output}/transcripts_freeformat_outputfile.txt"
mata: driver("*.txt","${root}/${output}/transcripts_freeformat_outputfile.txt") // text processing function 

*import to stata
clear
infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile.txt"
export delimited using "${root}/${output}/transcripts.csv" , replace

* example 
mata a = st_sdata(1,"text")	 
mata printf(a)


mata b = st_sdata(67,"text")	 
mata printf(b)

* Pull into Python 
local varlist filename text
python: from sfi import Data
python: import pandas as pd
python: df =  pd.DataFrame(Data.get('`varlist''))
python: transcript37 = df.iloc[36, 1]
python: print(transcript37.replace('\\n', '\n'))
python: df.head(5)

* or 
save ${root}/${output}/data.dta , replace
python: import pandas as pd
python: path = 'C:/Users/cns8vg/Desktop'
python: df = pd.read_stata(f'{path}/data.dta')
python: first_row_second_column = df.iloc[36, 1]
python: print(first_row_second_column.replace('\\n', '\n'))




// python 

