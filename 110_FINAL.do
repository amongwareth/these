* COMPUTE COMPARABLE TABLES FOR SQ-RESIDUALS. 

*** VERSION FEBRUARY 2015

* Final Do-file

/* Notes: 
------------- MAKE SURE NORMAL VERSION RUNS LAST TO ENSURE CORRECT TABLES FOR DEMAND ESTIMATION 
*/

  	macro drop _all
	global YearINIT = 2011
	global YearFIN = 2013 
	global HourINIT = 1
	global HourFIN = 24
	global vINPUT= "v38"
	global vOUTPUT= "v38"

  	global dofiledirectoryorig= Path to directory containing do files
	global LATEXPATH = Path to directory containing latex for article
	global CLOUDPATH = Path to directory containing data
  
	global focusk = 5
	
**********
* Data Prep
**********

	use "${CLOUDPATH}v38/Temp_data/DataReady_Y${YearINIT}-Y${YearFIN}.dta", clear
	* manually merged Roll_avgT24 to dataset. 
	* manually merged winddiffonly to dataset

		destring YYYY MM DD, replace
		drop Year Month
		gsort YYYY MM DD Hour SalePurchase select
		order Date Hour Price Volume SalePurchase select

	
	rename  COAL_IMPORTPRICE_EURpTON Coal
	rename  EST_PRICE_ELEC_EXPORT EExportPrice  /*in EUR*/
	rename BRENT_LDN_AVG Brent 
	rename GAS_SPOT_GBPpTHERM Gas
	rename LcWind2011 LcWind
	
	label var  Roll_Temp24 "Roll\_Temp24"
	label var  Roll_Temp240 "Roll\_Temp240"
	label var   Roll_Temp720 "Roll\_Temp720"
	label var   Roll_avgT24 "Roll\_avgT24"
	label var   Roll_avgT240 "Roll\_avgT240"

* dataprep: 
	gen IT2 = (PrevConsoH / 99400) * Gas  /*PrevConsoH not included in supply,  99400 is max of PrevConsoH */
	gen EWH = 0
	replace EWH = 1  if Hour<=4
	replace EWH = 1  if Hour>=22
	gen dfaT15 =  Roll_Temp24 -Roll_Temp240
	
	
	* generate slope of opposite function (on Demand, add fx of supply function)
	gsort select Datestata Hour SalePurchase 
	capture drop errorindic
	gen errorindic = 1 if SalePurchase[_n]==SalePurchase[_n+1]
	drop if errorindic == 1 & SalePurchase=="Purchase"
	drop errorindic
	capture drop fxInvertPQ_viaP fxInvertQP_viaP 
	capture drop Price_S_viaP Volume_S_viaP
	gen fxInvertPQ_viaP = 1/( fx[_n+1]) if SalePurchase=="Purchase"
	gen fxInvertQP_viaP = fx[_n+1] if SalePurchase=="Purchase"
	gen Price_S_viaP = Price[_n+1] if SalePurchase=="Purchase"
	gen Volume_S_viaP = Volume[_n+1] if SalePurchase=="Purchase"
	gsort SalePurchase select Datestata Hour
	gen fxInvertQP = fxInvertQP_viaP
	gen fxInvertPQ = fxInvertPQ_viaP
		
	* make points comparable by volume (not by price!) 
******************* remove to do other dimension + must rename fxinvertQP
	gen selectQ = select
	capture drop lowpk 
	capture drop selectviaP
	gen lowpk = 1 if select<5  & SalePurchase=="Purchase"
	replace selectQ =9 	if selectQ ==1  & SalePurchase=="Purchase" &  lowpk == 1
	replace selectQ =7 	if selectQ ==3  & SalePurchase=="Purchase" &  lowpk == 1
	replace selectQ =3 	if selectQ ==7  & SalePurchase=="Purchase" &  lowpk == .
	replace selectQ =1 	if selectQ ==9  & SalePurchase=="Purchase" &  lowpk == .
	rename select selectviaP
	rename selectQ select 
		* generate slope of opposite function (on Demand, add fx of supply function)
	gsort select Datestata Hour SalePurchase 
	capture drop errorindic
	gen errorindic = 1 if SalePurchase[_n]==SalePurchase[_n+1]
	drop if errorindic == 1 & SalePurchase=="Purchase"
	drop errorindic
	capture drop fxInvertPQ_viaQ fxInvertQP_viaQ 
	capture drop Price_S_viaQ Volume_S_viaQ
	gen fxInvertPQ_viaQ = 1/( fx[_n+1]) if SalePurchase=="Purchase"
	gen fxInvertQP_viaQ = fx[_n+1] if SalePurchase=="Purchase"
	gen Price_S_viaQ = Price[_n+1] if SalePurchase=="Purchase"
	gen Volume_S_viaQ = Volume[_n+1] if SalePurchase=="Purchase"
	gsort SalePurchase select Datestata Hour
	capture drop fxInvertQP fxInvertPQ 
	gen fxInvertQP = fxInvertQP_viaQ
	gen fxInvertPQ = fxInvertPQ_viaQ
	drop fxInvertPQ_viaP fxInvertQP_viaP
	order Date Hour Price Volume SalePurchase select selectviaP 
	
	**************************
	

**********
* Solar1DA prediction
**********
			capture drop IT1
			capture drop SolarRest
			gen IT1 = suncycle * Roll_avgT240 /*Interaction term 1 = suncycle * average temp no cutoff at 15 = proxy for sunangle - decided against as no change in ry of rte black box and easier interpretation*/
			global solarestimationvariables " suncycle"	

			reg Solar1DA $solarestimationvariables, robust
			est store Black_3
			
			capture drop SolarBlackBox 
			capture drop blackepsilon
			capture mat drop blackalpha 
			mat blackmat = e(b)
			mat li blackmat
			scalar blackalpha = blackmat[1,3]
			di  blackalpha

			predict blackepsilon if e(sample), residuals
			gen SolarRest = blackepsilon  /*+ blackalpha*/
			drop blackepsilon

		btoutreg2 [Black_3] using "${LATEXPATH}SolarBlack.tex", replace tex(frag pretty ) /*stats(coef  Var se)*/ label(proper)  level(95)  sideway noparen
			

		*drop irrelevant OBS and variables
			drop _est*
			drop if SolarRest==.



**********
* Black box prediction RTE
**********
			global blackestimationvariables1 " Tempeff15 Roll_Temp24  Roll_Temp240 SolarRest suncycle morning deltasun EWH"	
			global blackestimationvariables2 "Tempeff  Roll_avgT24  Roll_avgT240  SolarRest suncycle morning deltasun EWH "	
			global blackestimationvariables3 " Tempeff15 Roll_Temp24  Roll_Temp240 SolarRest suncycle morning deltasun   IT1 EWH CZlag EExportPlag"	
			global blackestimationvariables4 " Tempeff15 Roll_Temp24  Roll_Temp240 SolarRest suncycle morning deltasun   IT1 "	

		*** INTERPRETATION : coeff on tempeff15 much larger than tempeff -> positive for us. 

			reg PrevConsoH $blackestimationvariables1, robust
			est store Black_1
			
			capture drop RteBlackBox 
			capture drop blackepsilon
			capture mat drop blackalpha 
			mat blackmat = e(b)
			mat li blackmat
			scalar blackalpha = blackmat[1,9]
			di  blackalpha

			predict blackepsilon if e(sample), residuals
			gen RteBlackBox = blackepsilon  /*+ blackalpha*/
			drop blackepsilon
			
			reg PrevConsoH $blackestimationvariables2,  robust
			est store Black_2

			reg PrevConsoH $blackestimationvariables3,  robust
			est store Black_3
			
			reg PrevConsoH $blackestimationvariables4,  robust
			est store Black_4

		btoutreg2 [Black_1 Black_2 ] using "${LATEXPATH}Black1.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95)  sideway noparen
		btoutreg2 [Black_1 Black_2 Black_3 Black_4] using "${LATEXPATH}Black2.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95)  sideway noparen			

		*drop irrelevant OBS and variables
			drop _est*
			drop if RteBlackBox==.

		*save  
			save "${CLOUDPATH}v38/Temp_data/Pre4and5.dta", replace


**********
* Generate PLU using forecast model 
**********

	******
	* DEMAND ESTIMATION + generate residuals for PLU_D
	******

	* DEMAND ESTIMATION (no CZlag)
		local version "52"
		global runversionD `version'
		global demandestimationvariables`version' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "
	
	* run do file for demand estimation
		do "${CLOUDPATH}v38/DoFiles/107_Eqn4demand.do" 	




	******
	* PLUvD :  predicted uncertainty directly using regression 
	******
		* Only predict uncertainty for demand function
		* Cannot do so for supply function since mixed with ex-post own bidding strategy. 
	
		global DEV ${demandestimationvariables${runversionD}}
		
		capture drop PLUvDvarP
		capture drop PLUvDvarQ
		gen PLUvDvarP =.
		gen PLUvDvarQ =.

		forvalues k = 1(2)9{
		foreach s in /*Sell*/ Purchase{
		di "Point " `k' " Curve " "`s'"
			reg sqresVolume ${DEV} if select==`k' & SalePurchase=="`s'"
			predict PLUvDvartmpQ`k'a`s' if e(sample), xb
			est store predictuncQa`k'a`s'
			replace PLUvDvarQ = PLUvDvartmpQ`k'a`s' if e(sample)
			drop PLUvDvartmpQ`k'a`s'
		}
		}
	
		forvalues k = 1(2)9{
		foreach s in /*Sell*/ Purchase{
		di "Point " `k' " Curve " "`s'"
			reg sqresPrice ${DEV} if select==`k' & SalePurchase=="`s'"
			predict PLUvDvartmpP`k'a`s' if e(sample), xb
			est store predictuncPa`k'a`s'
			replace PLUvDvarP = PLUvDvartmpP`k'a`s' if e(sample)
			drop PLUvDvartmpP`k'a`s'
		}
		}
		
		capture drop PLUvDvarPabs
		capture drop PLUvDvarQabs
		gen PLUvDvarPabs =.
		gen PLUvDvarQabs =.

		forvalues k = 1(2)9{
		foreach s in /*Sell*/ Purchase{
		di "Point " `k' " Curve " "`s'"
			reg absresVolume ${DEV} if select==`k' & SalePurchase=="`s'"
			predict PLUvDvartmpQ`k'a`s' if e(sample), xb
			est store predictuncQa`k'a`s'ABS
			replace PLUvDvarQabs = PLUvDvartmpQ`k'a`s' if e(sample)
			drop PLUvDvartmpQ`k'a`s'
		}
		}
	
		forvalues k = 1(2)9{
		foreach s in /*Sell*/ Purchase{
		di "Point " `k' " Curve " "`s'"
			reg absresPrice ${DEV} if select==`k' & SalePurchase=="`s'"
			predict PLUvDvartmpP`k'a`s' if e(sample), xb
			est store predictuncPa`k'a`s'ABS
			replace PLUvDvarPabs = PLUvDvartmpP`k'a`s' if e(sample)
			drop PLUvDvartmpP`k'a`s'
		}
		}
		
			
		* (generating) tables on PLUvD
		btoutreg2 [predictuncPa5aPurchase predictuncPa5aPurchaseABS /*predictuncPa5aSell*/] using "${LATEXPATH}predictunc1.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) 

		btoutreg2 [predictuncQa5aPurchase predictuncQa5aPurchaseABS /*predictuncQa5aSell*/] using "${LATEXPATH}predictunc2.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) 

	* drop table data	
	drop _est*
	
	
	

	* take sqrt of squared PLUs to get other order of magnitudes
		gen PLUvDrtP = sqrt(PLUvDvarP)
		gen PLUvDrtQ = sqrt(PLUvDvarQ)


	******
	* PLUvR: LongueurCorrel Temp:
	******
	
		gen PLUvRvarT = 1 / LcTemp
		gen PLUvRvarW = 1 / LcWind
		gen PLUvRvarS = 1 / LcSolar

	* add u-shaped term
		gen PLUvRvarTsq = 1/(LcTemp * LcTemp)
		gen PLUvRvarWsq = 1/(LcWind * LcWind)
		gen PLUvRvarSsq = 1/( LcSolar * LcSolar)
		

		/* table of extracted slopes
			capture mat drop M
			local variables "1 3 5 7 9"
			local FUNC "r(mean) r(p50) r(sd) r(min) r(max)"
			local i=0
			foreach var of local variables{
			local i=`i'+1
			}
			local j=0
			foreach var of local FUNC{
			local j=`j'+1
			}
			di `j' "  " `i'
			mat M = J(`i',5,.)
			
			local c=1
			foreach FF of local FUNC{
			local r=1
			foreach VV of local variables{
			su /* fxInvertPQ */ /* fxInvertQP  if select==`VV', detail
			mat M[`r',`c']= `FF'
			local r=`r'+1
			}
			local c=`c'+1
			}
			mat rownames M =   `variables'
			mat colnames M =  Mean Median StdDev Min Max
			mat li M

			btouttable using "${LATEXPATH}extractedslopes", replace mat(M) asis nobox caption("Estimated slopes of the supply function per point k") format(%9.4fc %9.4fc %9.4fc %9.4fc %9.4fc %9.4fc) */

		*save  
			save "${CLOUDPATH}v38/Temp_data/Finaldataset.dta", replace



******
	* generate kernel based PLUs
******
			use  "${CLOUDPATH}v38/Temp_data/Finaldataset.dta", clear
					
		************* generate kernel PLUS
		 *		 do "${CLOUDPATH}v38/DoFiles/107_kernelbucketreg.do" 	
		*************

		************* dataset manipulations to obtain final dataset
				 do "${CLOUDPATH}v38/DoFiles/107_PrepkernelPLUdata.do" 	
		*************

		*save  
			save "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", replace



























*****
* Columns based on kernel PLUvD
*****
				* do "${CLOUDPATH}v38/DoFiles/107_BootstrapKernel2702.do" 	



















							**************************************************
							* START OF BASELINE RESULTS + BOOTSTRAP ROBUSTNESS
							**************************************************


********* BASELINE 


global focusk = 5


		****************
		* Some regressions:  ------------- on point k only -----------
		****************
		
			use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear

*********
* FOCUS POINT
*********
	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"

* MACROS: 
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global SupCo   "Coal Brent Gas IT2 EUA Wind1DA Hydro"

***** Program bootstrap of baseline
	capture program drop my2slsforbaselinebootstrap
	program my2slsforbaselinebootstrap
		local k=${focusk}
		capture drop  PLU_P_boot  PLU_Q_boot 
		capture drop PLUvDvarP`k'resc PLUvDvarQ`k'resc
		capture noisily reg sqresPrice Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_P_boot, xb
		su PLU_P_boot, meanonly
		scalar tmpP = r(mean)
		capture noisily gen PLUvDvarP`k'resc = PLU_P_boot / tmpP
		reg sqresVolume Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_Q_boot, xb
		su PLU_Q_boot, meanonly
		scalar tmpQ = r(mean)
		gen PLUvDvarQ`k'resc = PLU_Q_boot / tmpQ
		if `k'==1 | `k'==9 {
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLUvDvarP`k'resc*/ PLUvDvarQ`k'resc    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		else{
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarP`k'resc PLUvDvarQ`k'resc    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		capture drop  PLU_P_boot PLUvDvarP`k'resc PLU_Q_boot PLUvDvarQ`k'resc
	end


*FIRST TABLE: 
	
		*col 1
			local k=${focusk}
			capture drop PLUvDvarP`k'resc 
			capture drop PLUvDvarQ`k'resc
			su PLUvDvarP`k', meanonly
			scalar tmpresc = r(mean)
			capture noisily gen PLUvDvarP`k'resc = PLUvDvarP`k' / tmpresc
			su PLUvDvarQ`k', meanonly
			scalar tmpresc = r(mean)
			gen PLUvDvarQ`k'resc = PLUvDvarQ`k' / tmpresc
					if `k'==1 | `k'==9 {
			reg fxInvertQP   ${PLUsR} ${SupCo} /*PLUvDvarP`k'resc*/  PLUvDvarQ`k'resc 
			est store d1short1_`k'
					}
			else{
			reg fxInvertQP   ${PLUsR} ${SupCo} PLUvDvarP`k'resc  PLUvDvarQ`k'resc 
			est store d1short1_`k'
			}
		*col 2
			local k=${focusk}
			bootstrap _b, reps(200) seed(12345): my2slsforbaselinebootstrap
  			est store bs_baseline_`k'				
			est save "${CLOUDPATH}v38/Temp_data/bs_baseline_`k'.ster", replace
		*col 3
			local k=${focusk}
			estimates use "${CLOUDPATH}v38/Temp_data/kernelweigthed_`k'.ster"
			regress
			estimates esample
			estimates store kernel4_`k'
		*col 4
		local k=${focusk}
		if `k'==5{
			estimates use "${CLOUDPATH}v38/Temp_data/kernelbootstrap`k'.ster"
			regress
			estimates esample:
			estimates store kernel5_`k'
			}

		* table main
			local k=${focusk}
			if `k'==5{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' kernel5_`k'] using "${LATEXPATH}main1_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' kernel5_`k'] using "${LATEXPATH}mainNS1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' kernel5_`k'] using "${LATEXPATH}mainoS1_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}
			else{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}main1_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainNS1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainoS1_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}

	* table compare
	forvalues k=1(2)9{
	estimates use "${CLOUDPATH}v38/Temp_data/bs_baseline_`k'.ster"
	regress
	estimates esample:
	estimates store bs_baseline_`k'
	}
			btoutreg2 [bs_baseline_1 bs_baseline_3 bs_baseline_5 bs_baseline_7 bs_baseline_9] using "${LATEXPATH}compare_col2.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(Comparison of col. 2)	
			btoutreg2 [bs_baseline_1 bs_baseline_3 bs_baseline_5 bs_baseline_7 bs_baseline_9] using "${LATEXPATH}compareNS_col2.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(Comparison of col. 2)	
			
	forvalues k=1(2)9{
		estimates use "${CLOUDPATH}v38/Temp_data/kernelweigthed_`k'.ster"
		regress
		estimates esample
		estimates store kernel4_`k'
	}	
			btoutreg2 [ kernel4_1 kernel4_3 kernel4_5 kernel4_7 kernel4_9] using "${LATEXPATH}compare_col3.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(Comparison of col. 3)	
			btoutreg2 [ kernel4_1 kernel4_3 kernel4_5 kernel4_7 kernel4_9] using "${LATEXPATH}compareNS_col3.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(Comparison of col. 3)	







							**************************************************
							* END OF BASELINE RESULTS + BOOTSTRAP ROBUSTNESS
							**************************************************


							**************************************************
							* START OF DROPPING 1 PLUvDvarP or Q
							**************************************************

global focusk = 5


		****************
		* Some regressions:  ------------- on point k only -----------
		****************
		
			use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear

*********
* FOCUS POINT
*********
	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"

* MACROS: 
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global SupCo   "Coal Brent Gas IT2 EUA Wind1DA Hydro"

***** Program bootstrap of baseline
	capture program drop my2slsforbaselinebootstrap
	program my2slsforbaselinebootstrap
		local k=${focusk}
		capture drop  PLU_P_boot  PLU_Q_boot 
		capture drop PLUvDvarP`k'resc PLUvDvarQ`k'resc
		capture noisily reg sqresPrice Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_P_boot, xb
		su PLU_P_boot, meanonly
		scalar tmpP = r(mean)
		capture noisily gen PLUvDvarP`k'resc = PLU_P_boot / tmpP
		reg sqresVolume Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_Q_boot, xb
		su PLU_Q_boot, meanonly
		scalar tmpQ = r(mean)
		gen PLUvDvarQ`k'resc = PLU_Q_boot / tmpQ
		if `k'==1 | `k'==9 {
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLUvDvarP`k'resc*/ PLUvDvarQ`k'resc    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		else{
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLUvDvarP`k'resc*/ PLUvDvarQ`k'resc    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		capture drop  PLU_P_boot PLUvDvarP`k'resc PLU_Q_boot PLUvDvarQ`k'resc
	end


		*col 1
			local k=${focusk}
			capture drop PLUvDvarP`k'resc 
			capture drop PLUvDvarQ`k'resc
			su PLUvDvarP`k', meanonly
			scalar tmpresc = r(mean)
			capture noisily gen PLUvDvarP`k'resc = PLUvDvarP`k' / tmpresc
			su PLUvDvarQ`k', meanonly
			scalar tmpresc = r(mean)
			gen PLUvDvarQ`k'resc = PLUvDvarQ`k' / tmpresc
					if `k'==1 | `k'==9 {
			reg fxInvertQP   ${PLUsR} ${SupCo} /*PLUvDvarP`k'resc*/  PLUvDvarQ`k'resc 
			est store d1short1_`k'
					}
			else{
			reg fxInvertQP   ${PLUsR} ${SupCo} /*PLUvDvarP`k'resc*/  PLUvDvarQ`k'resc 
			est store d1short1_`k'
			}
		*col 2
			local k=${focusk}
			bootstrap _b, reps(200) seed(12345): my2slsforbaselinebootstrap
  			est store bs_baseline_`k'				
			est save "${CLOUDPATH}v38/Temp_data/bs_baseDROP_P_`k'.ster", replace
		*col 3
			local k=${focusk}
			estimates use "${CLOUDPATH}v38/Temp_data/kernelweigDROP_P_`k'.ster"
			regress
			estimates esample
			estimates store kernel4_`k'
		*col 4
/*		local k=${focusk}
		if `k'==5{
			estimates use "${CLOUDPATH}v38/Temp_data/kernelbootDROP_P_`k'.ster"
			regress
			estimates esample:
			estimates store kernel5_`k'
			}*/

		* table main
			local k=${focusk}
			if `k'==5{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}main1DROP_P_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainNS1DROP_P_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainoS1DROP_P_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}
			else{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}main1DROP_P_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainNS1DROP_P_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainoS1DROP_P_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}

		
			use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear

*********
* FOCUS POINT
*********
	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"

* MACROS: 
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global SupCo   "Coal Brent Gas IT2 EUA Wind1DA Hydro"

***** Program bootstrap of baseline
	capture program drop my2slsforbaselinebootstrap
	program my2slsforbaselinebootstrap
		local k=${focusk}
		capture drop  PLU_P_boot  PLU_Q_boot 
		capture drop PLUvDvarP`k'resc PLUvDvarQ`k'resc
		capture noisily reg sqresPrice Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_P_boot, xb
		su PLU_P_boot, meanonly
		scalar tmpP = r(mean)
		capture noisily gen PLUvDvarP`k'resc = PLU_P_boot / tmpP
		reg sqresVolume Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==`k'  & SalePurchase=="Purchase", robust
		predict PLU_Q_boot, xb
		su PLU_Q_boot, meanonly
		scalar tmpQ = r(mean)
		gen PLUvDvarQ`k'resc = PLU_Q_boot / tmpQ
		if `k'==1 | `k'==9 {
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarP`k'resc /*PLUvDvarQ`k'resc*/    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		else{
		reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarP`k'resc /*PLUvDvarQ`k'resc*/    if select ==`k'  & SalePurchase=="Purchase" , robust 
		}
		capture drop  PLU_P_boot PLUvDvarP`k'resc PLU_Q_boot PLUvDvarQ`k'resc
	end


	*col 1
			local k=${focusk}
			capture drop PLUvDvarP`k'resc 
			capture drop PLUvDvarQ`k'resc
			su PLUvDvarP`k', meanonly
			scalar tmpresc = r(mean)
			capture noisily gen PLUvDvarP`k'resc = PLUvDvarP`k' / tmpresc
			su PLUvDvarQ`k', meanonly
			scalar tmpresc = r(mean)
			gen PLUvDvarQ`k'resc = PLUvDvarQ`k' / tmpresc
					if `k'==1 | `k'==9 {
			reg fxInvertQP   ${PLUsR} ${SupCo} PLUvDvarP`k'resc  /*PLUvDvarQ`k'resc */
			est store d1short1_`k'
					}
			else{
			reg fxInvertQP   ${PLUsR} ${SupCo} PLUvDvarP`k'resc  /*PLUvDvarQ`k'resc */
			est store d1short1_`k'
			}
		*col 2
			local k=${focusk}
			bootstrap _b, reps(200) seed(12345): my2slsforbaselinebootstrap
  			est store bs_baseline_`k'				
			est save "${CLOUDPATH}v38/Temp_data/bs_baseDROP_Q_`k'.ster", replace
		*col 3
			local k=${focusk}
			estimates use "${CLOUDPATH}v38/Temp_data/kernelweigDROP_Q_`k'.ster"
			regress
			estimates esample
			estimates store kernel4_`k'
		*col 4
/*		local k=${focusk}
		if `k'==5{
			estimates use "${CLOUDPATH}v38/Temp_data/kernelbootDROP_Q_`k'.ster"
			regress
			estimates esample:
			estimates store kernel5_`k'
			}*/

		* table main
			local k=${focusk}
			if `k'==5{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}main1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainNS1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainoS1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}
			else{
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}main1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(coef se) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainNS1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
			btoutreg2 [d1short1_`k' bs_baseline_`k' kernel4_`k' /*kernel5_`k'*/] using "${LATEXPATH}mainoS1DROP_Q_`k'.tex", replace tex(frag pretty ) stats(se) label(proper)  level(95) title(For k=`k')	
			}








							**************************************************
							* END OF DROPPING 1 PLUvDvarP or Q
							**************************************************

							**************************************************
							* REST NOT RELEVANT
							**************************************************



********* testing on combined PLU using new ones. 


global focusk = 5


		****************
		* Some regressions:  ------------- on point k only -----------
		****************
		
			use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear



	***
	* scalefactor to adjust fx to slope 
	***
	capture drop group
		egen group= group(Datestatafrac)
	gsort group Datestata  Hour  SalePurchase select 
	capture drop slopeDpost slopeDpre slopeDatk fxscalefactor
		gen slopeDpost =.
		gen slopeDpre =.
		gen slopeDatk =.
		gen fxscalefactor =.

forvalues k= 1(2)9{
	*note in p-q dimension!
by group: replace slopeDpost  = (Volume[_n+1] - Volume[_n])/(Price[_n+1]- Price[_n]) if select==`k'

by group:	 replace slopeDpre = (Volume[_n] - Volume[_n-1])/(Price[_n]- Price[_n-1]) if select==`k'
by group:	 replace slopeDatk = abs(slopeDpost[_n]+ slopeDpre[_n])/2 if select==`k'

	capture drop tmp1 tmp2
	 egen tmp1 = mean(slopeDatk ) if select==`k'
	 egen tmp2 = mean(fx) if select==`k'
	replace fxscalefactor = tmp1 / tmp2 if select==`k'
	drop tmp1 tmp2 
	}
	capture drop fxscaled
	gen fxscaled = fx * fxscalefactor


	* scalefactor to adjust fx to slope 
	capture drop group
		egen group= group(Datestatafrac)
			gsort group Datestata  Hour  SalePurchase select 
	capture drop slopeDpostQP slopeDpreQP slopeDatkQP fxscalefactorQP
		gen slopeDpostQP =.
		gen slopeDpreQP =.
		gen slopeDatkQP =.
		gen fxscalefactorQP =.
			gen fxQP = (1/fx)
			
forvalues k= 1(2)9{
	*note in q-p dimension!
	by group: replace slopeDpostQP  = (Price[_n+1]- Price[_n])/(Volume[_n+1] - Volume[_n]) if select==`k'
	 by group: replace slopeDpreQP = (Price[_n]- Price[_n-1])/(Volume[_n] - Volume[_n-1]) if select==`k'
	 by group: replace slopeDatkQP = abs(slopeDpostQP[_n]+ slopeDpreQP[_n])/2 if select==`k'
	capture drop tmp1 tmp2
	 egen tmp1 = mean(slopeDatkQP ) if select==`k'
	 egen tmp2 = mean(fxQP) if select==`k'
	replace   fxscalefactorQP = tmp1 / tmp2 if select==`k'
	drop tmp1 tmp2 
	}
	capture drop fxscaledQP
	gen fxscaledQP = fxQP * fxscalefactorQP
	gen comparisonfx = 1/ fxscaled
* SCALING ONLY APPROPRIATE FOR K=5, otherwise too much mixing flat and vertical section.






	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"

	*gen check1 = sqrt(PLUvDvarP) / (1 / fxscaled ) 
	*gen check2= sqrt(PLUvDvarQ)
	capture drop PLUvDcomb
	capture noisily gen PLUvDcomb   = (( sqrt(PLUvDvarP) / (1 / fxscaled ) ) + sqrt(PLUvDvarQ) )^2
	capture drop PLUvDcombK
	capture noisily gen PLUvDcombK   = (( sqrt(PLUv51avarPsq) / (1 / fxscaled ) ) + sqrt(PLUv51avarQsq) )^2

	*rescale combined
	capture drop PLUvDvarC
	su PLUvDcomb, meanonly
	scalar tmpresc = r(mean)
	capture noisily gen PLUvDvarC = PLUvDcomb / tmpresc

	capture drop PLUvDvarCK
	su PLUvDcombK, meanonly
	scalar tmpresc = r(mean)
	capture noisily gen PLUvDvarCK = PLUvDcomb / tmpresc


*** REGS
	reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarC    if select ==`k'  & SalePurchase=="Purchase" , robust 
	reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarC    if select ==`k'  & SalePurchase=="Purchase" , vce(bootstrap, reps(300) seed(12345))


	reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarCK    if select ==`k'  & SalePurchase=="Purchase"  [aweight = PointsInBinv51a]














































******* 
* generate 1-dim PLUs:
*******
 	capture drop PLU_COMB*
	capture noisily gen PLU_COMBa_Dresc   = sqrt( (PLUvDvarPresc)^2 + (PLUvDvarQresc)^2 )
	capture noisily gen PLU_COMBa_Dabsresc   = sqrt( (PLUvDvarPabsresc)^2 + (PLUvDvarQabsresc)^2 )
	capture noisily gen PLU_COMBa_Drtresc   = sqrt( (PLUvDrtPresc)^2 + (PLUvDrtQresc)^2 )

	/* version b: translation approach - not allowed for rescaled variables!!
	capture noisily gen PLU_COMBb_D   =((PLUvDvarP)/ (1 / fxscaled ) ) + (PLUvDvarQ)
	capture noisily gen PLU_COMBb_Dabs   = ((PLUvDvarPabs)/ (1 / fxscaled) ) + (PLUvDvarQabs) 
	capture noisily gen PLU_COMBb_Drt   = ((PLUvDrtP)/ (1 / fxscaled ) ) + (PLUvDrtQ) */

/*	capture noisily gen PLU_COMBb_D   =((PLUvDvarP)/ (fxscaledQP ) ) + (PLUvDvarQ)
	capture noisily gen PLU_COMBb_Dabs   = ((PLUvDvarPabs)/ (fxscaledQP) ) + (PLUvDvarQabs) 
	capture noisily gen PLU_COMBb_Drt   = ((PLUvDrtP)/ (fxscaledQP ) ) + (PLUvDrtQ) */


****
* defining variables
****
		local versionS "61"
		global runversionS `versionS'
			global demandestimationvariables`version' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "
		global supplyestimationvariables`versionS' "Coal Brent Gas IT2 EUA suncycle morning deltasun EWH Wind1DA SolarRest Hydro RteBlackBox"
		global uncertaintyproxies`versionS' "PLUvDvarP PLUvDvarQ PLUvDvarPabs PLUvDvarQabs PLUvDrtP PLUvDrtQ PLUvRvarT PLUvRvarW PLUvRvarS PLUvRvarTsq PLUvRvarWsq PLUvRvarSsq PLUvDvarQresc PLUvDvarQabsresc PLUvDvarPresc PLUvDvarPabsresc PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dabsresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dabs PLU_COMBb_Drt "
		global PLUsD "PLUvDvarP PLUvDvarQ PLUvDvarPabs PLUvDvarQabs PLUvDrtP PLUvDrtQ PLUvDvarPresc PLUvDvarQresc PLUvDvarPabsresc PLUvDvarQabsresc   PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dabsresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dabs PLU_COMBb_Drt "
				global PLUsDP "PLUvDvarP`k' PLUvDvarPabs`k' PLUvDrtP`k'   "
				global PLUsDQ " PLUvDvarQ`k' PLUvDvarQabs`k' PLUvDrtQ`k' "
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global SEV ${supplyestimationvariables${runversionS}}
		global UCP ${uncertaintyproxies${runversionS}}
		di $SEV 
		di $UCP
		

***reg on demand slope as cross check to interpretation from level functional regressions:
	capture drop negfx
	gen negfx = -fx
	reg negfx   $demandestimationvariables`version', robust
	reg fx   $demandestimationvariables`version', robust
	est store demandslopepred${focusk}
		btoutreg2 [demandslopepred${focusk} ] using "${LATEXPATH}demandslopepred${focusk}.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(Demand-slope-regression at k=${focusk})
		drop _est*

		
******
* REGRESSION 1 : 

reg fxInvertQP  ${PLUsR}, robust
est store onlyplus
* all plu_renouvelable are significant, only plu wind of correct sign
reg fxInvertQP  ${PLUsR} $SEV, robust
est store onlyplur1
reg fxInvertQP  ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro, robust
est store onlyplur2
reg fxInvertQP  ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro $SEV, robust
est store onlyplur3
* when adding supply controls, only wind stay significant with correct sign, others non-sig. thats good. :)

			foreach UCP of global PLUsD{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro   `UCP' 
			est store linreg1`UCP'
			}
			
			foreach UCP1 of global PLUsDP{
			foreach UCP2 of global PLUsDQ{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro `UCP1' `UCP2' 
			est store `UCP1'`UCP2'
			}
			}
			

			
			
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarP`k'resc  PLUvDvarQ`k'resc 
			est store d1short1
			*reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarP`k'resc  PLUvDvarQ`k'resc , vce(bootstrap, rep(500))
			*est store b1short1
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUvDvarPabs`k'resc PLUvDvarQabs`k'resc   
			est store d1short2
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro  PLUvDrtP`k'resc PLUvDrtQ`k'resc 
			est store d1short3

		* (generating) regression output 
/* Shows: PLU_temperature never significant
	- wind1da : pos + sig (more wind, more uncertainty)
	- plu wind: sig + positive effect only for PLUs_on_P (longer autocorrelation wind-> more uncertainty)
	- plu wind squared : very neg + sig only for PLUs_on_P (very short or long autocorrel = low uncertainty, errors cancel out) 
	-PLU-solar never sig
	- solar1da included in plusD
	- HAVE EXCLUDED DAYTIME CONTROLS (but they are strongly included in PLUsD
	- all input prices has sig effect: coal positive and all other negative (interpretation?)
	- plu_D_on_P have negative, sigificant effects, plu_D_on_Q have positive effects, when very significant
	*/
		btoutreg2 [onlyplus  onlyplur2 onlyplur1] using "${LATEXPATH}onlypluRs.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(regression for k=`k')

		btoutreg2 [/*linreg1PLUvDvarP linreg1PLUvDvarPabs linreg1PLUvDrtP*/ linreg1PLUvDvarPresc    linreg1PLUvDvarPabsresc linreg1PLUvDrtPresc    ] using "${LATEXPATH}linregsummary1P_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(regression for k=`k')

		btoutreg2 [/*linreg1PLUvDvarQ linreg1PLUvDvarQabs    linreg1PLUvDrtQ */ linreg1PLUvDvarQresc    linreg1PLUvDvarQabsresc linreg1PLUvDrtQresc ] using "${LATEXPATH}linregsummary1Q_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(regression for k=`k')

		
		btoutreg2 [/*PLUvDvarP`k'PLUvDvarQ`k' PLUvDvarPabs`k'PLUvDvarQabs`k' PLUvDrtP`k'PLUvDrtQ`k' */  d1short1 d1short2 d1short3] using "${LATEXPATH}doublereg1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(regression for k=`k')
















		****************
		* some robustness regressions to plu_d specifications
		****************
	
*****
*****

	/*
		*********************************KERNEL BASED PLU = v52
*/

	use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear

	
* Generate 1 dimensional proxies for kernel based PLUs
**********
	
	********	
	* COMBINE P and Q uncertainty into single value on kernel based proxies. 
	********
			capture drop PLU_COMB*	
		* version a: Hypothenuse approach
		
	foreach versionD in "52a" "52b"{
			foreach switch in /*""*/ "abs"{	
			forvalues k = 1(2)9{		
capture noisily gen PLU_COMBa_v`versionD'_`switch'`k'resc   = sqrt( (PLUv`versionD'varP`switch'`k'resc)^2 + (PLUv`versionD'varQ`switch'`k'resc)^2 )
	}
	}
	}
	
		* version b: translation approach - not correct conversion anymore after rescaling!!!!
					forvalues k = 1(2)9{		
	capture noisily gen PLU_COMBb_v52a`k'   = ((PLUv52avarPabs`k')/ (1 / fxscaled ) ) + (PLUv52avarQabs`k') 
	capture noisily gen PLU_COMBb_v52b`k'   = ((PLUv52bvarPabs`k')/ (1 / fxscaled ) ) + (PLUv52bvarQabs`k') 
	}
	
/*	
						forvalues k = 1(2)9{		
	capture noisily gen PLU_COMBb_v52a`k'   = ((PLUv52avarPabs`k')/ ( fxscaledQP ) ) + (PLUv52avarQabs`k') 
	capture noisily gen PLU_COMBb_v52b`k'   = ((PLUv52bvarPabs`k')/ ( fxscaledQP ) ) + (PLUv52bvarQabs`k') 
	}
*/	

*********
* FOCUS POINT
*********
	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"
	
/*	* general placeholders
	 capture drop PLUvDvarQresc PLUvDvarQabsresc PLUvDvarPresc PLUvDvarPabsresc PLUvDrtPresc PLUvDrtQresc
	gen PLUvDvarQresc = PLUvDvarQ`k'resc
	gen PLUvDvarQabsresc = PLUvDvarQabs`k'resc
	gen PLUvDvarPresc = PLUvDvarP`k'resc
	gen PLUvDvarPabsresc = PLUvDvarPabs`k'resc
	gen PLUvDrtPresc = PLUvDrtP`k'resc
	gen PLUvDrtQresc = PLUvDrtQ`k'resc*/ 

	
****
* defining variables
****
		local versionS "61"
		global runversionS `versionS'
			global demandestimationvariables`version' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "
		global supplyestimationvariables`versionS' "Coal Brent Gas IT2 EUA suncycle morning deltasun EWH Wind1DA SolarRest Hydro RteBlackBox"
		*global uncertaintyproxies`versionS' "PLUvDvarP PLUvDvarQ PLUvDvarPabs PLUvDvarQabs PLUvDrtP PLUvDrtQ PLUvRvarT PLUvRvarW PLUvRvarS PLUvRvarTsq PLUvRvarWsq PLUvRvarSsq PLUvDvarQresc PLUvDvarQabsresc PLUvDvarPresc PLUvDvarPabsresc PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dabsresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dabs PLU_COMBb_Drt "
		*global PLUsD "PLUvDvarP PLUvDvarQ PLUvDvarPabs PLUvDvarQabs PLUvDrtP PLUvDrtQ PLUvDvarPresc PLUvDvarQresc PLUvDvarPabsresc PLUvDvarQabsresc   PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dabsresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dabs PLU_COMBb_Drt "
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global PLUsROB "PLUv52avarPabs`k' PLUv52avarQabs`k' PLUv52bvarPabs`k' PLUv52bvarQabs`k' PLUv52avarPabs`k'resc PLUv52bvarPabs`k'resc PLUv52avarQabs`k'resc PLUv52bvarQabs`k'resc PLU_COMBa_v52a_abs`k'resc PLU_COMBa_v52b_abs`k'resc PLU_COMBb_v52a`k' PLU_COMBb_v52b`k'"
		global PLUsROBa "PLUv52avarPabs`k' PLUv52avarQabs`k' PLUv52avarPabs`k'resc  PLUv52avarQabs`k'resc  PLU_COMBa_v52a_abs`k'resc  PLU_COMBb_v52a`k' "
		global PLUsROBb " PLUv52bvarPabs`k' PLUv52bvarQabs`k' PLUv52bvarPabs`k'resc  PLUv52bvarQabs`k'resc  PLU_COMBa_v52b_abs`k'resc  PLU_COMBb_v52b`k'"
		global SEV ${supplyestimationvariables${runversionS}}
		global UCP ${uncertaintyproxies${runversionS}}
		di $SEV 
		di ${PLUsROB}



*** first regression

reg fxInvertQP  ${PLUsR}, robust
est store onlyplus
reg fxInvertQP  Coal Brent Gas IT2 EUA Wind1DA Hydro, robust
est store onlycontrols
* all plu_renouvelable are sigigifcant, only plu wind of correct sign
reg fxInvertQP  ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro, robust
* when adding supply controls, only wind stay significant with correct sign, others non-sig. thats good. :)

			foreach UCP of global PLUsROB{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' 
			est store r1`UCP'
			}

		* including weighting using Pointsperbin
			foreach UCP of global PLUsROBa{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' [aweight=PointsInBinv52a]
			est store w1`UCP'
			}
			foreach UCP of global PLUsROBb{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' [aweight=PointsInBinv52b]
			est store w1`UCP'
			}


*simultaneous reg on PLu_P and PLU-Q
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUv52avarPabs`k'resc  PLUv52avarQabs`k'resc [aweight=PointsInBinv52a]
				est store w2_52a
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUv52bvarPabs`k'resc  PLUv52bvarQabs`k'resc [aweight=PointsInBinv52b]
				est store w2_52b 


		* (generating) regression output 
/* Shows: 
	- plu_r as before
	- PLU_temperature never significant
	- wind1da : pos + sig (more wind, more uncertainty)
	- plu wind: sig + positive effect only for PLUs_on_P (longer autocorrelation wind-> more uncertainty)
	- plu wind squared : very neg + sig only for PLUs_on_P (very short or long autocorrel = low uncertainty, errors cancel out) 
	-PLU-solar never sig
	- solar1da included in plusD
	- HAVE EXCLUDED DAYTIME CONTROLS (but they are strongly included in PLUsD
	- all input prices has sig effect: coal positive and all other negative (interpretation?)
	- plu_D_on_P have negative, sigificant effects, plu_D_on_Q have positive effects, when very significant
	***  PROMISING RESUTLS HERE ON ROBUSTNESS! 
	- resc variables have nonsignificnat effect when combined, significant and pos for quantities plus when individual effect. 
	*/
		btoutreg2 [/*onlyplus*/ onlycontrols r1PLUv52avarPabs`k' r1PLUv52avarQabs`k' r1PLUv52bvarPabs`k' r1PLUv52bvarQabs`k' /* r1PLUv52avarPabs`k'resc r1PLUv52bvarPabs`k'resc r1PLUv52avarQabs`k'resc r1PLUv52bvarQabs`k'resc */ r1PLU_COMBa_v52a_abs`k'resc r1PLU_COMBa_v52b_abs`k'resc r1PLU_COMBb_v52a`k' r1PLU_COMBb_v52b`k'] using "${LATEXPATH}r1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')
		btoutreg2 [/*onlyplus*/ onlycontrols w1PLUv52avarPabs`k' w1PLUv52avarQabs`k' w1PLUv52bvarPabs`k' w1PLUv52bvarQabs`k' /* w1PLUv52avarPabs`k'resc w1PLUv52bvarPabs`k'resc w1PLUv52avarQabs`k'resc w1PLUv52bvarQabs`k'resc */ w1PLU_COMBa_v52a_abs`k'resc w1PLU_COMBa_v52b_abs`k'resc w1PLU_COMBb_v52a`k' w1PLU_COMBb_v52b`k'] using "${LATEXPATH}w1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')
	
	*separate tables for individual P or Q
	
	btoutreg2 [w1PLUv52avarPabs`k' w1PLUv52avarQabs`k' w1PLUv52bvarPabs`k' w1PLUv52bvarQabs`k'] using "${LATEXPATH}w1a_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	

	btoutreg2 [w2_52a  w2_52b  w1PLU_COMBa_v52a_abs`k'resc w1PLU_COMBa_v52b_abs`k'resc /*w1PLU_COMBb_v52a`k' w1PLU_COMBb_v52b`k' */] using "${LATEXPATH}w1b_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
		
	
	/* run individually if only running first part
		drop _est*
*/

			



























		****************
		* some robustness regressions to plu_d specifications
		****************
	
*****
*****

	/*
		**************************   kernel based plus. = v51
*/

*	use "${CLOUDPATH}v38/Temp_data/FinalrundatasetK1.dta", clear
*	use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear

	
* Generate 1 dimensional proxies for kernel based PLUs
**********
	
	********	
	* COMBINE P and Q uncertainty into single value on kernel based proxies. 
	********
			capture drop PLU_COMB*	
		* version a: Hypothenuse approach
		
	foreach versionD in "51a" "51b"{
			foreach switch in /*""*/ "sq"{	
			forvalues k = 1(2)9{		
capture noisily gen PLU_COMBa_v`versionD'_`switch'`k'resc   = sqrt( (PLUv`versionD'varP`switch'`k'resc)^2 + (PLUv`versionD'varQ`switch'`k'resc)^2 )
	}
	}
	}
	
		* version b: translation approach - not correct conversion anymore after rescaling!!!!
					forvalues k = 1(2)9{		
	capture noisily gen PLU_COMBb_v51a`k'   = ((PLUv51avarPsq`k')/ (1 / fxscaled ) ) + (PLUv51avarQsq`k') 
	capture noisily gen PLU_COMBb_v51b`k'   = ((PLUv51bvarPsq`k')/ (1 / fxscaled ) ) + (PLUv51bvarQsq`k') 
	}
	
/*	
						forvalues k = 1(2)9{		
	capture noisily gen PLU_COMBb_v51a`k'   = ((PLUv51avarPsq`k')/ ( fxscaledQP ) ) + (PLUv51avarQsq`k') 
	capture noisily gen PLU_COMBb_v51b`k'   = ((PLUv51bvarPsq`k')/ ( fxscaledQP ) ) + (PLUv51bvarQsq`k') 
	}
*/	

*********
* FOCUS POINT
*********
	local k=${focusk}
	keep if select==`k' & SalePurchase=="Purchase"
	
/*	* general placeholders
	 capture drop PLUvDvarQresc PLUvDvarQsqresc PLUvDvarPresc PLUvDvarPsqresc PLUvDrtPresc PLUvDrtQresc
	gen PLUvDvarQresc = PLUvDvarQ`k'resc
	gen PLUvDvarQsqresc = PLUvDvarQsq`k'resc
	gen PLUvDvarPresc = PLUvDvarP`k'resc
	gen PLUvDvarPsqresc = PLUvDvarPsq`k'resc
	gen PLUvDrtPresc = PLUvDrtP`k'resc
	gen PLUvDrtQresc = PLUvDrtQ`k'resc*/ 

	
****
* defining variables
****
		local versionS "61"
		global runversionS `versionS'
			global demandestimationvariables`version' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "
		global supplyestimationvariables`versionS' "Coal Brent Gas IT2 EUA suncycle morning deltasun EWH Wind1DA SolarRest Hydro RteBlackBox"
		*global uncertaintyproxies`versionS' "PLUvDvarP PLUvDvarQ PLUvDvarPsq PLUvDvarQsq PLUvDrtP PLUvDrtQ PLUvRvarT PLUvRvarW PLUvRvarS PLUvRvarTsq PLUvRvarWsq PLUvRvarSsq PLUvDvarQresc PLUvDvarQsqresc PLUvDvarPresc PLUvDvarPsqresc PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dsqresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dsq PLU_COMBb_Drt "
		*global PLUsD "PLUvDvarP PLUvDvarQ PLUvDvarPsq PLUvDvarQsq PLUvDrtP PLUvDrtQ PLUvDvarPresc PLUvDvarQresc PLUvDvarPsqresc PLUvDvarQsqresc   PLUvDrtPresc PLUvDrtQresc PLU_COMBa_Dresc PLU_COMBa_Dsqresc PLU_COMBa_Drtresc PLU_COMBb_D PLU_COMBb_Dsq PLU_COMBb_Drt "
		global PLUsR "PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq"
		global PLUsROB "PLUv51avarPsq`k' PLUv51avarQsq`k' PLUv51bvarPsq`k' PLUv51bvarQsq`k' PLUv51avarPsq`k'resc PLUv51bvarPsq`k'resc PLUv51avarQsq`k'resc PLUv51bvarQsq`k'resc PLU_COMBa_v51a_sq`k'resc PLU_COMBa_v51b_sq`k'resc PLU_COMBb_v51a`k' PLU_COMBb_v51b`k'"
		global PLUsROBa "PLUv51avarPsq`k' PLUv51avarQsq`k' PLUv51avarPsq`k'resc  PLUv51avarQsq`k'resc  PLU_COMBa_v51a_sq`k'resc  PLU_COMBb_v51a`k' "
		global PLUsROBb " PLUv51bvarPsq`k' PLUv51bvarQsq`k' PLUv51bvarPsq`k'resc  PLUv51bvarQsq`k'resc  PLU_COMBa_v51b_sq`k'resc  PLU_COMBb_v51b`k'"
		global SEV ${supplyestimationvariables${runversionS}}
		global UCP ${uncertaintyproxies${runversionS}}
		di $SEV 
		di ${PLUsROB}



*** first regression

reg fxInvertQP  ${PLUsR}, robust
est store onlyplus
reg fxInvertQP  Coal Brent Gas IT2 EUA Wind1DA Hydro, robust
est store onlycontrols
* all plu_renouvelable are sigigifcant, only plu wind of correct sign
reg fxInvertQP  ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro, robust
* when adding supply controls, only wind stay significant with correct sign, others non-sig. thats good. :)

			foreach UCP of global PLUsROB{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' 
			est store r1`UCP'
			}

		* including weighting using Pointsperbin
			foreach UCP of global PLUsROBa{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' [aweight=PointsInBinv51a]
			est store w1`UCP'
			}
			foreach UCP of global PLUsROBb{
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro /*${SEV}*/ `UCP' [aweight=PointsInBinv51b]
			est store w1`UCP'
			}


*simultaneous reg on PLu_P and PLU-Q
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUv51avarPsq`k'resc  PLUv51avarQsq`k'resc [aweight=PointsInBinv51a]
				est store w2_51a
			reg fxInvertQP   ${PLUsR} Coal Brent Gas IT2 EUA Wind1DA Hydro PLUv51bvarPsq`k'resc  PLUv51bvarQsq`k'resc [aweight=PointsInBinv51b]
				est store w2_51b 


		* (generating) regression output 
/* Shows: 
	- plu_r as before
	- PLU_temperature never significant
	- wind1da : pos + sig (more wind, more uncertainty)
	- plu wind: sig + positive effect only for PLUs_on_P (longer autocorrelation wind-> more uncertainty)
	- plu wind squared : very neg + sig only for PLUs_on_P (very short or long autocorrel = low uncertainty, errors cancel out) 
	-PLU-solar never sig
	- solar1da included in plusD
	- HAVE EXCLUDED DAYTIME CONTROLS (but they are strongly included in PLUsD
	- all input prices has sig effect: coal positive and all other negative (interpretation?)
	- plu_D_on_P have negative, sigificant effects, plu_D_on_Q have positive effects, when very significant
	***  PROMISING RESUTLS HERE ON ROBUSTNESS! 
	- resc variables have nonsignificnat effect when combined, significant and pos for quantities plus when individual effect. 
	*/
		btoutreg2 [/*onlyplus*/ onlycontrols r1PLUv51avarPsq`k' r1PLUv51avarQsq`k' r1PLUv51bvarPsq`k' r1PLUv51bvarQsq`k' /* r1PLUv51avarPsq`k'resc r1PLUv51bvarPsq`k'resc r1PLUv51avarQsq`k'resc r1PLUv51bvarQsq`k'resc */ r1PLU_COMBa_v51a_sq`k'resc r1PLU_COMBa_v51b_sq`k'resc r1PLU_COMBb_v51a`k' r1PLU_COMBb_v51b`k'] using "${LATEXPATH}k1_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')
		btoutreg2 [/*onlyplus*/ onlycontrols w1PLUv51avarPsq`k' w1PLUv51avarQsq`k' w1PLUv51bvarPsq`k' w1PLUv51bvarQsq`k' /* w1PLUv51avarPsq`k'resc w1PLUv51bvarPsq`k'resc w1PLUv51avarQsq`k'resc w1PLUv51bvarQsq`k'resc */ w1PLU_COMBa_v51a_sq`k'resc w1PLU_COMBa_v51b_sq`k'resc w1PLU_COMBb_v51a`k' w1PLU_COMBb_v51b`k'] using "${LATEXPATH}k2_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')
	
	*separate tables for individual P or Q
	
	btoutreg2 [w1PLUv51avarPsq`k' w1PLUv51avarQsq`k' w1PLUv51bvarPsq`k' w1PLUv51bvarQsq`k'] using "${LATEXPATH}k2a_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	

	btoutreg2 [w2_51a  w2_51b  w1PLU_COMBa_v51a_sq`k'resc w1PLU_COMBa_v51b_sq`k'resc /*w1PLU_COMBb_v51a`k' w1PLU_COMBb_v51b`k' */] using "${LATEXPATH}k2b_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
		
	btoutreg2 [w2_51a  w2_51b w2_52a  w2_52b  ] using "${LATEXPATH}k5152_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(For k=`k')	
		

	
	/* run individually if only running first part
		drop _est*
*/

			





































******* alternative pairing  - not relevant for k=${focusk}




















*** BASELINE RESULTS:
		
	local k=${focusk}
		btoutreg2 [d1short1 bs_baseline`k' w2_51a  w2_51b] using "${LATEXPATH}comparableregs_`k'.tex", replace tex(frag pretty ) stats(coef) label(proper)  level(95) title(regression for k=`k')


































* OLD CODE (to delete)



** test in single step: ----- NOT CORRECT CODE; SINCE INCLUDE ALL EXOGENOUS IN PLU PREDICTION. 
/*ivregress 2sls  fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro (sqresPrice sqresVolume = Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox)  if select ==5  & SalePurchase=="Purchase" , robust first

ivregress 2sls  fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro (sqresPrice sqresVolume = Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox)  if select ==5  & SalePurchase=="Purchase" , vce(bootstrap, rep(200)) 


***** bootstrap example 1
/*capture drop yhat PLU_boot 
capture program drop my2slsforboot
program my2slsforboot
	reg sqresVolume Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==5  & SalePurchase=="Purchase", robust
	predict PLU_boot, xb
	reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_boot   if select ==5  & SalePurchase=="Purchase" , robust 
	drop yhat PLU_boot 
end
  bootstrap _b[PLU_boot] _se[PLU_boot], reps(50) seed(10): my2slsforboot
  bootstrap , bca reps(50) seed(10): my2slsforboot
di _se[PLU_boot]



***** bootstrap example 2
capture drop  PLU_boot 
capture drop  volhat
capture program drop my2slsforboot
program my2slsforboot
	reg Volume Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox if select ==5  & SalePurchase=="Purchase", robust
	predict yhat, xb
	gen PLU_boot = (Volume - yhat)^2
	reg fxInvertQP PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_boot   if select ==5  & SalePurchase=="Purchase" , robust 
	drop yhat PLU_boot 
end
  bootstrap _b[PLU_boot] _se[PLU_boot], reps(50) seed(10): my2slsforboot
  bootstrap , bca reps(50) seed(10): my2slsforboot
di _se[PLU_boot]

*/



	***
	* generate table of kernel variables
	***
/*		capture mat drop M
		mat M = J(9,6,.)
		local variables "  ${demandestimationvariables`version'} "
		local FUNC " r(mean) r(p50) r(sd) r(min) r(max)"
		local c=2
		foreach FF of local FUNC{
		local r=1
		foreach VV of local variables{
		su `VV', detail
		mat M[`r',`c']= `FF'
		local r=`r'+1
		}
		local c=`c'+1
		}
		mat rownames M =   `variables'
		mat colnames M = NumberBin Mean Median StdDev Min Max
		mat li M
		forvalues mm = 1/9{
		mat M[`mm', 1] =  `mm'
		}
				mat li M
*/
*		Table for Variables used in the kernel based PLU$^D$ computation: 
*		btouttable using "${LATEXPATH}multikernel", replace mat(M) asis nobox format(%9.0fc %9.1fc %9.0fc %9.0fc %9.0fc %9.0fc) longtable

						
						
						
					
