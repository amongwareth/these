** kernel based PLU



* Notes:
* -  51a. = sqres + 8 bins.  
* -  51b. = sqres + 9 bins.  
* -  52a. = absres + 8 bins.  
* -  52b. = absres + 9 bins.  


  	global dofiledirectoryorig= Path to directory containing do files
	global LATEXPATH = Path to directory containing latex for article
	global CLOUDPATH = Path to directory containing data
  
	global focusk = 5
	keep if select== ${focusk}
	global VVV = 51
	global APP = "sq"
		*global VVV = 52
		*global APP = "abs"

	* drop observations that will not be used for final reg anyway. (dropped 2989 obs) = last 6 months approx.
	drop if PLUvRvarW==.
	drop if Wind1DA==.





************** (Col. 3)
* for comparison, without bootstrap but weighted: 
**************

				use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear
				local binsetting "a"
				local k = ${focusk}
				local VVV = ${VVV}
				local APP = "${APP}"
				keep if select== `k'
	
		*gen rescaled PLU 
		capture drop  PLU_P_boot PLU_P_resc PLU_Q_boot PLU_Q_resc
		gen  PLU_P_boot = PLUv`VVV'`binsetting'varP`APP' 
			su PLU_P_boot, meanonly
			scalar tmpP = r(mean)
			gen PLU_P_resc = PLU_P_boot / tmpP
		gen  PLU_Q_boot = PLUv`VVV'`binsetting'varQ`APP'
			su PLU_Q_boot, meanonly
			scalar tmpQ = r(mean)
			gen PLU_Q_resc = PLU_Q_boot / tmpQ
		
		if `k'==1 | `k'==9 {
				local k = ${focusk}
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc     if select ==`k'  & SalePurchase=="Purchase", robust
				est store kernel3_`k'
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc    if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']
				est store kernel4_`k'
				est save "${CLOUDPATH}v38/Temp_data/kernelweigthed_`k'.ster", replace
		}
		else{
				local k = ${focusk}
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_P_resc PLU_Q_resc     if select ==`k'  & SalePurchase=="Purchase", robust
				est store kernel3_`k'
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_P_resc PLU_Q_resc    if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']
				est store kernel4_`k'
				est save "${CLOUDPATH}v38/Temp_data/kernelweigthed_`k'.ster", replace
}


******************************** NOW SAME BUT DROPPING 1 PLUvD (COL.3)

				use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear
				local binsetting "a"
				local k = ${focusk}
				local VVV = ${VVV}
				local APP = "${APP}"
				keep if select== `k'
	
		*gen rescaled PLU 
		capture drop  PLU_P_boot PLU_P_resc PLU_Q_boot PLU_Q_resc
		gen  PLU_P_boot = PLUv`VVV'`binsetting'varP`APP' 
			su PLU_P_boot, meanonly
			scalar tmpP = r(mean)
			gen PLU_P_resc = PLU_P_boot / tmpP
		gen  PLU_Q_boot = PLUv`VVV'`binsetting'varQ`APP'
			su PLU_Q_boot, meanonly
			scalar tmpQ = r(mean)
			gen PLU_Q_resc = PLU_Q_boot / tmpQ
		
		if `k'==1 | `k'==9 {
				local k = ${focusk}
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc     if select ==`k'  & SalePurchase=="Purchase", robust
				est store kernel3_`k'
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc    if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']
				est store kernel4_`k'
				est save "${CLOUDPATH}v38/Temp_data/kernelweigDROP_P_`k'.ster", replace
		}
		else{
				local k = ${focusk}
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc     if select ==`k'  & SalePurchase=="Purchase", robust
				est store kernel3_`k'
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro /*PLU_P_resc*/ PLU_Q_resc    if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']
				est store kernel4_`k'
				est save "${CLOUDPATH}v38/Temp_data/kernelweigDROP_P_`k'.ster", replace
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_P_resc /*PLU_Q_resc*/     if select ==`k'  & SalePurchase=="Purchase", robust
				est store kernel3_`k'
				reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_P_resc /*PLU_Q_resc*/    if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']
				est store kernel4_`k'
				est save "${CLOUDPATH}v38/Temp_data/kernelweigDROP_Q_`k'.ster", replace
}

















************
* for bootstrapping of kernel based PLUvD
	
	***** bootstrap of kernel based equation 4 forecasts
************

	use "${CLOUDPATH}v38/Temp_data/Finalrundataset.dta", clear
	global focusk = 5
	keep if select== ${focusk}
	* drop observations with missing values (dropped 2989 obs) = last 6 months approx.
	drop if PLUvRvarW==.
	drop if Wind1DA==.

	capture drop  PLU_P_boot
	capture drop  PLU_P_resc
	capture drop  PLU_Q_boot 
	capture drop  PLU_Q_resc



************************************************************* START PROG
	capture program drop my2slsforbootkernel
	program my2slsforbootkernel

* version
		local binsetting "a"
		local k = ${focusk}
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


**************************************************** stage 1 -> bucket specfic reg. 1
local endofdata = _N
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
			predict tmp`m' if e(sample), residuals 
			
			* gen deviations of residuals
			replace Kabsres`m' = abs(tmp) if _n==`obs'
			replace Ksqres`m' = tmp*tmp if _n==`obs' /*consistent with white*/
			capture drop tmp`m'


**************************************************** stage 2 -> bucket specfic reg. 2 (heteroskedasticity)			
			foreach g in /*"absres"*/ "sqres"{
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
			predict PLUvKDtmp`g'`m' if _n==`obs', xb
			scalar sizetmp = e(N)
			replace Ksamplesize`g'`m' = sizetmp if _n==`obs'
			replace PLUvKDvar`g'`m' = PLUvKDtmp`g'`m' if _n==`obs'
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
				*replace PLUv52`binsetting'var1   = PLUvKDvarabsresPrice
				*replace PLUv52`binsetting'var2   = PLUvKDvarabsresVolume
				replace PointsInBinv51`binsetting'  = KsamplesizesqresVolume
				*replace PointsInBinv52`binsetting'  = KsamplesizeabsresVolume
				drop Ksamplesize*

gen  PLU_P_boot = PLUv51`binsetting'var1 
	su PLU_P_boot, meanonly
	scalar tmpP = r(mean)
	gen PLU_P_resc = PLU_P_boot / tmpP
gen  PLU_Q_boot = PLUv51`binsetting'var2 
	su PLU_Q_boot, meanonly
	scalar tmpQ = r(mean)
	gen PLU_Q_resc = PLU_Q_boot / tmpQ


**************************************************** stage 3 -> final reg

			
		reg fxInvertQP   PLUvRvarT PLUvRvarTsq PLUvRvarW PLUvRvarWsq PLUvRvarS PLUvRvarSsq Coal Brent Gas IT2 EUA Wind1DA Hydro PLU_P_resc PLU_Q_resc     if select ==`k'  & SalePurchase=="Purchase" [aweight=PointsInBinv51`binsetting']

			drop PLU_P_boot PLU_P_resc  PLU_Q_boot  PLU_Q_resc 
			drop PointsInBinv51`binsetting'

************************************************************* END PROG
end


**************************************************** Run once and save dataset (not inside program)
 		*run prog
 		my2slsforbootkernel
 		
 		local k= ${focusk}
		save  "${CLOUDPATH}v38/Temp_data/Finaldataset_withKERNELpluDa`k'.dta", replace

**************************************************** Bootstrap (approx. 15h for 50reps)

			bootstrap _b, reps(50) seed(12345): my2slsforbootkernel
	
			est save "${CLOUDPATH}v38/Temp_data/kernelbootstrap`k'.ster", replace



























*OLD CODE: 
/*		* gen variables to fill 
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
				capture {
				replace PLUv51`binsetting'var1   = PLUvKDvarsqresPrice
				replace PLUv51`binsetting'var2   = PLUvKDvarsqresVolume
				replace PLUv52`binsetting'var1   = PLUvKDvarabsresPrice
				replace PLUv52`binsetting'var2   = PLUvKDvarabsresVolume
				replace PointsInBinv51`binsetting'  = KsamplesizesqresVolume
				replace PointsInBinv52`binsetting'  = KsamplesizeabsresVolume
				drop Ksamplesize*
				}
