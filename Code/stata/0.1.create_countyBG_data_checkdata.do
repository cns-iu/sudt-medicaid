
* 		File Description
*************************************************
*Author: Thuy Nguyen
*Date created: 12/01/2017
*Date modified: 12/15/2017
*Purpose: step 2: merging data

// Version of stata
version 15

// Close any open log files
capture log close

// Clear Memory
clear all

// Set Date
global date = subinstr("$S_DATE", " ", "-", .)

// Set your file paths.
global basedir "/N/dc2/scratch/thdnguye/PlosOneBG"   // Root folder directory that contains the subfolders for constructing the dataset and estimation
global intdir "${basedir}/intermediate_results" // Path for temp folder
global datadir "${basedir}/data"  // Path for raw data
global finaldatadir "${basedir}/DataForAnalysis"  // Path for data used in analysis
global sourcedir "${basedir}/Scripts" // Path for running the scripts to create tables and figures
global plotdir "${basedir}/Figures"  // Path for tables/figures output
global tabledir "${basedir}/Tables" // Path for tables/figures output
global logdir "${basedir}/Logs" // Path for logs


/* Start log */
capture log close
log using "${logdir}/pdmp_allstep.log", replace

capture log close

cd "${basedir}"

// Specify Screen Width for log files
set linesize 255

// Set font type
graph set window fontface "Times New Roman"

// Allow the screen to move without having to click more
set more off

// Drop everything in mata
matrix drop _all

// Install Stata Packages
local install_stata_packages 0

// Install Packages if needed, if not, make a note of this. This should be a comprehensive list of all additional packages needed to run the code.
if `install_stata_packages' {
	ssc install carryforward, replace
	ssc install estout, replace	
	ssc install reghdfe, replace
	ssc install blindschemes, replace
	ssc install coefplot, replace
	ssc install statastates, replace 
	ssc install ftools, replace
	ssc install shp2dta, replace
	ssc install spmap, replace
	ssc install sumup, replace
	
	ssc install distinct, replace
	ssc install unique, replace
	ssc install statastates, replace
	net get statastates.dta, replace
	ssc install binscatter, replace
}
else  {
	di "All packages up-to-date"
}

	clear
	import excel "/Box/thdnguye/Papers/Paper 016 - Job postings - treatment facilities/main-export.xlsx",firstrow
	save "${intdir}/main_2010_2018.dta", replace
	
	use "${intdir}/main_2010_2018.dta", clear
	*keep if socname=="Registered Nurses"
	*keep if employer!="Providence Service Corporation Maine"
	*keep if employer=="Sweetser"
	
	gen count=1
	collapse (sum) count, by(jobdate)
	
	sort jobdate
	twoway line count jobdate, ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings") ylabel(,labsize(small))
	graph export "${plotdir}/All_SUDT_posting_Maine.png" ,  replace	 width(4000)
	

	use "${intdir}/main_2010_2018.dta", clear
	*keep if socname=="Registered Nurses"
	keep if employer!="Providence Service Corporation Maine"
	*keep if employer=="Sweetser"
	
	gen count=1
	collapse (sum) count, by(jobdate)
	
	sort jobdate
	twoway line count jobdate, ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings") ylabel(,labsize(small))
	graph export "${plotdir}/All_SUDT_posting_Providence_Service_Corporation.png" ,  replace	 width(4000)
	

	use "${intdir}/main_2010_2018.dta", clear
	*keep if socname=="Registered Nurses"
	*keep if employer!="Providence Service Corporation Maine"
	keep if employer=="Sweetser"
	
	gen count=1
	collapse (sum) count, by(jobdate)
	
	sort jobdate
	twoway line count jobdate, ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings") ylabel(,labsize(small))
	graph export "${plotdir}/All_SUDT_posting_Sweetser.png" ,  replace	 width(4000)	

	use "${intdir}/main_2010_2018.dta", clear
	drop if employer=="Providence Service Corporation Maine"
	drop if employer=="Sweetser"
	
	gen count=1
	collapse (sum) count, by(jobdate)
	
	sort jobdate
	twoway line count jobdate, ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings") ylabel(,labsize(small))
	graph export "${plotdir}/All_SUDT_posting_other_employers.png" ,  replace	 width(4000)	
		


	clear
	import excel "/Box/thdnguye/Papers/Paper 016 - Job postings - treatment facilities/main-export.xlsx",firstrow

	*keep if socname=="Registered Nurses"
	*keep if employer!="Providence Service Corporation Maine"
	*keep if employer=="Sweetser"
	
	gen count=1
	collapse (sum) count, by(jobdate)
	
	sort jobdate
	twoway line count jobdate, 
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings ") ylabel(,labsize(small))
	graph export "${plotdir}/Maine.png" ,  replace	 width(4000)
		
	
	
	codebook
	keep if employer!="Providence Service Corporation Maine"
	keep if employer=="Sweetser"

	codebook 
	sort jobdate employer fips city socname cleantitle
	duplicates tag jobdate employer fips city socname cleantitle,gen(dup)
	tab dup
	tab jobdate
	gen t=jobdate
	
	keep if t==19616|t==19632|t==19677|t==19563|t==19565
	***************************************************
	* Read BG data                                    *
	***************************************************    
log using "$logdir/BGdata_naic4$S_DATE.log", replace


use "/N/dc2/projects/SPEAHTEMP/DataSets/QCEW/Gendata/QCEW_2010_2018.dta",clear

keep if industry_code=="62" | industry_code=="622210" | industry_code=="621420" ///
| industry_code=="623220"| industry_code=="722511"| industry_code=="621330"| industry_code=="621112" ///
| industry_code=="6232"| industry_code=="6222"| industry_code=="6214" ///
| industry_code=="623210"| industry_code=="621410"| industry_code=="621491" ///
| industry_code=="621492"| industry_code=="621493"| industry_code=="621498"


tostring year, gen(year_st)
tostring qtr, gen(qtr_st)
gen year_qtr = year_st+"_"+qtr_st

collapse (mean) qtrly_estabs month1_emplvl total_qtrly_wages  , by(industry_code year_qtr area_fips)
rename qtrly_estabs est_
rename total_qtrly_wages wage_
rename month1_emplvl emp_
gen avg_wage_=wage_/emp_
destring  industry_code, replace
reshape wide est_ wage_ emp_ avg_wage, i(area_fips year_qtr) j(industry_code)
drop if strpos( area_fips ,"C")>0
drop if strpos( area_fips ,"U")>0
split year_qtr, parse("_")
ren year_qtr1 year_st
ren year_qtr2 qtr_st
destring year_st,gen(year)
destring qtr_st,gen(qtr)
drop *_st
sort area_fips year qtr
	
		foreach y in est_ wage_ emp_ avg_wage_ {
		ren `y'622210 `y'Hospital
		ren `y'621420 `y'Outpatient
		ren `y'623220 `y'Residential
		ren `y'722511 `y'Food
		ren `y'621330 `y'MentalNdoc
		ren `y'621112 `y'Mentaldoc		 
		}

save "${intdir}/qcew_2010_2018.dta", replace

use "${intdir}/qcew_2010_2018.dta",clear
	destring area_fips,gen(fips_digit)
	drop area_fips
	ren fips_digit fips
	sort fips year
	collapse (sum) est_62 emp_62 wage_62 avg_wage_62 est_6214 emp_6214 wage_6214 avg_wage_6214 est_6222 emp_6222 wage_6222 avg_wage_6222 est_6232 emp_6232 wage_6232 avg_wage_6232 est_Mentaldoc emp_Mentaldoc wage_Mentaldoc avg_wage_Mentaldoc est_MentalNdoc emp_MentalNdoc wage_MentalNdoc avg_wage_MentalNdoc est_621410 emp_621410 wage_621410 avg_wage_621410 est_Outpatient emp_Outpatient wage_Outpatient avg_wage_Outpatient est_621491 emp_621491 wage_621491 avg_wage_621491 est_621492 emp_621492 wage_621492 avg_wage_621492 est_621493 emp_621493 wage_621493 avg_wage_621493 est_621498 emp_621498 wage_621498 avg_wage_621498 est_Hospital emp_Hospital wage_Hospital avg_wage_Hospital est_623210 emp_623210 wage_623210 avg_wage_623210 est_Residential emp_Residential wage_Residential avg_wage_Residential est_Food emp_Food wage_Food avg_wage_Food,by(fips year)
	
	save "${intdir}/QCEW_county_regression2011_2018_plot.dta",replace
// Converting csv files to BG county stata files
	
	import delimited "${datadir}/BGT Extract NAICS4/naics4-county-year.csv",  clear
	sort fips year
reshape wide count, i(fips year) j(naics4)
	ren count6214 count_Outpatient
	ren count6222 count_Hospital
	ren count6232 count_Residential	
	tab year
	sort fips year
	save "${intdir}/count_county_SUD2010_2018.dta",replace
	
// mortality rates
	import delimited "${datadir}/NCHS_-_Drug_Poisoning_Mortality_by_County__United_States_2017.csv",  clear
	ren ïfips fips
	ren modelbaseddeathrate mortality_rate
	tab urbanruralcategory,gen(URBAN)
	keep URBAN* fips year mortality_rate population urbanruralcategory fipsstate
	replace year=year+1
	keep if year>=2010
	sort fips year
	merge m:1 fips year using "${intdir}/count_county_SUD2010_2018.dta"
	drop if _merge==2
	drop _merge
	foreach var in count_Outpatient count_Hospital count_Residential {
	replace `var'=0 if `var'==.
	}
	
	replace population =subinstr(population,",","",.)	
	destring population, gen(cty_population) force
	drop population 
	
	gen count_SUD =count_Outpatient+count_Hospital+count_Residential
	
	foreach var in SUD Outpatient Hospital Residential  {
	gen `var'Pop=count_`var'/cty_population*100000
	sum,detail
	}
	ren fipsstate st_fips
	sort st_fips year
	
	merge m:1 st_fips year using  "${intdir}/state_year_data2009_2017.dta",nogen
	
	sort fips year
	merge m:1 fips year using  "${intdir}/QCEW_county_regression2011_2018_plot.dta",force
	
	
// Medicaid expansion 

	gen expansion4=.

	label var expansion4 "0 is no expansion, 1 is full expansion, 2 is mild expansion, 3 is substantial expansion"
	local control AL AK FL GA ID IN KS LA MI MS ME MO MT NE NH NC OK PA SC SD TN TX UT VA WY 
	foreach x in `control' { 
	replace expansion4=0 if state_code==`"`x'"'
	      }
	      
	local treatment AZ AR CO IL IA KY MD NV NM NJ ND OH OR RI WV  WA 
	foreach x in `treatment' { 
	replace expansion4=1 if state_code==`"`x'"'
	       }      
	local mild DE DC MA NY VT
	foreach x in `mild' {
	replace expansion4=2 if state_code==`"`x'"'
	       }
	local medium CA CT HI MN WI
	foreach x in `medium' {
	replace expansion4=3 if state_code==`"`x'"'
	       }
	//Account for mid-year expansions
	replace expansion4=1 if state_code=="MI"  //MI expanded in April 2014
	replace expansion4=1 if state_code=="NH"  //NH expanded in August 2014
	replace expansion4=1 if state_code=="PA"  //PA expanded in Jan 2015 
	replace expansion4=1 if state_code=="IN" //IN expanded in Feb 2015
	replace expansion4=1 if state_code=="AK"  //AK expanded in Sept 2015
	replace expansion4=1 if state_code=="MT" //MT expanded in Jan 2016 
	replace expansion4=1 if state_code=="LA" //LA expanded in July 2016
	*Maine's Medicaid expansion is approved but not yet implemented, so we will consider ME a non-expansion state.

	//3 category expansion info
	gen expansion3=expansion4
	label var expansion3 "0 is no expansion, 1 is full expansion, 2 is mild/substantial expansion"
	recode expansion3 3=2

	//2 category expansion info
	gen expansion2=expansion4
	label var expansion2 "0 is no expansion, 1 is any expansion"
	recode expansion2 3=1 2=1
	label var expansion2 "Expansion"
	gen post=year>=2014
	label var post "Post-2014"
		     
	// medicaid expansion - time varying
	gen expansion_post=post*expansion2
		label var expansion_post "Expansion$\times$Post-2014"

	replace expansion_post=0 if state_code=="MI"&year<2014  //MI expanded in April 2014
		replace expansion_post=(12-4+1)/12 if state_code=="MI"&year==2014  //MI expanded in April 2014	
	replace expansion_post=0 if state_code=="NH"&year<2014  //NH expanded in August 2014
		replace expansion_post=(12-8+1)/12 if state_code=="NH"&year==2014  //NH expanded in August 2014
	replace expansion_post=0 if state_code=="PA"&year<2015  //PA expanded in Jan 2015 
	replace expansion_post=0 if state_code=="IN"&year<2015  //IN expanded in Feb 2015
		replace expansion_post=(12-2+1)/12 if state_code=="IN"&year==2015
	replace expansion_post=0 if state_code=="AK"&year<2015  //AK expanded in Sept 2015
		replace expansion_post=(12-9+1)/12 if state_code=="IN"&year==2015
	replace expansion_post=0 if state_code=="MT"&year<2016 //MT expanded in Jan 2016 
	replace expansion_post=0 if state_code=="LA"&year<2016 //LA expanded in July 2016
		replace expansion_post=(12-7+1)/12 if state_code=="LA"&year==2016
	

	tab expansion2 expansion_post

// create panel data for regression analyses
	codebook state_code year st_fips 
	codebook median_income prescribingrate ageadjustedrate pov_rate_all_ages ue
	
	histogram count_SUD	

	xtset fips year
	gen lmedian_income=log(median_income)
	label var lmedian_income "Median income, logged"
	label var prescribingrate "Opioid prescribing rates"	
	label var ageadjustedrate "Drug poisoning death rates"	
	label var pov_rate_all_ages "Poverty rates, \%"	
	label var ue "Unemployment rates, \%"	
	
	
save  "${finaldatadir}/AllpostSUDCounty2010_2018_compiled.dta",replace
		

	gen NCHSURCodes3=1
	replace NCHSURCodes3=2 if URBAN4==1
	replace NCHSURCodes3=3 if URBAN5==1

	label define NCHSURCodes3l 1 "Metropolitan" 2 "Micropolitan" 3 "Rural" 
	label values NCHSURCodes3 NCHSURCodes3l
	
// correlation between BG data and QCEW 
	gen emp_SUD =emp_Outpatient+emp_Hospital+emp_Residential
	gen est_SUD =est_Outpatient+est_Hospital+est_Residential
	
	
	twoway  (lfitci emp_SUD count_SUD), by(year,total row(2))  ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Employment-QCEW") ylabel(,labsize(small)) ///
	xtitle("Job postings-BGT") xlabel(,labsize(small))
	graph export "${plotdir}/SUD_QCEW.png" ,  replace	 width(4000)

	twoway  (lfitci est_SUD count_SUD), by(year,total row(2))  ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Establishment-QCEW") ylabel(,labsize(small)) ///
	xtitle("Job postings-BGT") xlabel(,labsize(small))
	graph export "${plotdir}/SUD_QCEW_est.png" ,  replace	 width(4000)
	
	foreach var in SUD Outpatient Hospital Residential  {
	twoway lfitci `var'Pop mortality_rate, by(NCHSURCodes3,total row(2)) ///
	 graphregion(color(white)) legend(off) ///
	ytitle("Postings per 100,000 residents") ylabel(,labsize(small))
	graph export "${plotdir}/`var'_opioid_mort_rural.png" ,  replace	 width(4000)
	}
			
		
		
		
		
log close
exit
