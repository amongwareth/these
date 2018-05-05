*DO file for robustness - 23.02

*using bucket specific linear regression. 

* checking results with kernel based plus.
	global dofiledirectoryorig= Path to directory containing do files
	global LATEXPATH = Path to directory containing latex for article
	global CLOUDPATH = Path to directory containing data
 
***************************************
* version
		local binsetting "a"
		global runversionD `binsetting'
		global demandestimationvariables`binsetting' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "

***************************************

* Define macros 
		local sensitivity 0
		local endofdata = _N
		local REP1 SolarRest
		local Numbin`REP1' 6*(1-`sensitivity')
		local REP2 deltasun
		local Numbin`REP2' 6*(1-`sensitivity')
		local REP3 Tempeff15 
		local Numbin`REP3' 6*(1-`sensitivity')
		local REP4 Roll_Temp24
		local Numbin`REP4' 6*(1-`sensitivity')
		local REP5 Roll_Temp240 
		local Numbin`REP5' 1*(1-`sensitivity')
		local REP6 suncycle 
		local Numbin`REP6' 6*(1-`sensitivity')
		local REP7 morning 
		local Numbin`REP7' 6*(1-`sensitivity')
		local REP8 EWH 
		local Numbin`REP8' 6*(1-`sensitivity')
		local REP9 RteBlackBox
		local Numbin`REP9' 6*(1-`sensitivity')
		global variablesusedkernel "${demandestimationvariables`binsetting'}"

			**********
			* Execution PLU
			**********	
									
					* open saving loop for speeding up computation
					forvalues k = 1(2)9{
					foreach s in Purchase{
					use "${CLOUDPATH}v38/Temp_data/Pre4and5.dta", clear
						keep if select==`k' & SalePurchase == "`s'" 
						local endofdata = _N
			
			* run
				quietly{
					gsort SalePurchase select Datestata Hour
		
				* gen variables to fill
				foreach m in Price Volume{
						capture drop  Kabsres`m'
						capture drop  Ksqres`m'
						capture drop  PLUvKDvarabsres`m'
						capture drop  PLUvKDvarsqres`m'
						capture drop Ksamplesizeabsres`m'
						capture drop Ksamplesizesqres`m'
						gen Kabsres`m'=0 
						gen Ksqres`m'=0 
						gen PLUvKDvarabsres`m'=0
						gen PLUvKDvarsqres`m'=0
						gen Ksamplesizeabsres`m'=0
						gen Ksamplesizesqres`m'=0
				
		
		
				forvalues obs= 1/`endofdata'{  
				* su Tempeff if _n==`obs'  			/*crosscheck*/
				* su select if _n==`obs' 			/*crosscheck*/
				local CompPoint = select[`obs']
				local CompFunc = "SalePurchase[`obs']"
				* di `CompFunc'					/*crosscheck*/
	
			foreach controlfactor in $variablesusedkernel {
				* find bincentre per controlfactor for given observation
				local Bincentre_`controlfactor' = `controlfactor'[`obs']	
				* find binwidth per control factor
				su `controlfactor', meanonly
				local topendrange`controlfactor' = r(max)
				local lowendrange`controlfactor' = r(min)
				local binwidth`controlfactor' = (r(max) - r(min))/ `=`Numbin`controlfactor'''
				
				di "----------------    `controlfactor'"
				di `=`Numbin`controlfactor'''
				di "Max: " `topendrange`controlfactor''
				di "Min: " `lowendrange`controlfactor''
				di "Binwidth: "`binwidth`controlfactor''
				di "Bincentre from current obs: " `Bincentre_`controlfactor''
				}
		
			capture reg `m' ${demandestimationvariables`version'}  ///
			if select == `CompPoint' & SalePurchase== `CompFunc' ///
			& `REP1'<= `=`Bincentre_`REP1''+ `binwidth`REP1''' & `REP1'>=`=`Bincentre_`REP1''- `binwidth`REP1''' ///
			& `REP2'<= `=`Bincentre_`REP2''+ `binwidth`REP2''' & `REP2'>=`=`Bincentre_`REP2''- `binwidth`REP2''' ///
			& `REP3'<= `=`Bincentre_`REP3''+ `binwidth`REP3''' & `REP3'>=`=`Bincentre_`REP3''- `binwidth`REP3''' ///
			& `REP4'<= `=`Bincentre_`REP4''+ `binwidth`REP4''' & `REP4'>=`=`Bincentre_`REP4''- `binwidth`REP4''' ///
			& `REP5'<= `=`Bincentre_`REP5''+ `binwidth`REP5''' & `REP5'>=`=`Bincentre_`REP5''- `binwidth`REP5''' ///
			& `REP6'<= `=`Bincentre_`REP6''+ `binwidth`REP6''' & `REP6'>=`=`Bincentre_`REP6''- `binwidth`REP6''' ///
			& `REP7'<= `=`Bincentre_`REP7''+ `binwidth`REP7''' & `REP7'>=`=`Bincentre_`REP7''- `binwidth`REP7''' ///
			& `REP8'<= `=`Bincentre_`REP8''+ `binwidth`REP8''' & `REP8'>=`=`Bincentre_`REP8''- `binwidth`REP8''' ///
			& `REP9'<= `=`Bincentre_`REP9''+ `binwidth`REP9''' & `REP9'>=`=`Bincentre_`REP9''- `binwidth`REP9''' ///
			, robust
			
			*predict residuals locally
			capture  predict tmp`m' if e(sample), residuals 
			
			* gen deviations of residuals
			capture replace Kabsres`m' = abs(tmp) if _n==`obs'
			capture replace Ksqres`m' = tmp*tmp if _n==`obs' /*consistent with white*/
			capture drop tmp`m'
			
			foreach g in "absres" "sqres"{
			capture reg K`g'`m' ${demandestimationvariables`version'} ///
			if select == `CompPoint' & SalePurchase== `CompFunc' ///
			& `REP1'<= `=`Bincentre_`REP1''+ `binwidth`REP1''' & `REP1'>=`=`Bincentre_`REP1''- `binwidth`REP1''' ///
			& `REP2'<= `=`Bincentre_`REP2''+ `binwidth`REP2''' & `REP2'>=`=`Bincentre_`REP2''- `binwidth`REP2''' ///
			& `REP3'<= `=`Bincentre_`REP3''+ `binwidth`REP3''' & `REP3'>=`=`Bincentre_`REP3''- `binwidth`REP3''' ///
			& `REP4'<= `=`Bincentre_`REP4''+ `binwidth`REP4''' & `REP4'>=`=`Bincentre_`REP4''- `binwidth`REP4''' ///
			& `REP5'<= `=`Bincentre_`REP5''+ `binwidth`REP5''' & `REP5'>=`=`Bincentre_`REP5''- `binwidth`REP5''' ///
			& `REP6'<= `=`Bincentre_`REP6''+ `binwidth`REP6''' & `REP6'>=`=`Bincentre_`REP6''- `binwidth`REP6''' ///
			& `REP7'<= `=`Bincentre_`REP7''+ `binwidth`REP7''' & `REP7'>=`=`Bincentre_`REP7''- `binwidth`REP7''' ///
			& `REP8'<= `=`Bincentre_`REP8''+ `binwidth`REP8''' & `REP8'>=`=`Bincentre_`REP8''- `binwidth`REP8''' ///
			& `REP9'<= `=`Bincentre_`REP9''+ `binwidth`REP9''' & `REP9'>=`=`Bincentre_`REP9''- `binwidth`REP9''' ///
			, robust 
			 capture predict PLUvKDtmp`g'`m' if _n==`obs', xb
			capture scalar sizetmp = e(N)
			capture replace Ksamplesize`g'`m' = sizetmp if _n==`obs'
			capture replace PLUvKDvar`g'`m' = PLUvKDtmp`g'`m' if _n==`obs'
			capture drop PLUvKDtmp`g'`m'
			}
			
			di `obs'	
							} /*close observations loop*/
				} /* closes quietly*/
			} /*close `m'*/
			
			* gen variables to fill 
				capture drop PLUv51`binsetting'var1
				capture drop PLUv51`binsetting'var2
				capture drop PLUv52`binsetting'var1
				capture drop PLUv52`binsetting'var2
				capture drop PointsInBinv51`binsetting'
				capture drop PointsInBinv52`binsetting'
				gen PLUv51`binsetting'var1 =.
				gen PLUv51`binsetting'var2 =.
				gen PLUv52`binsetting'var1 =.
				gen PLUv52`binsetting'var2 =.
				gen PointsInBinv51`binsetting' =. 
				gen PointsInBinv52`binsetting' =. 	
			* generate PLUs
				replace PLUv51`binsetting'var1   = PLUvKDvarsqresPrice
				replace PLUv51`binsetting'var2   = PLUvKDvarsqresVolume
				replace PLUv52`binsetting'var1   = PLUvKDvarabsresPrice
				replace PLUv52`binsetting'var2   = PLUvKDvarabsresVolume
				replace PointsInBinv51`binsetting'  = KsamplesizesqresVolume
				replace PointsInBinv52`binsetting'  = KsamplesizeabsresVolume
				drop Ksamplesize*
			

		
				* close saving loop for speeding up computation		
						keep Date Hour SalePurchase select PLUv51`binsetting'var1 PLUv51`binsetting'var2 PLUv52`binsetting'var1 PLUv52`binsetting'var2 PointsInBinv51`binsetting'  PointsInBinv52`binsetting' KabsresPrice KsqresPrice KabsresVolume KsqresVolume PLUvKDvarabsresPrice PLUvKDvarsqresPrice PLUvKDvarabsresVolume PLUvKDvarsqresVolume
						save "${CLOUDPATH}v38/Temp_data/KERNEL`binsetting'buck`k'and`s'.dta", replace
					}
					}	


***************************************
* version
		local binsetting "b"
		global runversionD `binsetting'
		global demandestimationvariables`binsetting' "Tempeff15 Roll_Temp24 Roll_Temp240 suncycle morning deltasun EWH SolarRest RteBlackBox "

***************************************

* Define macros 
		local sensitivity 0
		local endofdata = _N
		local REP1 SolarRest
		local Numbin`REP1' 6*(1-`sensitivity')
		local REP2 deltasun
		local Numbin`REP2' 6*(1-`sensitivity')
		local REP3 Tempeff15 
		local Numbin`REP3' 6*(1-`sensitivity')
		local REP4 Roll_Temp24
		local Numbin`REP4' 6*(1-`sensitivity')
		local REP5 Roll_Temp240 
		local Numbin`REP5' 6*(1-`sensitivity')
		local REP6 suncycle 
		local Numbin`REP6' 6*(1-`sensitivity')
		local REP7 morning 
		local Numbin`REP7' 6*(1-`sensitivity')
		local REP8 EWH 
		local Numbin`REP8' 6*(1-`sensitivity')
		local REP9 RteBlackBox
		local Numbin`REP9' 6*(1-`sensitivity')
		global variablesusedkernel "${demandestimationvariables`binsetting'}"

			**********
			* Execution PLU
			**********	
									
					* open saving loop for speeding up computation
					forvalues k = 1(2)9{
					foreach s in Purchase{
					use "${CLOUDPATH}v38/Temp_data/Pre4and5.dta", clear
						keep if select==`k' & SalePurchase == "`s'" 
						local endofdata = _N
			
			* run
				quietly{
					gsort SalePurchase select Datestata Hour
		
				* gen variables to fill
				foreach m in Price Volume{
						capture drop  Kabsres`m'
						capture drop  Ksqres`m'
						capture drop  PLUvKDvarabsres`m'
						capture drop  PLUvKDvarsqres`m'
						capture drop Ksamplesizeabsres`m'
						capture drop Ksamplesizesqres`m'
						gen Kabsres`m'=0 
						gen Ksqres`m'=0 
						gen PLUvKDvarabsres`m'=0
						gen PLUvKDvarsqres`m'=0
						gen Ksamplesizeabsres`m'=0
						gen Ksamplesizesqres`m'=0
				
		
		
				forvalues obs= 1/`endofdata'{  
				* su Tempeff if _n==`obs'  			/*crosscheck*/
				* su select if _n==`obs' 			/*crosscheck*/
				local CompPoint = select[`obs']
				local CompFunc = "SalePurchase[`obs']"
				* di `CompFunc'					/*crosscheck*/
	
			foreach controlfactor in $variablesusedkernel {
				* find bincentre per controlfactor for given observation
				local Bincentre_`controlfactor' = `controlfactor'[`obs']	
				* find binwidth per control factor
				su `controlfactor', meanonly
				local topendrange`controlfactor' = r(max)
				local lowendrange`controlfactor' = r(min)
				local binwidth`controlfactor' = (r(max) - r(min))/ `=`Numbin`controlfactor'''
				
				di "----------------    `controlfactor'"
				di `=`Numbin`controlfactor'''
				di "Max: " `topendrange`controlfactor''
				di "Min: " `lowendrange`controlfactor''
				di "Binwidth: "`binwidth`controlfactor''
				di "Bincentre from current obs: " `Bincentre_`controlfactor''
				}
		
			capture reg `m' ${demandestimationvariables`version'}  ///
			if select == `CompPoint' & SalePurchase== `CompFunc' ///
			& `REP1'<= `=`Bincentre_`REP1''+ `binwidth`REP1''' & `REP1'>=`=`Bincentre_`REP1''- `binwidth`REP1''' ///
			& `REP2'<= `=`Bincentre_`REP2''+ `binwidth`REP2''' & `REP2'>=`=`Bincentre_`REP2''- `binwidth`REP2''' ///
			& `REP3'<= `=`Bincentre_`REP3''+ `binwidth`REP3''' & `REP3'>=`=`Bincentre_`REP3''- `binwidth`REP3''' ///
			& `REP4'<= `=`Bincentre_`REP4''+ `binwidth`REP4''' & `REP4'>=`=`Bincentre_`REP4''- `binwidth`REP4''' ///
			& `REP5'<= `=`Bincentre_`REP5''+ `binwidth`REP5''' & `REP5'>=`=`Bincentre_`REP5''- `binwidth`REP5''' ///
			& `REP6'<= `=`Bincentre_`REP6''+ `binwidth`REP6''' & `REP6'>=`=`Bincentre_`REP6''- `binwidth`REP6''' ///
			& `REP7'<= `=`Bincentre_`REP7''+ `binwidth`REP7''' & `REP7'>=`=`Bincentre_`REP7''- `binwidth`REP7''' ///
			& `REP8'<= `=`Bincentre_`REP8''+ `binwidth`REP8''' & `REP8'>=`=`Bincentre_`REP8''- `binwidth`REP8''' ///
			& `REP9'<= `=`Bincentre_`REP9''+ `binwidth`REP9''' & `REP9'>=`=`Bincentre_`REP9''- `binwidth`REP9''' ///
			, robust
			
			*predict residuals locally
			capture  predict tmp`m' if e(sample), residuals 
			
			* gen deviations of residuals
			capture replace Kabsres`m' = abs(tmp) if _n==`obs'
			capture replace Ksqres`m' = tmp*tmp if _n==`obs' /*consistent with white*/
			capture drop tmp`m'
			
			foreach g in "absres" "sqres"{
			capture reg K`g'`m' ${demandestimationvariables`version'} ///
			if select == `CompPoint' & SalePurchase== `CompFunc' ///
			& `REP1'<= `=`Bincentre_`REP1''+ `binwidth`REP1''' & `REP1'>=`=`Bincentre_`REP1''- `binwidth`REP1''' ///
			& `REP2'<= `=`Bincentre_`REP2''+ `binwidth`REP2''' & `REP2'>=`=`Bincentre_`REP2''- `binwidth`REP2''' ///
			& `REP3'<= `=`Bincentre_`REP3''+ `binwidth`REP3''' & `REP3'>=`=`Bincentre_`REP3''- `binwidth`REP3''' ///
			& `REP4'<= `=`Bincentre_`REP4''+ `binwidth`REP4''' & `REP4'>=`=`Bincentre_`REP4''- `binwidth`REP4''' ///
			& `REP5'<= `=`Bincentre_`REP5''+ `binwidth`REP5''' & `REP5'>=`=`Bincentre_`REP5''- `binwidth`REP5''' ///
			& `REP6'<= `=`Bincentre_`REP6''+ `binwidth`REP6''' & `REP6'>=`=`Bincentre_`REP6''- `binwidth`REP6''' ///
			& `REP7'<= `=`Bincentre_`REP7''+ `binwidth`REP7''' & `REP7'>=`=`Bincentre_`REP7''- `binwidth`REP7''' ///
			& `REP8'<= `=`Bincentre_`REP8''+ `binwidth`REP8''' & `REP8'>=`=`Bincentre_`REP8''- `binwidth`REP8''' ///
			& `REP9'<= `=`Bincentre_`REP9''+ `binwidth`REP9''' & `REP9'>=`=`Bincentre_`REP9''- `binwidth`REP9''' ///
			, robust 
			 capture predict PLUvKDtmp`g'`m' if _n==`obs', xb
			capture scalar sizetmp = e(N)
			capture replace Ksamplesize`g'`m' = sizetmp if _n==`obs'
			capture replace PLUvKDvar`g'`m' = PLUvKDtmp`g'`m' if _n==`obs'
			capture drop PLUvKDtmp`g'`m'
			}
			
			di `obs'	
							} /*close observations loop*/
				} /* closes quietly*/
			} /*close `m'*/
			
			* gen variables to fill 
				capture drop PLUv51`binsetting'var1
				capture drop PLUv51`binsetting'var2
				capture drop PLUv52`binsetting'var1
				capture drop PLUv52`binsetting'var2
				capture drop PointsInBinv51`binsetting'
				capture drop PointsInBinv52`binsetting'
				gen PLUv51`binsetting'var1 =.
				gen PLUv51`binsetting'var2 =.
				gen PLUv52`binsetting'var1 =.
				gen PLUv52`binsetting'var2 =.
				gen PointsInBinv51`binsetting' =. 
				gen PointsInBinv52`binsetting' =. 	
			* generate PLUs
				replace PLUv51`binsetting'var1   = PLUvKDvarsqresPrice
				replace PLUv51`binsetting'var2   = PLUvKDvarsqresVolume
				replace PLUv52`binsetting'var1   = PLUvKDvarabsresPrice
				replace PLUv52`binsetting'var2   = PLUvKDvarabsresVolume
				replace PointsInBinv51`binsetting'  = KsamplesizesqresVolume
				replace PointsInBinv52`binsetting'  = KsamplesizeabsresVolume
				drop Ksamplesize*
			

		
				* close saving loop for speeding up computation		
						keep Date Hour SalePurchase select PLUv51`binsetting'var1 PLUv51`binsetting'var2 PLUv52`binsetting'var1 PLUv52`binsetting'var2 PointsInBinv51`binsetting'  PointsInBinv52`binsetting' KabsresPrice KsqresPrice KabsresVolume KsqresVolume PLUvKDvarabsresPrice PLUvKDvarsqresPrice PLUvKDvarabsresVolume PLUvKDvarsqresVolume
						save "${CLOUDPATH}v38/Temp_data/KERNEL`binsetting'buck`k'and`s'.dta", replace
					}
					}	
