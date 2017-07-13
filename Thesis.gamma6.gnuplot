set table "Thesis.gamma6.table"; set format "%.5f"
set samples 400.0; plot [x=1.19:1.2] .8/(1-(1.2/x)**(-1/.3))**-.3
