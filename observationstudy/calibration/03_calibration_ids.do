/*------------------------------------------------------------------------------
Title:	cleaning.do 
Author:	Ling Chen 
Date : 	08/14/2024	 
Purpose: 

The goal of this do-file is to clean up identifiers for each level in a consistent format. 
A four-level identifier will be generated:

	Site ID: A 2-digit number indicating our partner site/university.
	Teacher ID: A 4-digit number, where the first two digits indicate the school they are teaching at.
	Observer ID: A 2-digit number.
	Target Student ID: A 1-digit number, which may have a leading zero added if needed.
------------------------------------------------------------------------------*/

// create a date variable 
tempvar pos temp date
gen `pos' = strrpos(i2,"/") + 4
gen `temp' = substr(i2,1,`pos')
replace `temp' = ustrltrim(`temp')
gen `date' = date(`temp',"MDY",2024)
local varlabel: variable label i2 
drop i2 
rename `date' i2
label variable i2 "`varlabel'"
format %td i2

/*
//teacher ID 
tostring i15, replace force
replace i15 = "0"  + substr(i15, 1, 3)  if length(i15) == 3
replace i15 = "02" + substr(i15, 1, 2) if length(i15) == 2 & i14 == "Copper Canyon Elementary"	
replace i15 = "01" + substr(i15, 1, 2) if length(i15) == 2 & i14 == "Forest Creek Elementary "

// observer ID
tostring i13, replace force
replace i13 = substr(i13, -2, 2)
replace i13 = "01" if strpos(i13, "Alex Smith") > 0

//target student ID 
tostring i16, replace force
replace i16 = substr(i16, -1, 1)

//schools 
replace i14 = ustrltrim(i14)
replace i14 = lower(i14)

local remove elementary - school 4th grade elemetary elemnentary elementaty 
foreach word of local remove {
	replace i14 = subinstr(i14, "`word'", "",.)
}
replace i14 = subinstr(i14, "&", "and",.)
replace i14 = stritrim(i14)
replace i14 = strltrim(i14)
replace i14 = strrtrim(i14)
replace i14 = subinstr(i14, "sanday", "sandy",.)


tab i14
*/


