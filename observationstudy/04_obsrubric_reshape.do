/*
Wide to -> Long
Final Data shape 
-------------------------------------------------------------------------
id  attributes section  occurrence  otr_type otr_recipient teach_feeback
------------------------------------------------------------------------- 
 i           c       1    		1   	   1     		1			   1
 1           c       1    		2   	   1    		0			   1
 1           c       1    		3   	   1    		1			   0
 1           c       2    		1   	   2    		0			   1
 1           c       2    		2   	   1    		1			   1
 1           c       2    		3   	   3    		1			   1
-------------------------------------------------------------------------
*/
//----------------------------------------------------------------------------//
// Series of reshapes 
//----------------------------------------------------------------------------//

egen id = group( /*i2*/ i12 i13 i14 i15 i16 i17 i18)
egen dupes = tag(id)
drop if dupes == 0 

// reshape 1 -----------------//
frame copy obsrubric tempframe, replace
frame tempframe :  keep id i*

local varstorelabel
foreach v of var *_*_1 *_1 {
	local len = strlen("`v'")
	local stub = substr("`v'",1,`len'-2)
	local `stub'_label : variable label `v'
	local varstorelabel: list varstorelabel | stub
}

local stublist
foreach v of var *_*_* *_* {
	local len = strlen("`v'")
	local stub = substr("`v'",1,`len'-1)
	local stublist : list stublist | stub
}

di "`stublist'"

keep id *_*_* *_* 
reshape long `stublist' , i(id) j(section)
frame tempframe : tempfile data
frame tempframe : save `data'
merge m:1 id using `data'
drop _merge
rename *_ *

foreach v of local varstorelabel {
	label variable `v' "``v'_label'"
}

drop if d1 == ""


// reshape 2 -----------------//
frame copy obsrubric tempframe, replace
frame tempframe :  keep id section i* d*

local varstorelabel
foreach v of var ?_* {
	local len = strlen("`v'")
	if `len' == 3 local subtract = 2
	if `len' == 4 local subtract = 3
	local stub = substr("`v'",1,`len'-`subtract')
	local `stub'_label : variable label `v'
	local varstorelabel: list varstorelabel | stub
}

local stublist
foreach v of var ?_*  {
	local len = strlen("`v'")
	if `len' == 3 local subtract = 1
	if `len' == 4 local subtract = 2
	local stub = substr("`v'",1,`len'-`subtract')
	local stublist : list stublist | stub
}

di "`stublist'"

keep id section ?_*
reshape long `stublist' , i(id section) j(occurrence)
frame tempframe : tempfile data
frame tempframe : save `data'
merge m:1 id section using `data'
drop _merge
rename *_ *
foreach v of local varstorelabel {
	label variable `v' "``v'_label'"
}

drop if a == ""

foreach v of var a-d7 {
	local string : var label `v'
	local len = strlen("`string'")
	local newlabel = substr("`string'",1,`len'-1)
	label var `v' "`newlabel'"
}

//----------------------------------------------------------------------------//
// Clean the variables 
//----------------------------------------------------------------------------//

foreach v in a b c {
	encode `v', gen(`v'2)
	drop `v'
	rename `v'2 `v'
}


replace b = 0 if b == . 
replace c = 0 if c == . 


tab a c , row chi







