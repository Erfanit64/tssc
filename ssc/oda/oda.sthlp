{smcl}
{* *! version 1.1.0 10Feb2020}{...}
{* *! version 1.0.0 07Jan2020}{...}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col:{hi:oda} {hline 2}} Optimal Discriminant Analysis  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 14 2}
{cmd:oda} {cmd:}{it:classvar} {it:attributes} {ifin} 
{cmd:,} {opt pathc:ta(filepath)} 
[ {opt sto:re(filepath)} 
{opt iter(string)}
{opt dir:ection(string)}
{opt seed(string)} 
{opt cat} 
{opt wt(varname)}
{opt miss:ing(integer)}  
{opt gen(varname)}
{opt pri:mary(string)} 
{opt sec:ondary(string)}
{opt name(string)}
{opt deg:en}
{opt nopriors}
{opt loo}
{opt sidak(integer)} 
]

{pstd}
{it:classvar} must be binary; {it:attribute} may be binary, ordinal, nomimal, or continuous. If {it:attribute} is treated as categorical, it must have more categories than the {it:classvar}


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{synopt:{opt patho:da}{cmd:(}{it:filepath}{cmd:)}}specify the file path of the megaODA.exe file; {cmd: pathoda() is required}  {p_end}
{synopt:{opt sto:re}{cmd:(}{it:filepath}{cmd:)}}specify the file path to store all files and output generated by {cmd:oda}; default is the current working directory  {p_end}
{synopt:{opt name}{cmd:(}{it:string}{cmd:)}}provide name for all files produced; default is name of the {it:attribute} {p_end}
{synopt:{opt iter}{cmd:(}{it:#}{cmd:)}}perform # random permutations  {p_end}
{synopt:{opt dir:ection}{cmd:(}{it:#}{cmd:)}}compute one-sided {it:p}-values. "<" or "lt" indicates that the {it:classvar} values are ordered in the “less-than” direction. ">" or "gt" 
indicates the {it:classvar} values are ordered in the “greater-than” direction. The value list must contain every value of the {it:classvar} currently defined  {p_end}
{synopt:{opt seed}{cmd:(}{it:#}{cmd:)}}set random-number seed to # {p_end}
{synopt:{opt cat}}indicates that the {it:attribute} should be treated as a categorical variable {p_end}
{synopt:{opt wt}{cmd:(}{it:varname}{cmd:)}}weight variable for use in weighted analyses {p_end}
{synopt:{opt miss:ing}{cmd:(}{it:#}{cmd:)}}integer value (positive or negative) indicating missing values {p_end}
{synopt:{opt gen}{cmd:(}{it:varname}{cmd:)}}a dummy variable indicating two or more independent samples; The {cmd:gen()} solution is a model which, when it is independently 
applied to the indicator groups, maximizes the worst performance observed {p_end}
{synopt:{opt pri:mary}{cmd:(}{it:string}{cmd:)}}specify the primary criterion for choosing among multiple optimal solutions. 
Options are "maxsens", "meansens", "samplerep", "balanced", "distance", "random", or "genmean"; The default is
"maxsens" when priors is on, and "meansens" when the {cmd:nopriors} option is specified {p_end}
{synopt:{opt sec:onday}{cmd:(}{it:string}{cmd:)}}specify the secondary criterion for choosing among multiple optimal solutions. 
Options are the same as {cmd:primary()}; The default is "samplerep" {p_end}
{synopt:{opt deg:en}}allow degenerate cutpoints; default is off {p_end}
{synopt:{opt nopriors}}turn priors off; default is on {p_end}
{synopt:{opt loo}}specify that leave-one-out (jackknife) analysis be performed; {cmd:loo} cannot be specified together with both {cmd:wt()} and {cmd:cat()} {p_end}
{synopt:{opt sidak}{cmd:(}{it:#}{cmd:)}}specifies that Sidak adjusted {it:p}-values be displayed for {it:p}-values derived from the permutation test and {cmd:loo}; 
An integer value must be provided to represent the number of comparisons to adjust for {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{p2colreset}{...}				

	
{title:Description}

{pstd}
{cmd:oda} is a wrapper program for the Optimal Discriminant Analysis (ODA) software (Yarnold & Soltysik 2005, 2016). Therefore, 
ODA must be installed in order for the {cmd:oda} Stata package to work. ODA software is available at {browse "https://odajournal.com/resources/"}. 

{pstd}
Optimal discriminant analysis is a machine learning algorithm that was introduced over 25 years ago to offer an alternative analytic 
approach to conventional statistical methods commonly used in research (Yarnold & Soltysik 1991). Its appeal lies in its simplicity, 
flexibility and accuracy as compared with conventional statistical methods (Yarnold & Soltysik 2005, 2016). 


{title:Remarks}

{pstd} 
To briefly describe how an ODA model is obtained, assume we have a continuous outcome (attribute) and a binary treatment (class) variable. 
First, we order the outcome variable from low to high. Next, we find all the points along the continuum of the outcome in which the next 
value belongs to an individual from the alternate class than that of the previous value (e.g. the next value belongs to a treated subject, 
whereas the previous value belongs to a control). The cutpoint thus represents the mean value of the outcome at this point: cutpoint = 
(previous value + current value)/2. Directionality defines how cutpoints are used to classify individual observations. The two directions 
are "less than" (controls have lower values on the outcome than treated subjects) and "greater than" (controls have higher values on the 
outcome than treated subjects). For an exploratory "two-tailed" hypothesis (controls and treated subjects have different values on the 
outcome), both directions are evaluated by the ODA algorithm. For a confirmatory "one-tailed" hypothesis (controls have lower values), 
only the appropriate direction (less than) is evaluated. For each cutpoint along the continuum of the outcome, ODA assesses how well 
the model – that is, the combination of cutpoint and direction – correctly predicts (in the current example) that controls have values 
of the outcome less than or equal to the cutpoint, and treated subjects have values of the outcome greater than the cutpoint (Yarnold & 
Soltysik 1991, 2005, 2016).

{pstd} 
Optimal discriminant analysis relies on three measures of accuracy to identify the optimal (maximum accuracy) model – that is, the exact 
combination of cutpoint and direction that produces the most accurate predictions possible for the sample. Sensitivity or true positive 
rate is the proportion of actual treated subjects that are correctly predicted by the ODA model – that is, those who have a value on the 
outcome that lies above the cutpoint. Specificity or true negative rate is the proportion of actual control subjects that are correctly 
predicted by the ODA model – that is, those who have a value on the outcome that lies at or below the cutpoint. The third measure 
of accuracy combines these two metrics and is called the {it:effect strength for sensitivity} or ESS (Yarnold & Soltysik 2005, 2016). ESS is a 
chance-corrected (0 = the level of accuracy expected by chance) and a maximum-corrected (100 = perfect prediction) index of predictive accuracy. The 
formula for computing ESS for a binary (two-category) case classification result is as follows:

{pstd}
ESS = [(Mean Percent Accuracy in Classification – 50)]/ 50 x 100%, where {p_end}

{pstd}
Mean Percent Accuracy in Classification = (sensitivity + specificity)/2 x 100. {p_end}
  
{pstd}
The ODA algorithm iterates through each successive cutpoint and calculates ESS. The maximally accurate model is that which has the cutpoint and direction 
with the highest associated value of ESS. Based on simulation research, ESS values <25% conventionally indicate a relatively weak effect, 25-50% indicate 
a moderate effect, 50–75% indicate a relatively strong effect and >75% indicate a strong effect (Yarnold & Soltysik 2005, 2016). Optimal discriminant 
analysis also computes {it:P}-values to assess the statistical reliability (or ‘significance’) of the maximally accurate ODA model. {it:P}-values are estimated 
using Monte Carlo permutation experiments. For example, in models with a binary treatment, this involves repeatedly shuffling subjects’ treatment 
assignment at random, holding their outcome value fixed at its true value. In each permuted dataset, the ESS is recorded, and the permutation {it:P}-value 
represents the proportion of all permuted datasets in which the ESS is higher than the ESS of the maximally accurate ODA model (Yarnold & Soltysik 1991, 2005, 2016).

{pstd}
Finally, ODA can be implemented using cross-validation to assess the generalizability of the model, using leave-one-out jackknife cross-validation. This typically 
entails first estimating a model using a training sample and calculating the accuracy measures, followed by applying the same model to one or more hold-out 
(test) samples and then recalculating the accuracy measures. If the accuracy measures remain consistent with those of the original model using the entire sample,
then the model is considered generalizable. This may be important, for example, if the goal of the analysis is to assist researchers identify new candidates for 
participation in an ongoing intervention or initiate the intervention in other settings. Cross-validation is less important if the goal is only to estimate treatment 
effects of the existing intervention.

{pstd}
Users are strongly encouraged to read Yarnold & Soltysik [2016] for a comprehensive guide to using ODA. Additional references are provided below that detail the use of
ODA for causal inferential problems.  


{title:Options}

{p 4 8 2}
{cmd:pathoda(}{it:filepath}{cmd:)} file path where the megaODA.exe is located on the user's computer (e.g. "C:\ODA\"). {cmd: pathoda() is required}.

{p 4 8 2}
{cmd:store(}{it:filepath}{cmd:)} file path to store all files and output generated by {cmd:oda} (e.g. "C:\ODA\output\"). Default is the current working directory.

{p 4 8 2}
{cmd:name(}{it:string}{cmd:)} provides a name for all files produced (extensions such as .csv, .out, .txt  will be added accordingly). Default is name of the {it:attribute}. 

{p 4 8 2}
{cmd:iter(}{it:#}{cmd:)} specifies the number of random permutations to perform. When {cmd:iter(#)} is not specified, permutation {it:P}-values are not computed.

{p 4 8 2}
{cmd:direction(}{it:string}{cmd:)} compute one-sided {it:P}-values. "<" or "lt" indicates that the {it:classvar} values are ordered in the “less-than” direction. ">" or "gt" 
indicates the {it:classvar} values are ordered in the “greater-than” direction. The value list must contain every value of the {it:classvar} currently 
defined, and each character must be separated with a space (e.g. "< 0 1 2" or "lt 0 1 2" or "> 3 2 1" or "gt 3 2 1"). By default, two-sided {it:P}-values are 
computed (i.e no directional hypothesis).

{p 4 8 2}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed in order to generate reproducible permutation {it:P}-values. 

{p 4 8 2}
{cmd:cat} indicates that the {it:attribute} should be treated as a categorical variable. The default is to treat the {it:attribute} as ordered (continuous).
If {cmd:cat} is specified, the {it:attribute} must have more categories than {it:classvar} or else an error will be issued. 

{p 4 8 2}
{cmd:wt(}{it:varname}{cmd:)} indicates the weight variable for use with weighted analyses. {cmd:wt()} cannot be the same variable specified as either the {it:classvar} 
or {it:attribute}; ODA treats {cmd: weight()} as an importance weight (see {helpb weight}).

{p 4 8 2}
{cmd:missing(}{it:#}{cmd:)} is an integer value (positive or negative) indicating missing values. It is common in surveys to code missing values as 99, 999, 9999, -99, etc.  

{p 4 8 2}
{cmd:gen(}{it:varname}{cmd:)} indicates a dummy variable indicating two or more independent samples; The {cmd:gen()} solution is a model which, when it is independently 
applied to the indicator groups, maximizes the worst performance observed amongst all samples.

{p 4 8 2}
{cmd:primary(}{it:string}{cmd:)} specifies the primary criterion for choosing among multiple optimal solutions. 
Options are "maxsens", "meansens", "samplerep", "balanced", "distance", "random", or "genmean". "maxsens" is maximum sensitivity; 
"meansens" is the mean of the sensitivities of the separate classes; "samplerep" selects the pattern of predicted class membership most
closely resembling the sample class membership; "balanced" selects the solution in which the sensitivity of the actual classes is most similar amongst each
other; "distance" selects the solution with smallest maximum (over all cutpoints) distance between the cutpoints and their boundaries; "random" selects a 
randomly chosen solution; "genmean" is used only when {cmd:gen} is in effect and selects the solution with maximum mean (weighted) sensitivity
over all {cmd:gen} groups. The default is "maxsens" when priors is on, and "meansens" when the {cmd:nopriors} option is specified. 

{p 4 8 2}
{cmd:secondary(}{it:string}{cmd:)} specifies the secondary criterion for choosing among multiple optimal solutions. The choice of criterion is the same 
as {cmd:primary}; The default is "samplerep". 

{p 4 8 2}
{cmd:degen} allows degenerate cutpoints. {cmd:degen} allows flexibility in data sets which have small or no representation in some classes. Conversely, when {cmd:degen} is
not specified, the resulting ODA solution must have at least one observation assigned to each predicted class.

{p 4 8 2}
{cmd:nopriors} by default, ODA weights analyses by the reciprocal of sample class membership, in order to adjust for differences in class category sizes. {cmd:nopriors} is 
therefore recommended for balanced samples so that no unnecessary weighting will be employed. 

{p 4 8 2}
{cmd:loo} specifies that leave-one-out (LOO) analysis be performed; In ODA, LOO is not available for weighted categorical problems (i.e. {cmd:loo} cannot be specified together with both {cmd:wt()} and {cmd:cat()}). Additionally, 
a {it:P}-value for LOO is provided only for a two-category class variable. 

{p 4 8 2}
{cmd:sidak(}{it:#}{cmd:)} specifies that Sidak adjusted {it:p}-values be displayed for {it:p}-values derived from the permutation test and {cmd:loo}; 
An integer value must be provided to represent the number of comparisons to adjust for. {cmd:iter()} must be specified when {cmd:sidak()} is specified. {cmd:sidak()} is currently available  with the {cmd:gen()} option.


{title:Examples}

{hline}
{pstd}
{opt (1) Binary class variable and continuous (ordered) attribute:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We assess whether ODA can distinguish between foreign and domestic autos based on gas mileage. We perform 1000 permutations and specify that LOO analysis be conducted {p_end}
{phang2}{cmd:. oda foreign mpg, pathoda("C:\ODA\") store("C:\ODA\stuff") iter(1000) loo}{p_end}

{hline}
{pstd}
{opt (2) Binary class variable and binary attribute:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first generate a binary variable for mpg using the cutpoint of 22.5 derived in Example 1 {p_end}
{phang2}{cmd:. gen binmpg = cond(mpg > 22.5,1,0)}{p_end}

{pstd}We assess whether ODA can distinguish between foreign and domestic autos based on this binary gas mileage variable. We specify that binmpg should be treated as a categorical variable {p_end}
{phang2}{cmd:. oda foreign binmpg, pathoda("C:\ODA\") store("C:\ODA\stuff") iter(1000) loo cat}{p_end}

{hline}
{pstd}
{opt (3) Binary class variable and multi-category attribute:}{p_end}

{pstd}We assess whether ODA can distinguish between foreign and domestic autos based on levels of repair record ratings. We specify that rep78 is categorical {p_end}
{phang2}{cmd:. oda foreign rep78, pathoda("C:\ODA\") store("C:\ODA\stuff") iter(1000) loo cat}{p_end}

{hline}
{pstd}
{opt (4) Multi-category class variable and continuous attribute:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first recode missing values to -99 {p_end}
{phang2}{cmd:. mvencode rep78, mv(-99)}{p_end}

{pstd}We assess whether ODA can distinguish between levels of repair record ratings based on gas mileage. We initially run ODA with no permutations or LOO to identify a model {p_end}
{phang2}{cmd:. oda rep78 mpg, pathoda("C:\ODA\") store("C:\ODA\stuff")}{p_end}

{pstd}Next we specify the directional statement using the values derived from the initial model and add permutations and LOO {p_end}
{phang2}{cmd:. oda rep78 mpg, pathoda("C:\ODA\") store("C:\ODA\stuff") iter(1000) loo dir(< 2 3 1 4 -99 5)}{p_end}

{hline}
{pstd}
{opt (5) Multi-category class variable and multi-category attribute:}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}We first ensure that missing values are recoded to -99 {p_end}
{phang2}{cmd:. mvencode rep78, mv(-99)}{p_end}

{pstd}Next we create a 3 category variable using the MPG variable {p_end}
{phang2}{cmd:xtile mpg3 = mpg , nq(3)}{p_end}

{pstd}We assess whether ODA can distinguish between 3 levels of gas mileage based on levels of repair record ratings {p_end}
{phang2}{cmd:. oda mpg3 rep78, pathoda("C:\ODA\") store("C:\ODA\stuff") iter(1000) cat loo}{p_end}

{hline}
{pstd}
{opt (6) Causal inference with a binary class variable (treatment) and continuous outcome (attribute):}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}

{pstd}Estimate propensity score for mbsmoke as the treatment, and generate inverse probability of treatment weights (IPTW) {p_end}
{phang2}{cmd:. logit mbsmoke mmarried c.mage c.mage#c.mage fbaby medu}{p_end}
{phang2}{cmd:. predict pscore, pr}{p_end}
{phang2}{cmd:. gen iptw = cond(mbsmoke, 1/pscore, 1/(1-pscore))}{p_end}

{pstd}Estimate treatment effect of mbsmoke on bweight using IPTW weights generated in the previous run{p_end}
{phang2}{cmd:. oda mbsmoke bweight, pathoda("C:\ODA\") store("C:\ODA\stuff")  wt(iptw) iter(1000) loo} {p_end}

{hline}
{pstd}
{opt (7) Causal inference with a multi-category class variable (treatment) and continuous outcome (attribute):}{p_end}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}{p_end}

{pstd}Estimate propensity scores for the four treatment levels of {cmd:msmoke} and generate four strata variables corresponding to each treatment, respectively {p_end}
{phang2}{cmd: . mlogit msmoke i.(mmarried fbaby) mage c.mage#c.mage medu c.medu#c.medu c.mage#c.medu, base(0)}{p_end}
{phang2}{cmd:. predict double (ps1 ps2 ps3 ps4), pr}{p_end}

{pstd}Generate weights for nominal treatments on common support using the {helpb mmws} package (available from SSC). {p_end}
{phang2}{cmd:. mmws msmoke, pscore(ps1 ps2 ps3 ps4) nominal nstrata(5 5 5 5) common replace}{p_end}

{pstd}Estimate treatment effect of msmoke on bweight using MMWS weights generated in the previous run. Note that we only specify that the model be reported, as this complex analysis is very computer intensive. {p_end}
{phang2}{cmd:. oda msmoke bweight, pathoda("C:\ODA\") store("C:\ODA\stuff") wt( _mmws)} {p_end}

{hline}
{p2colreset}{...}


{title:Stored results}

{pstd}
{cmd:oda} stores the following in {cmd:r()}, which can be displayed by typing {cmd: return list} after {cmd:oda} is finished. When {cmd: wt()} is specified, the stored values are weighted:

{synoptset 18 tabbed}{...}
{p2col 5 22 24 2: Scalars}{p_end}
{synopt:{cmd:r(est_P)}}Estimated {it:P}-value for the permutation test{p_end}
{synopt:{cmd:r(est_adjP)}}Sidak adjusted {it:P}-value for the permutation test{p_end}
{synopt:{cmd:r(est_P_LOO)}}{it:P}-value for the LOO analysis{p_end}
{synopt:{cmd:r(est_adjP_LOO)}}Sidak adjusted {it:P}-value for the LOO analysis{p_end}
{synopt:{cmd:r(ess_train)}}ESS for the training sample{p_end}
{synopt:{cmd:r(ess_loo)}}ESS for the leave-one-out analysis (when the loo option is specified){p_end}

{p2colreset}{...}


{title:References}

{p 4 8 2}
Yarnold PR Soltysik RC. Theoretical distributions of optima for univariate discrimination of random data. 
{it:Decision Sciences} 1991;22:739–752.

{p 4 8 2}
Yarnold PR Soltysik RC. {it:Optimal Data Analysis: A Guidebook with Software for Windows.} Washington, DC: APA Books, 2005.

{p 4 8 2}
Yarnold PR Soltysik RC. {it:Maximizing Predictive Accuracy.} Chicago, IL: ODA Books. DOI: 10.13140/RG.2.1.1368.3286, 2016.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to assess covariate balance in matching studies.{it:Journal of Evaluation in Clinical Practice} 2016;22:848-854.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to identify structural breaks in single-group interrupted time series designs.{it:Journal of Evaluation in Clinical Practice} 2016;22:855-859.

{p 4 8 2}
Linden A, Yarnold PR, Nallomothu BK. Using machine learning to model dose-response relationships.{it:Journal of Evaluation in Clinical Practice} 2016;22:860-867.

{p 4 8 2}
Linden A, Yarnold PR. Combining machine learning and matching techniques to improve causal inference in program evaluation.{it:Journal of Evaluation in Clinical Practice} 2016;22:868-874.

{p 4 8 2}
Linden A, Yarnold PR. Combining machine learning and propensity score weighting to estimate causal effects in multivalued treatments.{it:Journal of Evaluation in Clinical Practice} 2016;22:875-885.

{p 4 8 2}
Linden A, Yarnold PR. Using machine learning to evaluate treatment effects in multiple-group interrupted time series analysis.{it:Journal of Evaluation in Clinical Practice} 2018;24:740-744.


{marker citation}{title:Citation of {cmd:oda}}

{p 4 8 2}{cmd:oda} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2020). ODA: Stata module for conducting Optimal Discriminant Analysis. Statistical Software Components S458728, Boston College Department of Economics. {p_end}


{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}


{title:Acknowledgments} 

{p 4 4 2}
I wish to thank Paul R. Yarnold for reviewing {cmd:oda} and providing valuable comments.{p_end}
      

{title:Also see}

{p 4 8 2} Online: {helpb cta} (if installed), {helpb looclass} (if installed), {helpb kfoldclass} (if installed) {helpb classtabi} (if installed) {helpb mmws} (if installed){p_end}
