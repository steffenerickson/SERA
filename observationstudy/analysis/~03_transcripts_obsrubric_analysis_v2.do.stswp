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


mata 
string matrix splittext(string matrix text, string scalar regex)
{
	string matrix temp1,temp2,res
	real scalar i 
	
	res = J(0,2,"")
	for (i=1;i<=rows(text);i++) {
		temp1 = ustrsplit(text[i],regex)'
		temp2 = temp1,J(rows(temp1),1,strofreal(i))
		res = res \ temp2
	}
	return(res) 
}
end 

use "${root}/${data}/${cleandata}/transcripts_obsrubric.dta" , clear 

//----------------------------------------------------------------------------//
// More Cleaning 
//----------------------------------------------------------------------------//

mata X = st_sdata(.,"text")
mata X[1..5]
gen word_count = wordcount(text)


egen teachbyobs = group(teacher lessonnum)

sort teacher lessonnum linenum
egen avg_word_count_teacher = total(word_count) if teachertalk == 1 ,  by(teacher lessonnum)
egen avg_word_count_student = total(word_count) if studenttalk == 1 | wholeclasstalk == 1 ,  by(teacher lessonnum)

levelsof teachbyobs, local(teachbyobs)
foreach i of local teachbyobs {
	sum avg_word_count_teacher if teachbyobs == `i'
	replace avg_word_count_teacher = r(mean) if teachbyobs == `i' & avg_word_count_teacher == . 
	sum avg_word_count_student if teachbyobs == `i'
	replace avg_word_count_student = r(mean) if teachbyobs == `i' & avg_word_count_student == . 
}

gen scew  = .
gen scewrate = .
gen linenumsq = linenum^2
levelsof teachbyobs, local(teachbyobs)
foreach i of local teachbyobs {
	sum linenum if teachbyobs == `i' & teachertalk == 1, det
	local front = r(p50)
	local back = r(p50)
	sum word_count if linenum < `front' & teachbyobs == `i' & teachertalk == 1
	local wordsupfront = r(mean)
	sum word_count  if linenum > `back' & teachbyobs == `i' & teachertalk == 1
	local wordsinback = r(mean )
	replace scew =  `wordsinback' - `wordsupfront'  if teachbyobs == `i'
	//capture regress word_count linenum /*linenumsq*/ if teachbyobs == `i' & teachertalk == 1 & word_count > 50
	//replace scew = _b[linenum] if teachbyobs == `i'
	//replace scewrate = _b[linenumsq] if teachbyobs == `i'
	
}
sum scew
gen scew2 = 1 +  (scew - r(min)) * (100 - 1) / (r(max) - r(min))
hist scew
egen avgwordcount = mean(word_count) if teachertalk == 1, by(teachbyobs)
egen totalinenum = count(linenum) , by(teachbyobs)
egen avgwordcountstu = mean(word_count) if (grouptalk ==1 | studenttalk ==1 | wholeclasstalk==1) , by(teachbyobs)

foreach i of local teachbyobs {
	qui sum avgwordcount
	local a = r(mean)
	qui sum totalinenum
	local b = r(mean)
	replace avgwordcount = `a' if teachbyobs == `i' & avgwordcount == .
	replace totalinenum = `b' if teachbyobs == `i' & totalinenum== .
}


egen avg = rowmean(i48 i49 i50 i51)
egen otr = rowtotal(a_1 a_2 a_3 a_4 a_5 a_6) , missing
gen talking = tot_studenttalk + tot_wholeclasstalk
gen ratio1 = otr / tot_teachertalk 
//gen ratio2 = otr/ tot_studenttalk
//gen ratio3 = otr/ tot_wholeclasstalk
gen ratio2 = talking / tot_teachertalk
gen ratio3 = avg_word_count_student / avg_word_count_teacher




//----------------------------------------------------------------------------//
// Plot and text examples 
//----------------------------------------------------------------------------//
sum avg if directobsnum  == 2 & teacher == "030101"
local avg1 : display %6.1f `r(mean)'
sum ratio2 if directobsnum  == 2 & teacher == "030101"
local ratio1 : display %6.1f `r(mean)'
twoway (scatter word_count linenum if teacher == "030101" & directobsnum == 2 & teachertalk == 1 ) ///
       (scatter  word_count linenum if teacher == "030101" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)) ///
	   , name(g1, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 4: Low Quality (q score  =`avg1', st/tt =`ratio1')")

tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "030101" 
sum `n' if directobsnum  == 2 & teacher == "030101"  & word_count == r(max)
local a1 = text[r(mean)]
mata a1 = st_local("a1")


sum avg if teacher == "050101" & directobsnum == 1
local avg2 : display %6.1f `r(mean)'
sum ratio2 if teacher == "050101" & directobsnum == 1
local ratio2 : display %6.1f `r(mean)'
twoway (scatter word_count linenum if teacher == "050101" & directobsnum == 1 & teachertalk == 1) ///
(scatter word_count linenum if teacher == "050101" & directobsnum == 1 & word_count > 1 & (grouptalk == 1 | studenttalk == 1 | wholeclasstalk == 1), mcolor(blue%100)) ///
, name(g2, replace) legend(order(1 "Teacher Talk" 2 "Students")) title("Teacher 2: Med. Quality (q score =`avg2', st/tt =`ratio2')")

tempvar n 
gen `n' = _n
sum word_count if directobsnum == 1 & teacher == "050101"
sum `n' if directobsnum == 1 & teacher == "050101" & word_count == r(max)
local a2 = text[r(mean)]
mata a2 = st_local("a2")

sum avg  if directobsnum  == 2 & teacher == "140102"
local avg3 : display %6.1f `r(mean)'
sum ratio2  if directobsnum  == 2 & teacher == "140102"
local ratio3 : display %6.1f `r(mean)'
twoway (scatter word_count linenum if teacher == "140102" & directobsnum == 2 & teachertalk == 1) ///
(scatter  word_count linenum if teacher == "140102" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)) ///
, name(g3, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 3: High Quality (q score  =`avg3', st/tt =`ratio3')")

tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "140102" 
sum `n' if directobsnum  == 2 & teacher == "140102" & word_count == r(max)
local a3 = text[r(mean)]
mata a3 = st_local("a3")


grc1leg2 g1 g2 g3 , legendfrom(g1) title("Student vs. Teacher Talk")  ycommon note("st/tt is the ratio of student talk to teacher talk") //rows(1) 
mata textsamples = a1 \ a2 \ a3 
mata textsamples





//---------------------------------------------------------------------------//
// Modeling relationships 
//---------------------------------------------------------------------------//


collapse  (mean) totalinenum avgwordcount avgwordcountstu i21 i24 otr  ratio1 ratio2 tot_teachertalk  tot_studenttalk tot_wholeclasstalk i48 i49 i50 i51 avg scew scew2 avg_word_count_teacher avg_word_count_student ratio3, by(teacher lessonnum /*grade*/ site)
keep if otr != .                                                                                                                                        

rename  ratio2 stu2teachtalk 
rename  ratio3 stu2teachwords
rename avg quality 


label variable quality "quality score"
label variable scew "beg vs end talkbalance"
label variable stu2teachtalk "student to teacher talk turns ratio"
label variable stu2teachwords "student to teacher talk words ratio"
label variable otr "otr count"
label variable avgwordcount "average teacher talk word count"
label variable totalinenum "transcript line length"
label variable i48 "Overall student interest in the science lesson"
label variable i49 "Target student interest in the science lesson"
label variable i50 "Overall discourse opportunities"
label variable i51 "Overall teaching for scientific understanding"


//encode grade, gen(grade2)
encode site, gen(site2)

//hist scew ,  name(g1,replace) color(blue%50)
hist stu2teachtalk ,  name(g2,replace) color(blue%50)
hist otr,  name(g3, replace) color(blue%50)
hist avgwordcount ,  name(g4,replace) color(blue%50)
hist totalinenum,  name(g5,replace) color(blue%50)
graph combine /*g1*/ g2 g3 g4 g5 , title("Text Feature and OTR Distributions")

hist quality,  name(g1,replace) color(red%50)
hist i48,  name(g2,replace) color(red%50)
hist i49,  name(g3,replace) color(red%50)
hist i50,  name(g4,replace) color(red%50)
hist i51,  name(g5,replace) color(red%50)
graph combine g1 g2 g3 g4 g5 , title("Quality Score Distributions")

regress quality  stu2teachtalk otr totalinenum avgwordcount , vce(cluster teacher) 

sem (F -> i48 i49 i50 i51) , standardized 

sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr totalinenum avgwordcount ) , standardized  cov(e.i48*e.i49) vce(cluster teacher) 
sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr totalinenum avgwordcount ) , standardized vce(cluster teacher) 
sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr totalinenum avgwordcount ) , standardized vce(cluster teacher) cov(stu2teachtalk*otr) //method(adf)


sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr totalinenum avgwordcount ) , standardized  cov(e.i48*e.i49) 

// More of the variation in quality is explained by ratio than otr counts 
sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk ) , standardized  cov(e.i48*e.i49) vce(cluster teacher) 
estat eqgof

sem (F -> i48 i49 i50 i51) (F <- otr) , standardized  cov(e.i48*e.i49) vce(cluster teacher) 
estat eqgof


gen n = 1 
collapse  (mean) quality i48 i49 i50 i51 stu2teachtalk  otr  totalinenum avgwordcount scew avgwordcountstu (count) n, by(teacher)
sem (F -> i48 i49 i50 i51) (F <-stu2teachtalk otr totalinenum avgwordcount ) , standardized //cov(e.i48*e.i49)

sem (F -> i48 i49 i50 i51)
predict Fscore, latent 

twoway (scatter Fscore stu2teachtalk) (lfit Fscore stu2teachtalk), name(g1 , replace)
twoway  (scatter Fscore otr) (lfit Fscore otr) ,name(g2 , replace)
graph combine g1 g2 , title("Bivariate Scatter Plots: Quality and IVs")




regress quality  stu2teachtalk otr totalinenum avgwordcount





twoway (scatter quality stu2teachtalk) (lfit quality stu2teachtalk), name(g1 , replace)
twoway  (scatter quality otr) (lfit quality otr) ,name(g2 , replace)
graph combine g1 g2
regress quality  stu2teachtalk otr totalinenum avgwordcount




sem (i48 i49 i50 i51 <-stu2teachtalk otr totalinenum avgwordcount ) , standardized //cov(e.i48*e.i49)

sem (F -> i48 i49 i50 i51) (F <-stu2teachtalk otr totalinenum avgwordcount ) , standardized //cov(e.i48*e.i49)


// ------------------------//
// Features table 
// ------------------------//

gen t = _n
drop teacher 
rename t teacher 



label variable quality "Avg Quality Score"
label variable stu2teachtalk "Stu2teachtalk Ratio"
label variable otr "Total OTRs"
label variable totalinenum "Total Lines"
label variable avgwordcount "Average Teach Talk Length"
label variable avgwordcountstu "Average Student Talk Length"
label variable i48 "Overall Student Interest"
label variable i49 "Target Student Interest"
label variable i50 "Discourse Opportunities"
label variable i51 "Scientific Understanding"


cap matrix drop res
foreach var of varlist stu2teachtalk totalinenum avgwordcount avgwordcountstu quality otr {
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
foreach var of varlist stu2teachtalk totalinenum avgwordcount avgwordcountstu  quality otr {
	sum `var'
	mat avgs = (nullmat(avgs), r(mean))
}
mat rownames avgs = "Average"
mat res = res \ avgs

cap matrix drop sds
foreach var of varlist stu2teachtalk totalinenum avgwordcount avgwordcountstu quality otr {
	sum `var'
	mat sds = (nullmat(sds), r(sd))
}
mat rownames sds = "Standard Deviation"
mat res = res \ sds

cap matrix drop corrs1
foreach var of varlist stu2teachtalk totalinenum avgwordcount  avgwordcountstu {
	corr `var' quality
	mat corrs1 = (nullmat(corrs1), r(rho))
}
mat corrs1 = corrs1 ,.,.
mat rownames corrs1 = "Quality Correlation"
mat res = res \ corrs1

cap matrix drop corrs2
foreach var of varlist stu2teachtalk totalinenum avgwordcount avgwordcountstu {
	corr `var' otr
	mat corrs2 = (nullmat(corrs2), r(rho))
}
mat corrs2 = corrs2 ,.,.
mat rownames corrs2 = "OTR Correlation"
mat res = res \ corrs2

mat res4 = res 


frmttable,statmat(res4) title("Text Features ") 








/*




cap matrix drop res
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr quality  i48 i49 i50 i51 {
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
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr quality i48 i49 i50 i51 {
	sum `var'
	mat avgs = (nullmat(avgs), r(mean))
}
mat rownames avgs = "Average"
mat res = res \ avgs

cap matrix drop sds
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr quality i48 i49 i50 i51 {
	sum `var'
	mat sds = (nullmat(sds), r(sd))
}
mat rownames sds = "Standard Deviation"
mat res = res \ sds

cap matrix drop corrs
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr  {
	corr `var' quality
	mat corrs = (nullmat(corrs), r(rho))
}
mat corrs = corrs ,.,.,.,.,. 
mat rownames corrs = "Avg Quality Rho"
mat res = res \ corrs

cap matrix drop corrs1
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr   {
	corr `var' i48
	mat corrs1 = (nullmat(corrs1), r(rho))
}
mat corrs1 = corrs1 ,.,.,.,.,.  
mat rownames corrs1 = "Student Interest Rho"
mat res = res \ corrs1

cap matrix drop corrs2
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr {
	corr `var' i49
	mat corrs2 = (nullmat(corrs2), r(rho))
}
mat corrs2 = corrs2 ,.,.,.,.,. 
mat rownames corrs2 = "Target Interest Rho"
mat res = res \ corrs2

cap matrix drop corrs3
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr  {
	corr `var' i50
	mat corrs3 = (nullmat(corrs3), r(rho))
}
mat corrs3 = corrs3 ,.,.,.,.,.  
mat rownames corrs3 = "Discourse Opportunities Rho"
mat res = res \ corrs3
mat res3 = res 

cap matrix drop corrs4
foreach var of varlist stu2teachtalk totalinenum avgwordcount otr  {
	corr `var' i51
	mat corrs4 = (nullmat(corrs4), r(rho))
}
mat corrs4 = corrs4 ,.,.,.,.,. 
mat rownames corrs4 = "Scientific Understanding Rho"
mat res = res \ corrs4
mat res3 = res 


frmttable,statmat(res3) title("Text Features ") 












