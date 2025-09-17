clear all 

global folder /Users/steffenerickson/Documents/GitHub/SERA/observationstudy/analysis/textmessagesurvey
include /Users/steffenerickson/Documents/GitHub/stata_programs/00_fullstack.ado
use ${folder}/sms.dta , clear 

egen id = group(id_partner id_school id_teacher)
tempvar temp
encode tms01, gen(`temp')
drop tms01
rename `temp' tms01
destring tms04, replace
replace tms04 =0 if tms01 == 1 
recode tms01 (1=0) (2=1)
//gen datevar = date(textweek, "MD20Y")
gen double datetimevar = clock(startdate, "YMDhms")
format datetimevar %tc
sort datetimevar
sort id datetimevar
by id: gen n = _n 
egen nvals = nvals(n), by(id)
tab nvals
drop if nvals == 1



//keep if nvals > 8
//keep if n < 10
//scatter tms04 datetimevar 
//mixed tms04 || id:
//mvgstudy (tms04 = id n|id)
mixed tms01 || id:
mvgstudy (tms01 = id n|id)

//mkf results 

levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms01 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps1)[1,1],r(df)[1,1]))
}
preserve 
clear 
svmat r 
mean r1 [aweight =r2]
scalar pvar = r(table)[1,1]
restore

levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms01 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps2)[1,1],r(df)[2,1]))
}
preserve 
clear 
svmat r 
mean r1 [aweight =r2]
scalar nvar = r(table)[1,1]
restore

di pvar / (pvar + nvar) * 100
di nvar / (pvar + nvar) * 100



levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms04 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps1)[1,1],r(df)[1,1]))
}
preserve 
clear 
svmat r 
mean r1 [aweight =r2]
scalar pvar = r(table)[1,1]
restore

levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms04 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps2)[1,1],r(df)[2,1]))
}
preserve 
clear 
svmat r 
mean r1 [aweight =r2]
scalar nvar = r(table)[1,1]
restore

di pvar / (pvar + nvar) * 100
di nvar / (pvar + nvar) * 100










levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms01 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps1)[1,1],r(df)[1,1]))
}
preserve 
clear 
svmat r 
mean r1 [aweight =r2]
restore




















levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mvgstudy (tms04 = id n|id) if n <= `v'
	matrix r = (nullmat(r) \ (r(covcomps1)[1,1],r(df)[1,1]))
}
preserve 
clear 
svmat r 
mean r1 [weight =r2]
restore







levelsof nvals, local(lvls)
cap matrix drop r
foreach v of local lvls {
	mixed tms04 || id: if n <= `v'
}








mvgstudy (tms04 = id n|id) if nvals == 7






