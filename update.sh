#!/bin/sh
gams modelcli.gms --instname=QBWLBeispiel.sm --iterlim=9999 --timelimit=9999 --solver=CPLEX --trace=0 --nthreads=0
python visualizestructure.py
#copy /Y ergebnisse.txt JSScheduleVisualizer\ergebnisse.txt
#copy /Y zielwerte.txt JSScheduleVisualizer\zielwerte.txt
#copy /Y jobcolors.txt JSScheduleVisualizer\jobcolors.txt
#copy /Y forgviz.pdf JSScheduleVisualizer\forgviz.pdf
#pause