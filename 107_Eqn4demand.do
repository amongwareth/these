


* pull in do-file: needs to draw in following global macros:

		global DEV ${demandestimationvariables${runversionD}}


* open base file:
		use "${CLOUDPATH}v38/Temp_data/Pre4and5.dta", clear


**********
* 1st step: demand  estimation
**********
	
		
* initiate variables	
		
		capture drop absres*
		capture drop sqres*
		capture drop normalres*
		capture drop stdres*
		capture drop tmp

	foreach m in Price Volume{		
		gen absres`m'=.
		gen sqres`m'=.
		gen normalres`m'=. 
		gen stdres`m'=.
	}
	

	**********
	* eqn 4 : DEMAND
	**********
	
* open loop for measure of uncertainty
	foreach m in Price Volume{
	
		* open loop for points and marketside
		forvalues i=9(-2)1{ 
		foreach k in Purchase{
		forvalues XXX=1/1{		/*Irrelevant in this setting, left for copy convenience*/
		di "Next: " "`k' " `i' " " `XXX'
				
			* reg 1a: retrieve absolute prediction errors
					
			reg `m' ${DEV} if select ==`i'  & SalePurchase=="`k'" , robust 
					
			est store DE_`m'_`k'_`i'
			
			* White test for heteroskedasticity
			
			estat imtest, white
			capture mat drop whitestat
				mat whitestat = r(chi2_h)
				di whitestat[1,1]
				global  a`m'a`k'a`i' = whitestat[1,1]
			di "next global"
			di   ${a`m'a`k'a`i'}
				if whitestat[1,1] == . {
				global  a`m'a`k'a`i' = 99999999  
				}
			di "next global"
			di   ${a`m'a`k'a`i'}
										
			* predict errors
			predict tmp if e(sample), residuals 
			
			* gen deviations of residuals
			replace absres`m' = abs(tmp) if e(sample)
			replace sqres`m' = tmp*tmp if e(sample) /*consistent with white*/
			replace normalres`m' = tmp if e(sample)
			
			* gen Stdev of residuals /*over all residuals of that regression, thus single value for all -> add only to */
			tabstat tmp if e(sample), stat(sd) save
			mat tmpstdev = r(StatTotal)
			di tmpstdev[1,1]
			replace stdres`m' = tmpstdev[1,1] if e(sample)		
			
			drop tmp
				}
			}
		}
	}



	


	
	**********
	* generate tables for demand estimation, incl white test
	**********
		
		*******
		* Tables for k=1...5
		*******
	

		foreach m in Price{
		forvalues i=9/9{ 
		foreach k in Purchase {
			btoutreg2 [DE_`m'_`k'_`i'] using "${LATEXPATH}PriceDEPur${runversionD}.tex", replace tex(frag pretty landscape) label(proper)  addstat(White, ${a`m'a`k'a`i'} )
			}
			}
			}
			foreach m in Price{
		forvalues i=7(-2)1{ 
		foreach k in Purchase {
			btoutreg2 [DE_`m'_`k'_`i'] using "${LATEXPATH}PriceDEPur${runversionD}.tex", append tex(frag pretty landscape) label(proper)  addstat(White, ${a`m'a`k'a`i'} )
			}
			}
			}

		
		foreach m in Volume{
		forvalues i=9/9{ 
		foreach k in Purchase {
			btoutreg2 [DE_`m'_`k'_`i'] using "${LATEXPATH}VolDEPur${runversionD}.tex", replace tex(frag pretty landscape) label(proper)  addstat(White, ${a`m'a`k'a`i'} )
			}
			}
			}
		foreach m in Volume{
		forvalues i=7(-2)1{ 
		foreach k in Purchase {
			btoutreg2 [DE_`m'_`k'_`i'] using "${LATEXPATH}VolDEPur${runversionD}.tex", append tex(frag pretty landscape) label(proper)  addstat(White, ${a`m'a`k'a`i'} )
			}
			}
			}


	
		
	**********
	* generate tables for heteroskedasticity test
	**********
				
		* can do later, already incl above
		* if so, then create matrix with inputs, then export. 


		drop _est*


* save
		save "${CLOUDPATH}v38/Temp_data/PreKernel_D_${runversionD}.dta", replace
	
