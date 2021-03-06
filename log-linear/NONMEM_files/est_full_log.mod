$PROB PK model
$INPUT ID TIME DV AMT AGE WT
$DATA est.dat IGNORE=@
$SUBROUTINES ADVAN1 TRANS2
$PK

 TVCL  = THETA(1) + ETA(1)
 TVV   = THETA(2) + ETA(2)
 TM50  = THETA(3)
 HL    = THETA(4)

 LCL    = TVCL+LOG(WT/70)*0.75+LOG((AGE**HL)/(AGE**HL + TM50**HL))
 LV     = TVV +LOG((WT/70))
 CL = EXP(LCL)
 V = EXP(LV)
 SC    = V

$THETA
 (0,  1.01,   100)        ; TVCL
 (0,  3,   100)       ; TVV
 (0, 25,  1000)         ; TM50
 (0, 5, 20)            ; HL
$OMEGA
 0.05 
 0.05 
$SIGMA
 0.015
 0.0015
$ERROR
 IPRED = F
 Y= IPRED*(1+EPS(1))+EPS(2)

;$SIM (1000) ONLYSIM NSUBPROBLEM=1
;$TABLE ID TIME DV AMT FILE=outA.tab NOAPPEND NOPRINT NOHEADER
$EST METHOD=1 INTER MAXEVAL=9999 SIG=3 PRINT=5 NOABORT POSTHOC
$COV UNCONDITIONAL
;$COV MATRIX=S UNCONDITIONAL
