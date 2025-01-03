clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"
qui include ${programs}/mvgstudy.ado
use "${root}/${cleandata}/obsrubric.dta" , clear 


label define who 0 "Not Labeled" 1 "Non-Target Student" 2 "Both" 3 "Target Student"
label values c who

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

destring i48 i49 i50 i51 , replace 

keep i12 i13 i14 i15 i16 i17 i18 i19 i20 i21 i24 a b c i48 i49 i50 i51 
foreach var in a b c {
	dummieswithlabels `var'
}
	
foreach var of varlist a_* b_* c_* {
	local `var'_label: variable label `var'
}
collapse (sum) a_* b_* c_* (mean) i48 i49 i50 i51, by(i12 i13 i14 i15 i16 i17 i18 i19 i20 i21 i24)
foreach var of varlist a_* b_* c_* {
	label variable `var' "``var'_label'"
}

egen teacher = group(i15 i12)
destring i17, gen(obsround)
egen teacherround = group(teacher obsround)

preserve
keep teacher obsround i12 i14 i21 i24
egen dupes = tag(teacher obsround)
keep if dupes == 1
drop dupes 
tempfile data 
save `data'
restore 

foreach var of varlist a_* b_* c_* {
	local `var'_label: variable label `var'
}
collapse a_* b_* c_* i48 i49 i50 i51, by(teacher obsround)
foreach var of varlist a_* b_* c_* {
	label variable `var' "``var'_label'"
}
merge 1:1 teacher obsround using `data'
drop _merge 
foreach var of varlist a_* b_* c_* {
	local pos = strpos("`:variable label `var''","=")
	local newlabel = substr("`:variable label `var''", `pos' + 2, .)
	label variable `var' "`newlabel'"
}
foreach var of varlist a_* b_* c_*  {
	replace `var' = round(`var',1)
}

destring i21 , gen(minutes) force
destring i24 , gen(numstudents) force
replace i14 = "provident charter west" if i14 != "provident charter central" & i12 ==  "University of Pittsburgh"

egen quality = rowmean(i48 i49 i50 i51)
egen otrtotal = rowtotal(c_1 c_2 c_3 c_4)
label variable otrtotal "Total OTRs"
label variable c_4  "OTRs to Target"
label variable quality "Quality Score"
label variable i48 "Overall Student Tnterest"
label variable i49 "Target Student Interest"
label variable i50 "Discourse Opportunities"
label variable i51 "Scientific Understanding"

// ------------------------//
// OTRS
// ------------------------//

cap matrix drop res
foreach var of varlist a_* otrtotal c_4 quality {
	tempname mat1 mat2 
	levelsof(teacher) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if teacher == `i'
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "Teacher `i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res = (nullmat(res), `mat2')
		
}
cap matrix drop avgs
foreach var of varlist a_* otrtotal c_4 quality {
	sum `var'
	mat avgs = (nullmat(avgs), r(mean))
}
mat rownames avgs = "Average"
mat res = res \ avgs

cap matrix drop sds
foreach var of varlist a_* otrtotal c_4 quality {
	sum `var'
	mat sds = (nullmat(sds), r(sd))
}
mat rownames sds = "Standard Deviation"
mat res = res \ sds

cap matrix drop corrs
foreach var of varlist a_* otrtotal c_4 {
	corr `var' quality
	mat corrs = (nullmat(corrs), r(rho))
}
mat corrs = corrs ,. 
mat rownames corrs = "Quality Correlation"
mat res = res \ corrs
mat res1 = res 


// ------------------------//
// Quality 
// ------------------------//
cap matrix drop res
foreach var of varlist i48 i49 i50 i51 quality otrtotal {
	tempname mat1 mat2 
	levelsof(teacher) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if teacher == `i'
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "Teacher `i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res = (nullmat(res), `mat2')
		
}
cap matrix drop avgs
foreach var of varlist i48 i49 i50 i51 quality otrtotal {
	sum `var'
	mat avgs = (nullmat(avgs), r(mean))
}
mat rownames avgs = "Average"
mat res = res \ avgs

cap matrix drop sds
foreach var of varlist i48 i49 i50 i51 quality otrtotal {
	sum `var'
	mat sds = (nullmat(sds), r(sd))
}
mat rownames sds = "Standard Deviation"
mat res = res \ sds

cap matrix drop corrs
foreach var of varlist i48 i49 i50 i51 quality {
	corr `var' otrtotal
	mat corrs = (nullmat(corrs), r(rho))
}
mat corrs = corrs ,. 
mat rownames corrs = "Total OTR Correlation"
mat res = res \ corrs
mat res2 = res 


frmttable,statmat(res1) title("Average Types and Recipients of Opportunities to Respond by Teacher") 


frmttable,statmat(res2) title("Quality Scores by Teacher") 


















/*

cap matrix drop res4
foreach var of varlist c_* {
	tempname mat1 mat2 
	levelsof(teacher) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if teacher == `i'
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "teacher `i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res4 = (nullmat(res4), `mat2')
}
frmttable  ,statmat(res3) title("Average (over a lesson) Recipients of Opportunities to Respond by Teacher") 













// Averages 
cap matrix drop res1
foreach var of varlist a_* {
	tempname mat 
	sum `var'
	mat `mat' = round(r(mean),.01) \ round(r(sd),.01) \ r(min) \ r(max)
	mat colnames `mat' = "`:variable label `var''"
	mat res1 = (nullmat(res1),`mat')
}
matrix rownames res1 = "mean" "sd" "min" "max"
matrix list res1

cap matrix drop res2
foreach var of varlist c_* {
	tempname mat 
	sum `var'
	mat `mat' = round(r(mean),.01) \ round(r(sd),.01) \ r(min) \ r(max)
	mat colnames `mat' = "`:variable label `var''"
	mat res2 = (nullmat(res2),`mat')
}
matrix rownames res2 = "mean" "sd" "min" "max"
matrix list res2

// By teacher 

cap matrix drop res3
foreach var of varlist a_* {
	tempname mat1 mat2 
	levelsof(teacher) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if teacher == `i'
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "teacher `i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res3 = (nullmat(res3), `mat2')
}

cap matrix drop res4
foreach var of varlist c_* {
	tempname mat1 mat2 
	levelsof(teacher) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if teacher == `i'
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "teacher `i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res4 = (nullmat(res4), `mat2')
}

// By Site 

cap matrix drop res5
foreach var of varlist a_* {
	tempname mat1 mat2 
	levelsof(i14) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if i14 == "`i'"
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "`i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res5 = (nullmat(res5), `mat2')
}

cap matrix drop res6
foreach var of varlist c_* {
	tempname mat1 mat2 
	levelsof(i14) , local(teachlist)
	foreach i of local teachlist {
		sum `var' if i14 == "`i'"
		mat `mat1' = round(r(mean),.01)
		mat rownames `mat1' = "`i'"
		mat `mat2' = (nullmat(`mat2') \ `mat1')
	} 
		mat colnames `mat2' = "`:variable label `var''"
		mat res6 = (nullmat(res6), `mat2')
}


frmttable  ,statmat(res3) title("Average (over a lesson) Recipients of Opportunities to Respond by Teacher") 


frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res1) title("Average (over a lesson) Opportunities to Respond") replace 
frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res2) title("Average (over a lesson) Recipients of Opportunities to Respond") addtable 
frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res3) title("Average (over a lesson) Opportunities to Respond by Teacher") addtable 
frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res4) title("Average (over a lesson) Recipients of Opportunities to Respond by Teacher") addtable 
frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res5) title("Average (over a lesson) Opportunities to Respond by School") addtable 
frmttable using "${root}/${results}/obs_rubric_desc_tables.rtf" ,statmat(res6) title("Average (over a lesson) Recipients of Opportunities to Respond by School") addtable 


frmttable /*using "${root}/${results}/obs_rubric_desc_tables.rtf" */ ,statmat(res2) title("Average (over a lesson) Recipients of Opportunities to Respond") addtable 


replace c_2 = c_2 / (numstudents -1)
cap matrix drop res2
foreach var of varlist c_* {
	tempname mat 
	sum `var'
	mat `mat' = round(r(mean),.01) \ round(r(sd),.01) \ r(min) \ r(max)
	mat colnames `mat' = "`:variable label `var''"
	mat res2 = (nullmat(res2),`mat')
}
matrix rownames res2 = "mean" "sd" "min" "max"
matrix list res2


frmttable ,statmat(res2) title("Average (over a lesson) Recipients of Opportunities to Respond")

replace minutes = minutes / 15 
foreach var of varlist c* {
	replace `var' = `var' / minutes
}

cap matrix drop res2
foreach var of varlist c_* {
	tempname mat 
	sum `var'
	mat `mat' = round(r(mean),.01) \ round(r(sd),.01) \ r(min) \ r(max)
	mat colnames `mat' = "`:variable label `var''"
	mat res2 = (nullmat(res2),`mat')
}
matrix rownames res2 = "mean" "sd" "min" "max"
matrix list res2

frmttable  ,statmat(res2) title("Average (over a lesson) Recipients of Opportunities to Respond") addtable 








mvgstudy (a_* = teacher obsround|teacher)






