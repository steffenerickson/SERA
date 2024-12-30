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
egen totalinenum = count(linenum) if teachertalk == 1, by(teachbyobs)
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


sum avg if teacher == "080101" & directobsnum == 2
local avg1 = round(r(mean), .01)
sum ratio2 if teacher == "080101" & directobsnum == 2
local ratio1 = round(r(mean), .01)
twoway (scatter word_count linenum if teacher == "080101" & directobsnum == 1 & teachertalk == 1) (scatter word_count linenum if teacher == "080101" & directobsnum == 1 & word_count > 1 & (grouptalk == 1 | studenttalk == 1 | wholeclasstalk == 1), mcolor(blue%100)), name(g1, replace) legend(order(1 "Teacher Talk" 2 "Students")) title("Teacher 1: Quality (q score = `avg1', st/tt = `ratio1')")

sum avg if teacher == "130101" & directobsnum == 1
local avg2 = round(r(mean), .01)
sum ratio2 if teacher == "130101" & directobsnum == 1
local ratio2 = round(r(mean), .01)
twoway (scatter word_count linenum if teacher == "130101" & directobsnum == 1 & teachertalk == 1) (scatter word_count linenum if teacher == "130101" & directobsnum == 1 & word_count > 1 & (grouptalk == 1 | studenttalk == 1 | wholeclasstalk == 1), mcolor(blue%100)), name(g2, replace) legend(order(1 "Teacher Talk" 2 "Students")) title("Teacher 2: Quality (q score = `avg2', st/tt = `ratio2')")

sum avg if teacher == "160103" & directobsnum == 1
local avg3 = round(r(mean), .001)
sum ratio2 if teacher == "160103" & directobsnum == 1
local ratio3 = round(r(mean), .01)
twoway (scatter word_count linenum if teacher == "160103" & directobsnum == 1 & teachertalk == 1) (scatter word_count linenum if teacher == "160103" & directobsnum == 1 & word_count > 1 & (grouptalk == 1 | studenttalk == 1 | wholeclasstalk == 1), mcolor(blue%100)), name(g3, replace) legend(order(1 "Teacher Talk" 2 "Students")) title("Teacher 3: Quality (q score = `avg3', st/tt = `ratio3')")

sum avg if teacher == "010101" & directobsnum == 1
local avg4 = round(r(mean), .01)
sum ratio2 if teacher == "010101" & directobsnum == 1
local ratio4 = round(r(mean), .01)
twoway (scatter word_count linenum if teacher == "010101" & directobsnum == 1 & teachertalk == 1) (scatter word_count linenum if teacher == "010101" & directobsnum == 1 & word_count > 1 & (grouptalk == 1 | studenttalk == 1 | wholeclasstalk == 1), mcolor(blue%100)), name(g4, replace) legend(order(1 "Teacher Talk" 2 "Students")) title("Teacher 4: Quality (q score = `avg4', st/tt = `ratio4')")

grc1leg2 g1 g2 g3 g4, legendfrom(g1) title("Student vs. Teacher Talk") ycommon

tempvar n 
gen `n' = _n
sum word_count if directobsnum == 2 & teacher == "080101"
sum `n' if directobsnum == 2 & teacher == "080101" & word_count == r(max)
local a1 = text[r(mean)]
di "`a1'"

tempvar n 
gen `n' = _n
sum word_count if directobsnum == 1 & teacher == "130101"
sum `n' if directobsnum == 1 & teacher == "130101" & word_count == r(max)
local a2 = text[r(mean)]
di "`a2'"

tempvar n 
gen `n' = _n
sum word_count if directobsnum == 1 & teacher == "160103"
sum `n' if directobsnum == 1 & teacher == "160103" & word_count == r(max)
local a3 = text[r(mean)]
di "`a3'"

tempvar n 
gen `n' = _n
sum word_count if directobsnum == 1 & teacher == "010101"
sum `n' if directobsnum == 1 & teacher == "010101" & word_count == r(max)
local a4 = text[r(mean)]
di "`a4'"

mata a1 = st_local("a1")
mata a2 = st_local("a2")
mata a3 = st_local("a3")
mata a4 = st_local("a4")

mata textsamples = a1 \ a2 \ a3 \ a4
mata textsamples







080101


/*


sum scew if  teacher == "080101" & directobsnum == 1 
local avg1 = round(r(mean),.001)
sum scew if  teacher == "130101" & directobsnum == 1 
local avg2 = round(r(mean),.001)
sum scew if  teacher == "160103" & directobsnum == 1 
local avg3 = round(r(mean),.001)
sum scew if  teacher == "010101" & directobsnum == 1 
local avg4 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "080101" & directobsnum == 1 & teachertalk == 1 , text(150 200 "`avg1'")) (scatter  word_count linenum if teacher == "080101" & directobsnum == 1 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g1, replace)  legend(order(1 "Teacher Talk" 2 "Students" ))
twoway (scatter word_count linenum if teacher == "130101" & directobsnum == 1 & teachertalk == 1 , text(150 200 "`avg2'")) (scatter  word_count linenum if teacher == "130101" & directobsnum == 1 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g2, replace)  legend(order(1 "Teacher Talk" 2 "Students" ))
twoway (scatter word_count linenum if teacher == "160103" & directobsnum == 1 & teachertalk == 1 , text(150 200 "`avg3'")) (scatter  word_count linenum if teacher == "160103" & directobsnum == 1 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g3, replace)  legend(order(1 "Teacher Talk" 2 "Students" ))
twoway (scatter word_count linenum if teacher == "010101" & directobsnum == 1 & teachertalk == 1 , text(150 200 "`avg4'")) (scatter  word_count linenum if teacher == "010101" & directobsnum == 1 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g4, replace)  legend(order(1 "Teacher Talk" 2 "Students" ))
grc1leg2 g1 g2 g3 g4  , legendfrom(g1) title("Student vs. Teacher Talk") // xcommon ycommon
//grc1leg2 g1 g2 g3 g4  , legendfrom(g1) xcommon ycommon

*/
sum avg if directobs == 1
tab avg teacher if directobs == 1
tab avg directobsnum if directobs == 1

tab avg directobsnum if directobs == 1 & teacher == "050101"
tab avg teacher if directobs == 1




sum avg  if directobsnum  == 2 & teacher == "140102"
local avg1 = round(r(mean),.001)
sum ratio2  if directobsnum  == 2 & teacher == "140102"
local ratio1 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "140102" & directobsnum == 2 & teachertalk == 1) (scatter  word_count linenum if teacher == "140102" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g1, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 1: High Quality (q score  = `avg1', st/tt = `ratio1')")



sum avg  if directobsnum  == 2 & teacher == "130101"
local avg2 = round(r(mean),.001)
sum ratio2  if directobsnum  == 2 & teacher == "130101"
local ratio2 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "130101" & directobsnum == 2 & teachertalk == 1 ) (scatter  word_count linenum if teacher == "130101" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g2, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 2: High Quality (q score = `avg2', st/tt = `ratio2')")


sum avg  if directobsnum  == 2 & teacher == "130201"
local avg3 = round(r(mean),.001)
sum ratio2  if directobsnum  == 2 & teacher == "130201"
local ratio3 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "130201" & directobsnum == 2 & teachertalk == 1 ) (scatter  word_count linenum if teacher == "130201" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g3, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 3: Low Quality (q score  = `avg3', st/tt = `ratio3')")

sum avg if directobsnum  == 2 & teacher == "030101"
local avg4 = round(r(mean),.001)
sum ratio2 if directobsnum  == 2 & teacher == "030101"
local ratio4 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "030101" & directobsnum == 2 & teachertalk == 1 ) (scatter  word_count linenum if teacher == "030101" & directobsnum == 2 &  word_count > 1 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g4, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 4: Low Quality (q score  = `avg4', st/tt = `ratio4')")

grc1leg2 g1 g2 g3 g4  , legendfrom(g1) title("Student vs. Teacher Talk")  ycommon


tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "140102" 
sum `n' if directobsnum  == 2 & teacher == "140102" & word_count == r(max)
local a1 = text[r(mean)]
di "`a1'"

tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "130101" 
sum `n' if directobsnum  == 2 & teacher == "130101"  & word_count == r(max)
local a2 = text[r(mean)]
di "`a2'"

tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "130201" 
sum `n' if directobsnum  == 2 & teacher == "130201"  & word_count == r(max)
local a3 = text[r(mean)]
di "`a3'"


tempvar n 
gen `n' = _n
sum word_count if directobsnum   == 2 & teacher == "030101" 
sum `n' if directobsnum  == 2 & teacher == "030101"  & word_count == r(max)
local a4 = text[r(mean)]
di "`a4'"

mata a1 = st_local("a1")
mata a2 = st_local("a2")
mata a3 = st_local("a3")
mata a4 = st_local("a4")


mata textsamples = a1 \ a2 \ a3 \ a4
mata textsamples

preserve
clear
getmata a = textsamples
list
restore







sum ratio2  if directobsnum  == 2 & teacher == "140102"
local avg1 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "140102" & directobsnum == 2 & teachertalk == 1 & linenum < 81 ) (scatter  word_count linenum if teacher == "140102" & directobsnum == 2 &  word_count > 1 & linenum < 81 &  (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g1, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 1: High Quality (`avg1')")

sum ratio2  if directobsnum  == 2 & teacher == "130101"
local avg2 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "130101" & directobsnum == 2 & teachertalk == 1 & linenum < 81 ) (scatter  word_count linenum if teacher == "130101" & directobsnum == 2 &  word_count > 1 & linenum < 81 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g2, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 2: High Quality (`avg2')")


sum ratio2  if directobsnum  == 2 & teacher == "130201"
local avg3 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "130201" & directobsnum == 2 & teachertalk == 1 & linenum < 81 ) (scatter  word_count linenum if teacher == "130201" & directobsnum == 2 &  word_count > 1 & linenum < 81 &(grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g3, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 3: Low Quality (`avg3')")


sum ratio2 if directobsnum  == 2 & teacher == "030101"
local avg4 = round(r(mean),.001)
twoway (scatter word_count linenum if teacher == "030101" & directobsnum == 2 & teachertalk == 1 & linenum < 81 ) (scatter  word_count linenum if teacher == "030101" & directobsnum == 2 &  word_count > 1 & linenum < 81 & (grouptalk ==1 | studenttalk ==1  | wholeclasstalk==1 ) , mcolor(blue%100)), name(g4, replace)  legend(order(1 "Teacher Talk" 2 "Students" )) title("Teacher 4: Low Quality (`avg4')")

grc1leg2 g1 g2 g3 g4  , legendfrom(g1) title("Student vs. Teacher Talk")  ycommon






drop  i12 i14
keep if linenum == 1 
encode teacher, gen(teach)
tab teach, gen(teacher_)










collapse  (mean) totalinenum avgwordcount i21 i24 otr  ratio1 ratio2 tot_teachertalk  tot_studenttalk tot_wholeclasstalk i48 i49 i50 i51 avg scew scew2 avg_word_count_teacher avg_word_count_student ratio3, by(teacher lessonnum grade site)
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


encode grade, gen(grade2)
encode site, gen(site2)

hist scew ,  name(g1,replace) color(blue%50)
hist stu2teachtalk ,  name(g2,replace) color(blue%50)
hist otr,  name(g3, replace) color(blue%50)
hist avgwordcount ,  name(g4,replace) color(blue%50)
hist totalinenum,  name(g5,replace) color(blue%50)
graph combine g1 g2 g3 g4 g5 , title("Text Feature and OTR Distributions")

hist quality,  name(g1,replace) color(red%50)
hist i48,  name(g2,replace) color(red%50)
hist i49,  name(g3,replace) color(red%50)
hist i50,  name(g4,replace) color(red%50)
hist i51,  name(g5,replace) color(red%50)
graph combine g1 g2 g3 g4 g5 , title("Quality Score Distributions")



sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr  totalinenum avgwordcount totalinenum scew) , standardized vce(cluster teacher) 
sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr  totalinenum avgwordcount totalinenum scew) , standardized vce(cluster teacher) cov(stu2teachtalk*otr) //method(adf)


sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk stu2teachwords otr  totalinenum  totalinenum scew) , standardized vce(cluster teacher) 
sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk stu2teachword otr  totalinenum totalinenum scew) , standardized vce(cluster teacher) cov(stu2teachtalk*otr) //method(adf)


/*

sem (F -> i48 i49 i50 i51) (F <- stu2teachtalk  otr  totalinenum avgwordcount totalinenum scew2), standardized vce(cluster teacher) //method(adf)

gen n = 1 
collapse  (mean) totalinenum avgwordcount i21 i24 otr  ratio1 ratio2 tot_teachertalk  tot_studenttalk tot_wholeclasstalk i48 i49 i50 i51 avg scew (count) n, by(teacher)


sem (F -> i48 i49 i50 i51) (F <- ratio2 otr totalinenum avgwordcount totalinenum ) [fweight = n], standardized //method(adf)
sem (F -> i48 i49 i50 i51) (F <- ratio2 otr totalinenum avgwordcount totalinenum ) , standardized //method(adf)




sem (avg <- ratio2 otr totalinenum scew avgwordcount totalinenum scew), standardized //method(adf)



sem (F -> i48 i49 i50 i51) (F <- ratio2 ratio1 /*scew avgwordcount totalinenum*/) // if ratio1 < 1.5,  standardized





sem (F -> i48 i49 i50 i51) (F <- ratio2 ratio1 scew avgwordcount totalinenum) if ratio1 < 1.5 //,  standardized

egen f = rowmean(i48 i49 i50 i51)
scatter f scew


sem (F -> i48 i49 i50 i51) (F <- ratio2 ratio1) c//,  standardized



corr ratio2 avgwordcount


sem (F -> i48 i49 i50 i51) (F <- ratio2 otr) , standardized 

gen lnotr = ln(otr)
sem (F -> i48 i49 i50 i51) (F <- ratio2 otr totalinenum avgwordcount ) , standardized cov(ratio2*otr) method(adf)




sem (i48 i49 i50 i51 <- ratio2 otr totalinenum avgwordcount  ) , standardized cov(e.i48*e.i49 e.i48*e.i50 e.i48*e.i51 e.i49*e.i50 e.i49*e.i51 e.i50*e.i51)



regress f ratio2 otr totalinenum avgwordcount  i21 i24 



gen interaction = ratio2 * otr
sem (F -> i48 i49 i50 i51) (F <- ratio2 otr interaction totalinenum avgwordcount) , standardized


corr ratio2 ratio1 scew avgwordcount totalinenum

/*
factor scew word_count 


corr scew avgwordcount totalinenum tot_teachertalk tot_studenttalk tot_wholeclasstalk



sem (F -> i48 i49 i50 i51) (F <-  tot_teachertalk tot_studenttalk tot_wholeclasstalk) , standardized

sem (F -> i48 i49 i50 i51) (F <-  a_1 a_2 a_3 a_4 a_5 a_6 b_2 c_2 c_3 c_4) , standardized


sem (F -> i48 i49 i50 i51) (F <-  tot_teachertalk tot_studenttalk tot_wholeclasstalk a_1 a_2 a_3 a_4 a_5 a_6 b_2 c_2 c_3 c_4) , standardizedz
*/





sem (F -> i48 i49 i50 i51) (F <-  ratio1 ratio2 scew ) if ratio1 < 3 , standardized





sem (F -> i48 i49 i50 i51) (F <-   scew ) , standardized






//drop if ratio1 > 3

browse if ratio1 > 3
keep if _merge == 3

sem (F -> i48 i49 i50 i51)
predict f , latent 



sem (F -> i48 i49 i50 i51) (F <- ratio2 ratio1 scew avgwordcount totalinenum) if ratio1 < 1.5 & scew > -1.9 , var(e.i50@0) standardized



collapse f otr scew ratio1 ratio2 tot_teachertalk  tot_studenttalk tot_wholeclasstalk i48 i49 i50 i51 avgwordcount totalinenum, by(teacher text linenum)

scatter f ratio1 if ratio1 < 1.5
 


sem (F -> i48 i49 i50 i51) (F <- ratio2) if ratio1 < 1.5 , var(e.i50@0) standardized

sem (i48 i49 i50 i51 <- ratio2) if ratio1 < 1.5, cov(e.i48*e.i49 e.i48*e.i50 e.i48*e.i51 e.i49*e.i50 e.i49*e.i51 e.i50*e.i51) standardized


sem (F -> i48 i49 i50@1 i51) (F <- ratio2) if ratio1 < 1.5  //, standardized
sem (F -> i48 i49 i50@1 i51) (F <- ratio2)  //, standardized
sem (F -> i48 i49 i50@1 i51) (F <- ratio2)  , standardized
sem (F -> i48 i49 i50@1 i51) (F <- ratio1)  if ratio1 < 1.5 , standardized
sem (F -> i48 i49 i50 i51)   (F <- ratio2)   if ratio1 < 1.5 , var(e.i50@0) standardized

scatter f ratio2 if linenum < 50 , mlabel(text) mlabsize(half_tiny) 

preserve
drop if ratio2 < .5
twoway (scatter f ratio2 , mlabel(text) mlabsize(half_tiny)) (lowess f ratio2 , bwidth(30))
restore

foreach v in i48 i49 i50 i51 ratio2 ratio1{
	egen `v'_std = std(`v')
}
sem (F -> i48_std i49_std i50_std i51_std) (F <- ratio2_std)  //, standardized

sem (ratio1 <- ratio2) if ratio2 < 1.5 , standardized







sem (f <-  ratio2) if ratio1 < 1.5, standardized
sem (f <-  ratio1) if ratio1 < 1.5, standardized

sem (f <-  ratio1 ratio2) if ratio1 < 1.5, standardized


sem (f <-  tot_teachertalk tot_studenttalk tot_wholeclasstalk) if ratio1 < 1.5, standardized


corr f 




/*



sem (F -> i48 i49 i50 i51) (F <- ratio1) if ratio1 < 3
estat eqgof
sem (F -> i48 i49 i50 i51) (F <- ratio2) if ratio1 < 3
estat eqgof
sem (F -> i48 i49 i50 i51) (F <- ratio1 ratio2) if ratio1 < 3
estat eqgof



levelsof teacher, local(teachers)
foreach t of local teachers {
	sum ratio2 if teacher == "`t'"
	replace ratio2 = ratio2 - r(mean) if teacher == "`t'"
}

levelsof teacher, local(teachers)
foreach t of local teachers {
	sum ratio1 if teacher == "`t'"
	replace ratio1 = ratio1 - r(mean) if teacher == "`t'"
}



sem (F -> i48 i49 i50 i51) (F <- ratio2 ratio1) 


sem (F -> i48 i49 i50 i51) (F <- otr teacher_2-teacher_28)
estat eqgof











corr ratio1 ratio2 if ratio1 != 0

foreach var in i48 i49 i50 i51 {
	regress `var' ratio1 ratio2
}




 


sem (F -> i48 i49 i50 i51) (D -> ratio1 ratio2)





sem (F -> i48 i49 i50 i51) (F <- ratio3)
sem (F -> i48 i49 i50 i51) (F <- ratio4 ratio1)


sem (F -> i48 i49 i50 i51) (F <- ratio1 ratio3)

sem (F -> i48 i49 i50 i51) (D -> ratio1 ratio3) (F <- D)

sem (F -> i48 i49 i50 i51) (F <- ratio1 i21 i24) , standardized


sem (F -> i48 i49 i50 i51) (F <- otr)
sem (F -> i48 i49 i50 i51) (F <- ratio2)
sem (F -> i48 i49 i50 i51) (F <- ratio3)


hist ratio1 if ratio2 != 0 , bins(20)

sem (F -> i48 i49 i50 i51) (F <- ratio1)


frame change obsrubric




/*
export delimited using "${root}/${output}/transcripts.csv" , replace

* example 
mata a = st_sdata(1,"text")	 
mata printf(a)


mata b = st_sdata(67,"text")	 
mata printf(b)

mata c = st_sdata(130,"text")	 
mata printf(c)




