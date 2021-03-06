{smcl}
{hline}
help for {cmd:predsurv}{right:(Roger Newson)}
{hline}


{title:Compute predicted survival or cumulative incidence to a specified time after {helpb streg}}

{p 8 21 2}
{cmd:predsurv} {ifin} ,
  {opt t:ime(#)} {opth g:enerate(newvarname)} [
    {opt ty:pe(type)} {opt cum:inc} {opt fast}
  ]
  
{pstd}
where {it:type} specifies a {help datatypes:numeric storage type}.


{title:Description}

{pstd}
{cmd:predsurv} is intended for use in a survival time dataset set up by {helpb stset},
after {helpb streg} has been used to fit a survival time model.
It computes a survival probability or cumulative incidence for a user-specified survival time,
in the units specified by the {cmd:scale()} option of {helpb stset}.
Note that {cmd:predsurv} can do out-of-sample prediction,
if {helpb streg} has been used to fit a model on a subset of the data.


{title:Options}

{phang}
{opt time(#)} is required.
It specifies a survival time, for which survival probabilities are estimated.
Note that the times are assumed to be given in the units specified by the {cmd:scale()} option of {helpb stset},
as stored in the variable {cmd:_t} generated by {helpb stset}.

{phang}
{opth generate(newvarname)} is required.
It specifies the name of a new variable to be generated,
containing the survival probabilities, at the time specified by the {cmd:time()} option.

{phang}
{opt type(type)} specifies a {help datatypes:numeric storage type} for the generated variable
specified by the {cmd:generate()} option.
If absent, then {cmd:float} is assumed.

{phang}
{opt cuminc} specifies that the generated variable will be a cumulative incidence probability variable.
In default, it shall be a survival probablity variable.

{phang}
{opt fast} is an option for programmers.
It specifies that {cmd:predsurv} will do no extra work to restore the original dataset
if the user presses {cmd:Break}.
It is necessary because {cmd:predsurv} makes temporary changes to the variable {cmd:_t}
generated by the {helpb stset} command.
It can save time when working with very large datasets.


{title:Remarks}

{pstd}
{cmd:predsurv} is useful for out-of-sample predictions after {helpb streg}.
The predicted survival probability can be used as a positive ordinal predictor of survival,
much as the hazard ratio generated using {helpb stcox_postestimation:predict} after {helpb stcox}
can be used as a negative ordinal predictor of survival.
The fitting of survival models to a training set,
and the testing of their ordinal predictive power using out-of-sample prediction in a test set,
is discussed in {browse "http://www.stata-journal.com/article.html?article=st0198":Newson (2010)}.


{title:Examples}

{pstd}
These examples use the {cmd:cancer} dataset,
which the user can download using the {helpb webuse} command.

{pstd}
Set-up

{phang2}{cmd:. webuse cancer, clear}{p_end}
{phang2}{cmd:. stset studytime died}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. tab died, miss}{p_end}
{phang2}{cmd:. summ studytime, de}{p_end}

{pstd}
Fit model and compute median survival time and 12-month survival probability

{phang2}{cmd:. streg age, dist(weibull) strata(drug)}{p_end}
{phang2}{cmd:. predict medsurv}{p_end}
{phang2}{cmd:. summ medsurv, de}{p_end}
{phang2}{cmd:. predsurv, time(12) gene(surv12)}{p_end}
{phang2}{cmd:. summ surv12, de}{p_end}

{pstd}
Plot 12-month survival probability against median survival time

{phang2}{cmd:. scatter surv12 medsurv, yline(0.5) ylab(0(0.1)1) xline(12) xlab(0(6)60)}{p_end}

{pstd}
Note that the 12-month survival probability {cmd:s12} is above (or below) 0.5
if and only if the median survival time {cmd:medsurv} is above (or below) 12 months.


{title:Author}

{pstd}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:References}

{phang}
Newson, R. B.  2010.
Comparing the predictive powers of survival models using Harrell's {it:C} or Somers' {it:D}.
{it:Stata Journal} 10: 339-358.
Download from
{browse "http://www.stata-journal.com/article.html?article=st0198":the {it:Stata Journal} website}.


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[ST] stset}, {hi:[ST] streg}, {hi:[ST] stcox}
{p_end}
{p 4 13 2}
On-line: help for {helpb stset}, {helpb streg}, {helpb stcox}
{p_end}
