
//----------------------------------------------------------------------------//
// Reliability 
//----------------------------------------------------------------------------//
clear all 
frame reset 

global root "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data"	
global code "/Users/steffenerickson/Documents/GitHub/SERA/observationstudy"
global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
global rawdata "Quant Team - Data Exports"
global cleandata "Quant Team - Clean Data"
global results "Quant Team - Results"

include ${programs}/mvgstudy.ado
use "${root}/${cleandata}/obsrubric.dta" , clear 

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

keep i12 i13 i14 i15 i16 i17 i18 i19 i20 a b c 
foreach var in a b c {
	dummieswithlabels `var'
}
	
foreach var of varlist a_* b_* c_* {
	local `var'_label: variable label `var'
}
collapse (sum) a_* b_* c_*, by(i12 i13 i14 i15 i16 i17 i18 i19 i20)
foreach var of varlist a_* b_* c_* {
	label variable `var' "``var'_label'"
}

egen teacher = group(i15 i12)
destring i17, gen(obsround)
egen teacherround = group(teacher obsround)

tempvar n nobs 
gen `n' = _n
egen `nobs' = count(`n') , by(teacherround)
keep if `nobs' > 1
tab `nobs'

bysort teacherround : gen rater = _n
keep if rater < 3

tab teacherround rater 

// Opportunities to respond 
drop a_2
version 16 : table teacherround rater, c(mean a_5)
version 16 : table teacherround, c(mean a_5)
mvgstudy (a_* = teacherround  rater|teacherround) 
mat true =  r(covcomps1) 
mat error =  r(covcomps2) 
qui ds a_* 
local length = `:word count `r(varlist)''
mat w = J(`length',1,1/`length') // equally weighting the components 
mat list w
mat T = w'*true*w
mat E = w'*error*w

di T[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to between-observation differences in the first section. Good variance! 
di E[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to raters disagreeing within an obseravtion. Bad variance :( 


// Who got the Opportunity?
drop c_1
mvgstudy (c_* = teacherround rater|teacherround) 
mat true =  r(covcomps1) 
mat error =  r(covcomps2) 
qui ds c_* 
local length = `:word count `r(varlist)''
mat w = J(`length',1,1/`length') // equally weighting the components 
mat list w
mat T = w'*true*w
mat E = w'*error*w


di T[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to between-observation differences in the first section. Good variance! 
di E[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to raters disagreeing within an obseravtion. Bad variance :( 




