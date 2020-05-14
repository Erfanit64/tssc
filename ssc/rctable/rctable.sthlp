{smcl}
{* *!version 1.1.0 12/03/2014}{...}
{cmd:help rctable}
{hline}
{title:Title}

{phang}
{bf:rctable} {hline 2} Simple tables for Randomized Controlled Trials




{title:Syntax}
{p 8 17 3}
{cmdab:rctable}
 {depvar} 
[if]
{weight} 
{cmd:,} {it:options}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth treat:ment(treatvar)}} specify the treatment variable to be used. Multiple branches are possible. In that case, A dummy variable per treatment branch should be included. Do not include a dummy for the control group. Interaction terms can also be included.  {p_end} 
{synopt:{opth est:imator(esttype)}} either ITT or LATE (default is ITT) {p_end} 
{synopt:{opth treated(varname)}}	  for LATE estimate, specify the "treated" variable {p_end} 
{synopt:{    opth  clust:er(varname)}}    specify the clustering variable if any {p_end} 
{synopt:{ opt      pval}}   		  display pvalues in square parenthesis under the standard error  {p_end} 
{synopt:{ opth  control(varlist)}}   specify the variables used for baseline covariate adjustment. These variables are used for every single outcome variables. You may use factor variable (fixed effects) but only if in numeric format. For control variables specific to each outcome see basecontrol option.  {p_end} 
{synopt:{ opth  basecontrol(varlist)}}   specify a specific variable use for each outcome variable. The number of outcome variable should be equal to the number of basecontrol variables  {p_end} 
{synopt:{ opt  keep }} instead of dropping the columns after running, the program keeps them in the dataset. {p_end} 
{synopt:{ opt  sd }} display the standard deviations of the average and of the control group below in square parenthesis.  
{p_end}
{synopt:{ opt  quiet }} do not show the regression outcomes. {p_end} 
{synopt:{ opt  sheet(string asis[, replace|modify])}} replace a worksheet in an already existing excel document. Sub-options replace or modify are necessary if the worksheet already exists (see export excel command) {p_end} 
{synoptline}

{p2colreset}{...}
{p 4 6 2}
{cmd:if} is allowed; see .{p_end}
{p 4 6 2}
{cmd:fweight, aweight, pweight}s are allowed; see {help weight}. {p_end} 

{title:Description}

{pstd}
 {cmd:rctable } creates regressions and tables (with the subcommand using) for experimental studies. Rctable is particularly well adadpted to Randomized Controlled Trial or any analysis comparing different (experimental) groups.  rctable creates several variables: VAR (the variable name) LAB (its label) M (the average in both groups) C (the average in the control group), and COEF1 [COEF2...] (typically the difference between a treatment branch and the control group). With the using option, rctable exports the table in an excel, csv or text format. The variables created are then 
dropped. Beware, using the command includes a replace option by default: any variable called VAR LAB M C COEF will be dropped. Rctable can also be used without using.  The command accepts multiple treatment branches and can also be used to create tables with interaction terms. For multiple treatment branches, include one dummy per treatment branch but do not include a control dummy.  

{pstd}
The csv, excel or text document created with the using subcommand can be used either directly or be linked to another master excel document. This way, the master document can be formatted and edited 
independantly while the excel documents generated by the command are updated. rctable table can also be used with listtex to create Latex tables.  

	
{title:Examples}

{phang}
Perform a simple ITT regression on several dependant varibles : {break}
{cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable)}

{phang}
Save the results in a csv table :  {break}
{cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) save(C:\mytable.csv)}

{phang}	
	Perform a simple TOT regression on several dependant varibles : {break}
 {cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) estimator(TOT) treated(treated_variable)}
 
{phang}
Edit a simple Latex table using listtex and the keep option  : {break}
 {cmd:. rctable unemployment_rate health_score cognitive_score noncognitive_score, treat(treat_variable) estimator(ITT) treated(treated_variable) keep save(C:\mytable.txt) }

#delimit ;
listtex LAB    N_ind  N_clust M C COEF  if COEF!="" | LAB!=""   using "C:\mytable.txt", replace rstyle(tabular) 
head(" \begin{table}[htbp] \centering \begin{threeparttable}[b]  \medskip 
\begin{tabularx}{10cm}{l c c c c c \toprule & N  & Cluster & Average & C  &  {T-C} \\ 
\midrule") 
foot("\hline
  \end{tabularx} 
  \fignote{}
\end{threeparttable}
\end{table}");
#delimit cr	


{title:Author}
{pstd}
Adrien Bouguen, University of California, Berkeley