
//----------------------------------------------------------------------------//
// Config
//----------------------------------------------------------------------------//
clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data"
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata24 "2023-2024 Final Data/Quant Team - Clean Data"
global cleandata25 "2024-2025 Final Data/Quant Team - Clean Data"
global results "Quant Team - Results"

//----------------------------------------------------------------------------//
// Programs
//----------------------------------------------------------------------------//

include ${programs}/mvgstudy.ado

capture program drop dummieswithlabels
program dummieswithlabels, nclass 
	syntax varlist(max=1)
	capture drop `varlist'_*
	qui tab `varlist', gen(`varlist'_)
	local vlname: value label `varlist'
	qui levelsof `varlist' , local(list)
	local i = 1 
	foreach x of local list1 {
		local label`x': `:label `vlname' `x''
		label variable `varlist'`i' `label'`x'
		local++i 
	}
end 

//----------------------------------------------------------------------------//
// Append the two datasets 
//----------------------------------------------------------------------------//

* There is an extra variable in the first dataset (need to remove so that the columns are aligned)
mkf obs24
mkf obs25
frame obs24: use "${root}/${cleandata24}/obsrubric2324.dta" 
frame obs25: use "${root}/${cleandata25}/obsrubric2425.dta" 

foreach x in 24 25 {
	frame obs`x' {
		mata res`x' = J(0,2,"")
		foreach var of varlist * {
			local a  "`var'"
			local b "`:variable label `var''"
			mata a = st_local("a")
			mata b = st_local("b")
			mata res`x' = res`x' \ (a,b)
		}
		}
}

mkf comparedata
	frame comparedata {
	getmata (name1 label1) = res24
	getmata (name2 label2) = res25, force
	list
}
frame drop comparedata
frame obs24 {
	drop i18
	forvalues x = 19/51 {
		local y = `x' - 1
		rename i`x' i`y'
	}
}

frame copy obs24 all, replace
frame obs25: tempfile data 
frame obs25: save `data'
frame all: append using `data' , gen(year)

//----------------------------------------------------------------------------//
// Additional Cleaning 
//----------------------------------------------------------------------------//

frame change all 
label define years 0 "23-24" 1 "24-25"
label values year years 

drop id 
egen teachid = group(i12 i14 i15 year)

keep teachid year i13 i12 i13 i16 i17 i20 i23 i24 i26 i30 i32 i38 a b c i47 i48 i49 i50

rename i12 partnerid 
rename i13 observerid 
rename i16 targetstuid
rename i17 obsround
rename i20 lessontime 
rename i23 numstudents 
rename i24 curriculum   
rename i26 lessontheme 
rename i30 instructformat  
rename i32 instructtypes 
rename a   otr_type
rename b   otr_teachfeedback
rename c   otr_recipient
rename i47 quality1  
rename i48 quality2  
rename i49 quality3 
rename i50 quality4 

global byvars teachid year partnerid observerid obsround
global otrvars otr_type otr_teachfeedback otr_recipient
global qualityvars  quality1 quality2 quality3 quality4 
global descriptors_string curriculum  lessontheme instructformat instructtypes 
global descriptors_numeric lessontime numstudents 

foreach var in $otrvars {
	dummieswithlabels `var'
}
destring $descriptors_numeric $qualityvars , replace


//----------------------------------------------------------------------------//
// OTRs for LD versus OTR counts for non LD (exlcuding group responses)
//----------------------------------------------------------------------------//


frame copy all plot1 , replace
frame plot1 {
	
	keep if otr_type == 5 // keep only the verbal otrs
	keep if otr_recipient  == 1 |  otr_recipient  == 3
	
	// Collapse to totals (teacher x lesson x observer)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
		local `var'_label: variable label `var'
	}
	collapse (sum) otr_*_* (mean) $descriptors_numeric $qualityvars  (firstnm) $descriptors_string , by($byvars)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
		label variable `var' "``var'_label'"
	}
	
	// Collapse to averages (teacher x lesson)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
		local `var'_label: variable label `var'
	}
	collapse (mean) otr_*_*  $descriptors_numeric $qualityvars (firstnm) $descriptors_string , by(year obsround teachid)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
		label variable `var' "``var'_label'"
	}

	drop otr_recipient_1
	forvalues i = 2/4 {
		gen otr_recipient_`i'_permin = otr_recipient_`i'/ lessontime 
	}
	
	gen otr_recipient_2_perstudent =  otr_recipient_2 / (numstudents  - 1)
	
	qui sum otr_recipient_2, det
	local m1 = round(r(p50),.01)
	qui sum otr_recipient_4, det 
	local m2 = round(r(p50),.01)
	qui sum otr_recipient_2_perstudent, det 
	local m3 = round(r(p50),.01)
	
	graph box otr_recipient_2 /*otr_recipient_3*/ otr_recipient_4, /// 
		legend(order(1 "Non-Target Student" 2 /* "Group Response"  3 */ "Target Student") rows(3) pos(6)) ///
		ylabel(0(5)80, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") ///
		title("Total Recieved by any Non-Target Student vs. Target Student", size(small)) ///
		name(g1, replace) nooutsides note("") text(`m1' 1 "`m1'") text(`m2' 50 "`m2'")
	graph box otr_recipient_2_perstudent otr_recipient_4, /// 
		legend(order(1 "Average number per Non-Target"2 "Target Student") rows(2) pos(6)) ///
		ylabel(0(1)10, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") ///
		title("Average Per Non-Target Student vs. Target Student ", size(small)) ///
		name(g3, replace) nooutsides note("") text(`m3' 1 "`m3'") text(`m2' 50 "`m2'")
	graph combine g1 g3, altshrink rows(1) ///
		title("Verbal OTRs per Lesson by Recipient (Group Responses Excluded)", size(medium))
}

//----------------------------------------------------------------------------//
// OTRs for LD versus OTR counts for non LD (adding in the group responses)
//----------------------------------------------------------------------------//


frame copy all plot2 , replace
frame plot2 {
	

	keep if otr_type == 5 // keep only the verbal otrs
	keep if otr_recipient  == 1 |  otr_recipient  == 3 | otr_recipient == 2
	
		
	replace otr_recipient_2 = otr_recipient_2 + otr_recipient_3
	replace otr_recipient_4 = otr_recipient_4 + otr_recipient_3
	
	
	
	// Collapse to totals (teacher x lesson x observer)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
		local `var'_label: variable label `var'
	}
	collapse (sum) otr_*_* (mean) $descriptors_numeric $qualityvars  (firstnm) $descriptors_string , by($byvars)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
		label variable `var' "``var'_label'"
	}
	
	// Collapse to averages (teacher x lesson)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
		local `var'_label: variable label `var'
	}
	collapse (mean) otr_*_*  $descriptors_numeric $qualityvars (firstnm) $descriptors_string , by(year obsround teachid)
	foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
		label variable `var' "``var'_label'"
	}

	drop otr_recipient_1
	forvalues i = 2/4 {
		gen otr_recipient_`i'_permin = otr_recipient_`i'/ lessontime 
	}
	
	gen otr_recipient_2_perstudent =  otr_recipient_2 / (numstudents  - 1)
	
	qui sum otr_recipient_2, det
	local m1 = round(r(p50),.01)
	qui sum otr_recipient_4, det 
	local m2 = round(r(p50),.01)
	qui sum otr_recipient_2_perstudent, det 
	local m3 = round(r(p50),.01)
	
	graph box otr_recipient_2 /*otr_recipient_3*/ otr_recipient_4, /// 
		legend(order(1 "Non-Target Student" 2 /* "Group Response"  3 */ "Target Student") rows(3) pos(6)) ///
		ylabel(0(5)80, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") ///
		title("Total Recieved by any Non-Target Student vs. Target Student", size(small)) ///
		name(g1, replace) nooutsides note("") text(`m1' 1 "`m1'") text(`m2' 50 "`m2'")
	graph box otr_recipient_2_perstudent otr_recipient_4, /// 
		legend(order(1 "Average number per Non-Target"2 "Target Student") rows(2) pos(6)) ///
		ylabel(0(1)10, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") ///
		title("Average Per Non-Target Student vs. Target Student ", size(small)) ///
		name(g3, replace) nooutsides note("") text(`m3' 1 "`m3'") text(`m2' 50 "`m2'")
	graph combine g1 g3, altshrink rows(1) ///
		title("Verbal OTRs per Lesson by Recipient (Group Responses Included)", size(medium))
}



//----------------------------------------------------------------------------//
// Percent of lessons including 
//----------------------------------------------------------------------------//



frame copy all plot3 , replace
frame plot3 {
	
	collapse (max) otr_type_1 otr_type_5 otr_type_3 otr_type_4 otr_type_6 , by(year obsround teachid)
	
	
	graph hbar otr_type_5 otr_type_1 otr_type_3 otr_type_4 otr_type_6 , ///
		blabel(bar, format(%9.2f)) bargap(5) ///
		bar(1, color(red) fintensity(20)) ///
		bar(2, color(green) fintensity(20)) ///
		bar(3, color(purple) fintensity(20)) ///
		bar(4, color(yellow) fintensity(20)) ///
		bar(5, color(orange) fintensity(20)) ///
		legend(order(1 "Verbal" 2 "Hands on Activity" 3  "Physical Gesture " 4 "Reading" 5 "Writing or Drawing ") rows(1) pos(6)) ///
		title("Percent of Lessons with  OTR Types") ytitle("Percent")

}

//----------------------------------------------------------------------------//
// Types of OTRs for LD versus OTR counts for non LD 
//----------------------------------------------------------------------------//

frame copy all plot4 , replace
frame plot4 {
	drop if otr_recipient == 0
	
	drop otr_type otr_teachfeedback otr_teachfeedback_* otr_recipient_*
	
	// Collapse to totals (teacher x lesson x observer)
	foreach var of varlist otr_type_*  {
		local `var'_label: variable label `var'
	}
	collapse (sum) otr_type_* , by($byvars otr_recipient)
	foreach var of varlist otr_type_* {
		label variable `var' "``var'_label'"
	}
	
	// Collapse to averages (teacher x lesson)
	foreach var of varlist otr_type_* {
		local `var'_label: variable label `var'
	}
	collapse (mean) otr_type_* , by(year obsround teachid otr_recipient)
	foreach var of varlist otr_type_*   {
		label variable `var' "``var'_label'"
	}
	
	drop otr_type_2
	
	graph box otr_type_* if otr_recipient == 1, /// 
		legend(order(1 "Hands on Activity" 2 "Physical Gesture" 3 "Read" 4 "Verbal" 5 "Write/Draw" ) rows(1) pos(6)) ///
		title("Non-Target Student", size(medium)) name(g1, replace)  nooutsides  note("") ///
		ylabel(0(5)60, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") 
	graph box otr_type_* if otr_recipient == 2, /// 
		legend(order(1 "Hands on Activity" 2 "Physical Gesture" 3 "Read" 4 "Verbal" 5 "Write/Draw") rows(1) pos(6)) ///
		title("Group Response", size(medium)) name(g2, replace) nooutsides note("") ///
		ylabel(0(5)60, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") 
	
	graph box otr_type_* if otr_recipient == 3, /// 
		legend(order(1 "Hands on Activity" 2 "Physical Gesture" 3 "Read" 4 "Verbal" 5 "Write/Draw" ) rows(1) pos(6)) ///
		title("Target Student", size(medium)) name(g3, replace) nooutsides note("") ///
		ylabel(0(5)60, nogrid angle(horizontal)) ///
		ytitle("Number of OTRs") 
	
	grc1leg2 g1 g2 g3 , ycommon altshrink rows(1) title("Types of OTRs by Recipient", size(medium))

}

//----------------------------------------------------------------------------//
// Quality Indicators 
//----------------------------------------------------------------------------//


frame copy all plot5 , replace
frame plot5 {

	foreach var of varlist quality*   {
		local `var'_label: variable label `var'
	}
	collapse quality*, by(year obsround teachid)
	foreach var of varlist quality* {
		label variable `var' "``var'_label'"
	}
	
	qui sum quality1, det
	local m1 = round(r(p50),.01)
	qui sum quality2, det 
	local m2 = round(r(p50),.01)
	qui sum quality3, det 
	local m3 = round(r(p50),.01)
	qui sum quality4, det 
	local m4 = round(r(p50),.01)
	graph box quality* , /// 
		legend(order(1 "Overall student interest in the science lesson" ///
		2 "Target student interest in the science lesson"  ///
		3 "Overall discourse opportunities" ///
		4 "Overall teacher for scientific understanding" ///
		) rows(4) pos(6)) ///
		title("Distribution of Quality Indicator Scores", size(medium)) name(g1, replace)  nooutsides  note("") ///
		ylabel(1(.5)5, nogrid angle(horizontal)) ///
		ytitle("Scale Score (1-5)")  text(`m1' 1 "`m1'") text(`m2' 25 "`m2'") text(`m3' 50 "`m3'") text(`m4' 75 "`m4'")
}

/*
frame copy all plot3 , replace
frame plot3 {
	drop if otr_recipient == 0
	
	drop otr_type otr_teachfeedback otr_teachfeedback_* otr_recipient_*
	
	// Collapse to totals (teacher x lesson x observer)
	foreach var of varlist otr_type_* quality* {
		local `var'_label: variable label `var'
	}
	collapse (sum) otr_type_* (mean) quality*, by($byvars )
	foreach var of varlist otr_type_* {
		label variable `var' "``var'_label'"
	}
	
	// Collapse to averages (teacher x lesson)
	foreach var of varlist otr_type_* quality*{
		local `var'_label: variable label `var'
	}
	collapse (mean) otr_type_* quality* , by(year obsround teachid)
	foreach var of varlist otr_type_*   {
		label variable `var' "``var'_label'"
	}
	
	drop otr_type_2
	
	egen quality = rowmean(quality*)
	egen qualitybins = cut(quality) , group(6) icodes

	forvalues i = 0/5 {
		graph box otr_type_* if qualitybins == `i', /// 
			legend(order(1 "Hands on Activity" 2 "Physical Gesture" 3 "Read" 4 "Verbal" 5 "Write/Draw" ) rows(1) pos(6)) ///
			title("Non-Target Student", size(medium)) name(g`i', replace)  nooutsides  note("") ///
			ylabel(0(5)60, nogrid angle(horizontal)) ///
			ytitle("Number of OTRs") 
	}
	
	grc1leg2 g0 g1 g2 g3 g4 g5, ycommon altshrink rows(1) title("Types of OTRs by Recipient", size(medium)) 
}
*/

drop otr_recipient_1 


// Collapse to totals (teacher x lesson x observer)
foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
	local `var'_label: variable label `var'
}
collapse (sum) otr_*_* (mean) $descriptors_numeric $qualityvars  (firstnm) $descriptors_string , by($byvars)
foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
	label variable `var' "``var'_label'"
}

// Collapse to averages (teacher x lesson)
foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars {
	local `var'_label: variable label `var'
}
collapse (mean) otr_*_*  $descriptors_numeric $qualityvars (firstnm) $descriptors_string , by(year obsround teachid)
foreach var of varlist otr_*_* $descriptors_numeric $descriptors_string $qualityvars  {
	label variable `var' "``var'_label'"
}

// Classify Science Topics 
gen topic_group = ""
* Earth & Space Science
replace topic_group = "Earth & Space Science" if regexm(lessontheme , "(?i)earth|moon|weather|climate|water cycle|astronomy|space|night sky|rotation|seasons|geosphere|tectonic")
* Life Science
replace topic_group = "Life Science" if regexm(lessontheme , "(?i)plant|animal|ecosystem|food web|food chain|camouflage|adaptation|senses|instinct|decomposition|living")
* Physical Science: Matter & Energy
replace topic_group = "Physical Science: Matter & Energy" if regexm(lessontheme , "(?i)energy|force|motion|light|sound|vibration|waves|electric|circuit|power|heat")
* Chemistry
replace topic_group = "Chemistry" if regexm(lessontheme , "(?i)chemical|solution|mixture|matter|particles|density|acid")
* Human Body & Life Systems
replace topic_group = "Human Body & Life Systems" if regexm(lessontheme , "(?i)digestive|body|muscle|bone|biceps|structure and function|vision")
* Geology & Fossils
replace topic_group = "Geology & Fossils" if regexm(lessontheme , "(?i)rock|fossil|sediment|earthquake|geology")
* Scientific Practices & Models
replace topic_group = "Scientific Practices & Models" if regexm(lessontheme , "(?i)model|black box|scale|measurement|pre-test|standard units")
* Artifacts & History
replace topic_group = "Artifacts & History" if regexm(lessontheme , "(?i)artifact|indigenous")
* Review/Assessment
replace topic_group = "Review/Assessment" if regexm(lessontheme , "(?i)review|prep|test")
* Other
replace topic_group = "Other / Interdisciplinary / Unclear" if topic_group == ""




// Step 1: Clean the string
gen curriculum_clean = lower(trim(curriculum))

// Step 2: Create grouped curriculum variable
gen curriculum_group = ""

replace curriculum_group = "Amplify"          if regexm(curriculum_clean, "amplify")
replace curriculum_group = "Mystery Science"  if regexm(curriculum_clean, "mystery")
replace curriculum_group = "BOCES 4 Science"  if regexm(curriculum_clean, "boces")
replace curriculum_group = "FOSS"             if regexm(curriculum_clean, "foss")
replace curriculum_group = "Generation Genius" if regexm(curriculum_clean, "generation genius")
replace curriculum_group = "Go2 Science"      if regexm(curriculum_clean, "go2")
replace curriculum_group = "District-Created" if regexm(curriculum_clean, "district")
replace curriculum_group = "STEMScopes"       if regexm(curriculum_clean, "stemscopes|stem scopes")
replace curriculum_group = "Science Penguin"  if regexm(curriculum_clean, "penguin")
replace curriculum_group = "Explore Learning Gizmos" if regexm(curriculum_clean, "gizmo")
replace curriculum_group = "OpenSciEd"        if regexm(curriculum_clean, "open scied|open sci-ed")
replace curriculum_group = "Rock by Rock"     if regexm(curriculum_clean, "rock by rock")
replace curriculum_group = "PHET Simulations" if regexm(curriculum_clean, "phet")
replace curriculum_group = "PLTW"             if regexm(curriculum_clean, "pltw")
replace curriculum_group = "Seed Storylines"  if regexm(curriculum_clean, "seed storylines|seedstorylines")
replace curriculum_group = "Unrecognizable"   if regexm(curriculum_clean, "unrecognizable|unknown|state testing|mixtures and solutions|snaps|series and parallel circuits")

// For any remaining uncategorized entries
replace curriculum_group = "Other/Uncategorized" if missing(curriculum_group)

encode curriculum_group , gen(curriculum_group_cat)


encode topic_group, gen(topic)
encode instructformat, gen(instruct)
egen otr_total = rowtotal(otr_recipient_*)
egen quality = rowmean(quality*)
gen qualitybin = 1 if quality < 2
replace qualitybin = 2 if quality >= 2 & quality < 3
replace qualitybin = 3 if quality >= 3 & quality < 4
replace qualitybin = 4 if quality >= 4 & quality < 5
egen numstudents_cat = cut(numstudents) , group(6)
label define numstudentslabel 0 "students < 15" 1 "15 <= students < 18" 2 "18 <= students < 20" 3 "20 <= students < 22" 4 "22 <= students < 24" 5 "students > 24"
label values numstudents_cat numstudentslabel


regress otr_total  i.topic
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox  otr_recipient_*, over(topic) ///
    title("OTRs by Lesson Topic") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) nooutsides 
	
tab topic

regress otr_total i.qualitybin
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_recipient_*, over(qualitybin) ///
    title("OTRs by Quality Bins") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) nooutsides 
	
tab qualitybin


regress otr_total  i.numstudents_cat
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_recipient_*, over(numstudents_cat) ///
    title("OTRs by Number of Students") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) nooutsides 
	
tab numstudents_cat
	
regress otr_total i.instruct
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_recipient_*, over(instruct) ///
    title("OTRs by Instructional Format") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) nooutsides 

tab instruct

regress otr_total i.curriculum_group_cat 
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_recipient_*, over(curriculum_group_cat) ///
    title("OTRs by Curriculum") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) nooutsides 
	
	
tab curriculum_group_cat 	




regress quality i.numstudents_cat
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbar quality, over(numstudents_cat) ///
    title("OTRs by Curriculum") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "NonTarget" 2 "Group" 3 "Target") rows(1) position(6) ring(1)) 
	




anova otr_total curriculum_group_cat instruct qualitybin topic numstudents_cat
	

/*
regress otr_recipient_4  i.topic
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox  otr_total otr_recipient_*, over(topic) ///
    title("OTRs by Lesson Topic") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "Total" 2 "NonTarget" 3 "Group" 4 "Target") rows(1) position(6) ring(1)) nooutsides 
	
	

regress otr_recipient_4  i.qualitybin
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_total otr_recipient_*, over(qualitybin) ///
    title("OTRs by Quality Bins") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "Total" 2 "NonTarget" 3 "Group" 4 "Target") rows(1) position(6) ring(1)) nooutsides 
	
regress otr_recipient_4  i.numstudents_cat
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_total otr_recipient_*, over(numstudents_cat) ///
    title("OTRs by Number of Students") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "Total" 2 "NonTarget" 3 "Group" 4 "Target") rows(1) position(6) ring(1)) nooutsides 
	

	
regress otr_recipient_4 i.instruct
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbox otr_total otr_recipient_*, over(instruct) ///
    title("OTRs by Instructional Format") ///
    note("Joint F stat = `F', pval = `p'") ///
    ytitle("Average Number of OTRs") ///
    legend(order(1 "Total" 2 "NonTarget" 3 "Group" 4 "Target") rows(1) position(6) ring(1)) nooutsides 
	
	
	
	
	
	
	
	
	
	

regress otr_total i.numstudents_cat
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbar otr_total otr_recipient_*, over(numstudents_cat) title("OTRs by Instructional Format")  note("Joint F stat = `F', pval = `p'") ytitle("Average Number of OTRs")





regress otr_total i.instruct
mat a =  e(beta)
local coefs : colfullnames a 
test `coefs'
local F = round(r(F), 0.01)
local p = round(r(p), 0.01)
graph hbar otr_total otr_recipient_*, over(instruct) title("OTRs by Number of Student")  note("Joint F stat = `F', pval = `p'") ytitle("Average Number of OTRs")






graph hbar otr_total, over(topic) title("OTRs by Quality Scores")





regress otr_total i.topic
regress otr_total quality4

graph hbar otr_total, over(topic)




foreach i of local topiclist {
	qui {
	graph box otr_recipient_2 otr_recipient_3 otr_recipient_4 if `topic' == `i', /// 
		legend(order(1 "Non-Target Student" 2 "Group Response" 3 "Target Student") rows(3) pos(6)) ///
		ylabel(0(5)80,angle(horizontal)) ///
		ytitle("Number of OTRs") ///
		title("Quality Bin `i'", size(medium)) ///
		name(g`i', replace) nooutsides note("")
	}
	local g g`i'
	local graphlist : list graphlist | g
}

grc1leg2 `graphlist', ycommon altshrink rows(1) title("Types of OTRs by Recipient", size(medium)) 









