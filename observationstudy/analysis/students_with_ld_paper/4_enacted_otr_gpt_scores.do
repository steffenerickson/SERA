clear all
include "/Users/steffenerickson/Documents/GitHub/stata_programs/00_mvgstudy_v2/mvgstudy.ado"

mkf year1 
mkf year14
mkf year2 
mkf year24

frame year1 : use "/Users/steffenerickson/Box Sync/mvgstudy_paper/data/chatgptdata.dta", clear 
frame year1 :recast str2045  filename 
frame year14 : use "/Users/steffenerickson/Box Sync/mvgstudy_paper/data/chatgptdata_prompt4.dta" , clear 
frame year14 :recast str2045  filename 
frame year14 : tempfile data 
frame year14 : save `data'
frame year1 : merge 1:1 filename group using `data'

frame year2 : use "/Users/steffenerickson/Box Sync/mvgstudy_paper/data/chatgptdata2425.dta", clear 
frame year2 :recast str2045  filename 
frame year24 : use "/Users/steffenerickson/Box Sync/mvgstudy_paper/data/chatgptdata2425_prompt4.dta" , clear 
frame year24 :recast str2045  filename 
frame year24 : tempfile data 
frame year24 : save `data'
frame year2 : merge 1:1 filename group using `data'

frame change year1
frame year2 : tempfile data
frame year2 : save `data'
append using `data' , gen(year)
label values year .

replace filename = subinstr(filename,"_transcript.txt","",.)
replace filename = subinstr(filename,"transcript.txt","",.)
replace filename = subinstr(filename,"transcript .txt","",.)
replace filename = subinstr(filename,"_transcript (2).txt","",.)
replace filename = subinstr(filename,"_trancript.txt","",.)
replace filename = subinstr(filename,"_trancript.txt","",.)


split filename, parse(_)

replace filename4 = "L08" if filename == "09_0102_L08_part1"
replace filename3 = "G4" if filename == "09_0102_L08_part1"

replace filename4 = "L01" if filename == "11_0102_L01"
replace filename4 = "L02" if filename == "11_0102_L02"
replace filename3 = "GM" if filename == "11_0102_L01"
replace filename3 = "GM" if filename == "11_0102_L02"
replace filename5 = "part1" if filename5 == ""

gen teacher = filename1 + "_" + filename2 
gen obs  = teacher + "_"  + filename3 +  "_" + filename4
rename filename3 grade 
tempvar temp
gen `temp' = subinstr(filename4,"L","",.)
destring `temp' , gen(lesson)

encode filename5, gen(part)
rename group chunk 

sort teacher lesson part chunk year 
keep teacher lesson part chunk  score? obs grade year

collapse score? , by(lesson teacher obs grade year)

gen targetstudentparticipation = (score4 != .)

tab targetstudentparticipation

preserve
egen id = group(teacher grade)
collapse (sum) targetstudentparticipation (count) n = targetstudentparticipation, by(id)
gen percentparticipation = targetstudentparticipation / n

graph bar percentparticipation , over(id , sort(percentparticipation) label(labsize(tiny))) ///
ytitle("Target Student Presence (%)")  title("Percent of Transcripts Where Target Student Appears, by Teacher" , size(medium))

restore





keep if targetstudentparticipation == 1

rename score1 quality1 
rename score4 quality2 
rename score2 quality3 
rename score3 quality4 



qui sum quality1, det
local m1 = round(r(mean),.01)
qui sum quality2, det 
local m2 = round(r(mean),.01)
qui sum quality3, det 
local m3 = round(r(mean),.01)
qui sum quality4, det 
local m4 = round(r(mean),.01)
graph box quality* , /// 
	legend(order(1 "Overall student interest in the science lesson" ///
	2 "Target student interest in the science lesson"  ///
	3 "Overall discourse opportunities" ///
	4 "Overall teacher for scientific understanding" ///
	) rows(4) pos(6)) ///
	title("Distribution of GPT Quality Indicator Scores", size(medium)) name(g1, replace)  nooutsides  note("") ///
	ylabel(1(.5)5, nogrid angle(horizontal)) ///
	ytitle("Scale Score (1-5)")  text(`m1' 1 "`m1'") text(`m2' 25 "`m2'") text(`m3' 50 "`m3'") text(`m4' 75 "`m4'")






egen id = group(teacher grade)
collapse (percent) score4, by(id)









