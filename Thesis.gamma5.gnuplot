set table "Thesis.gamma5.table"; set format "%.5f"
set samples 50.0; plot [x=0:1.19] .8/(1-(1.2/x)**(-1/.3))**-.3
