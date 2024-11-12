
//----------------------------------------------------------------------------//
// Config 
//----------------------------------------------------------------------------//

clear all 
frame reset 
global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy/calibration"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Resuts"
qui include ${programs}/mvgstudy.ado

use "${root}/${cleandata}/obsrubric24.dta" , clear 

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
// Collapse down to module x exercise totals 
//----------------------------------------------------------------------------//


keep i12 i13 i14 a b c exercise /*occurrence*/
foreach var in a b c {
	dummieswithlabels `var'
}
foreach var of varlist a_* b_* c_* {
	local `var'_label: variable label `var'
}
collapse (sum) a_* b_* c_*, by(i12 i13 i14 exercise /*occurrence*/)
foreach var of varlist a_* b_* c_* {
	label variable `var' "``var'_label'"
}
frame put * if i12 == "MASTER" , into(master_scores)
frame put * if i12 != "MASTER" , into(scores)
frame master_scores {
	drop i13 i12
	rename (a_* b_* c_*) (ma_* mb_* mc_*)
	tempfile data
	save `data'
}
frame scores {
	merge m:1 i14 exercise /*occurrence*/ using `data'
	foreach var of varlist a_* b_* c_*{
		gen diff_`var' = `var' - m`var'
	}
}

frame change scores 
drop diff_b_1


foreach var of varlist diff* {
	replace `var' = 0 if `var' == . & i14 != "Module 3"
}

replace i13 = "04" if i13 == ""
replace i12 = "University of Texas Austin" if i12 == ""


//order diff_a_2 diff_a_1 diff_a_3


//----------------------------------------------------------------------------//
// Report Program Code 
//----------------------------------------------------------------------------//

capture program drop get_phrases
program get_phrases , rclass 

	syntax , Matrix(string)
	
	local colnames : colfullnames scores 
	local count = 0 
	forvalues i = 1/`:rowsof(`matrix')' {
		forvalues j = 1/`:colsof(`matrix')' {
			local word `:word `j' of `colnames''
			// type
			if "`word'" == "diff_a_1" local subtasks "hands on"
			if "`word'" == "diff_a_2" local subtasks "verbal"
			if "`word'" == "diff_a_3" local subtasks "written"
			if "`word'" == "diff_b_2" local subtasks "teacher feedback"
			if "`word'" == "diff_c_1" local subtasks "nontarget student"
			if "`word'" == "diff_c_2" local subtasks "target and nontarget student"
			if "`word'" == "diff_c_3" local subtasks "target student"
			// category 
			local identify = substr("`word'",6,1)
			if "`identify'" == "a" local category "OTR Type"
			if "`identify'" == "b" local category "Teacher Feedback to OTR"
			if "`identify'" == "c" local category "OTR Recipient"
			// over under 
			if `matrix'[`i',`j'] > 0 local misstype "overcounted"
			if `matrix'[`i',`j'] < 0 local misstype "undercounted"
			// count value
			local num = abs(scores[`i',`j'])
			// create phrase if there is a miss 
			if `matrix'[`i',`j'] != 0 {
				// Phrase that will appear if there is a miss 
				local++count
				local phrase  In exercise `i', you `misstype' the number of `subtasks' instances in the `category' category by `num'
				return local phrase`count' `phrase'
			}
		} 
	} 
	return scalar count = `count'
end 

capture program drop get_report
program get_report , nclass 
	syntax varlist [if] , DOCument(string)
	
	// variable names for display 
	local displaynames hands_on verbal written teacher_feeback nontarget target_nontarget target
	// sub if statement for use later 
	tokenize `varlist'	
	local pos = strpos(`"`if'"',"&")
	local subif = substr(`"`if'"',1,`pos'-1) + "& `1' != . "	
	// grab ID info
	preserve 
	keep `if'
	local partner = i12[1] 
	local id = i13[1] 
	if i14 == "Module 1" local num 1 
	if i14 == "Module 2" local num 2 
	if i14 == "Module 3" local num 3 
	restore 
	
	// start the document
	putdocx clear
	putdocx begin 
	putdocx paragraph, style(Title)
	putdocx text ("Crowdsource Science Observations (CSO) Calibration Module Report") , bold 
	
	// Print ID info
	putdocx paragraph
	putdocx text ("Partner Site Name: `partner' ") 
	putdocx paragraph
	putdocx text ("Observer ID: `id' ") 
	putdocx paragraph
	putdocx text ("Calibration Report:  `num'/3") 

	// Session Level info 
	putdocx paragraph, style(Heading1)
	putdocx text ("Current Module Performance") , bold 
	putdocx paragraph
	putdocx text ("The numbers in the table below indicate the difference between your scores and master scores. Negative values suggest you undercounted compared to the master score, while positive values suggest you overcounted.") 
		
    preserve
    rename (`varlist') (`displaynames')
    putdocx table data = data(exercise `displaynames') `if' , varnames title("Current Module Performance") note("Agreement: cell = 0 , Undercounted: cell < 0 , Overcounted: cell > 0" ) 
    restore
	
	mkmat `varlist' `if' , matrix(scores) rownames(exercise)
	get_phrases, m(scores)
	putdocx paragraph , style(Heading3)
	putdocx text ("Current Module Miscounts:") 
	if `r(count)' == 0 {
		putdocx paragraph 
		putdocx text ("None, great work!") 
	}
	else {
		forvalues i = 1/`r(count)' {
			putdocx paragraph 
			putdocx text ("`r(phrase`i')'") 
		}
	}
	
	// full table - displays starting on module 2
	if strpos(`"`if'"',"Module 1") == 0 {	
		putdocx paragraph , style(Heading1)
		putdocx text ("Historic Module Performance") 
		putdocx paragraph
		putdocx text ("The numbers in the table below indicate the difference between your scores and master scores for each activity you have completed so far.") 
		preserve
		rename (`varlist') (`displaynames')
		tokenize `displaynames'	
		local pos = strpos(`"`if'"',"&")
		local subif2 = substr(`"`if'"',1,`pos'-1) + "& `1' != . "	
		putdocx table data = data(exercise `displaynames') `subif2' , varnames title("Historic Performance") note("Agreement: cell = 0 , Undercounted: cell < 0 , Overcounted: cell > 0" ) 
		restore
	}
	
	// average miscounts  
	putdocx paragraph, style(Heading1)
	putdocx text ("Average Performance") , bold 
	putdocx paragraph
	putdocx text ( "The numbers in the table below indicate the AVERAGE difference between your scores and master scores for the activities you have completed so far. If the cell values are greater than one, you tend to overcount OTR behaviors. If the cell values are less than negative one, you tend to undercount.")
	preserve
	keep `subif'
	collapse `varlist' , by(i13)
	rename (`varlist') (`displaynames')	
	putdocx table data = data(`displaynames') , varnames title("Average Performance") note("Keep doing what you're doing!: -1 < cell < 1 , Tend to undercount: cell <= 1 , Tend to overcount: cell >= 1" ) 
	restore
	
	putdocx paragraph, style(Heading1)
	putdocx text ("Reminders") , bold 
	putdocx paragraph
	putdocx text ("An OTR must be academic in nature and paired with an overt student response.")
	putdocx text (" Students watching a video or reading silently should not be scored.") , italic 
	putdocx paragraph
	putdocx text ("Teacher feedback must be academic in nature and directed at the Target Student.")
	putdocx text (" Whole class feedback should not be scored.") , italic 
	
	putdocx save "`document'", replace
end 




get_report diff_* if i13 == "04" & i14 == "Module 1" , doc(module1)
get_report diff_* if i13 == "04" & i14 == "Module 2" , doc(module2)
