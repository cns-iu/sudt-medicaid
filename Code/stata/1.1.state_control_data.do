
	***************************************************
	* Prepare data                                    *
	***************************************************  
capture log close
	log using "$logdir/compileData$S_DATE.log", replace



// CDC prescribing rate to 2017
	/* NOTES */
	//Downloaded from https://www.cdc.gov/drugoverdose/maps/rxstate2006.html
		// cdc_full_state_2006-2016.csv
		// This dataset is a combination of CDC State Level Prescription Data 
		// (pulled from cdc_opioid_prescribing_rate.xlsx) 
	clear
	import delimited "${datadir}/merged_cdc_prescription_2006_2016.csv", clear	
	ren state state_name
	ren stateabbr state_code
	sort state_code year
	tab year
	keep state_code year state_name prescribingrate
	save  "${intdir}/StateCDC_prescribingrate_2006_2016.dta",replace

	import excel using "${datadir}/2017.xlsx",  sheet("2015") first clear cellrange(A1:D52) 	
	ren State state_name
	ren StateABBR state_code
	ren X2017PrescribingRate prescribingrate
	gen year=2017
	sort state_name state_code year
	keep state_code year state_name prescribingrate
	replace state_name=lower(itrim(state_name))			
	save  "${intdir}/StateCDC_prescribingrate_2017.dta",replace	
	merge 1:1 state_code year using "${intdir}/StateCDC_prescribingrate_2006_2016.dta",nogen keep(1 2 3) 
	replace state_name=lower(itrim(state_name))			
	sort state_code state_name year
	save  "${intdir}/StateCDC_prescribingrate_2006_2017.dta",replace	
		
	
// CDC opioid overdose mortality rates (age-adjsuted) to 2017
	/* NOTES */
	//Downloaded from https: https://www.cdc.gov/nchs/data-visualization/drug-poisoning-mortality/
	clear
	import delimited "${datadir}/NCHS_-_Drug_Poisoning_Mortality_by_State__United_States.csv", clear	
	keep ageadjustedrate year ïstate
	ren ïstate state_name
	keep if year >2005
	replace state_name=lower(itrim(state_name))			
	sort state_name year
	drop if state_name =="united states" 
	save  "${intdir}/StateCDC_OUDmortalityrate_2006_2017.dta",replace	
	
// State population estimates 
	/* NOTES */
	//Downloaded from https://www.census.gov/newsroom/press-kits/2018/pop-estimates-national-state.html 
	import excel using "${datadir}/nst-est2018-01.xlsx",  sheet("NST01") clear cellrange(a10:l60) 	
	rename A state_name
	replace state_name=lower(trim(state_name))	
	drop B C
	rename D statepop2010
	rename E statepop2011
	rename F statepop2012
	rename G statepop2013
	rename H statepop2014
	rename I statepop2015
	rename J statepop2016
	rename K statepop2017
	rename L statepop2018
	replace state_name = subinstr(state_name,".","",.)	
	reshape long statepop, i(state_name) j(year)
	sort year state_name	
	save "${intdir}/state_population_year2010_2018.dta",replace	
	
// unemployment rate
	/* NOTES */
	// Downloaded from https://download.bls.gov/pub/time.series/la/
	//   la.data.3.AllStatesS" 
	// We downloaded the file to the data directory and Stat transfered it 
	// from ascii text to Stata. (use ascii delimited, and override their need for *.txt etc)
	clear
	import delimited "${datadir}/la.data.3.AllStatesS"
	keep if year>1979
	destring series_id,replace ignore ("LASST")
	gen fipstate = int(series_id/10000000000000)
	*earlier only 6 zeros in the division, now 13 zeros
	gen code=series_id-fipstate*10000000000000
	*now just 3,4,5,6
	keep if code==3
	*for the unemployment rate
	drop code
	destring period,replace ignore ("M")
	rename period month
	sort fipstate year
	collapse (mean) value, by (fipstate year)
	*my way to get the average for the year
	rename value ue
	*drop series_id footnote_codes
	sort fipstate year
	ren fipstate st_fips
	sort  st_fips year
	drop if year<2008
	tab year
	save  "${intdir}/stateuerate_annual_2009_2018.dta",replace

	// State median income
	/* NOTES */
	//Downloaded from https://www.census.gov/programs-surveys/saipe/data/datasets.html
	!unzip "${datadir}/RawSAIPEData.zip" -d "$intdir"
	 
	/* CLEAN DATA */

	//Convert each excel file to stata
	foreach x of numlist 2003/2017 {
		import excel using "$intdir/RawData/est`x'ALL.xls", clear 
		drop F G I J L M O P R S U V X Y AA AB AD AE
		rename (A B C D E H K N Q T W Z AC) ///
			(state county statename countyname pov_all_ages pov_rate_all_ages ///
			pov_0_17 pov_rate_0_17 pov_5_17 pov_rate_5_17 median_income ///
			pov_0_4 pov_rate_0_4)
		drop if statename==""
		drop in 1
		gen year=`x'
		destring *, replace	
		saveold "$intdir/RawData/est`x'ALL.dta", replace
		}	
		
	//Append all years together
	clear
	foreach x of numlist 2003/2017 {
		append using "$intdir/RawData/est`x'ALL.dta"
		}
		
	label var year "Year"
	label var state "State"
	label var county "County" 
	label var statename "State"
	label var countyname "County"
	label var pov_all_ages "Poverty Number, All Ages"
	label var pov_rate_all_ages "Poverty Rate, All Ages"
	label var pov_0_17 "Poverty Number, 0-17"
	label var pov_rate_0_17 "Poverty Rate, 0-17"
	label var pov_5_17 "Poverty Number, 5-17"
	label var pov_rate_5_17 "Poverty Rate, 5-17"
	label var median_income "Median household income"
	label var pov_0_4 "Poverty Number, 0-4"
	label var pov_rate_0_4 "Poverty Rate, 0-4"

	//Save county dataset
	preserve
	drop if county==0
	drop pov_0_4 pov_rate_0_4
	count
	tab county,m
	compress
	save "$intdir/saipe_county_2003_2017", replace

	//Save state dataset
	restore
	keep if county==0|state==11
	rename countyname statelong
	label var statelong "State"
	drop if pov_0_4==.
	drop if county==1
	drop county
	count
	tab state,m
		ren statename state_code
		ren statelong state_name
		ren state st_fips
		sort  st_fips state_code year
		codebook st_fips state_code year
		tab year
		drop if year<2008	
	compress
	save "$intdir/saipe_state_2009_2017", replace	

// compiling all data
	clear
	use "${intdir}/StateCDC_prescribingrate_2006_2017.dta",clear
	merge m:1 state_name year using  "${intdir}/StateCDC_OUDmortalityrate_2006_2017.dta", nogen
	sort state_code year
	merge m:1 state_code year using  "${intdir}/saipe_state_2009_2017.dta", keep (3) nogen	
	sort st_fips year
	merge m:1 st_fips year year using  "${intdir}/stateuerate_annual_2009_2018.dta", keep (3) nogen	

	replace year=year+1
	tab year
	
	save  "${intdir}/state_year_data2009_2017.dta",replace	
	/*Notes: we use 1-year-lag values for control variables*/
	

log close
exit
