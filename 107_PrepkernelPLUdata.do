*PrepkernelPLUdata


	global dofiledirectoryorig= Path to directory containing do files
	global LATEXPATH = Path to directory containing latex for article
	global CLOUDPATH = Path to directory containing data
 

	****
	* Append kernel PLUs
	****	
	
			* on sq residuals	
	foreach binsetting in "a" "b"{
			use "${CLOUDPATH}v38/Temp_data/KERNEL`binsetting'buck1andPurchase.dta", clear
			*append 
			forvalues k = 3(2)9{
			foreach s in Purchase{
			append using "${CLOUDPATH}v38/Temp_data/Kernel`binsetting'buck`k'andPurchase.dta"
				}
				}
							
		duplicates list  SalePurchase select Date Hour
		duplicates drop  SalePurchase select Date Hour, force
		
* -  51a. = sqres + 8 bins.  
* -  51b. = sqres + 9 bins.  
* -  52a. = absres + 8 bins.  
* -  52b. = absres + 9 bins.  

				capture rename PLUv51avar1 PLUv51avarPsq
				capture rename PLUv51avar2 PLUv51avarQsq
				capture rename PLUv52avar1 PLUv52avarPabs
				capture rename PLUv52avar2 PLUv52avarQabs

				capture rename PLUv51bvar1 PLUv51bvarPsq
				capture rename PLUv51bvar2 PLUv51bvarQsq
				capture rename PLUv52bvar1 PLUv52bvarPabs
				capture rename PLUv52bvar2 PLUv52bvarQabs

				drop PLUvKD*
				save "${CLOUDPATH}v38/Temp_data/PLUKernel`binsetting'.dta", replace
				}
				
	****
	* Merge PLUs with dataset
	****	

		use "${CLOUDPATH}v38/Temp_data/Finaldataset.dta", clear		
		duplicates list  SalePurchase select Date Hour
		duplicates drop  SalePurchase select Date Hour, force
	foreach binsetting in "a" "b"{
		/* here add other versions */
	merge 1:1 SalePurchase select Date Hour using "${CLOUDPATH}v38/Temp_data/PLUKernel`binsetting'.dta", nogenerate
		}

	*save
		save "${CLOUDPATH}v38/Temp_data/Int1.dta", replace


	****
	* transpose uncertainty of k points. 
	****

		use "${CLOUDPATH}v38/Temp_data/Int1.dta", clear
			keep Date SalePurchase select Hour Datestata PLU* 
			reshape wide PLU* , i(SalePurchase Datestata Hour) j(select)
			order _all, sequential
			 gsort Datestata Hour SalePurchase
			duplicates list Date Hour SalePurchase
			duplicates drop Date Hour SalePurchase, force
		save "${CLOUDPATH}v38/Temp_data/Int2.dta", replace
	
		use "${CLOUDPATH}v38/Temp_data/Int1.dta", clear
		merge m:1 Date Hour SalePurchase using "${CLOUDPATH}v38/Temp_data/Int2.dta", nogenerate

		* drop constant plu_r
		drop PLUvRvarS1 PLUvRvarS3 PLUvRvarS5 PLUvRvarS7 PLUvRvarS9 PLUvRvarSsq1 PLUvRvarSsq3 PLUvRvarSsq5 PLUvRvarSsq7 PLUvRvarSsq9 PLUvRvarT1 PLUvRvarT3 PLUvRvarT5 PLUvRvarT7 PLUvRvarT9 PLUvRvarTsq1 PLUvRvarTsq3 PLUvRvarTsq5 PLUvRvarTsq7 PLUvRvarTsq9 PLUvRvarW1 PLUvRvarW3 PLUvRvarW5 PLUvRvarW7 PLUvRvarW9 PLUvRvarWsq1 PLUvRvarWsq3 PLUvRvarWsq5 PLUvRvarWsq7 PLUvRvarWsq9

			gsort Datestata  Hour  SalePurchase select
			order Date Datestata Hour SalePurchase select , first
			order PLU* Poin*, last	
		save "${CLOUDPATH}v38/Temp_data/Int3.dta", replace


			
			***
			* table of Points in bin and PLU and PDU
			***
					forvalues k = 5/5{		
					foreach versionD in "51a" "51b"{	
					foreach versionS in ""{
					foreach switch in /*"abs"*/ "sq"{	
						
								
				capture mat drop M`versionD'
				local variables "PLUv`versionD'varP`switch'`k' PLUv`versionD'varQ`switch'`k'  PointsInBinv`versionD' "
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
				mat M`versionD' = J(`i',5,.)
				
				local c=1
				foreach FF of local FUNC{
				local r=1
				foreach VV of local variables{
				su `VV', detail
				mat M`versionD'[`r',`c']= `FF'
				local r=`r'+1
				}
				local c=`c'+1
				}
				mat rownames M`versionD' =   `variables'
				mat colnames M`versionD' =  Mean Median StdDev Min Max
				mat li M`versionD'
		}
		}
		}
				capture mat drop Mtogether
				mat Mtogether = J(6,5,.)
				mat Mtogether = M51a \ M51b
				mat li Mtogether
					 
* Summary Statistics of PLUs and PDUs: 					 
		btouttable using "${LATEXPATH}suPDUPLU", replace mat(Mtogether) label asis nobox  format(%9.1fc %9.0fc %9.0fc %9.0fc %9.0fc) footnote(Proxies based on multi-variate kernels) longtable caption(Summary statistics of kernel based PLU$^D$ for k=`k')
		}


	**********
	* all variables of interest in purchase obs.
	**********	
	
		drop if SalePurchase=="Sell"
	
	








































* OLD CODE
/*

	***
	* scalefactor to adjust fx to slope 
	***
/*		capture drop group
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
*/



/*		
	*******
	* rescale variables
	*******
			foreach versionD in "D" "51a" "51b"{
			foreach switch in "" "abs"{	
			foreach switch2 in "var" "rt"{	
			foreach dim in "P" {
			forvalues k = 3(2)7{	
			capture noisily su PLUv`versionD'`switch2'`dim'`switch'`k', detail	
			capture noisily scalar meanPLUv`versionD'`switch2'`dim'`switch'`k' = r(mean)
			capture noisily di  meanPLUv`versionD'`switch2'`dim'`switch'`k'
			capture noisily gen PLUv`versionD'`switch2'`dim'`switch'`k'resc = PLUv`versionD'`switch2'`dim'`switch'`k' / meanPLUv`versionD'`switch2'`dim'`switch'`k'
	}
	}
	}
	}
	}
	
			foreach versionD in "D" "52a" "52b"{
			foreach switch in "" "abs"{	
			foreach switch2 in "var" "rt"{	
			foreach dim in "P" {
			forvalues k = 1(8)9{
			capture noisily su PLUv`versionD'`switch2'`dim'`switch'`k', detail	
			capture noisily scalar meanPLUv`versionD'`switch2'`dim'`switch'`k' = r(mean)
			capture noisily di  meanPLUv`versionD'`switch2'`dim'`switch'`k'
			capture noisily gen PLUv`versionD'`switch2'`dim'`switch'`k'resc = PLUv`versionD'`switch2'`dim'`switch'`k'
	}
	}
	}
	}
	}
	
			foreach versionD in "D" "52a" "52b"{
			foreach switch in "" "abs"{	
			foreach switch2 in "var" "rt"{	
			foreach dim in "Q" {
			forvalues k = 1(2)9{	
			capture noisily su PLUv`versionD'`switch2'`dim'`switch'`k', detail	
			capture noisily scalar meanPLUv`versionD'`switch2'`dim'`switch'`k' = r(mean)
			capture noisily di  meanPLUv`versionD'`switch2'`dim'`switch'`k'
			capture noisily gen PLUv`versionD'`switch2'`dim'`switch'`k'resc = PLUv`versionD'`switch2'`dim'`switch'`k' / meanPLUv`versionD'`switch2'`dim'`switch'`k'
	}
	}
	}
	}
	}
	
			order Date Datestata Hour SalePurchase select , first
			order PLU* Poin*, last	
*/
