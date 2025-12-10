//----------------------------------------------------------------------------//
// Removing nuisance strings from labels
//----------------------------------------------------------------------------//
 
//drop startdate-durationinseconds recordeddate-userlanguage q43 q47 q39
replace q14 = "science program/curriculum used during instruction" in 1
local remove1 "Please enter the following Opportunity to Respond (OTR) and Teacher Feedback codes as they are fo..."
local remove2 "Please enter the following Target Student codes as they are found on the 1st coded half-sheet of..."
local remove3 "Please enter the following Target Student codes as they are found on the 2nd coded half-sheet of..."
local remove4 "Please enter the following Target Student codes as they are found on the 3rd coded half-sheet of..."
local remove5 "Please enter the following Target Student codes as they are found on the 4th coded half-sheet of..."
local remove6 "Please enter the following ratings as they are found in the Overall Quality of Science Instruction section of the instrument. -"
local remove7 "(e.g., SERA Elementary School):"
local remove8 "Did this observation include interobserver agreement (or"
local remove9 ") assessment?"
local remove10 "Please enter the researcher's "
local remove11 "- Other (please specify) -"
local remove12 "(select all that apply):"
local remove14 "(24:00):"
local remove15 ":"
local remove16 "- If Other, please specify"
local remove17 " -"
local remove18 "-"
local remove20 "(select all that apply)? Selected Choice"
local remove21 "(select all that apply)?  Text"
local remove22 "(i.e., observable event)?"
local remove23 "(e.g., habitats, pollution, erosion, H20 on Earth)"
local remove24 "(s)"
local remove25 "(s)"

forvalues i = 1/25 {
	foreach v of var *{
		replace `v' = subinstr(`v', "`remove`i''", "",.) in 1
	}
}

forvalues i = 1/26 { 
	replace q371_`i' = q374_`i'_1 if  q371_`i' == ""
	replace q411_`i' = q414_`i'_1 if  q411_`i' == ""
	replace q451_`i' = q454_`i'_1 if  q451_`i' == ""
	replace q491_`i' = q494_`i'_1 if  q491_`i' == ""
	replace q531_`i' = q534_`i'_1 if  q531_`i' == ""
	
}

drop q374_*_1 q414_*_1 q454_*_1 q494_*_1 q534_*_1

foreach v of var * {
	local a = `v'[1]
	label variable `v' "`a'"
}
foreach v of var q36-q383_2_1 {
	local old : var label `v'
	local new = "`old'" + " 1"
	label var `v' "`new'"	
}
foreach v of var q40-q423_2_1 {
	local old : var label `v'
	local new = "`old'" + " 2"
	label var `v' "`new'"	
}
foreach v of var q44-q463_2_1 {
	local old : var label `v'
	local new = "`old'" + " 3"
	label var `v' "`new'"	
}
foreach v of var q48-q503_2_1 {
	local old : var label `v'
	local new = "`old'" + " 4"
	label var `v' "`new'"	
}
foreach v of var q51-q543_2_1 {
	local old : var label `v'
	local new = "`old'" + " 5"
	label var `v' "`new'"	
}

foreach v of var * {	
	local string : var label `v'
	if regexm("`string'", "\s+(OTR Type)\s+([A-Za-z]{1,2})\s+(\d+)") {
		local type       = regexs(1)
		local instance   = regexs(2)
		local session    = regexs(3)
		forvalues i = 1/26{
			local check2 = strpos("`instance'", "`:word `i' of `c(ALPHA)''") 
			if `check2' > 0  local second `i'
		}
		forvalues i = 1/5 {
			local check = strpos("`session'", "`i'") 
			if `check' > 0  local third `i'
		}
		local newstring = "a" + "_" + "`second'" + "_" +  "`third'"
		rename `v' `newstring'
	}
	else if regexm("`string'", "\s+(Teacher Feedback)\s+([A-Za-z]{1,2})\s+(\d+)") {
		local type       = regexs(1)
		local instance   = regexs(2)
		local session    = regexs(3)
		forvalues i = 1/26{
			local check2 = strpos("`instance'", "`:word `i' of `c(ALPHA)''") 
			if `check2' > 0  local second `i'
		}
		forvalues i = 1/5 {
			local check = strpos("`session'", "`i'") 
			if `check' > 0  local third `i'
		}
		local newstring = "b" + "_" + "`second'" + "_" +  "`third'"
		rename `v' `newstring'
	}
	else if regexm("`string'", "\s+(OTR Recipient)\s+([A-Za-z]{1,2})\s+(\d+)") {
		local type       = regexs(1)
		local instance   = regexs(2)
		local session    = regexs(3)
		forvalues i = 1/26{
			local check2 = strpos("`instance'", "`:word `i' of `c(ALPHA)''") 
			if `check2' > 0  local second `i'
		}
		forvalues i = 1/5 {
			local check = strpos("`session'", "`i'") 
			if `check' > 0  local third `i'
		}
		local newstring = "c" + "_" + "`second'" + "_" +  "`third'"
		rename `v' `newstring'
	}
}
local i = 1
foreach v of var finished-q35_4 {
	rename `v' i`i'
	local++i
}
local i = 1
foreach v of var q36 q381_1-q383_2_1 {
	rename `v' d`i'_1
	local++i
}
local i = 1
foreach v of var q40 q421_1-q423_2_1{
	rename `v' d`i'_2
	local++i
}
local i = 1
foreach v of var q44 q461_1-q463_2_1 {
	rename `v' d`i'_3
	local++i
}
local i = 1
foreach v of var q48 q501_1-q503_2_1 {
	rename `v' d`i'_4
	local++i
}
local i = 1
foreach v of var q52 q541_1-q543_2_1 {
	rename `v' d`i'_5
	local++i
}

drop in 1
drop if i1 == "False"

label variable i12 "partner site"

