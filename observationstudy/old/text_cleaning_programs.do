
clear
infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile.txt"


// ---------------------------------------------------------------------------//

// ---------------------------------------------------------------------------//

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
		temp1 = ustrsplit(text[i],"\\n")'
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




gen match = regexm(speakertag, "^(.*)\s+(\d{1,2}:\d{2})\s*$")
replace person = regexs(1) if match
replace time = regexs(2) if match

ge

if regexm(speakertag, "^(.*)\s+(\d{1,2}:\d{2})\s*$") {
	replace person = regexs(1)
	replace time = regexs(2)
}



split speakertag, parse("")






drop startspeaking






drop id

mata data = st_sdata(.,"text")	
mata res = splittext(data,"\\n") 
mkf hold 
frame hold : getmata (x*)  = res



		temp =  ustrsplit(text[i],"\\n")

mata res = J(0,1,"")
mata cols(res)

