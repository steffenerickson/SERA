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

frame obsrubric {
	keep i12 i13 i14 i15 i17 i18 i19 i20 i21 i24 a b c /*i47*/ i48 i49 i50 i51 
	
	// Create dummies for opportunities to respond 
	foreach var in a b c {
		dummieswithlabels `var'
	}
	
	// Total Lesson Counts 
	foreach var of varlist a_* b_* c_* {
		local `var'_label: variable label `var'
	}
	collapse (sum) a_* b_* c_*, by(i12 i13 i14 i15 i17 i18 i19 i20 i21 i24 /*i47*/ i48 i49 i50 i51 )
	foreach var of varlist a_* b_* c_* {
		label variable `var' "``var'_label'"
	}
	
	// Create site variable for merge 
	gen site = ""
	replace site = "01" if i12 == "University of Virginia"
	replace site = "02" if i12 == "University of Texas Austin"
	replace site = "03" if i12 == "Delaware State University"
	replace site = "04" if i12 == "Michigan State University"
	replace site = "05" if i12 == "SUNY Buffalo State University"
	replace site = "06" if i12 == "University of Arkansas Pine Bluff"
	replace site = "07" if i12 == "University of California Riverside"
	replace site = "08" if i12 == "University of Nevada Las Vegas"
	replace site = "09" if i12 == "University of North Carolina Wilmington"
	replace site = "10" if i12 == "University of Pittsburgh"
	replace site = "11" if i12 == "University of Utah"
	replace site = "12" if i12 == "Wichita State University"
	replace site = "13" if i12 == "Brigham Young University"
	replace site = "14" if i12 == "Washington State University"
	replace site = "16" if i12 == "University of Missouri"
	replace site = "18" if i12 == "Texas Christian University"
	
	gen teacher = site + i15
	destring i17, gen(directobsnum) 
	destring i48 i49 i50 i51 i21 i24 , replace
	gen date = date(i20,"MDY")
	format date %td
		
	replace i14 = "provident charter central" if i14 != "provident charter central" & teacher ==  "100201"

	// Collapse over the double coded observations
	foreach var of varlist a_* b_* c_* i48 i49 i50 i51 i21 i24 {
		local `var'_label: variable label `var'
	}
	collapse (mean) a_* b_* c_* i48 i49 i50 i51 i21 i24, by(teacher directobsnum i12 i14 /*date*/ site i12 i14 )
	foreach var of varlist a_* b_* c_* i48 i49 i50 i51  i21 i24  {
		label variable `var' "``var'_label'"
	}
	
	tempfile data
	save `data'
	
}

merge m:1 teacher directobsnum using `data'
keep if _merge != 2




