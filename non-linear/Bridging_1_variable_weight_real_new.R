
##Simulated bridging study of IV admin. drug X with true 1 comp kinetics from
# 25 y.o. adults with weight 70 to infants 3 monts -2 years old and
## simulated values (the truth) in this case will be c(TM50=80 (WEEKS),hill=2.4)



#set path to the directory where this file is located
if(Sys.getenv("LOGNAME")=="ahooker"){
  setwd("~/Documents/_PROJECTS/AOD/repos/mbaod_sim/non-linear")
} else {
  setwd("C:/Users/erist836/Documents/GitHub/mbaod_sim/non-linear")  
}


# remove things from the global environment
rm(list=ls())

if(Sys.getenv("LOGNAME")=="ahooker"){
  devtools::load_all("~/Documents/_PROJECTS/PopED/repos/PopED")
} else {
  devtools::load_all("C:/Users/erist836/Documents/GitHub/PopED")
}
library(mvtnorm)
library(xpose4)

# load the MBAOD package change to your relevant load call
if(Sys.getenv("LOGNAME")=="ahooker"){
  devtools::load_all("~/Documents/_PROJECTS/AOD/repos/MBAOD")
} else {
  devtools::load_all("C:/Users/erist836/Documents/GitHub/MBAOD")
}

# load the PopED model file 
source("PopED_files/poped.mod.PK.1.comp.maturation_real_new.R")
# load the weight estimator file
source("get_weight.R")
source("stop_critX_2.R")
source("mbaod_simulate.R")

############################################RUN THIS SECTION FOR MBAOD WITH no Misspecification############################################
#Adults
step_1=list(
  design = list(
    groupsize = 100,
    a = c(age_group=c(7)),
    xt = c(0.1, 2, 6, 12, 24)
  ),
  optimize=NULL,
  simulate=list(target="NONMEM", model="NONMEM_files/sim_propofol.mod",
                data=list(dosing = list(list(AMT=1000,Time=0)),
                          manipulation = list(expression(PMA <- age_group_2_PMA(ID,age_group)),
                                              expression(WT <- get_weight(ID,PMA,probs = c(0.1,0.9))),
                                              expression(AMT <- AMT*(WT/70))
                          )
                )
                
  ),
  estimate=list(target="NONMEM", model="NONMEM_files/est_red_propofol.mod")
)

##Initial Design space for the age groups. subadults 12-18 y.o. and adults.
##If only adults and subadults are allowed, the information about TM50 is too sparse.
a.space <- cell(6,1)
a.space[,] <- list(c(1,2,3,4,5,6))
#x.space[,] <- list(c(6,7))

###




#First cohort with children
step_2 = list(
  design = list(
    groupsize = 2,
    m=6,
    a = cbind(age_group=c(6,5,4,3,2,1)),
    #a = t(rbind(age_group=c(6,6,6,6,6))),
    xt = c(0.1, 2, 6, 12, 24)
  ),
  optimize=list(target="poped_R",
                model = list(
                  ff_file="PK.1.comp.maturation.ff",
                  fError_file="feps.add.prop",
                  fg_file="PK.1.comp.maturation.fg"
                ),
                design_space=list(#minxt=0,
                                  #maxxt=24,
                                  a_space = a.space
                ),
                parameters=list(
                  bpop=c(TM50=3.651, HILL=1.5261), #log of parameters. change to tm50= 3.862 and hill=1.224 for misspec
                  manipulation=NULL # manipulation of initial parameters
                ),
                settings.db=list(
                  notfixed_sigma=c(1,0),
                  notfixed_bpop = c(1,1,1,1)
                ),
                settings.opt=list(
                  opt_xt=F,
                  opt_a=T,
                  parallel=F,
                  method=c("LS"), 
                  loop_methods=T
                  # opt_x=T,
                  # bUseRandomSearch= 0,
                  # bUseStochasticGradient = 0,
                  # bUseBFGSMinimizer = 0,
                  # bUseLineSearch = 1,
                  # bUseExchangeAlgorithm=0,
                  # EACriteria = 1,
                  # compute_inv=F
                )
  ),
  simulate=list(target="NONMEM", model="NONMEM_files/sim_propofol.mod",
                data=list(
                  dosing = list(list(AMT=1000,Time=0)),
                  manipulation = list(expression(PMA <- age_group_2_PMA(ID,age_group)),
                                      expression(WT <- get_weight(ID,PMA,probs = c(0.1,0.9))),
                                      expression(AMT <- AMT*(WT/70))
                  )
                )                      
                
  ),
  estimate=list(target="NONMEM", model="NONMEM_files/est_full_propofol.mod") #Change to est_full_gfr.mod for misspec
)

a.space <- cell(1,1)
#a.space[,] <- list(c(6))
a.space[,] <- list(c(1:6))
step_3 <- step_2
step_3$optimize$parameters <- NULL
step_3$design$groupsize <- 1
step_3$design$a <- t(rbind(age_group=c(6,6)))
step_3$design$m <- 2
step_3$optimize$design_space$a_space<- a.space

results_mbaod_small <- mbaod_simulate(cohorts=list(step_1,step_2,step_3), # anything after step_3 is the same as step_3
                                      #ncohorts=50, # number of steps or cohorts in one AOD
                                      ncohorts=50, # allowed number of steps or cohorts in one AOD
                                      rep=100, #number of times to repeat the MBAOD simulation 
                                      name="propofol_run", lower_limit=0.6,higher_limit=1.4,
                                      description="50 possible steps",
                                      seednr=1234, stop_crit_fun = stop_critX_2,
                                      run_commands="-retries=5", 
                                      ci_corr=0,option=3)

## to check reproducibility
# results_mbaod_small_2 <- mbaod_simulate(cohorts=list(step_1,step_2,step_3), # anything after step_3 is the same as step_3
#                                       #ncohorts=50, # number of steps or cohorts in one AOD
#                                       ncohorts=2, # allowed number of steps or cohorts in one AOD
#                                       rep=1, #number of times to repeat the MBAOD simulation 
#                                       name="propofol_run", lower_limit=0.6,higher_limit=1.4,
#                                       description="25 steps, 1st step one group, steps 2-10 have 1 added group per step",
#                                       seednr=1234, stop_crit_fun = NULL,#stop_critX_2,
#                                       run_commands="-retries=5", 
#                                       ci_corr=0,option=3)
# 
# all(results_mbaod_small$iteration_1$est_summary==results_mbaod_small_2$iteration_1$est_summary,na.rm = T)
# all(results_mbaod_small$iteration_1$final_design$a==results_mbaod_small_2$iteration_1$final_design$a)
# 
