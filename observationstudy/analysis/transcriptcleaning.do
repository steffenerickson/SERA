//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Transcript cleaning code 
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//



clear all 

//----------------------------------------------------------------------------//
// Import text files program 
//----------------------------------------------------------------------------//
mata 
struct myproblem {
	struct file_record scalar fr
	string scalar line
	real scalar output_fh
}
struct file_record {
	string scalar id 
	string scalar text
}
void driver(string scalar filespec, string scalar output_filename)
{
	string colvector filenames
	real scalar i
	real scalar output_fh
	filenames = sort(dir(".", "files", filespec),1)
	output_fh = fopen(output_filename, "w")
	for (i=1; i<=length(filenames); i++) {
		process_file(filenames[i], output_fh)
	}
	fclose(output_fh)
}
void process_file(string scalar filename, real scalar output_fh)
{
	struct myproblem scalar pr
	initialize_record(pr.fr)
	pr.output_fh = output_fh
	pr.fr.id = filename
	storetext(pr)
	output_record(pr)
}
void initialize_record(struct file_record scalar fr)
{
	fr.id = ""
	fr.text = ""
}
void storetext(struct myproblem scalar pr) 
{
	real scalar fh
	
	pr.fr.text = ""
	fh = fopen(pr.fr.id, "r")
		while ((pr.line=fget(fh))!=J(0,0,"")) {
				pr.fr.text = pr.fr.text + "\n" + pr.line 
			}
	fclose(fh)
	pr.fr.text = subinstr(pr.fr.text, `"""', "")
}
void output_record(struct myproblem scalar pr)
{
	fput(pr.output_fh, sprintf(`""%s" "%s""', pr.fr.id, pr.fr.text))
}
end 

//----------------------------------------------------------------------------//
// File paths to box folders 
//----------------------------------------------------------------------------//

global root "/Users/steffenerickson"
global raw "Box Sync/ECR Observation Data"
global transcripts1 "2023-2024 Final Data/transcripts"
global transcripts2 "2024-2025 Final Data/Research Assistants/24-25 Transcripts"
global output "Box Sync/mvgstudy_paper/output"

mkf transcripts1 
mkf transcripts2

//----------------------------------------------------------------------------//
// Import both years of transcripts 
//----------------------------------------------------------------------------//

forvalues i = 1/2 {
	
	cd "${root}/${raw}/${transcripts`i'}"
	capture erase "${root}/${output}/transcripts_freeformat_outputfile`i'.txt"
	mata: driver("*.txt","${root}/${output}/transcripts_freeformat_outputfile`i'.txt") // text processing function 
	frame transcripts`i': infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile`i'.txt"

}

//----------------------------------------------------------------------------//
// Append files and Clean 
//----------------------------------------------------------------------------//
frame copy transcripts1 transcripts , replace 
frame transcripts2: tempfile data
frame transcripts2: save `data'
frame transcripts {
	
	//append two years of data
	append using `data' , gen(year)
	label define y 0 "2324" 1 "2425"
	label values year y 
	
	replace filename = strtrim(filename)
	replace filename = subinstr(filename," ","",.)
	replace filename = subinstr(filename,"trancript.txt","",.)
	replace filename = subinstr(filename,"transcript(2).txt","",.)
	replace filename = subinstr(filename,"transcript..txt","",.)
	replace filename = subinstr(filename,"transcript.txt","",.)
	replace filename = subinstr(filename,"transcript2.txt","",.) 
	replace filename = subinstr(filename,"transcripts.txt","",.) 

	split filename , parse(_)
	replace filename5 = "part1" if filename5 == ""
	rename (filename?) (partnersite teacher grade lesson part) // rename with correct variable names 
	
	
}

frame change transcripts
save "${root}/${output}/transcriptsappended.dta" , replace 

	
	

	
	





