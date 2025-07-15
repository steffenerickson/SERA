// ---------------------------------------------------------------------------//
// Split and Clean Transcript
// ---------------------------------------------------------------------------//

// Program to split text blocks into individual lines 
capture program drop splittext
program splittext, nclass 
	syntax varlist(max=1), Id(varlist) Regex(string)
	tempname hold data res 
	
	mkf `hold' 
	quietly {
		sort `id'
		egen id = group(`id')
		mata `data' = st_sdata(.,"`varlist'")	
		mata `res'  = splittext(`data',"`regex'") 
		frame `hold'{
			getmata (text id)  = `res'
			destring id , replace
			bysort id: gen linenum = _n
			tempfile expandedtext
			save `expandedtext'
		}
		
		drop `varlist'
		merge 1:m id using `expandedtext'
		drop _merge 
	}
end 

mata 
string matrix splittext(string matrix text, string scalar regex)
{
	string matrix temp1,temp2,res
	real scalar i 
	
	res = J(0,2,"")
	for (i=1;i<=rows(text);i++) {
		temp1 = ustrsplit(text[i],regex)'
		temp2 = temp1,J(rows(temp1),1,strofreal(i))
		res = res \ temp2
	}
	return(res) 
}
end 

// Split the text into lines 
splittext text, id(filename) regex(\\n)
drop if text == ""

// Keep only the transcript
gen match =  regexm(text, ".*?\s+\d{1,2}:\d{2}(:\d{2})?\s*$") //regexm(text,".*?\s+\d{1,2}:\d{2}\s*$")
bysort id: gen cum_match = sum(match)
drop if cum_match < 1
drop if text ==  "Transcribed by https://otter.ai"

// Move the speaker tag next to the lines (rather than having them stacked above)
gen speakertag = text if match == 1
bysort id cum_match: replace speakertag = speakertag[1] if speakertag == ""
keep if match == 0 
drop match cum_match linenum
bysort id: gen linenum = _n

// Bad way to split the speaker from the time stamp 
gen speaker = ""
gen timestamp = ""
qui desc
forvalues i = 1/`r(N)' {
	local obs = speakertag[`i']
	if regexm("`obs'", "^(.*)\s+(\d{1,2}:\d{2})\s*$") {
		qui replace speaker = regexs(1) in `i'
		qui replace timestamp  = regexs(2) in `i'
	}
}
drop speakertag 
gen time = clock(timestamp,"ms")
split filename , parse(_)
drop filename5 filename6
replace filename4 = substr(filename4,1,3)
gen teacher = filename1 + filename2
drop filename2 
rename (filename1 filename3 filename4) (site grade lessonnum)

*Mark Transcripts with a direct observation 
gen directobs = 0 
foreach file of global files {
	local  file2 `file'_transcript.txt
	replace directobs = 1 if filename == "`file2'"
}

tempvar temp 
gen `temp' = substr(lessonnum,2,.)
destring `temp', gen(lesson) force

gen directobsnum = . 
levelsof teacher, local(teachers)
foreach teacher of local teachers {
	qui sum lesson if teacher == "`teacher'" & directobs == 1
	qui replace directobsnum = 1 if teacher == "`teacher'" & directobs == 1 & lesson == r(min)
	qui replace directobsnum = 2 if teacher == "`teacher'" & directobs == 1 & lesson > r(min) & lesson < r(max)
	qui replace directobsnum = 3 if teacher == "`teacher'" & directobs == 1 & lesson == r(max)
}
replace directobsnum = 0 if missing(directobsnum)

tab directobsnum lesson if teacher == "040101" & directobsnum != 0

// need to filter out other adult speakers and random events 
replace speaker = lower(speaker)
replace speaker = strtrim(speaker)
replace speaker =  "teacher " + speaker if speaker == "02_0101"  
replace speaker =  "teacher " + speaker if speaker == "16_0101"  
replace speaker =  "teacher " + speaker if speaker == "16_0102" 
 
gen teachertalk = (strpos(speaker,"teacher") !=0 )
gen grouptalk = (strpos(speaker,"group") !=0 )
gen studenttalk = (strpos(speaker,"student") !=0)
gen targetstudenttalk = (strpos(speaker,"target student") !=0)
gen wholeclasstalk = (strpos(speaker,"whole class") !=0)

egen tot_teachertalk    = total(teachertalk), by(filename)  
egen tot_grouptalk      = total(grouptalk), by(filename)  
egen tot_studenttalk  = total(studenttalk), by(filename)  
egen tot_targetstudenttalk = total(targetstudenttalk) , by(filename)
egen tot_wholeclasstalk = total(wholeclasstalk) , by(filename)






