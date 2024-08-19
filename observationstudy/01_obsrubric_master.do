clear all 
frame reset 

global root "/Users/steffenerickson/Desktop/summer2024/sera/observationstudy"	
global code "code"
global data "data"
global results "results"
qui include ${root}/${code}/00_mvgstudy.ado

mkf   obsrubric 
frame obsrubric : import excel "${root}/${data}/CrowdSource: Science Observation Form_August 15, 2024_08.06.xlsx", sheet("Sheet0") firstrow case(lower) clear
frame obsrubric : qui drop startdate enddate status ipaddress progress durationinseconds
frame obsrubric : qui do ${root}/${code}/02_obsrubric_stringcleaning.do
frame obsrubric : qui do ${root}/${code}/03_obsrubric_ids.do
frame obsrubric : qui do ${root}/${code}/04_obsrubric_reshape.do


//----------------------------------------------------------------------------//
// Reliability 
//----------------------------------------------------------------------------//
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

frame change obsrubric
keep i12 i13 i14 i15 i16 i17 i18 i19 i20 a b c section occurrence
foreach var in a b c {
	dummieswithlabels `var'
}
	
foreach var of varlist a_* b_* c_* {
	local `var'_label: variable label `var'
	di "``var'_label'"
}
collapse (sum) a_* b_* c_*, by(i12 i13 i14 i15 i16 i17 i18 i19 i20 section)
foreach var of varlist a_* b_* c_* {
	label variable `var' "``var'_label'"
}

egen obsid = group(i15 i12 i20)
egen sectionplusobsid = group(obsid section)
gen n = _n
egen nobs = count(n) , by(sectionplusobsid)
keep if nobs == 2
drop nobs n 
destring i17, gen(obsround)
bysort sectionplusobsid: gen rater = _n
egen id = group(i15 i12)
egen idplusround = group(id obsround)

mvgstudy (a_* = idplusround rater|idplusround) if section == 1 // Looking at the first section 
mat true =  r(covcomps1) 
mat error =  r(covcomps2) 
mat w = (1/6,1/6,1/6,1/6,1/6,1/6)' // equally weighting the components 
mat T = w'*true*w
mat E = w'*error*w

di T[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to between-observation differences in the first section. Good variance! 
di E[1,1] / (T[1,1] + E[1,1]) // proportion of variance attributed to raters disagreeing within an obseravtion. Bad variance :( 










