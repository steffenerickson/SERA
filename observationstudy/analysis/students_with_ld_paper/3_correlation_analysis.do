
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






corr quality* otr_type_1 otr_type_3 otr_type_4 otr_type_5 otr_type_6 otr_recipient_2 otr_recipient_3 otr_recipient_4 lessontime numstudents
mat m1 = r(C)

heatplot m1, lower values(format(%9.1f)) colors(hcl diverging, intensity(.6)) legend(off) aspectratio(1) ylabel(,nogrid angle(50) labsize(small)) xlabel(,nogrid angle(50) labsize(small)) title("Grade 1") name(g1, replace) 
















