$PROBLEM    PK model
$INPUT      ID TIME DV DROP DROP AMT DROP DROP DROP AGE WT
$DATA       sim_data.csv IGNORE=@
$SUBROUTINE ADVAN1 TRANS2
$PK 

 TVCL  = THETA(1) + ETA(1)
 TVV   = THETA(2) + ETA(2)
 TM50  = THETA(3)
 HL    = 0.75

 LCL    = TVCL+LOG(WT/70)*HL+LOG((AGE)/(AGE + TM50))
 LV     = TVV +LOG((WT/70))
 CL = EXP(LCL)
 V = EXP(LV)
 SC    = V

$ERROR 
 IPRED = F
 Y= IPRED*(1+EPS(1))  + EPS(2)

$THETA  (0,1,100) ; TVCL
 (0,3,100) ; TVV
 (40,100,1000) ; TM50
$OMEGA  0.05
 0.05
$SIGMA  0.015
 0.0001  FIX
$SIMULATION (277587) ONLYSIM NSUBPROBLEM=1
$TABLE      ID TIME DV AMT AGE WT FILE=mc_sim_1.tab NOAPPEND NOPRINT
            NOHEADER
;$EST METHOD=1 INTER MAXEVAL=9999 SIG=3 PRINT=5 NOABORT POSTHOC

