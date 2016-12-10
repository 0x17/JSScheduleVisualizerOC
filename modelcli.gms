$ontext
example parameters: --instname=QBWLBeispiel.sm --iterlim=99999 --timelimit=99999 --solver=CPLEX --trace=0 --nthreads=1 --zfactor=0.5

STj=tk bzw. FTj=tk bedeutet, dass AG j am Ende von Periode k anfängt bzw. beginnt.
tk als Zeitpunkt interpretiert bedeutet also Ende der Periode k.
$offtext

$eolcom §

*$set instname ProjectStructureData

$setglobal use_seed

options OPTCR = 0
        MIP = %solver%
        RESLIM = %timelimit%
        THREADS = %nthreads%
        ITERLIM = %iterlim%;

**** DECLARATIONS ************************************************

sets j Arbeitsgänge
     t Perioden
     r Ressourcen;

alias(j,i);
alias(t,tau);

sets pred(i,j) yes gdw. i Vorgänger von j ist
     tw(j, t) yes gdw. t im Zeitfenster von j liegt
     actual(j) yes gdw. Job kein Dummy
     lastJob(j) yes gdw. Job letzter AG
     fw(j, t, tau) yes gdw. AG j in tau beendet werden kann wenn er in t lief;

parameters
         seedsol(j)      Startloesung
         solvetime       CPU-Zeit
         slvstat         Termination status
         modelstat       Model solution status
         zmax(r)         Maximale ZK
         kappa(r)        Kosten pro Einheit ZK
         capacities(r)   Kapazitäten
         durations(j)    Dauern
         u(t)            Erlös (Parabel) bei Makespan t
         efts(j)         Früheste Startzeitpunkte
         lfts(j)         Späteste Endzeitpunkte
         demands(j,r)    Bedarf;

binary variable  x(j,t) 1 gdw. AG j in Periode t endet d.h. FTj=t;
variables        z(r,t) Einheiten ZK von r in Periode t gebucht
                 profit Gewinn (Parabel);

equations
                objective   Weitere ZF
                precedence  Vorrangbeziehung durchsetzen
                resusage    Ressourcenverbrauchsrestriktion
                once        Jeden AG genau 1x einplanen
                oclimits    Beschränke buchbare ZK;
                
**** EQUATIONS ************************************************

objective                 .. profit =e= sum(j$lastJob(j), sum(t$tw(j,t), x(j,t)*u(t)))-sum(r, sum(t, z(r,t)*kappa(r)));
precedence(i,j)$pred(i,j) .. sum(t$tw(i,t), ord(t)*x(i,t)) =l= sum(t$tw(j,t), ord(t)*x(j,t)) - durations(j);
resusage(r,t)             .. sum(j$actual(j), demands(j,r)*sum(tau$fw(j,t,tau), x(j,tau))) =l= capacities(r) + z(r,t);
once(j)                   .. sum(t$tw(j,t), x(j,t)) =e= 1;
oclimits(r,t)             .. z(r,t) =l= zmax(r);

model rcpspoc  /objective, precedence, resusage, once/;
rcpspoc.optfile = %trace%;

**** SET / PARAM INIT ************************************************

$GDXIN %instname%.gdx
$load j t r zmax kappa capacities durations u efts lfts demands pred seedsol
$GDXIN

*** MODIFY ZMAX ******
loop(r, zmax(r) = capacities(r) * %zfactor%);
*** /MODIFY ZMAX *****

tw(j, t)$(efts(j) <= ord(t) and ord(t) <= lfts(j)) = yes;
actual(j)$(1 < ord(j) and ord(j) < card(j)) = yes;
lastJob(j)$(ord(j) = card(j)) = yes;
fw(j, t, tau)$(ord(tau)>=ord(t) and ord(tau)<=ord(t)+durations(j)-1 and tw(j,tau)) = yes;
z.lo(r,t) = 0;
z.up(r,t) = zmax(r);
profit.lo = 0;

********************************************* SEED ************************************************

$ifthen setglobal use_seed
$log using seed solution!
  loop(j,
    loop(t,
      if(seedsol(j) = ord(t)-1 - durations(j),
        x.l(j,t) = 1;
      else
        x.l(j,t) = 0)));
  profit.l = 0;
  z.l(r,t) = 0;
$else
$log seed solution disabled!
$endif

********************************************* SOLVE STATEMENTS ************************************************

*execute_unload 'DebugOutput.gdx';
*$exit

solve rcpspoc using mip maximizing profit;

solvetime = rcpspoc.resusd;
slvstat = rcpspoc.solvestat;
modelstat = rcpspoc.modelstat;

********************************************* FILE OUTPUT ************************************************

*execute_unload '%instname%_results.gdx' x.l x.m z.l z.m profit.l profit.m solvetime slvstat modelstat;
*display z.l;

file fpprops /activityproperties.txt/;
put fpprops;
loop(j, put durations(j):<4:0 /);
loop(r,loop(j, put demands(j,r):<4:0 /));
putclose fpprops;

file fppstruct /projectstructure.txt/;
put fppstruct;
loop(i, loop(j, if(pred(i,j), put ord(i):>4:0 '->':2 ord(j):<4:0 /)));
putclose fppstruct;

file fp /myschedule.txt/;
put fp;
scalar stj;
loop(j,
  loop(t$tw(j,t),
    if(x.l(j,t)=1,
      stj = ord(t) - durations(j) - 1;
      put ord(j):>4:0 '->':2 stj:<4:0 / )));
putclose fp

file fpprof /myprofit.txt/;
put fpprof;
put round(profit.l,4)
putclose fpprof;

file fpopt /optimality.txt/;
put fpopt;
if(modelstat = 1 and slvstat = 1,
  put 'optimal' /;
else
  put 'not-optimal' /;
);
putclose fpopt;

parameters sts(j) startzeiten;
scalar stj;
loop(j, sts(j) = -1);
loop(j,
  loop(t,
    if(x.l(j,t)=1,
      stj = ord(t) - durations(j) - 1;
      sts(j) = stj)));

file fpjs /jsdata.txt/;
put fpjs;
put card(j) /;
put card(r) /;
loop(j, put durations(j) /);
loop(r, put capacities(r) /);
loop(r, loop(j, put demands(j, r) /));
loop(j, put sts(j) /);
putclose fpjs;

scalar makespan;
loop(j, if(ord(j) = card(j), makespan = sts(j);));

file fp5 /jsobjdata.txt/
put fp5;
put profit.l /;
put makespan /;
putclose fp5;