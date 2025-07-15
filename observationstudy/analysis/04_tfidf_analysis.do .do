clear all 
version 18

* Set up directories 
local office 0
if `office' == 1 {
	global root 	"C:/Users/cns8vg"
	global code 	"GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results"

}
if `office' == 0 {
	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 
}

// Data frames 

mkf tfidf_table 
mkf vocab_table 
mkf obsrubric_table 


//----------------------------------------------------------------------------//
// PCA and Word Clouds 
//----------------------------------------------------------------------------//

// Import Data 
frame obsrubric_table {
	use "$root/$data/$cleandata/transcripts_obsrubric.dta" , clear
	drop text 
	drop _merge 
	rename * o_*
	rename (o_id o_linenum) (id linenum)
	tempfile data 
	save `data'
}
frame tfidf_table : import delimited "$root/$data/$cleandata/TFIDF.csv", clear 
frame copy tfidf_table PCA, replace 
frame tfidf_table {
	merge 1:1 id linenum using `data'
	keep if _merge == 3 
	keep if o_teachertalk == 1	
	//keep if o_directobs == 1
	drop _merge 
}
//----------------------------------------------------------------------------//
// Word clouds 
//----------------------------------------------------------------------------//
/*
frame copy tfidf_table wordcloud, replace
frame change wordcloud 
rename (o_teacher o_lesson o_directobsnum) (Teacher Lesson directobsnum) 
drop o_*

qui ds 
local temp `r(varlist)'
local remove id subgroup linenum Teacher Lesson directobsnum
local varlist : list temp - remove 
global varlist `varlist'
foreach v of global varlist {
	rename `v' w_`v'
}
greshape long w_ , i(id linenum Teacher Lesson directobsnum) j(word) string
drop if w_ == 0
bysort id : gen freq = _n


local low directobsnum == 2 & Teacher == "030101" 
local med directobsnum == 1 & Teacher == "050101" 
local high directobsnum == 2 & Teacher == "140102"
local x = 1
foreach i in 20 75 {
	preserve
	keep if id == `i'
	collapse (mean) w_ (count) freq , by(word)
	wordcloud word freq , nogrammar  nocommon style(2) name(g`i', replace) title(Lesson `x')  //scheme(s1color) 
	restore
	local g g`i'
	local glist : list glist | g 
	local++x
}
graph combine `glist' , rows(3) altshrink 
*/
//----------------------------------------------------------------------------//
// PCA 
//----------------------------------------------------------------------------//


frame copy tfidf_table PCA, replace
frame change PCA
drop o_*
qui ds 
local temp `r(varlist)'
local remove id subgroup linenum
local varlist : list temp - remove 
global varlist `varlist'
//collapse $varlist , by(id subgroup)
collapse $varlist , by(id)
qui pca $varlist 
matrix loadings = e(L)
//qui factor $varlist 
//rotate, promax(3)
//matrix loadings = e(r_L)

local rownames : rowfullnames loadings 
tempname tempframe 
mkf `tempframe'
frame `tempframe' {
	svmat loadings 
	ds 
	gen item = ""
	qui desc item 
	forvalues i = 1/`r(N)' {
		replace item = "`:word `i' of `rownames''" in `i'
	}
	forvalues j = 1/10 {
		gsort -  loadings`j'
		list item loadings`j' in 1/10
	}
}
frame copy `tempframe' loadingsframe, replace 
//frame loadingsframe : scatter loadings1 loadings2 , mlabel(item) mlabsize(half_tiny) msize(vtiny)
frame loadingsframe : cap drop alt_row
frame loadingsframe : cap drop n
frame loadingsframe : sort loadings1
frame loadingsframe : gen n = _n
frame loadingsframe : gen alt_row = mod(_n, 30) 
frame loadingsframe : replace alt_row = 1 if loadings1 > .075
frame loadingsframe : scatter loadings1 n if alt_row == 1, mlabel(item) mlabsize(tiny) msize(vtiny) /// 
ytitle("PCA Score for Command Like Language" , size(small)) xtitle("Rank For Command Like Language" , size(small)) ///
title("Grouping Similar Words with Principal Component Analysis" , size(small))
frame loadingsframe : scatter loadings1 n if alt_row == 1 & n > 950, mlabel(item) mlabsize(tiny) msize(vtiny) ///
ytitle("PCA Score for Command Like Language" , size(small)) ///
xtitle("Rank For Command Like Language" , size(small)) ///
title("Grouping Similar Words with Principal Component Analysis (High End of Distribution)" , size(small))








//----------------------------------------------------------------------------//
// Vocab Tables 
//----------------------------------------------------------------------------//

//vocab 
frame vocab_table: import delimited "$root/$data/$cleandata/vocab.csv", clear 
frame change vocab_table 
gsort - dfidf
gen n = _n 
gen s =  (mod(_n,5) == 0)  if dfidf > 2000
replace s =  (mod(_n,10) == 0)  if dfidf <= 2000
scatter  n dfidf  if s == 1 ///
, mlabel(term_str) mlabsize(tiny) msize(vtiny) /*xscale(reverse)*/ ///
title("Term Frequency-Inverse Document Frequency (Term Importance)" , size(small))

























// ---------------------------------------------------------------------------// 
// Word Clouds 
// ---------------------------------------------------------------------------// 

import delimited "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Clean Data/TFIDF.csv", clear 

qui ds 
local temp `r(varlist)'
local remove id subgroup linenum
local varlist : list temp - remove 
global varlist `varlist'
foreach v of global varlist {
	rename `v' w_`v'
}
greshape long w_ , i(id linenum) j(word) string
drop if w_ == 0
bysort id : gen freq = _n
foreach i in 1 20 50 75 /*100 150*/ {
	preserve
	keep if id == `i'
	collapse (mean) w_ (count) freq , by(word)
	wordcloud word w_ , nogrammar  nocommon style(2) name(g`i', replace) title(`i')  //scheme(s1color)
	restore
	local g g`i'
	local glist : list glist | g 
}
graph combine `glist' , rows(3) altshrink 

foreach i in 25 36 103 170 /*100 150*/ {
	preserve
	keep if id == `i'
	collapse (mean) w_ (count) freq , by(word)
	wordcloud word w_ , nogrammar  nocommon style(2) name(g`i', replace) title(`i')  //scheme(s1color)
	restore
	
	local g g`i'
	local glist : list glist | g 
}
graph combine `glist' , rows(3) altshrink 

// ---------------------------------------------------------------------------// 
// PCA Scores
// ---------------------------------------------------------------------------// 

clear all 
import delimited "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Clean Data/TFIDF.csv", clear 

qui ds 
local temp `r(varlist)'
local remove id subgroup linenum
local varlist : list temp - remove 
global varlist `varlist'
//collapse $varlist , by(id subgroup)
qui pca $varlist 
matrix loadings = e(L)
//qui pca have-learn
matrix loadings = e(L)
local rownames : rowfullnames loadings 
tempname tempframe 
mkf `tempframe'
frame `tempframe' {
	svmat loadings 
	ds 
	gen item = ""
	qui desc item 
	forvalues i = 1/`r(N)' {
		replace item = "`:word `i' of `rownames''" in `i'
	}
	forvalues j = 1/10 {
		gsort -  loadings`j'
		list item loadings`j' in 1/10
	}
}
frame copy `tempframe' loadingsframe, replace 
//frame loadingsframe : scatter loadings1 loadings2 , mlabel(item) mlabsize(half_tiny) msize(vtiny)
frame loadingsframe : cap drop alt_row
frame loadingsframe : sort loadings1
frame loadingsframe : gen alt_row = mod(_n, 10)
frame loadingsframe : replace alt_row = 1 if loadings1 > .075
frame loadingsframe : scatter loadings1 loadings1 if alt_row == 1, mlabel(item) mlabsize(half_tiny) msize(vtiny)


predict pc1 
keep pc1 id linenum
mkf obsrubric
frame obsrubric : use "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Clean Data/transcripts_obsrubric.dta" , clear
frame obsrubric : drop _merge 
frame obsrubric : tempfile data
frame obsrubric : save `data'
merge 1:1 id linenum using `data'
keep if directobs == 1
preserve
drop if pc1 == . 
scatter pc1 linenum if teacher == "010101" & lessonnum == "L07"
list text if  teacher == "010101" & lessonnum == "L07" & pc1 > 6
list text if  teacher == "010101" & lessonnum == "L07" & pc1 < -3.5
restore




egen otr = rowtotal(a_1 a_2 a_3 a_4 a_5 a_6) , missing
gen talking = tot_studenttalk + tot_wholeclasstalk
gen ratio2 = talking / tot_teachertalk
collapse  (mean) i48 i49 i50 i51 pc1 otr ratio2, by(teacher lessonnum /*grade*/ site)
keep if otr != .                                             


                                                          
sem (F -> i48 i49 i50 i51) (F <- ratio2 otr pc1), standardized 
estat eqgof

sem (F -> i48 i49 i50 i51) (F <- ratio2 otr pc1), standardized vce(cluster teacher)



regress i48 pc1 otr ratio2
regress i49 pc1 otr ratio2
regress i50 pc1 otr ratio2
regress i51 pc1 otr ratio2

  


preserve
collapse  (mean) i48 i49 i50 i51 pc1 otr ratio2, by(teacher)                                                                       
regress i48 pc1
regress i49 pc1
regress i50 pc1
regress i51 pc1
restore

regress 




clear all 
version 18

* Set up directories 
local office 0
if `office' == 1 {
	global root 	"C:/Users/cns8vg"
	global code 	"GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results"

}
if `office' == 0 {
	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 
}


mkf base 
frame change base 
use "${root}/${data}/${cleandata}/transcripts_byline.dta" , clear 
include ${programs}/python_functions.ado 

keep if teachertalk == 1
rename teacher Teacher
keep linenum id lessonnum Teacher 

mkf frame1 
frame frame1 : import delimited "/Users/steffenerickson/Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Clean Data/TFIDF.csv", clear 
frame frame1 {
	qui ds 
	local temp `r(varlist)'
	local remove id subgroup linenum
	local varlist : list temp - remove 
	global varlist `varlist'
	collapse $varlist , by(id)
	
}
frame frame1 : tempfile data
frame frame1 : save `data'
merge m:1 id using `data'


bysort id : gen n = _n
keep if n == 1
drop linenum 
drop _merge n 


qui ds 
local temp `r(varlist)'
local remove id Teacher lessonnum
local varlist : list temp - remove 
global varlist `varlist'

collapse $varlist , by(Teacher)


qui factor $varlist 
qui rotate , promax(4)
//qui pca have-learn
matrix loadings = e(r_L)
local rownames : rowfullnames loadings 
tempname tempframe 
mkf `tempframe'
frame `tempframe' {
	svmat loadings 
	ds 
	gen item = ""
	qui desc item 
	forvalues i = 1/`r(N)' {
		replace item = "`:word `i' of `rownames''" in `i'
	}
	forvalues j = 1/5 {
		gsort -  loadings`j'
		list item loadings`j' in 1/10
	}
}
frame copy `tempframe' loadingsframe, replace 

frame loadingsframe : scatter loadings1 loadings2 , mlabel(item) mlabsize(half_tiny) msize(vtiny)



predict PC1 PC2 PC3 PC4 PC5

















