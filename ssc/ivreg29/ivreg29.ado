*! ivreg29 2.2.14  19Jan2015
*! authors cfb & mes
*! see end of file for version comments

*  Variable naming:
*  lhs = LHS endogenous
*  endo = RHS endogenous (instrumented)
*  inexog = included exogenous (instruments)
*  exexog = excluded exogenous (instruments)
*  iv = {inexog exexog} = all instruments
*  rhs = {endo inexog} = RHS regressors
*  1 at the end of the name means the varlist after duplicates and collinearities removed
*  ..1_ct at the end means a straight count of the list
*  .._ct at the end means ..1_ct with any additional detected cnts removed

program define ivreg29, eclass byable(recall) /* properties(svyj) */ sortpreserve
	version 9.2
	local lversion 02.2.14

	local ivreg2_cmd "ivreg29"

	if replay() {
		syntax [, FIRST FFIRST RF Level(integer $S_level) NOHEader NOFOoter dropfirst droprf /*
			*/ EForm(string) PLUS VERsion]
		if "`version'" != "" & "`first'`ffirst'`rf'`noheader'`nofooter'`dropfirst'`droprf'`eform'`plus'" != "" {
			di as err "option version not allowed"
			error 198
		}
		if "`version'" != "" {
			di in gr "`lversion'"
			ereturn clear
			ereturn local version `lversion'
			exit
		}
		if `"`e(cmd)'"' != "`ivreg2_cmd'"  {
			error 301
		}
		if "`e(firsteqs)'" != "" & "`dropfirst'" == "" {
* On replay, set flag so saved eqns aren't dropped
			local savefirst "savefirst"
		}
		if "`e(rfeq)'" != "" & "`droprf'" == "" {
* On replay, set flag so saved eqns aren't dropped
			local saverf "saverf"
		}
	}
	else {
		local cmdline "`ivreg2_cmd' `*'"

		syntax [anything(name=0)] [if] [in] [aw fw pw iw/] [, /*
			*/ FIRST FFIRST NOID NOCOLLIN SAVEFIRST SAVEFPrefix(name) SMall Robust CLuster(varname) /*
			*/ GMM GMM2s CUE CUEINIT(string) CUEOPTions(string) ORTHOG(string) ENDOGtest(string) /*
			*/ PARTIAL(string) FWL(string) NOConstant Level(integer $S_level) Beta hc2 hc3 /*
			*/ NOHEader NOFOoter NOOUTput title(string) subtitle(string) /*
			*/ DEPname(string) EForm(string) PLUS /*
			*/ BW(string) kernel(string) Tvar(varname) Ivar(varname)/*
			*/ LIML COVIV FULLER(real 0) Kclass(string) /*
			*/ REDundant(string) RF SAVERF SAVERFPrefix(name) /*
			*/ B0(string) SMATRIX(string) WMATRIX(string) /*
			*/ dofminus(integer 0) sdofminus(integer 0) NOPARTIALSMALL ]

		local n 0

		gettoken lhs 0 : 0, parse(" ,[") match(paren)
		IsStop `lhs'
		if `s(stop)' { 
			error 198 
		}
		while `s(stop)'==0 { 
			if "`paren'"=="(" {
				local n = `n' + 1
				if `n'>1 { 
capture noi error 198
di in red `"syntax is "(all instrumented variables = instrument variables)""'
exit 198
				}
				gettoken p lhs : lhs, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
capture noi error 198 
di in red `"syntax is "(all instrumented variables = instrument variables)""'
di in red `"the equal sign "=" is required"'
exit 198 
					}
					local endo `endo' `p'
					gettoken p lhs : lhs, parse(" =")
				}
* To enable Cragg HOLS estimator, allow for empty endo list
				local temp_ct  : word count `endo'
				if `temp_ct' > 0 {
					tsunab endo : `endo'
				}
* To enable OLS estimator with (=) syntax, allow for empty exexog list
				local temp_ct  : word count `lhs'
				if `temp_ct' > 0 {
					tsunab exexog : `lhs'
				}
			}
			else {
				local inexog `inexog' `lhs'
			}
			gettoken lhs 0 : 0, parse(" ,[") match(paren)
			IsStop `lhs'
		}
		local 0 `"`lhs' `0'"'

		tsunab inexog : `inexog'
		tokenize `inexog'
		local lhs "`1'"
		local 1 " " 
		local inexog `*'

		if "`gmm2s'`cue'" != "" & "`exexog'" == "" {
			di in red "option `gmm2s'`cue' invalid: no excluded instruments specified"
			exit 102
		}

/* Block disabled - ranktest code now incorporated into ivreg29.
* Check that -ranktest- is installed
		capture ranktest, version
		if _rc != 0 {
di as err "Error: must have ranktest version `ranktestversion' or greater installed"
di as err "To install, from within Stata type " _c
di in smcl "{stata ssc install ranktest :ssc install ranktest}"
			exit 601
		}
		local vernum "`r(version)'"
		if ("`vernum'" < "`ranktestversion'") | ("`vernum'" > "09.9.99") {
di as err "Error: must have ranktest version `ranktestversion' or greater installed"
di as err "Currently installed version is `vernum'"
di as err "To update, from within Stata type " _c
di in smcl "{stata ssc install ranktest, replace :ssc install ranktest, replace}"
			exit 601
		}
*/

* Process options

* Legacy gmm option
		if "`gmm'" ~= "" {
di in ye "-gmm- is no longer a supported option; use -gmm2s- with the appropriate option"
di in ye "      gmm             =  gmm2s robust"
di in ye "      gmm robust      =  gmm2s robust"
di in ye "      gmm bw()        =  gmm2s bw()"
di in ye "      gmm robust bw() =  gmm2s robust bw()"
di in ye "      gmm cluster()   =  gmm2s cluster()"
			local gmm2s "gmm2s"
			if "`robust'`cluster'`bw'"=="" {
* 2-step efficient gmm with arbitrary heteroskedasticity
				local robust "robust"
			}
		}
		
* partial, including legacy FWL option
		local partial "`partial' `fwl'"
		local partial : list retokenize partial
* Need word option so that varnames with cons in them aren't zapped
		local partial : subinstr local partial "_cons" "", all count(local partialcons) word
		if `partialcons' > 0 & "`noconstant'"~="" {
di in r "Error: _cons listed in partial() but equation specifies -noconstant-." 
			error 198
		}
		else if "`noconstant'"~="" {
			local partialcons 0
		}
		else if `partialcons' > 1 {
* Just in case of multiple _cons
di in r "Error: _cons listed more than once in partial()." 
			error 198
		}
		else if "`partial'" ~= "" {
			local partialcons 1
		}

* Fuller implies LIML
		if "`liml'" == "" & `fuller' != 0 {
			local liml "liml"
			}

* b0 implies noid.  Also check for incompatible options.
		if "`b0'" ~= "" {
			local noid "noid"
			local b0opts "`gmm2s'`cue'`liml'`wmatrix'`kclass'"
			if "`b0opts'" != "" {
* ...with spaces
				local b0opts "`gmm2s' `cue' `liml' `wmatrix' `kclass'"
				local b0opts : list retokenize b0opts 
di as err "incompatible options: -b0- and `b0opts'"
				exit 198
			}
		}

		if "`gmm2s'" != "" & "`cue'" != "" {
di as err "incompatible options: 2-step efficient gmm and cue gmm"
			exit 198
		}

* savefprefix implies savefirst
		if "`savefprefix'" != "" & "`savefirst'" == "" {
			local savefirst "savefirst"
		}

* default savefprefix is _ivreg2_
		if "`savefprefix'" == "" {
			local savefprefix "_`ivreg2_cmd'_"
		}

* saverfprefix implies saverf
		if "`saverfprefix'" != "" & "`saverf'" == "" {
			local saverf "saverf"
		}

* default saverfprefix is _ivreg2_
		if "`saverfprefix'" == "" {
			local saverfprefix "_`ivreg2_cmd'_"
		}

* LIML/kclass incompatibilities
		if "`liml'`kclass'" != "" {
			if "`gmm2s'`cue'" != "" {
di as err "GMM estimation not available with LIML or k-class estimators"
			exit 198
			}
			if `fuller' < 0 {
di as err "invalid Fuller option"
			exit 198
			}
			if "`liml'" != "" & "`kclass'" != "" {
di as err "cannot use liml and kclass options together"
			exit 198
			}
* Process kclass string
			tempname kclass2
			scalar `kclass2'=real("`kclass'")
			if "`kclass'" != "" & (`kclass2' == . | `kclass2' < 0 ) {
di as err "invalid k-class option"
				exit 198
				}			
		}

* HAC estimation.
* If bw is omitted, default `bw' is empty string.
* If bw or kernel supplied, check/set `kernel'.
* Macro `kernel' is also used for indicating HAC in use.
		if "`bw'" != "" | "`kernel'" != "" {
* Need tvar only for markout with time-series stuff
* but data must be tsset for time-series operators in code to work
* User-supplied tvar not used but checked if consistent with tsset
			capture tsset
			if "`r(timevar)'" == "" {
di as err "must tsset data and specify timevar"
				exit 5
			}
			if "`tvar'" == "" {
				local tvar "`r(timevar)'"
			}
			else if "`tvar'"!="`r(timevar)'" {
di as err "invalid tvar() option - data already -tsset-"
				exit 5
			}
			tsreport, panel
			if `r(N_gaps)' != 0 {
di in gr "Warning: time variable " in ye "`tvar'" in gr " has " /*
	*/ in ye "`r(N_gaps)'" in gr " gap(s) in relevant range"
			}

			if "`bw'" == "" {
di as err "bandwidth option bw() required for HAC-robust estimation"
				exit 102
			}
* Check for bw(auto); flag as -1
			if lower("`bw'") == "auto" {
				if "`ivar'" ~= "" {
di as err "Automatic bandwidth selection not available for panel data"
					exit 198
				}
				local bw=-1
			}
			else {
				local bw real("`bw'")
* Check it's a valid bandwidth
				if   `bw' != int(`bw') | /*
					*/   `bw' == .  | /*
					*/   `bw' <= 0 {
di as err "invalid bandwidth in option bw() - must be integer > 0 or 'auto'"
					exit 198
				}
* Convert bw macro to simple integer
				local bw=`bw'
			}
* Check it's a valid kernel
			local validkernel 0
			if lower(substr("`kernel'", 1, 3)) == "bar" | "`kernel'" == "" {
* Default kernel
				local kernel "Bartlett"
				local window "lag"
				local validkernel 1
				if `bw'==1 {
di in ye "Note: kernel=Bartlett and bw=1 implies zero lags used.  Standard errors and"
di in ye "      test statistics are not autocorrelation-consistent."
				}
			}
			if lower(substr("`kernel'", 1, 3)) == "par" {
				local kernel "Parzen"
				local window "lag"
				local validkernel 1
				if `bw'==1 {
di in ye "Note: kernel=Parzen and bw=1 implies zero lags used.  Standard errors and"
di in ye "      test statistics are not autocorrelation-consistent."
				}
			}
			if lower(substr("`kernel'", 1, 3)) == "tru" {
				local kernel "Truncated"
				local window "lag"
				local validkernel 1
			}
			if lower(substr("`kernel'", 1, 9)) == "tukey-han" | lower("`kernel'") == "thann" {
				local kernel "Tukey-Hanning"
				local window "lag"
				local validkernel 1
				if `bw'==1 {
di in ye "Note: kernel=Tukey-Hanning and bw=1 implies zero lags.  Standard errors and"
di in ye "      test statistics are not autocorrelation-consistent."
				}
			}
			if lower(substr("`kernel'", 1, 9)) == "tukey-ham" | lower("`kernel'") == "thamm" {
				local kernel "Tukey-Hamming"
				local window "lag"
				local validkernel 1
				if `bw'==1 {
di in ye "Note: kernel=Tukey-Hamming and bw=1 implies zero lags.  Standard errors and"
di in ye "      test statistics are not autocorrelation-consistent."
				}
			}
			if lower(substr("`kernel'", 1, 3)) == "qua" | lower("`kernel'") == "qs" {
				local kernel "Quadratic spectral"
				local window "spectral"
				local validkernel 1
			}
			if lower(substr("`kernel'", 1, 3)) == "dan" {
				local kernel "Daniell"
				local window "spectral"
				local validkernel 1
			}
			if lower(substr("`kernel'", 1, 3)) == "ten" {
				local kernel "Tent"
				local window "spectral"
				local validkernel 1
			}
			if ~`validkernel' {
				di in red "invalid kernel"
				exit 198
			}
		}

		if "`kernel'" != "" & "`cluster'" != "" {
di as err "cannot use HAC kernel estimator with -cluster- option"
				exit 198
		}

		if "`orthog'`endogtest'`redundant'`partial'" != "" {
			capture tsunab orthog    : `orthog'
			capture tsunab endogtest : `endogtest'
			capture tsunab redundant : `redundant'
			capture tsunab partial   : `partial'
		}

		if "`hc2'`hc3'" != "" {
			if "`hc2'"!="" {
				di in red "option `hc2' invalid"
			}
			else	di in red "option `hc3' invalid"
			exit 198
		}

		if "`beta'" != "" {
			di in red "option `beta' invalid"
			exit 198
		}

* Weights
* fweight and aweight accepted as is
* iweight not allowed with robust or gmm and requires a trap below when used with summarize
* pweight is equivalent to aweight + robust
*   but in HAC case, robust implied by `kernel' rather than `robust'

		tempvar wvar
		if "`weight'" == "fweight" | "`weight'"=="aweight" {
			local wtexp `"[`weight'=`exp']"'
			qui gen double `wvar'=`exp'
		}
		if "`weight'" == "fweight" & "`kernel'" !="" {
			di in red "fweights not allowed (data are -tsset-)"
			exit 101
		}
		if "`weight'" == "iweight" {
			if "`robust'`cluster'`gmm2s'`kernel'" !="" {
				di in red "iweights not allowed with robust or gmm"
				exit 101
			}
			else {
				local wtexp `"[`weight'=`exp']"'
				qui gen double `wvar'=`exp'
			}
		}
		if "`weight'" == "pweight" {
			local wtexp `"[aweight=`exp']"'
			qui gen double `wvar'=`exp'
			local robust "robust"
		}
		if "`weight'" == "" {
* If no weights, define neutral weight variable
			qui gen byte `wvar'=1
		}

		if `dofminus' > 0 {
			local dofmopt "dofminus(`dofminus')"
		}

		marksample touse
		markout `touse' `lhs' `inexog' `exexog' `endo' `cluster' `tvar', strok

* Weight statement
		if "`weight'" ~= "" {
			sum `wvar' if `touse' `wtexp', meanonly
di in gr "(sum of wgt is " %14.4e `r(sum_w)' ")"
		}

* Set local macro T and check that bw < T
* Also make sure only used sample is checked
		if "`bw'" != "" {
			sum `tvar' if `touse', meanonly
			local T = r(max)-r(min)+1
			if (`bw' > `T') & (`bw' ~= -1)  {
di as err "invalid bandwidth in option bw() - cannot exceed timespan of data"
				exit 198
			}
		}

************* Collinearities and duplicates block *****************

		if "`noconstant'" != "" {
			local rmcnocons "nocons"
		}

* Check for duplicates of variables
* To mimic official ivreg, in the case of duplicates,
* (1)  inexog > endo
* (2)  inexog > exexog
* (3)  endo + exexog = inexog, as if it were "perfectly predicted"
		local dupsen1 : list dups endo
		local endo1   : list uniq endo
		local dupsex1 : list dups exexog
		local exexog1 : list uniq exexog
		local dupsin1 : list dups inexog
		local inexog1 : list uniq inexog
* Remove inexog from endo
		local dupsen2 : list endo1 & inexog1
		local endo1   : list endo1 - inexog1
* Remove inexog from exexog
		local dupsex2 : list exexog1 & inexog1
		local exexog1 : list exexog1 - inexog1
* Remove endo from exexog
		local dupsex3 : list exexog1 & endo1
		local exexog1 : list exexog1 - endo1
		local dups "`dupsen1' `dupsex1' `dupsin1' `dupsen2' `dupsex2' `dupsex3'"
		local dups    : list uniq dups

		if "`nocollin'" == "" {
* First, collinearities check using canonical correlations approach
* Eigenvalue=1 => included endog is really included exogenous
* Eigenvalue=0 => included endog collinear with another included endog
* Corresponding column names give name of variable
* Code block stolen from below, so some repetition
			local insts1 `inexog1' `exexog1'
			local rhs1   `endo1'   `inexog1'
			local endo1_ct : word count `endo1'
			if `endo1_ct' > 0 {
				tempname ccmat ccrealev ccimagev cc A XX XXinv ZZ ZZinv XZ XPZX
				qui mat accum `A' = `endo1' `insts1' if `touse' `wtexp', `rmcnocons'
				mat `XX' = `A'[1..`endo1_ct',1..`endo1_ct']
				mat `XXinv'=syminv(`XX')
				mat `ZZ' = `A'[`endo1_ct'+1...,`endo1_ct'+1...]
				mat `ZZinv'=syminv(`ZZ')
				mat `XZ' = `A'[1..`endo1_ct',`endo1_ct'+1...]
				mat `XPZX'=`XZ'*`ZZinv'*`XZ''
				mat `ccmat' = `XXinv'*`XPZX'
				mat eigenvalues `ccrealev' `ccimagev' = `ccmat'
* Loop through endo1 to find eigenvalues=0 or 1
				foreach vn of varlist `endo1' {
					local i=colnumb(`ccmat',"`vn'")
					if round(`ccmat'[`i',`i'],10e-7)==0 {
* Collinear with another endog, so remove from endog list
						local endo1 : list endo1-vn
						local ncollin "`ncollin' `vn'"
					}
					if round(`ccmat'[`i',`i'],10e-7)==1 {
* Collinear with exogenous, so remove from endog and add to inexog
						local endo1 : list endo1-vn
						local inexog1 "`inexog1' `vn'"
						local ecollin "`ecollin' `vn'"
					}
				}
			}

* _rmcollright crashes if no arguments supplied
			capture _rmcollright `inexog1' `exexog1' if `touse' `wtexp', `rmcnocons'

* endo1 has had within-endo collinear removed, so non-colllinear list is _rmcoll result + endo1
			local ncvars `r(varlist)' `endo1'
			local allvars1 `endo1' `inexog1' `exexog1'
* collin gets collinear variables to be removed
			local collin  : list allvars1-ncvars
* Remove collin from exexog1
			local exexog1 : list exexog1-collin
* Remove collin from inexog1
			local inexog1 : list inexog1-collin		
* Add dropped endogenous to collinear list, trimming down to "" if empty
			local collin "`collin' `ncollin'"
			local collin : list clean collin

* Collinearity and duplicates warning messages, if necessary
			if "`dups'" != "" {
di in gr "Warning - duplicate variables detected"
di in gr "Duplicates:" _c
				Disp `dups', _col(21)
			}
			if "`ecollin'" != "" {
di in gr "Warning - endogenous variable(s) collinear with instruments"
di in gr "Vars now exogenous:" _c
				Disp `ecollin', _col(21)
			}
			if "`collin'" != "" {
di in gr "Warning - collinearities detected"
di in gr "Vars dropped:" _c
				Disp `collin', _col(21)
			}
		}

**** End of collinearities block ************

**** Partial-out block ******************

* `partial' has all to be partialled out except for constant
		if "`partial'" != "" | `partialcons'==1 {
			preserve
			local partialdrop   : list inexog - inexog1
			local partial1      : list partial - partialdrop
			local partialcheck  : list partial1 - inexog1
			if ("`partialcheck'"~="") {
di in r "Error: `partialcheck' listed in partial() but not in list of regressors." 
				error 198
			}
			local inexog1   : list inexog1 - partial1
* Check that cluster or weight var won't be transformed
			local allvars "`lhs' `inexog' `endo' `exexog'"
			if "`cluster'"~="" {
				local clustvarcheck : list cluster in allvars
				if `clustvarcheck' {
di in r "Error: cannot use cluster variable `cluster' as dependent variable, regressor or IV"
di in r "       in combination with -partial- option." 
				error 198
				}
			}
			if "`wtexp'"~="" {
				tokenize `exp', parse("*/()+-^&|~")
				local wvartokens `*'
				local nwvarnames : list allvars - wvartokens
				local wvarnames  : list allvars - nwvarnames
				if "`wvarnames'"~="" {
di in r "Error: cannot use weight variables as dependent variable, regressor or IV"
di in r "       in combination with -partial- option." 
				error 198
				}
			}
* Constant is partialled out, unless nocons already specified in the first place
			tempname partial_resid
			foreach var of varlist `lhs' `inexog1' `endo1' `exexog1' {
				qui regress `var' `partial1' if `touse' `wtexp', `noconstant'
				qui predict double `partial_resid' if `touse', resid
				qui replace `var' = `partial_resid'
				drop `partial_resid'
			}
			local partial_ct : word count `partial1'
			if "`noconstant'" == "" {
* partial_ct used for small-sample adjustment to regression F-stat
				local partial_ct = `partial_ct' + 1
				local noconstant "noconstant"
			}
		}
		else {
* Set count of partial vars to zero if option not used
			local partial_ct 0
			local partialcons 0
		}
* Add partial_ct to small dof adjustment sdofminus
		if "`nopartialsmall'"=="" {
			local sdofminus = `sdofminus'+`partial_ct'
		}

*********************************************

		local insts1 `inexog1' `exexog1'
		local rhs1   `endo1'   `inexog1'
		local iv1_ct       : word count `insts1'
		local rhs1_ct      : word count `rhs1'
		local endo1_ct     : word count `endo1'
		local exex1_ct     : word count `exexog1'
		local endoexex1_ct : word count `endo1' `exexog1'
		local inexog1_ct   : word count `inexog1'

		if "`noconstant'" == "" {
			local cons 1
		}
		else {
			local cons 0
		}

		if `rhs1_ct' > `iv1_ct' {
			di in red "equation not identified; must have at " /*
			*/ "least as many instruments not in"
			di in red "the regression as there are "           /*
			*/ "instrumented variables"
			exit 481
		}

		if `rhs1_ct' + `cons' == 0 {
			di in red "error: no regressors specified"
			exit 102
		}

		if "`cluster'"!="" {
			local clopt "cluster(`cluster')"
			if "`robust'"=="" {
				local robust "robust"
			}
		}
		if "`bw'"!="" {
			local bwopt "bw(`bw')"
		}
		if "`kernel'"!="" {
			local kernopt "kernel(`kernel')"
		}
* If depname not provided (default) name is lhs variable
		if "`depname'"=="" {
			local depname `lhs'
		}

************************************************************************************************
* Cross-products and basic IV coeffs, residuals and moment conditions
		tempvar iota y2 yhat ivresid ivresid2 gresid gresid2 lresid lresid2 b0resid b0resid2 s1resid
		tempname ysum yy yyc r2u r2c B V ivB gmmB wB lB gmmV ivest
		tempname r2 r2_a ivrss lrss wbrss b0rss rss mss rmse sigmasq iv_s2 l_s2 wb_s2 b0_s2 F Fp Fdf2
		tempname S Sinv W s1Zu s2Zu b0Zu wbZu wbresid wbresid2 s1sigmasq
		tempname A XZ XZa XZb Zy ZZ ZZinv XPZX XPZXinv XPZy
		tempname YY Z2Z2 ZY Z2Y XXa XXb XX Xy Z2Z2inv XXinv
		tempname XZWZX XZWZXinv XZWZy XZW
		tempname B V B1 uZSinvZu j jp arubin arubinp arubin_lin arubin_linp tempmat

* Generate cross-products of y, X, Z
		qui matrix accum `A' = `lhs' `endo1' `exexog1' `inexog1' /*
			*/ if `touse' `wtexp', `noconstant'
		if "`noconstant'"=="" {
			matrix rownames `A' = `lhs' `endo1' `exexog1' /*
				*/ `inexog1' _cons
			matrix colnames `A' = `lhs' `endo1' `exexog1' /*
				*/ `inexog1' _cons
		}
		else {
			matrix rownames `A' = `lhs' `endo1' `exexog1' `inexog1'
			matrix colnames `A' = `lhs' `endo1' `exexog1' `inexog1'
		}
		if `endo1_ct' > 0 {
* X'Z is [endo1 inexog1]'[exexog1 inexog1]
			mat `XZ'=`A'[2..`endo1_ct'+1,`endo1_ct'+2...]
* Append portion corresponding to included exog if they (incl constant) exist
			if 2+`endo1_ct'+`iv1_ct'-(`rhs1_ct'-`endo1_ct') /*
					*/ <= rowsof(`A') {
				mat `XZ'=`XZ' \ /*
					*/ `A'[2+`endo1_ct'+`iv1_ct'- /*
					*/ (`rhs1_ct'-`endo1_ct')..., /*
					*/ `endo1_ct'+2...]
			}
* If included exog (incl const) exist, create XX matrix in 3 steps
			if `inexog1_ct' + `cons' > 0 {
				mat `XXa'  = `A'[2..`endo1_ct'+1, 2..`endo1_ct'+1], /*
					*/ `A'[2..`endo1_ct'+1, `endoexex1_ct'+2...]
				mat `XXb'  = `A'[`endoexex1_ct'+2..., 2..`endo1_ct'+1], /*
					*/ `A'[`endoexex1_ct'+2..., `endoexex1_ct'+2...]
				mat `XX'   = `XXa' \ `XXb'
				mat `Xy'  = `A'[2..`endo1_ct'+1, 1] \ `A'[`endoexex1_ct'+2..., 1]
			}
			else {
				mat `XX'   = `A'[2..`endo1_ct'+1, 2..`endo1_ct'+1]
				mat `Xy'  = `A'[2..`endo1_ct'+1, 1]
			}
		}
		else {
* Cragg HOLS estimator with no endogenous variables
			mat `XZ'= `A'[2+`iv1_ct'-(`rhs1_ct'-`endo1_ct')..., /*
					*/ 2...]
			mat `XX'   = `A'[`endoexex1_ct'+2..., `endoexex1_ct'+2...]
			mat `Xy'  = `A'[`endoexex1_ct'+2..., 1]
		}

		mat `XX'=(`XX'+`XX'')/2
		mat `XXinv'=syminv(`XX')
		mat `Zy'=`A'[`endo1_ct'+2...,1]
		mat `ZZ'=`A'[`endo1_ct'+2...,`endo1_ct'+2...]
		mat `ZZ'=(`ZZ'+`ZZ'')/2
		mat `ZZinv'=syminv(`ZZ')
* diag0cnt not superfluous - collinearity checks will catch but may be disabled
		local iv_ct = rowsof(`ZZ') - diag0cnt(`ZZinv')
		mat `YY'=`A'[1..`endo1_ct'+1, 1..`endo1_ct'+1]
		mat `ZY' = `A'[`endo1_ct'+2..., 1..`endo1_ct'+1]
		mat `XPZX'=`XZ'*`ZZinv'*`XZ''
		mat `XPZX'=(`XPZX'+`XPZX'')/2
		mat `XPZXinv'=syminv(`XPZX')
		mat `XPZy'=`XZ'*`ZZinv'*`Zy'
******************************
		qui gen byte `iota'=1
		qui gen double `y2'=`lhs'^2
* Stata summarize won't work with iweights, so must use matrix cross-product
		qui matrix vecaccum `ysum' = `iota' `y2' `lhs' `wtexp' if `touse'
* N is ob count from mat accum.
* `N' is rounded down to nearest integer if iweights are used.
* If aw, pw or fw, should already be integer but use round in case of numerical imprecision.
		if "`weight'" == "iweight" {
			local N=int(`ysum'[1,3])
		}
		else {
			local N=round(`ysum'[1,3])
		}
* For yyc, use unrounded N to mimic official -regress- (needed in R-sq)
		scalar `yy'=`ysum'[1,1]
		scalar `yyc'=`yy'-`ysum'[1,2]^2/`ysum'[1,3]

*******************************************************************************************
* First-step estimators: b0, wmatrix, LIML-kclass, IV.
* Generate residuals s1resid for used in 2SFEGMM and robust.
* User-supplied b0 provides value of CUE obj fn.
		if "`b0'" != "" {
			capture drop `yhat'
			qui mat score double `yhat' = `b0' if `touse'
			qui gen double `b0resid'=`lhs'-`yhat'
			qui gen double `b0resid2'=`b0resid'^2
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `b0resid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `b0rss'= `ysum'[1,1]
* Adjust sigma-squared for dofminus
			scalar `b0_s2'=`b0rss'/(`N'-`dofminus')
			scalar `s1sigmasq'=`b0_s2'
			qui gen double `s1resid'=`b0resid'
		}
		else if "`wmatrix'" != "" {
* GMM with arbitrary weighting matrix provides first-step estimates
			local cn : colnames(`ZZ')
			matrix `W'=`wmatrix'
* Rearrange/select columns to mat IV matrix
			capture matsort `W' "`cn'"
			local wrows = rowsof(`W')
			local wcols = colsof(`W')
			local zcols = colsof(`ZZ')
			if _rc ~= 0 | (`wrows'~=`zcols') | (`wcols'~=`zcols') {
di as err "-wmatrix- option error: supplied matrix columns/rows do not match IV list"
exit 198
			}
			mat `XZWZX'=`XZ'*`W'*`XZ''
			mat `XZWZy'=`XZ'*`W'*`Zy'
			mat `XZWZX'=(`XZWZX'+`XZWZX'')/2
			mat `XZWZXinv'=syminv(`XZWZX')
			mat `XZW'=`XZ'*`W'
			mat `wB'=`XZWZy''*`XZWZXinv''

			capture drop `yhat'
			qui mat score double `yhat' = `wB' if `touse'
			qui gen double `wbresid'=`lhs'-`yhat'
			qui gen double `wbresid2'=`wbresid'^2
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `wbresid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `wbrss'= `ysum'[1,1]
* Adjust sigma-squared for dofminus
			scalar `wb_s2'=`wbrss'/(`N'-`dofminus')
			scalar `s1sigmasq'=`wb_s2'
			qui gen double `s1resid'=`wbresid'
		}
		else if "`liml'`kclass'" != "" {
* LIML and kclass code
			tempname WW WW1 Eval lambda khs XhXh XhXhinv ll
			if "`kclass'" == "" {
* LIML block
				matrix `WW'  = `YY' - `ZY''*`ZZinv'*`ZY'
				if `inexog1_ct' + `cons' > 0 {
					mat `Z2Y'  = `A'[`endoexex1_ct'+2..., 1..`endo1_ct'+1]
					mat `Z2Z2' = `A'[`endoexex1_ct'+2..., `endoexex1_ct'+2...]
					mat `Z2Z2'=(`Z2Z2'+`Z2Z2'')/2
					mat `Z2Z2inv' = syminv(`Z2Z2')
					matrix `WW1' = `YY' - `Z2Y''*`Z2Z2inv'*`Z2Y'
				}
				else {
* Special case of no included exogenous (incl constant)
					matrix `WW1' = `YY'
				}
				matrix `WW'=(`WW'+`WW'')/2
				mata: M=matpowersym(st_matrix("`WW'"), -0.5)
				mata: Eval=symeigenvalues(makesymmetric(M*st_matrix("`WW1'")*M))
				mata: lambda=rowmin(Eval)
				mata: st_numscalar("r(lambda)", lambda)
				scalar `lambda'=r(lambda)

				if `fuller'==0 {
* Basic LIML.  Macro kclass2 is the scalar.
					scalar `kclass2'=`lambda'
				}
				else {
* Fuller LIML
					if `fuller' > (`N'-`iv_ct') {
di as err "error: invalid choice of Fuller LIML parameter"
						exit 198
					}
					scalar `kclass2' = `lambda' - `fuller'/(`N'-`iv_ct')
				}
* End of LIML block
			}
			mat `XhXh'=(1-`kclass2')*`XX'+`kclass2'*`XPZX'
			mat `XhXh'=(`XhXh'+`XhXh'')/2
			mat `XhXhinv'=syminv(`XhXh')
			mat `lB'=`Xy''*`XhXhinv'*(1-`kclass2') + `kclass2'*`Zy''*`ZZinv'*`XZ''*`XhXhinv'
			capture drop `yhat'
			qui mat score double `yhat'=`lB' if `touse'
			qui gen double `lresid'=`lhs' - `yhat'
			qui gen double `lresid2'=`lresid'^2
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `lresid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `lrss'= `ysum'[1,1]
* Adjust sigma-squared for dofminus
			scalar `l_s2'=`lrss'/(`N'-`dofminus')
			scalar `s1sigmasq'=`l_s2'
			qui gen double `s1resid'=`lresid'
		}
		else {
* IV resids are 1st-step GMM resids
* In these expressions, ignore scaling of W
			mat `ivB' = `XPZy''*`XPZXinv''
			mat `XZWZX'=`XPZX'
			mat `XZWZXinv'=`XPZXinv'
			mat `XZW'=`XZ'*`ZZinv'
			capture drop `yhat'
			qui mat score double `yhat' = `ivB' if `touse'
			qui gen double `ivresid'=`lhs'-`yhat'
			qui gen double `ivresid2'=`ivresid'^2
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `ivresid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `ivrss'=`ysum'[1,1]
			scalar `iv_s2'=`ivrss'/(`N'-`dofminus')
			scalar `s1sigmasq'=`iv_s2'
			qui gen double `s1resid'=`ivresid'
		}
* Orthogonality conditions using step 1 residuals
		qui mat vecaccum `s1Zu'=`s1resid' `exexog1' `inexog1' /*
			*/ `wtexp' if `touse', `noconstant'

* call abw code if bw() is defined and bw(auto) selected
			if "`bw'" != "" {
				if `bw' == -1 {
					tempvar abwtouse
					gen byte `abwtouse' = (`s1resid' < .) 
					abw `s1resid' `exexog1' `inexog1' `abwtouse', noconstant kernel(`kernel')
					local bw `r(abw)'
					local bwopt "bw(`bw')"
					local bwchoice "`r(bwchoice)'"
				}
			}
*******************************************************************************************
* S covariance matrix of orthogonality conditions
*******************************************************************************************
* If user-supplied S matrix is used, use it
		if "`smatrix'" != "" {
			local cn : colnames(`ZZ')
			matrix `S'=`smatrix'
* Rearrange/select columns to mat IV matrix
			capture matsort `S' "`cn'"
			local srows = rowsof(`S')
			local scols = colsof(`S')
			local zcols = colsof(`ZZ')
			if _rc ~= 0 | (`srows'~=`zcols') | (`scols'~=`zcols') {
di as err "-smatrix- option error: supplied matrix columns/rows do not match IV list"
exit 198
			}
			mat `S' = (`S' + `S'') / 2
			mat `Sinv'=syminv(`S')
			local rankS = rowsof(`Sinv') - diag0cnt(`Sinv')
		}

*******************************************************************************************
* Start robust block for robust-HAC S and Sinv
* Do not enter if user supplies smatrix or if CUE
		if "`robust'`cluster'" != "" & "`cue'"=="" & "`smatrix'"=="" {
* Optimal weighting matrix
* Block calculates S_0 robust matrix
* _robust has same results as
* mat accum `S'=`exexog1' `inexog1' [iweight=`ivresid'^2] if `touse'
* mat `S' = `S'*1/`N'
* _robust doesn't work properly with TS variables, so must first tsrevar
			tsrevar `exexog1' `inexog1'
			local TSinsts1 `r(varlist)'
* Create identity matrix with matching col/row names
			mat `S'=I(colsof(`s1Zu'))
			if "`noconstant'"=="" {
				mat colnames `S' = `TSinsts1' "_cons"
				mat rownames `S' = `TSinsts1' "_cons"
			}
			else {
				mat colnames `S' = `TSinsts1'
				mat rownames `S' = `TSinsts1'
			}
			_robust `s1resid' `wtexp' if `touse', variance(`S') `clopt' minus(0)
			if "`cluster'"!="" {
				local N_clust=r(N_clust)
			}
			mat `S' = `S'*1/`N'
* Above doesn't work properly with iweights (i.e. yield same matrix as fw),
*   hence iweight trap at start
			if "`kernel'" != "" {
* HAC block for S_1 onwards matrices
				tempvar vt1
				qui gen double `vt1' = .
				tempname tt tx kw karg ow
* Use insts with TS ops removed and with iota (constant) column
				if "`noconstant'"=="" {
					local insts1c "`TSinsts1' `iota'"
				}
				else {
					local insts1c "`TSinsts1'"
				}
				local iv1c_ct   : word count `insts1c'
* "tau=0 loop" is S_0 block above for all robust code
				local tau=1
* Spectral windows require looping through all T-1 autocovariances
				if "`window'" == "spectral" {
					local TAU = `T'-1
di in ye "Computing kernel ..."
				}
				else {
					local TAU=`bw'
				}
				if "`weight'" == "" {
* If no weights specified, define neutral ow variable and weight expression for code below
					qui gen byte `ow'=1
					local wtexp `"[fweight=`wvar']"'
				}
				else {
* pweights and aweights
					summ `wvar' if `touse', meanonly
					qui gen double `ow' = `wvar'/r(mean)
				}
				while `tau' <= `TAU' {
					capture mat drop `tt' 
					local i 1
					while `i' <= `iv1c_ct' {
						local x : word `i' of `insts1c'
* Add lags defined with TS operators
						local Lx "L`tau'.`x'"
						local Ls1resid "L`tau'.`s1resid'"
						local Low "L`tau'.`ow'"
						qui replace `vt1' = `Lx'*`s1resid'* /*
							*/ `Ls1resid'*`Low'*`ow' if `touse'
* Use capture here because there may be insufficient observations, e.g., if
*   the IVs include lags and tau=N-1.  _rc will be 2000 in this case.
* Bug in vecaccum means that if there is only 1 observation it will crash with insufficient obs.
* Replace missings with zeros to head this off.
						qui replace `vt1' = 0 if `vt1'==. & `touse'
						capture mat vecaccum `tx' = `vt1' `insts1c' /*
							*/ if `touse', nocons
						if _rc == 0 {
							mat `tt' = nullmat(`tt') \ `tx'
						}
						local i = `i'+1
					}
* bw = bandwidth, karg is argument to kernel function, kw is kernel function (weight)
					scalar `karg' = `tau'/(`bw')
					if "`kernel'" == "Truncated" {
						scalar `kw'=1
					}
					if "`kernel'" == "Bartlett" {
						scalar `kw'=(1-`karg')
					}
					if "`kernel'" == "Parzen" {
						if `karg' <= 0.5 {
							scalar `kw' = 1-6*`karg'^2+6*`karg'^3
						}
						else {
							scalar `kw' = 2*(1-`karg')^3
						}
					}
					if "`kernel'" == "Tukey-Hanning" {
						scalar `kw'=0.5+0.5*cos(_pi*`karg')
					}
					if "`kernel'" == "Tukey-Hamming" {
						scalar `kw'=0.54+0.46*cos(_pi*`karg')
					}
					if "`kernel'" == "Tent" {
						scalar `kw'=2*(1-cos(`tau'*`karg')) / (`karg'^2)
					}
					if "`kernel'" == "Daniell" {
						scalar `kw'=sin(_pi*`karg') / (_pi*`karg')
					}
					if "`kernel'" == "Quadratic spectral" {
						scalar `kw'=25/(12*_pi^2*`karg'^2) /*
							*/ * ( sin(6*_pi*`karg'/5)/(6*_pi*`karg'/5) /*
							*/     - cos(6*_pi*`karg'/5) )
					}
* Need -capture-s here because tt may not exist (because of insufficient observations/lags)
					capture mat `tt' = (`tt'+`tt'')*`kw'*1/`N'
					if _rc == 0 {
						mat `S' = `S' + `tt'
					}
					local tau = `tau'+1
				}
				if "`weight'" == "" {
* If no weights specified, remove neutral weight variables
					local wtexp ""
				}
			}
* To give S the right col/row names
			mat `S'=`S'+0*diag(`s1Zu')
* Right approach is to adjust S by N/(N-dofminus) if NOT cluster
* because clustered S is already "adjusted"
			if "`cluster'"=="" {
				mat `S'=`S'*`N'/(`N'-`dofminus')
			}

			mat `S'=(`S'+`S'')/2
			mat `Sinv'=syminv(`S')
			local rankS = rowsof(`Sinv') - diag0cnt(`Sinv')
		}

* End robust-HAC S and Sinv block
************************************************************************************
* Block for non-robust S and Sinv, including autocorrelation-consistent (AC).
* Do not enter if user supplies smatrix or if cue

		if "`robust'`cluster'`cue'`smatrix'"=="" {
* First do with S_0 (=S for simple IV)
* Step 1 sigma^2 is IV sigma^2 unless b0 or wmatrix provided
			mat `S' = `s1sigmasq'*`ZZ'*(1/`N')

			if "`kernel'" != "" {
* AC code for S_1 onwards matrices
				tempvar vt1
				qui gen double `vt1' = .
				tempname tt tx kw karg ow sigttj
* Use insts with TS ops removed and with iota (constant) column
				tsrevar `exexog1' `inexog1'
				local TSinsts1 `r(varlist)'
				if "`noconstant'"=="" {
					local insts1c "`TSinsts1' `iota'"
				}
				else {
					local insts1c "`TSinsts1'"
				}
				local iv1c_ct   : word count `insts1c'
* "tau=0 loop" is S_0 block above
				local tau=1
* Spectral windows require looping through all T-1 autocovariances
				if "`window'" == "spectral" {
					local TAU=`T'-1
di in ye "Computing kernel ..."
				}
				else {
					local TAU=`bw'
				}
				if "`weight'" == "" {
* If no weights specified, define neutral ow variable and wtexp for code below
					qui gen byte `ow'=1
					local wtexp `"[fweight=`wvar']"'
				}
				else {
* pweights and aweights
					sum `wvar' if `touse', meanonly
					qui gen double `ow' = `wvar'/r(mean)
				}
				while `tau' <= `TAU' {
					capture mat drop `tt' 
					local i 1
* errflag signals problems that make this loop's tt invalid
					local errflag 0
* Additional marksample/markout required so that treatment of MVs is consistent across all IVs and obs
					marksample touse2
					markout `touse2' `insts1c' L`tau'.(`insts1c') L`tau'.(`s1resid')

					local Low "L`tau'.`ow'"
					while `i' <= `iv1c_ct' {
						local x : word `i' of `insts1c'
* Add lags defined with TS operators
						local Lx "L`tau'.`x'"
						qui replace `vt1'=.
						qui replace `vt1' = `Lx'*`Low'*`ow' if `touse' & `touse2'
* Use capture here because there may be insufficient observations, e.g., if
*   the IVs include lags and tau=N-1.  _rc will be 2000 in this case.
* Bug in vecaccum means that if there is only 1 observation it will crash with insufficient obs.
* Replace missings with zeros to head this off.
						qui replace `vt1' = 0 if `vt1'==. & `touse'
						capture mat vecaccum `tx' = `vt1' `insts1c' /*
							*/ if `touse', nocons

						if _rc == 0 {
							mat `tt' = nullmat(`tt') \ `tx'
						}
						local i = `i'+1
					}

					capture mat `tt' = 1/`N' * `tt'
					if _rc != 0 {
						local errflag = 1
					}
					local Ls1resid "L`tau'.`s1resid'"
					tempvar ivLiv
					qui gen double `ivLiv' = `s1resid'*`Ls1resid'*`ow'*`Low' if `touse'
					qui sum `ivLiv' if `touse', meanonly
					scalar `sigttj' = r(sum)/(`N'-`dofminus')
					capture mat `tt' = `sigttj' * `tt'
* bw = bandwidth, karg is argument to kernel function, kw is kernel function (weight)
					scalar `karg' = `tau'/(`bw')
					if "`kernel'" == "Truncated" {
						scalar `kw'=1
					}
					if "`kernel'" == "Bartlett" {
						scalar `kw'=(1-`karg')
					}
					if "`kernel'" == "Parzen" {
						if `karg' <= 0.5 {
							scalar `kw' = 1-6*`karg'^2+6*`karg'^3
						}
						else {
							scalar `kw' = 2*(1-`karg')^3
						}
					}
					if "`kernel'" == "Tukey-Hanning" {
						scalar `kw'=0.5+0.5*cos(_pi*`karg')
					}
					if "`kernel'" == "Tukey-Hamming" {
						scalar `kw'=0.54+0.46*cos(_pi*`karg')
					}
					if "`kernel'" == "Tent" {
						scalar `kw'=2*(1-cos(`tau'*`karg')) / (`karg'^2)
					}
					if "`kernel'" == "Daniell" {
						scalar `kw'=sin(_pi*`karg') / (_pi*`karg')
					}
					if "`kernel'" == "Quadratic spectral" {
						scalar `kw'=25/(12*_pi^2*`karg'^2) /*
							*/ * ( sin(6*_pi*`karg'/5)/(6*_pi*`karg'/5) /*
							*/     - cos(6*_pi*`karg'/5) )
					}
* Need -capture-s here because tt may not exist (because of insufficient observations/lags)
					capture mat `tt' = (`tt'+`tt'')*`kw'
					if _rc != 0 {
						local errflag = 1
					}
* Accumulate if tt is valid
					if `errflag' == 0 {
						capture mat `S' = `S' + `tt'
					}
					local tau = `tau'+1
				}
				if "`weight'" == "" {
* If no weights specified, remove neutral weight variables
					local wtexp ""
				}
			}
* End of AC code
* To give S the right col/row names
			mat `S'=`S'+0*diag(`s1Zu')
			mat `S'=(`S'+`S'')/2
			mat `Sinv'=syminv(`S')
			local rankS = rowsof(`Sinv') - diag0cnt(`Sinv')
		}

* End of non-robust S and Sinv code (including AC)
*******************************************************************************************
* 2nd step and final coefficients
*******************************************************************************************
* User-supplied b0.  CUE objective function.
		if "`b0'" ~= "" {
			mat `B' = `b0'
			scalar `rss'=`b0rss'
			scalar `sigmasq'=`b0_s2'
			mat `W' = `Sinv'
		}
*******************************************************************************************
* Block for gmm 2nd step to get coefficients and 2nd step residuals

* Non-robust IV, LIML, k-class, CUE do not enter
		if "`gmm2s'`robust'`cluster'`kernel'`wmatrix'" != "" & "`cue'"=="" {
			mat `tempmat'=`XZ'*`Sinv'*`XZ''
			mat `tempmat'=(`tempmat'+`tempmat'')/2
			mat `B1'=syminv(`tempmat')
			mat `B1'=(`B1'+`B1'')/2
			mat `gmmB'=(`B1'*`XZ'*`Sinv'*`Zy')'
			
			capture drop `yhat'
			qui mat score double `yhat'=`gmmB' if `touse'
			qui gen double `gresid'=`lhs'-`yhat'
			qui gen double `gresid2'=`gresid'^2
			qui mat vecaccum `s2Zu'=`gresid' `exexog1' `inexog1' /*
				*/ `wtexp' if `touse', `noconstant'
		}
*******************************************************************************************
* GMM with arbitrary weighting matrix
		if ("`wmatrix'"~="") & ("`gmm2s'"=="") & ("`liml'`kclass'`cue'"=="") & "`b0'"=="" {
			mat `B'=`wB'
			scalar `rss'=`wbrss'
			scalar `sigmasq'=`wb_s2'
* Weighting matrix wmatrix already checked and assigned to macro W
		}
*******************************************************************************************
* IV coefficients
		if ("`wmatrix'"=="") & ("`gmm2s'"=="") & ("`liml'`kclass'`cue'"=="") & "`b0'"=="" {
			mat `B'=`ivB'
			scalar `rss'=`ivrss'
			scalar `sigmasq'=`iv_s2'
* IV weighting matrix.  By convention, no small-sample adjustment (consistent with S)
* No dofminus correction (needed in sigma^2, not ZZ)
			mat `W' = `ZZinv'*`N'/`iv_s2'
		}
*******************************************************************************************
* LIML, k-class coefficients
		if "`liml'`kclass'" ~= "" {
			mat `B'=`lB'
			scalar `rss'=`lrss'
			scalar `sigmasq'=`l_s2'
* No weighting matrix.
		}
*******************************************************************************************
* Efficient GMM coefficients
		if "`gmm2s'"!=""  & ("`liml'`kclass'`cue'"=="") & "`b0'"=="" {
			mat `B'=`gmmB'
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `gresid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `rss'= `ysum'[1,1]
* Adjust sigma-squared for dofminus
			scalar `sigmasq'=`rss'/(`N'-`dofminus')
			mat `W'=`Sinv'
		}
*******************************************************************************************
* Var-cov matrix
*******************************************************************************************
* Expressions below multipy by N because we are working with cross-products (XZ) not vcvs (Qxz)
* Efficient GMM: homoskedastic IV, 2-step FEGMM.  LIML, k-class, CUE handled separately.
* No robust, cluster, kernel => must be efficient GMM
* GMM option => must be efficient GMM
* b0 => must be efficient GMM
* wmatrix => (possibly) inefficient GMM
		tempname rankV
		if ("`robust'`cluster'`kernel'`liml'`kclass'`cue'`wmatrix'"=="")	/*
				*/	| ("`gmm2s'"~="")				/*
				*/	| ("`b0'"~="")			{
			mat `tempmat'=`XZ'*`Sinv'*`XZ''
			mat `tempmat'=(`tempmat'+`tempmat'')/2
			mat `V' = syminv(`tempmat')*`N'
			mat `V'=(`V'+`V'')/2
			scalar `rankV'=rowsof(`tempmat') - diag0cnt(`tempmat')
		}
* Possibly inefficient GMM: robust of all sorts with no 2nd step.  LIML, k-class, CUE handled separately.
		else if ("`liml'`kclass'`cue'"=="") {
			mat `V'=`XZWZXinv'*`XZW'*`S'*  /*
				*/ `XZW''*`XZWZXinv'*`N'
			mat `V'=(`V'+`V'')/2
			mat `tempmat'=syminv(`V')
			scalar `rankV'=rowsof(`tempmat') - diag0cnt(`tempmat')
		}
* LIML and k-class non-robust
		else if ("`liml'`kclass'" ~= "") & ("`robust'`cluster'`kernel'" == "") {
			if "`coviv'"== "" {
* LIML or k-class cov matrix
				mat `V'=`sigmasq'*`XhXhinv'
				scalar `rankV'=rowsof(`XhXh') - diag0cnt(`XhXh')
			}
			else {
* IV cov matrix
				mat `V'=`sigmasq'*`XPZXinv'
				scalar `rankV'=rowsof(`XPZXinv') - diag0cnt(`XPZXinv')
			}
			mat `V'=(`V'+`V'')/2
		}
* LIML and k-class robust
		else if ("`liml'`kclass'" ~= "") & ("`robust'`cluster'`kernel'" ~= "") {
			if "`coviv'"== "" {
* Use LIML or k-class cov matrix
				mat `V'=`XhXhinv'*`XZ'*`ZZinv'*`S'*`N'*  /*
					*/ `ZZinv'*`XZ''*`XhXhinv'
			}
			else {
* Use IV cov matrix
				mat `V'=`XPZXinv'*`XZ'*`ZZinv'*`S'*`N'*  /*
					*/ `ZZinv'*`XZ''*`XPZXinv'
			}
			mat `V'=(`V'+`V'')/2
			mat `tempmat'=syminv(`V')
			scalar `rankV'=rowsof(`tempmat') - diag0cnt(`tempmat')
		}
* End of VCV block
********************************************************************************
* Sargan-Hansen-Anderson-Rubin statistics
*******************************************************************************************
* Robust requires using gmm residuals; otherwise use iv residuals. CUE handled separately.
* wmatrix is possibly inefficient GMM so require 2nd step residuals
* b0 => return value of CUE objective function.  b0 is efficient GMM.
		if ("`robust'`cluster'`kernel'`wmatrix'" == "") & ("`cue'"=="") & ("`b0'"=="") {
			mat `uZSinvZu'= (`s1Zu'/`N')*`Sinv'*(`s1Zu''/`N')
			scalar `j' = `N'*`uZSinvZu'[1,1]
		}
		if ("`robust'`cluster'`kernel'`wmatrix'" ~= "") & ("`cue'"=="") & ("`b0'"=="") {
			mat `uZSinvZu'= (`s2Zu'/`N')*`Sinv'*(`s2Zu''/`N')
			scalar `j' = `N'*`uZSinvZu'[1,1]
		}
		if "`b0'"~="" {
			mat `uZSinvZu'= (`s1Zu'/`N')*`Sinv'*(`s1Zu''/`N')
			scalar `j' = `N'*`uZSinvZu'[1,1]
		}
		if "`liml'" != "" {
* Also save Anderson-Rubin overid stat if LIML
* Note dofminus is required because unlike Sargan and 2-step GMM J, doesn't derive from S
			scalar `arubin'=(`N'-`dofminus')*ln(`lambda')
			scalar `arubin_lin'=(`N'-`dofminus')*(`lambda'-1)
		}

***************************************************************************************
* Block for cue gmm
*******************************************************************************************
		if "`cue'" != "" {
			tempname b_init temphold
			capture _estimates hold `temphold', restore
			if _rc==1000 {
di as err "ivreg2 internal error - no room to save temporary estimation results"
di as err "Please drop one or more estimation results using -estimates drop-"
				exit 1000
			}
			if "`robust'`cluster'`bwopt'"~="" {
				local init_opt "gmm2s"
			}
			qui `ivreg2_cmd' `lhs' `inexog1' (`endo1'=`exexog1') `wtexp' /*
				*/ if `touse', `robust' `clopt' `bwopt' `kernopt' `dofmopt' /*
				*/ `noconstant' `init_opt' noid nocollin
			if e(rankzz)>e(rankxx) {
				if "`cueinit'"== "" {
					mat `b_init'=e(b)
				}
				else {
					mat `b_init'=`cueinit'
				}
* Use ML for numerical optimization.  Always nocons since not there by user or partialled-out
* Set up variables and options as globals
				global IV_lhs "`lhs'"
				global IV_inexog "`inexog1'"
				global IV_endog "`endo1'"
				global IV_exexog "`exexog1'"
				global IV_wt "`wtexp'"
				global IV_opt "`noconstant' `robust' `clopt' `bwopt' `kernopt' `dofmopt'"
* `gmm2s' not in IV_opt because cue+gmm2s not allowed
				ml model d0 `ivreg2_cmd'_cue (`lhs' = `endo1' `inexog1', `noconstant') `wtexp' /*
					*/ if `touse', maximize init(`b_init') `cueoptions' /*
					*/ crittype(neg GMM obj function -J) /*
					*/ collinear nooutput nopreserve missing noscvars
			}
			else {
di in ye "Equation exactly-identified: CUE and 2-step GMM coincide"
			}

			mat `B'=e(b)
			mat colnames `B' = _:
* Last call to get vcv, j, Sinv etc.
			qui `ivreg2_cmd' `lhs' `inexog1' (`endo1'=`exexog1') `wtexp' if `touse', /*
				*/ `noconstant' `robust' `clopt' `bwopt' `kernopt' `dofmopt' /*
				*/ b0(`B') noid nocollin

* Save all results
			mat `V'=e(V)
			mat `S'=e(S)
			mat `Sinv'=syminv(`S')
			mat `W'=`Sinv'

			local rankS = e(rankS)
			scalar `j'=e(j)
			local df_m = e(df_m)
			scalar `rankV'=e(rankV)

			if "`cluster'" != "" {
				local N_clust=e(N_clust)
			}
			capture drop `yhat'
			qui mat score double `yhat'=`B' if `touse'
			qui gen double `gresid'=`lhs'-`yhat'
			qui gen double `gresid2'=`gresid'^2
			capture drop `ysum'
			qui matrix vecaccum `ysum' = `iota' `gresid2' /*
				*/ `wtexp' if `touse', `noconstant'
			scalar `rss'= `ysum'[1,1]
* Adjust sigma-squared for dofminus
			scalar `sigmasq'=`rss'/(`N'-`dofminus')

			macro drop IV_lhs IV_inexog IV_endog IV_exexog IV_wt IV_opt
			capture _estimates unhold `temphold'

		}

*******************************************************************************************
* RSS, counts, dofs, F-stat, small-sample corrections
*******************************************************************************************

		scalar `rmse'=sqrt(`sigmasq')
		if "`noconstant'"=="" {
			scalar `mss'=`yyc' - `rss'
		}
		else {
			scalar `mss'=`yy' - `rss'
		}

* Counts modified to include constant if appropriate
		if "`noconstant'"=="" {
			local iv1_ct  = `iv1_ct' + 1
			local rhs1_ct = `rhs1_ct' + 1
		}
* Correct count of rhs variables accounting for dropped collinear vars
* Count includes constant

		local rhs_ct = rowsof(`XX') - diag0cnt(`XXinv')
		local Fdf1 = `rhs_ct' - `cons'
* CUE handled separately
		if "`cue'"=="" {
			local df_m = `rhs_ct' - `cons' + (`sdofminus'-`partialcons')
		}
		if "`cluster'"=="" {
* Residual dof adjusted for dofminus
			local df_r = `N' - `rhs_ct' - `dofminus' - `sdofminus'
		}
		else {
* To match Stata, subtract 1
			local df_r = `N_clust' - 1
		}

* Sargan-Hansen J dof and p-value
* df=0 doesn't guarantee j=0 since can be call to get value of CUE obj fn
		local jdf = `iv_ct' - `rhs_ct'
		if `jdf' == 0 & "`b0'"=="" {
			scalar `j' = 0
		}
		else {
			scalar `jp' = chiprob(`jdf',`j')
		}
		if "`liml'"~="" {
			scalar `arubinp' = chiprob(`jdf',`arubin')
			scalar `arubin_linp' = chiprob(`jdf',`arubin_lin')
		}

* Small sample corrections for var-cov matrix.
* If robust, the finite sample correction is N/(N-K), and with no small
* we change this to 1 (a la Davidson & MacKinnon 1993, p. 554, HC0).
* If cluster, the finite sample correction is (N-1)/(N-K)*M/(M-1), and with no small
* we change this to 1 (a la Wooldridge 2002, p. 193), where M=number of clusters.

		if "`small'" != "" {
			if "`cluster'"=="" {
				matrix `V'=`V'*(`N'-`dofminus')/(`N'-`rhs_ct'-`dofminus'-`sdofminus')
			}
			else {
				matrix `V'=`V'*(`N'-1)/(`N'-`rhs_ct'-`sdofminus') /*
					*/		* `N_clust'/(`N_clust'-1)
			}
			scalar `sigmasq'=`rss'/(`N'-`rhs_ct'-`dofminus'-`sdofminus')
			scalar `rmse'=sqrt(`sigmasq')
		}

		scalar `r2u'=1-`rss'/`yy'
		scalar `r2c'=1-`rss'/`yyc'
		if "`noconstant'"=="" {
			scalar `r2'=`r2c'
			scalar `r2_a'=1-(1-`r2')*(`N'-1)/(`N'-`rhs_ct'-`dofminus'-`sdofminus')
		}
		else {
			scalar `r2'=`r2u'
			scalar `r2_a'=1-(1-`r2')*`N'/(`N'-`rhs_ct'-`dofminus'-`sdofminus')
		}

* Fstat
* To get it to match Stata's, must post separately with dofs and then do F stat by hand
*   in case weights generate non-integer obs and dofs
* Create copies so they can be posted
		tempname FB FV
		mat `FB'=`B'
		mat `FV'=`V'
		capture ereturn post `FB' `FV'
* If the cov matrix wasn't positive definite, the post fails with error code 506
		local rc = _rc
		if `rc' != 506 {
			local Frhs1 `rhs1'
			capture test `Frhs1'
			if "`small'" == "" {
				if "`cluster'"=="" {
					capture scalar `F' = r(chi2)/`Fdf1' * `df_r'/(`N'-`dofminus')
				}
				else {
					capture scalar `F' = r(chi2)/`Fdf1' * /*
* sdofminus used here so that F-stat matches test stat from regression with no partial and small
						*/ (`N_clust'-1)/`N_clust' * (`N'-`rhs_ct'-`sdofminus')/(`N'-1)
				}
			}
			else {
				capture scalar `F' = r(chi2)/`Fdf1'
			}
			capture scalar `Fp'=Ftail(`Fdf1',`df_r',`F')
			capture scalar `Fdf2'=`df_r'
		}

* If j==. or vcv wasn't full rank, then vcv problems and F is meaningless
		if `j' == . | `rc'==506 {
			scalar `F' = .
			scalar `Fp' = .
		}

* End of counts, dofs, F-stat, small sample corrections
*******************************************************************************************
* orthog option: C statistic (difference of Sargan statistics)
*******************************************************************************************
* Requires j dof from above
		if "`orthog'"!="" {
			tempname cj cstat cstatp
* Initialize cstat
			scalar `cstat' = 0
* Each variable listed must be in instrument list.
* To avoid overwriting, use cendo, cinexog1, cexexog, cendo_ct, cex_ct
			local cendo1   "`endo1'"
			local cinexog1 "`inexog1'"
			local cexexog1 "`exexog1'"
			local cinsts1  "`insts1'"
			local crhs1    "`rhs1'"
			local clist1   "`orthog'"
			local clist_ct  : word count `clist1'

* Check to see if c-stat vars are in original list of all ivs
* cinexog1 and cexexog1 are after c-stat exog list vars have been removed
* cendo1 is endo1 after included exog being tested has been added
			foreach x of local clist1 {
				local llex_ct : word count `cexexog1'
				Subtract cexexog1 : "`cexexog1'" "`x'"
				local cex1_ct : word count `cexexog1'
				local ok = `llex_ct' - `cex1_ct'
				if (`ok'==0) {
* Not in excluded, check included and add to endog list if it appears
					local llin_ct : word count `cinexog1'
					Subtract cinexog1 : "`cinexog1'" "`x'"
					local cin1_ct : word count `cinexog1'
					local ok = `llin_ct' - `cin1_ct'
					if (`ok'==0) {
* Not in either list
di in r "Error: `x' listed in orthog() but does not appear as exogenous." 
						error 198
					}
					else {
						local cendo1 "`cendo1' `x'"
					}
				}
			}

* If robust, HAC/AC or GMM (but not LIML or IV), create optimal weighting matrix to pass to ivreg2
*   by extracting the submatrix from the full S and then inverting.
*   This guarantees the C stat will be non-negative.  See Hayashi (2000), p. 220. 
* Calculate C statistic with recursive call to ivreg2
* Collinearities may cause problems, hence -capture-.
* smatrix works generally, including homoskedastic case with Sargan stat
			capture {
				capture _estimates hold `ivest', restore
				if _rc==1000 {
di as err "ivreg2 internal error - no room to save temporary estimation results"
di as err "Please drop one or more estimation results using -estimates drop-"
					exit 1000
				}
				if "`kernel'" != "" {
					local bwopt "bw(`bw')"
					local kernopt "kernel(`kernel')"
				}
* clopt is omitted because it requires calculation of numbers of clusters, which is done
* only when S matrix is calculated
				capture `ivreg2_cmd' `lhs' `cinexog1' /*
					*/ (`cendo1'=`cexexog1') /*
					*/ if `touse' `wtexp', `noconstant' /*
					*/ `options' `small' `robust' /*
					*/ `gmm2s' `bwopt' `kernopt' `dofmopt' /*
					*/ smatrix("`S'") noid nocollin
				local rc = _rc
				if `rc' == 481 {
					scalar `cstat' = 0
					local cstatdf = 0
				}
				else {
					scalar `cj'=e(j)
					local cjdf=e(jdf)
				}
				scalar `cstat' = `j' - `cj'
				local cstatdf  = `jdf' - `cjdf'
				_estimates unhold `ivest'
				scalar `cstatp'= chiprob(`cstatdf',`cstat')
* Collinearities may cause C-stat dof to differ from the number of variables in orthog()
* If so, set cstat=0
				if `cstatdf' != `clist_ct' {
					scalar `cstat' = 0
				}
			}
		}
* End of orthog block

*******************************************************************************************
* Endog option
*******************************************************************************************
* Uses recursive call with orthog
		if "`endogtest'"!="" {
			tempname estat estatp
* Initialize estat
			scalar `estat' = 0
* Each variable to test must be in endo list.
* To avoid overwriting, use eendo, einexog1, etc.
			local eendo1   "`endo1'"
			local einexog1 "`inexog1'"
			local einsts1  "`insts1'"
			local elist1   "`endogtest'"
			local elist_ct  : word count `elist1'
* Check to see if endog test vars are in original endo1 list of endogeneous variables
* eendo1 and einexog1 are after endog test vars have been removed from endo and added to inexog
			foreach x of local elist1 {
				local llendo_ct : word count `eendo1'
				local eendo1    : list eendo1 - x
				local eendo1_ct : word count `eendo1'
				local ok = `llendo_ct' - `eendo1_ct'
				if (`ok'==0) {
* Not in endogenous list
di in r "Error: `x' listed in endog() but does not appear as endogenous." 
						error 198
				}
				else {
					local einexog1 "`einexog1' `x'"
				}
			}
* Recursive call to ivreg2 using orthog option to obtain endogeneity test statistic
* Collinearities may cause problems, hence -capture-.
			capture {
				capture _estimates hold `ivest', restore
				if _rc==1000 {
di as err "ivreg2 internal error - no room to save temporary estimation results"
di as err "Please drop one or more estimation results using -estimates drop-"
					exit 1000
				}
				capture `ivreg2_cmd' `lhs' `einexog1' /*
					*/ (`eendo1'=`exexog1') if `touse' /*
					*/ `wtexp', `noconstant' `robust' `clopt' /*
					*/ `gmm2s' `liml' `bwopt' `kernopt' /*
					*/ `small' `dofmopt' `options' /*
					*/ orthog(`elist1') noid nocollin
				local rc = _rc
				if `rc' == 481 {
					scalar `estat' = 0
					local estatdf = 0
					}
				else {
					scalar `estat'=e(cstat)
					local  estatdf=e(cstatdf)
					scalar `estatp'=e(cstatp)
				}
				_estimates unhold `ivest'
* Collinearities may cause endog stat dof to differ from the number of variables in endog()
* If so, set estat=0
				if `estatdf' != `elist_ct' {
					scalar `estat' = 0
				}
			}
* End of endogeneity test block
		}

*******************************************************************************************
* Rank identification and redundancy block
*******************************************************************************************
		if `endo1_ct' > 0 & "`noid'"=="" {

* id=underidentification statistic, wid=weak identification statistic
			tempname rkmatrix idrkstat widrkstat iddf idp
			tempname ccf cdf rkf cceval cdeval cd cc
			tempname idstat widstat

* Anderson canon corr underidentification statistic if homo, rk stat if not
* Need id stat for testing full rank=(#cols-1) but might need all rk stats for -redundant- test
			if "`redundant'"=="" {
				local rkopt "full"
			}
			else {
				local rkopt "all"
			}
			qui ranktest (`endo1') (`exexog1') `wtexp' if `touse', partial(`inexog1') `rkopt' /*
				*/ `noconstant' `robust' `clopt' `bwopt' `kernopt'
			mat `rkmatrix'=r(rkmatrix)
			if "`cluster'"=="" {
				scalar `idstat'=r(chi2)/r(N)*(`N'-`dofminus')
			}
			else {
* No dofminus adjustment needed for cluster-robust
				scalar `idstat'=r(chi2)
			}
			mat `cceval'=r(ccorr)
			mat `cdeval' = J(1,`endo1_ct',.)
			forval i=1/`endo1_ct' {
				mat `cceval'[1,`i'] = (`cceval'[1,`i'])^2
				mat `cdeval'[1,`i'] = `cceval'[1,`i'] / (1 - `cceval'[1,`i'])
			}
			local iddf = `iv_ct' - (`rhs_ct'-1)
			scalar `idp' = chiprob(`iddf',`idstat')
* Cragg-Donald F statistic.
* Under homoskedasticity, Wald cd eigenvalue = cc/(1-cc) Anderson canon corr eigenvalue.
			scalar `cd'=`cdeval'[1,`endo1_ct']
			scalar `cdf'=`cd'*(`N'-`sdofminus'-`iv_ct'-`dofminus')/`exex1_ct'

* Weak id statistic is Cragg-Donald F stat, rk Wald F stat if not
			if "`robust'`cluster'`kernel'"=="" {
				scalar `widstat'=`cdf'
			}
			else {
* Need only test of full rank
				qui ranktest (`endo1') (`exexog1') `wtexp' if `touse', partial(`inexog1') full wald /*
				*/ `noconstant' `robust' `clopt' `bwopt' `kernopt'
* sdofminus used here so that F-stat matches test stat from regression with no partial
				if "`cluster'"=="" {
					scalar `rkf'=r(chi2)/r(N)*(`N'-`iv_ct'-`sdofminus'-`dofminus')/`exex1_ct'
				}
				else {
					scalar `rkf'=r(chi2)/(`N'-1) /*
					*/	*(`N'-`iv_ct'-`sdofminus') /*
					*/	*(`N_clust'-1)/(`N_clust')/`exex1_ct'
				}
				scalar `widstat'=`rkf'
			}
		}

* LM redundancy test
		if `endo1_ct' > 0 & "`redundant'" ~= "" & "`noid'"=="" {
* Use K-P rk statistics and LM version of test
* Statistic is the rank of the matrix of Z_1B*X_2, where Z_1B are the possibly redundant
* instruments and X_1 are the endogenous regressors; both have X_2 (exogenous regressors)
* and Z_1A (maintained excluded instruments) partialled out.  LM test of rank is
* is numerically equivalent to estimation of set of RF regressions and performing
* standard LM test of possibly redundant instruments.

			local redlist1 "`redundant'"
			local rexexog1 : list exexog1 - redlist1
			local notlisted : list redlist1 - exexog1
			if "`notlisted'" ~= "" {
di in r "Error: `notlisted' listed in redundant() but does not appear as excluded instrument." 
				error 198
				}
			local rexexog1_ct : word count `rexexog1'
			if `rexexog1_ct' < `endo1_ct' {
di in r "Error: specification with redundant() option is unidentified (fails rank condition)" 
				error 198
			}
* LM version requires only -nullrank- rk statistics so would not need -all- option
			tempname rrkmatrix
			qui ranktest (`endo1') (`redlist1') `wtexp' if `touse', partial(`inexog1' `rexexog1') null /*
				*/ `noconstant' `robust' `clopt' `bwopt' `kernopt'
			mat `rrkmatrix'=r(rkmatrix)
			tempname redstat redp
			local redlist_ct : word count `redlist1'
* dof adjustment needed because it doesn't use the adjusted S
			if "`cluster'"=="" {
				scalar `redstat' = `rrkmatrix'[1,1]/r(N)*(`N'-`dofminus')
			}
			else {
* No dofminus adjustment needed for cluster-robust
				scalar `redstat' = `rrkmatrix'[1,1]
			}
			local reddf = `endo1_ct'*`redlist_ct'
			scalar `redp' = chiprob(`reddf',`redstat')
		}

* End of identification stats block

*******************************************************************************************
* Error-checking block
*******************************************************************************************

* Check if adequate number of observations
		if `N' <= `iv_ct' {
di in r "Error: number of observations must be greater than number of instruments"
di in r "       including constant."
			error 2001
		}

* Check if robust VCV matrix is of full rank
		if "`gmm2s'`robust'`cluster'`kernel'" != "" {
* Robust covariance matrix not of full rank means either a singleton dummy  or too few
*   clusters (in which case the indiv SEs are OK but no F stat or 2-step GMM is possible),
*   or there are too many AC/HAC-lags, or the HAC covariance estimator
*   isn't positive definite (possible with truncated and Tukey-Hanning kernels)
			if `rankS' < `iv_ct' {
* If two-step GMM then exit with error ...
				if "`gmm2s'" != "" {
di in r "Error: estimated covariance matrix of moment conditions not of full rank;"
di in r "       cannot calculate optimal weighting matrix for GMM estimation."
di in r "Possible causes:"
					if "`cluster'" != "" {
di in r "       number of clusters insufficient to calculate optimal weighting matrix"
					}
					if "`kernel'" != "" {
di in r "       covariance matrix of moment conditions not positive definite"
di in r "       covariance matrix uses too many lags"
					}
di in r "       singleton dummy variable (dummy with one 1 and N-1 0s or vice versa)"
di in r "-partial- option may address problem.  See help " _c
di in smcl "{help ivreg2}".
					error 498
				}
* Estimation isn't two-step GMM so continue but J, F, and C stat (if present) all meaningless
* Must set Sargan-Hansen j = missing so that problem can be reported in output
				else {
					scalar `j' = .
					if "`orthog'"!="" {
						scalar `cstat' = .
					}
					if "`endogtest'"!="" {
						scalar `estat' = .
					}
				}
			}
		}

* End of error-checking block
********************************************************************************************
* Reduced form and first stage regression options
*******************************************************************************************
* Relies on proper count of (non-collinear) IVs generated earlier.
* Note that nocons option + constant in instrument list means first-stage
* regressions are reported with nocons option.  First-stage F-stat therefore
* correctly includes the constant as an explanatory variable.

		if "`rf'`saverf'`first'`ffirst'`savefirst'" != "" & (`endo1_ct' > 0) & "`noid'"=="" {
* Reduced form needed for AR first-stage test stat.  Also estimated if requested.
				tempname archi2 archi2p arf arfp ardf ardf_r sstat sstatp sstatdf
				doRF "`lhs'" "`inexog1'" "`exexog1'" /*
					*/ `touse' `"`wtexp'"' `"`noconstant'"' `"`robust'"' /*
					*/ `"`clopt'"' `"`bwopt'"' `"`kernopt'"' /*
					*/ `"`saverfprefix'"' /*
					*/ "`dofminus'" "`sdofminus'" "`ivreg2_cmd'"
				scalar `archi2'=r(archi2)
				scalar `archi2p'=r(archi2p)
				scalar `arf'=r(arf)
				scalar `arfp'=r(arfp)
				scalar `ardf'=r(ardf)
				scalar `ardf_r'=r(ardf_r)
				local rfeq "`r(rfeq)'"
* Drop saved rf results if needed only for first-stage estimations
				if "`rf'`saverf'" == "" {
					capture estimates drop `rfeq'
				}
* Stock-Wright S statistic.  Evaluate CUE objective function at b=0.
* Included exogenous, if any, are partialled out.
				tempname b1
				mat `b1'=J(1,`endo1_ct',0)
				matrix colnames `b1' = `endo1'
				if `inexog1_ct' > 0 {
					qui `ivreg2_cmd' `lhs' `inexog1' (`endo1'=`exexog1') `wtexp' if `touse', /*
						*/	b0(`b1') `noconstant' dofminus(`dofminus') /*
						*/	`robust' `clopt' `bwopt' `kernopt' nocollin partial(`inexog1')
				}
				else if `cons' > 0 {
					qui `ivreg2_cmd' `lhs' (`endo1'=`exexog1') `wtexp' if `touse', /*
						*/	b0(`b1') `noconstant' dofminus(`dofminus') /*
						*/	`robust' `clopt' `bwopt' `kernopt' nocollin partial(_cons)
				}
				else {
					qui `ivreg2_cmd' `lhs' (`endo1'=`exexog1') `wtexp' if `touse', /*
						*/	b0(`b1') `noconstant' dofminus(`dofminus') /*
						*/	`robust' `clopt' `bwopt' `kernopt' nocollin
				}

				scalar `sstat'=e(j)
				scalar `sstatdf'=`ardf'
				scalar `sstatp'=chiprob(`sstatdf',`sstat')
		}

		if "`first'`ffirst'`savefirst'" != ""  & (`endo1_ct' > 0) {

			if `iv1_ct' > `iv_ct' {
di
di in gr "Warning: collinearities detected among instruments"
di in gr "1st stage tests of excluded exogenous variables may be incorrect"
			}

			tempname firstmat
			local sdofmopt = "sdofminus(`sdofminus')"
			doFirst "`endo1'" "`inexog1'" "`exexog1'" "`XXinv'" "`XPZXinv'" /*
				*/ `touse' `"`wtexp'"' `"`noconstant'"' `"`robust'"' /*
				*/ `"`clopt'"' `"`bwopt'"' `"`kernopt'"' /*
				*/ `"`savefprefix'"' `"`dofmopt'"' `"`sdofmopt'"' /*
				*/ "`ivreg2_cmd'"

			local firsteqs "`r(firsteqs)'"
			capture mat `firstmat' = r(firstmat)
			if _rc != 0 {
di in ye "Warning: missing values encountered; first stage regression results not saved"
			}
		}
* End of first-stage regression code
**********************************************************************************************
* Post and display results.
*******************************************************************************************

* restore data if preserved for partial option
		if "`partial'" != "" {
			restore
		}

		if "`small'"!="" {
			local NminusK = `N'-`rhs_ct'-`sdofminus'
			capture ereturn post `B' `V', dep(`depname') obs(`N') esample(`touse') /*
				*/ dof(`NminusK')
		}
		else {
			capture ereturn post `B' `V', dep(`depname') obs(`N') esample(`touse')
		}
		local rc = _rc
		if `rc' == 504 {
di in red "Error: estimated variance-covariance matrix has missing values"
			exit 504
		}
		if `rc' == 506 {
di in red "Error: estimated variance-covariance matrix not positive-definite"
			exit 506
		}
		if `rc' > 0 {
di in red "Error: estimation failed - could not post estimation results"
			exit `rc'
		}

		ereturn local instd `endo'
		local insts : colnames `S'
* Stata convention is to exclude constant from instrument list
* Need word option so that varnames with "_cons" in them aren't zapped
		local insts : subinstr local insts "_cons" "", word
		ereturn local insts  `insts'
		ereturn local inexog `inexog'
		ereturn local exexog `exexog'
		ereturn local partial `partial'
		ereturn scalar inexog_ct=`inexog1_ct'
		ereturn scalar exexog_ct=`exex1_ct'
		ereturn scalar endog_ct =`endo1_ct'
		ereturn scalar partial_ct   =`partial_ct'
		if "`collin'`ecollin'`dups'" != "" | `partial_ct' > 0 {
			ereturn local collin   `collin'
			ereturn local ecollin  `ecollin'
			ereturn local dups     `dups'
			ereturn local instd1   `endo1'
			ereturn local inexog1  `inexog1'
			ereturn local exexog1  `exexog1'
			ereturn local partial1 `partial1'
		}

		if "`smatrix'" == "" {
			ereturn matrix S `S'
		}
		else {
* Create a copy so posting doesn't zap the original
			tempname Scopy
			mat `Scopy'=`smatrix'
			ereturn matrix S `Scopy'
		}

* No weighting matrix defined for LIML and kclass
		if "`wmatrix'"=="" & "`liml'`kclass'"=="" {
			ereturn matrix W `W'
		}
		else if "`liml'`kclass'"=="" {
* Create a copy so posting doesn't zap the original
			tempname Wcopy
			mat `Wcopy'=`wmatrix'
			ereturn matrix W `Wcopy'
		}

		if "`kernel'"!="" {
			ereturn local kernel "`kernel'"
			ereturn scalar bw=`bw'
			ereturn local tvar "`tvar'"
			if "`ivar'" ~= "" {
				ereturn local ivar "`ivar'"
			}
			if "`bwchoice'" ~= "" {
				ereturn local bwchoice "`bwchoice'"
			}
		}

		if "`small'"!="" {
			ereturn scalar df_r=`df_r'
			ereturn local small "small"
		}
		if "`nopartialsmall'"=="" {
			ereturn local partialsmall "small"
		}

		if "`cluster'"!="" {
			ereturn scalar N_clust=`N_clust'
			ereturn local clustvar `cluster'
		}

		if "`robust'`cluster'" != "" {
			ereturn local vcetype "Robust"
		}

		ereturn scalar df_m=`df_m'
		ereturn scalar sdofminus   =`sdofminus'
		ereturn scalar dofminus=`dofminus'
		ereturn scalar r2=`r2'
		ereturn scalar rmse=`rmse'
		ereturn scalar rss=`rss'
		ereturn scalar mss=`mss'
		ereturn scalar r2_a=`r2_a'
		ereturn scalar F=`F'
		ereturn scalar Fp=`Fp'
		ereturn scalar Fdf1=`Fdf1'
		ereturn scalar Fdf2=`Fdf2'
		ereturn scalar yy=`yy'
		ereturn scalar yyc=`yyc'
		ereturn scalar r2u=`r2u'
		ereturn scalar r2c=`r2c'
		ereturn scalar rankzz=`iv_ct'
		ereturn scalar rankxx=`rhs_ct'
		if "`gmm2s'`robust'`cluster'`kernel'" != "" {
			ereturn scalar rankS=`rankS'
		}
		ereturn scalar rankV=`rankV'
		ereturn scalar ll = -0.5 * (`N'*ln(2*_pi) + `N'*ln(`rss'/`N') + `N')

* Always save J.  Also save as Sargan if homoskedastic; save A-R if LIML.
		ereturn scalar j=`j'
		ereturn scalar jdf=`jdf'
		if `j' != 0 & `j' != . {
			ereturn scalar jp=`jp'
		}
		if ("`robust'`cluster'"=="") {
			ereturn scalar sargan=`j'
			ereturn scalar sargandf=`jdf'
			if `j' != 0  & `j' != . {
				ereturn scalar sarganp=`jp'
			}
		}
		if "`liml'"!="" {
			ereturn scalar arubin=`arubin'
			ereturn scalar arubin_lin=`arubin_lin'
			if `j' != 0  & `j' != . {
				ereturn scalar arubinp=`arubinp'
				ereturn scalar arubin_linp=`arubin_linp'
			}
			ereturn scalar arubindf=`jdf'
		}

		if "`orthog'"!="" {
			ereturn scalar cstat=`cstat'
			if `cstat'!=0  & `cstat' != . {
				ereturn scalar cstatp=`cstatp'
				ereturn scalar cstatdf=`cstatdf'
				ereturn local clist `clist1'
			}
		}

		if "`endogtest'"!="" {
			ereturn scalar estat=`estat'
			if `estat'!=0  & `estat' != . {
				ereturn scalar estatp=`estatp'
				ereturn scalar estatdf=`estatdf'
				ereturn local elist `elist1'
			}
		}

		if `endo1_ct' > 0 & "`noid'"=="" {
			ereturn scalar idstat=`idstat'
			ereturn scalar iddf=`iddf'
			ereturn scalar idp=`idp'
			ereturn scalar cd=`cd'
			ereturn scalar widstat=`widstat'
			ereturn scalar cdf=`cdf'
			capture ereturn matrix ccev=`cceval'
			capture ereturn matrix cdev `cdeval'
			capture ereturn scalar rkf=`rkf'
		}

		if "`redundant'"!="" & "`noid'"=="" {
			ereturn scalar redstat=`redstat'
			ereturn scalar redp=`redp'
			ereturn scalar reddf=`reddf'
			ereturn local  redlist `redlist1'
		}

		if "`first'`ffirst'`savefirst'" != "" & `endo1_ct'>0 & "`noid'"=="" {
* Capture here because firstmat empty if mvs encountered in 1st stage regressions
			capture ereturn matrix first `firstmat'
			ereturn scalar  arf=`arf'
			ereturn scalar  arfp=`arfp'
			ereturn scalar  archi2=`archi2'
			ereturn scalar  archi2p=`archi2p'
			ereturn scalar  ardf=`ardf'
			ereturn scalar  ardf_r=`ardf_r'
			ereturn scalar  sstat=`sstat'
			ereturn scalar  sstatp=`sstatp'
			ereturn scalar  sstatdf=`sstatdf'
			ereturn local   firsteqs `firsteqs'
		}
		if "`rf'`saverf'" != "" & `endo1_ct'>0 {
			ereturn local   rfeq `rfeq'
		}

		ereturn local depvar `lhs'

		if "`liml'"!="" {
			ereturn local model "liml"
			ereturn scalar kclass=`kclass2'
			ereturn scalar lambda=`lambda'
			if `fuller' > 0 & `fuller' < . {
				ereturn scalar fuller=`fuller'
			}
		}
		else if "`kclass'" != "" {
			ereturn local model "kclass"
			ereturn scalar kclass=`kclass2'
		}
		else if "`gmm2s'`cue'`b0'`wmatrix'"=="" {
			if "`endo1'" == "" {
				ereturn local model "ols"
			}
			else {
				ereturn local model "iv"
			}
		}
		else if "`cue'`b0'"~="" {
				ereturn local model "cue"
			}
		else if "`gmm2s'"~="" {
			ereturn local model "gmm2s"
		}
		else if "`wmatrix'"~="" {
				ereturn local model "gmmw"
		}
		else {
* Should never enter here
			ereturn local model "unknown"
		}

		if "`weight'" != "" { 
			ereturn local wexp "=`exp'"
			ereturn local wtype `weight'
		}
		ereturn local cmd `ivreg2_cmd'
		ereturn local cmdline `cmdline'
		ereturn local version `lversion'
		ereturn scalar cons=`cons'
		ereturn scalar partialcons=`partialcons'

		ereturn local predict "`ivreg2_cmd'_p"

		if "`e(model)'"=="gmm2s" & "`wmatrix'"=="" {
			local title2 "2-Step GMM estimation"
		}
		else if "`e(model)'"=="gmm2s" & "`wmatrix'"~="" {
			local title2 "2-Step GMM estimation with user-supplied first-step weighting matrix"
		}
		else if "`e(model)'"=="gmmw" {
			local title2 "GMM estimation with user-supplied weighting matrix"
		}
		else if "`e(model)'"=="cue" & "`b0'"=="" {
			local title2 "CUE estimation"
		}
		else if "`e(model)'"=="cue" & "`b0'"~="" {
			local title2 "CUE evaluated at user-supplied parameter vector"
		}
		else if "`e(model)'"=="ols" {
			local title2 "OLS estimation"
		}
		else if "`e(model)'"=="iv" {
			local title2 "IV (2SLS) estimation"
		}
		else if "`e(model)'"=="liml" {
			local title2 "LIML estimation"
		}
		else if "`e(model)'"=="kclass" {
			local title2 "k-class estimation"
		}
		else {
* Should never reach here
			local title2 "unknown estimation"
		}
		if "`e(vcetype)'" == "Robust" {
			local hacsubtitle1 "heteroskedasticity"
		}
		if "`e(kernel)'"!="" {
			local hacsubtitle3 "autocorrelation"
		}
		if "`e(clustvar)'"!="" {
			local hacsubtitle3 "clustering on `e(clustvar)'"
		}
		if "`hacsubtitle1'"~="" & "`hacsubtitle3'" ~= "" {
			local hacsubtitle2 " and "
		}
		if "`title'"=="" {
			ereturn local title "`title1'`title2'"
		}
		else {
			ereturn local title "`title'"
		}
		if "`subtitle'"~="" {
			ereturn local subtitle "`subtitle'"
		}
		local hacsubtitle "`hacsubtitle1'`hacsubtitle2'`hacsubtitle3'"
		if "`b0'"~="" {
			ereturn local hacsubtitleB "Estimates based on supplied parameter vector"
		}
		else if "`hacsubtitle'"~="" & "`gmm2s'`cue'"~="" {
			ereturn local hacsubtitleB "Estimates efficient for arbitrary `hacsubtitle'"
		}
		else if "`wmatrix'"~="" {
			ereturn local hacsubtitleB "Efficiency of estimates dependent on weighting matrix"
		}
		else {
			ereturn local hacsubtitleB "Estimates efficient for homoskedasticity only"
		}
		if "`hacsubtitle'"~="" {
			ereturn local hacsubtitleV "Statistics robust to `hacsubtitle'"
		}
		else {
			ereturn local hacsubtitleV "Statistics consistent for homoskedasticity only"
		}
	}

*******************************************************************************************
* Display results unless ivreg2 called just to generate stats or nooutput option

	if "`nooutput'" == "" {
		if "`savefirst'`saverf'" != "" {
			DispStored `"`saverf'"' `"`savefirst'"' `"`ivreg2_cmd'"'
		}
		if "`rf'" != "" {
			DispRF
		}
		if "`first'" != "" {
			DispFirst `"`ivreg2_cmd'"'
		}
		if "`first'`ffirst'" != "" {
			DispFFirst `"`ivreg2_cmd'"'
		}
		if "`eform'"!="" {
			local efopt "eform(`eform')"
		}
		DispMain `"`noheader'"' `"`plus'"' `"`efopt'"' `"`level'"' `"`nofooter'"' `"`ivreg2_cmd'"'
	}

* Drop first stage estimations unless explicitly saved or if replay
	if "`savefirst'" == "" {
		local firsteqs "`e(firsteqs)'"
		foreach eqname of local firsteqs {
			capture estimates drop `eqname'
		}
		ereturn local firsteqs
	}
	
* Drop reduced form estimation unless explicitly saved or if replay
	if "`saverf'" == "" {
		local eqname "`e(rfeq)'"
		capture estimates drop `eqname'
		ereturn local rfeq
	}

end

*******************************************************************************************
* SUBROUTINES
*******************************************************************************************

program define DispMain, eclass
	args noheader plus efopt level nofooter helpfile
	version 8.2
* Prepare for problem resulting from rank(S) being insufficient
* Results from insuff number of clusters, too many lags in HAC,
*   to calculate robust S matrix, HAC matrix not PD, singleton dummy,
*   and indicated by missing value for j stat
* Macro `rprob' is either 1 (problem) or 0 (no problem)
	capture local rprob ("`e(j)'"==".")

	if "`noheader'"=="" {
		if "`e(title)'" ~= "" {
di in gr _n "`e(title)'"
			local tlen=length("`e(title)'")
di in gr "{hline `tlen'}"
		}
		if "`e(subtitle)'" ~= "" {
di in gr "`e(subtitle)'"
		}
		if "`e(model)'"=="liml" | "`e(model)'"=="kclass" {
di in gr "k               =" %7.5f `e(kclass)'
		}
		if "`e(model)'"=="liml" {
di in gr "lambda          =" %7.5f `e(lambda)'
		}
		if e(fuller) > 0 & e(fuller) < . {
di in gr "Fuller parameter=" %-5.0f `e(fuller)'
		}
		if "`e(hacsubtitleB)'" ~= "" {
di in gr _n "`e(hacsubtitleB)'" _c
		}
		if "`e(hacsubtitleV)'" ~= "" {
di in gr _n "`e(hacsubtitleV)'"
		}
		if "`e(kernel)'"!="" {
di in gr "  kernel=`e(kernel)'; bandwidth=" %6.2g `e(bw)'
			if "`e(bwchoice)'"!="" {
di in gr "  `e(bwchoice)'"
			}
di in gr "  time variable (t):  " in ye e(tvar)
			if "`e(ivar)'" != "" {
di in gr "  group variable (i): " in ye e(ivar)
			}
		}
		di
		if "`e(clustvar)'"!="" {
di in gr "Number of clusters (" "`e(clustvar)'" ") = " in ye %-4.0f e(N_clust) _continue
		}
		else {
di in gr "                                   " _continue
		}
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
di in gr _c _col(55) "F(" %3.0f e(Fdf1) "," %6.0f e(Fdf2) ") = "
		if e(F) < 99999 {
di in ye %8.2f e(F)
		}
		else {
di in ye %8.2e e(F)
		}
di in gr _col(55) "Prob > F      = " in ye %8.4f e(Fp)

di in gr "Total (centered) SS     = " in ye %12.0g e(yyc) _continue
di in gr _col(55) "Centered R2   = " in ye %8.4f e(r2c)
di in gr "Total (uncentered) SS   = " in ye %12.0g e(yy) _continue
di in gr _col(55) "Uncentered R2 = " in ye %8.4f e(r2u)
di in gr "Residual SS             = " in ye %12.0g e(rss) _continue
di in gr _col(55) "Root MSE      = " in ye %8.4g e(rmse)
di
	}

* Display coefficients etc.
* Unfortunate but necessary hack here: to suppress message about cluster adjustment of
*   standard error, clear e(clustvar) and then reset it after display
	local cluster `e(clustvar)'
	ereturn local clustvar
	ereturn display, `plus' `efopt' level(`level')
	ereturn local clustvar `cluster'

* Display 1st footer with identification stats
* Footer not displayed if -nofooter- option or if pure OLS, i.e., model="ols" and Sargan-Hansen=0
	if ~("`nofooter'"~="" | (e(model)=="ols" & (e(sargan)==0 | e(j)==0))) {

* Under ID test
		if "`e(instd)'"~="" & "`e(idstat)'"~="" {
di in smcl _c "{help `helpfile'##idtest:Underidentification test}"
			if "`e(vcetype)'`e(kernel)'"=="" {
di in gr _c " (Anderson canon. corr. LM statistic):"
			}
			else {
di in gr _c " (Kleibergen-Paap rk LM statistic):"
			}
di in ye _col(71) %8.3f e(idstat)
di in gr _col(52) "Chi-sq(" in ye e(iddf) /* 
	       			*/  in gr ") P-val =  " in ye _col(73) %6.4f e(idp)
* IV redundancy statistic
			if "`e(redlist)'"!="" {
di in gr "-redundant- option:"
di in smcl _c "{help `helpfile'##redtest:IV redundancy test}"
di in gr _c " (LM test of redundancy of specified instruments):"
di in ye _col(71) %8.3f e(redstat)
di in gr _col(52) "Chi-sq(" in ye e(reddf) /* 
	       			*/  in gr ") P-val =  " in ye _col(73) %6.4f e(redp)
di in gr "Instruments tested: " _c
					Disp `e(redlist)', _col(23)
			}
di in smcl in gr "{hline 78}"
		}
* Report Cragg-Donald statistic
		if "`e(instd)'"~="" & "`e(idstat)'"~="" {
di in smcl _c "{help `helpfile'##widtest:Weak identification test}"
di in gr " (Cragg-Donald Wald F statistic):" in ye _col(71) %8.3f e(cdf)
			if "`e(vcetype)'`e(kernel)'"~="" {
di in gr "                         (Kleibergen-Paap rk Wald F statistic):" in ye _col(71) %8.3f e(widstat)
			}
di in gr _c "Stock-Yogo weak ID test critical values:"
			local cdmissing=1
			if "`e(model)'"=="iv" | "`e(model)'"=="gmm2s" | "`e(model)'"=="gmmw" {
				cdsy, type(ivbias5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(43) "5% maximal IV relative bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "10% maximal IV relative bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "20% maximal IV relative bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "30% maximal IV relative bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "10% maximal IV size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize15) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "15% maximal IV size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "20% maximal IV size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize25) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "25% maximal IV size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
			}
			else if ("`e(model)'"=="liml" & e(fuller)==.) | "`e(model)'"=="cue" {
				cdsy, type(limlsize10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "10% maximal LIML size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize15) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "15% maximal LIML size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "20% maximal LIML size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize25) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "25% maximal LIML size" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
			}
			else if ("`e(model)'"=="liml" & e(fuller)<.) {
				cdsy, type(fullrel5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(43) "5% maximal Fuller rel. bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "10% maximal Fuller rel. bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "20% maximal Fuller rel. bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "30% maximal Fuller rel. bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(43) "5% Fuller maximum bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "10% Fuller maximum bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "20% Fuller maximum bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(42) "30% Fuller maximum bias" in ye _col(73) %6.2f r(cv)
					local cdmissing=0
				}
				di in gr "NB: Critical values based on Fuller parameter=1"
			}
			if `cdmissing' {
				di in gr _col(64) "<not available>"
			}
			else {
				di in gr "Source: Stock-Yogo (2005).  Reproduced by permission."
				if "`e(vcetype)'`e(kernel)'"~="" {
di in gr "NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors."
				}
			}
			di in smcl in gr "{hline 78}"
		}

* Report either (a) Sargan-Hansen-C stats, or (b) robust covariance matrix problem
* e(model)="gmmw" means user-supplied weighting matrix and Hansen J using 2nd-step resids reported
		if `rprob' == 0 {
* Display overid statistic
			if "`e(vcetype)'" == "Robust" | "`e(model)'" == "gmmw" {
				if "`e(instd)'" != "" {
di in smcl _c "{help `helpfile'##overidtests:Hansen J statistic}"
di in gr _c " (overidentification test of all instruments):"
				}
				else {
di in smcl _c "{help `helpfile'##overidtests:Hansen J statistic}"
di in gr _c " (Lagrange multiplier test of excluded instruments):"
				}
			}
			else {
				if "`e(instd)'" != "" {
di in smcl _c "{help `helpfile'##overidtests:Sargan statistic}"
di in gr _c " (overidentification test of all instruments):"
				}
				else {
di in smcl _c "{help `helpfile'##overidtests:Sargan statistic}"
di in gr _c " (Lagrange multiplier test of excluded instruments):"
				}
			}
di in ye _col(71) %8.3f e(j)
			if e(rankxx) < e(rankzz) {
di in gr _col(52) "Chi-sq(" in ye e(jdf) /* 
	       			*/  in gr ") P-val =  " in ye _col(73) %6.4f e(jp)
			}
			else {
di in gr _col(50) "(equation exactly identified)"
			}

* Display orthog option: C statistic (difference of Sargan statistics)
			if e(cstat) != . {
* If C-stat = 0 then warn, otherwise output
				if e(cstat) > 0  {
di in gr "-orthog- option:"
					if "`e(vcetype)'" == "Robust" {
di in gr _c "Hansen J statistic (eqn. excluding suspect orthog. conditions): "
					}
					else {
di in gr _c "Sargan statistic (eqn. excluding suspect orthogonality conditions):"
					}
di in ye _col(71) %8.3f e(j)-e(cstat)
di in gr _col(52) "Chi-sq(" in ye e(jdf)-e(cstatdf) in gr ") P-val =  " /*
				*/ in ye _col(73) %6.4f chiprob(e(jdf)-e(cstatdf),e(j)-e(cstat))
di in smcl _c "{help `helpfile'##ctest:C statistic}"
di in gr _c " (exogeneity/orthogonality of suspect instruments): "
di in ye _col(71) %8.3f e(cstat)
di in gr _col(52) "Chi-sq(" in ye e(cstatdf) in gr ") P-val =  " /*
				*/ in ye _col(73) %6.4f e(cstatp)
di in gr "Instruments tested:  " _c
					Disp `e(clist)', _col(23)
				}
				if e(cstat) == 0 {
di in gr _n "Collinearity/identification problems in eqn. excl. suspect orthog. conditions:"
di in gr "  C statistic not calculated for -orthog- option"
				}
			}
		}
		else {
* Problem exists with robust VCV - notify and list possible causes
di in r "Warning: estimated covariance matrix of moment conditions not of full rank."
			if e(rankxx) < e(rankzz) {
di in r "         overidentification statistic not reported, and"
			}
di in r "         standard errors and model tests should be interpreted with caution."
di in r "Possible causes:"
			if "`e(N_clust)'" != "" {
di in r "         number of clusters insufficient to calculate robust covariance matrix"
			}
			if "`e(kernel)'" != "" {
di in r "         covariance matrix of moment conditions not positive definite"
di in r "         covariance matrix uses too many lags"
			}
di in r "         singleton dummy variable (dummy with one 1 and N-1 0s or vice versa)"
di in r in smcl _c "{help `helpfile'##partial:partial}"
di in r " option may address problem."
		}

* Display endog option: endogeneity test statistic
		if e(estat) != . {
* If stat = 0 then warn, otherwise output
			if e(estat) > 0  {
di in gr "-endog- option:"
di in smcl _c "{help `helpfile'##endogtest:Endogeneity test}"
di in gr _c " of endogenous regressors: "
di in ye _col(71) %8.3f e(estat)
di in gr _col(52) "Chi-sq(" in ye e(estatdf) /* 
       			*/  in gr ") P-val =  " in ye _col(73) %6.4f e(estatp)
di in gr "Regressors tested:  " _c
				Disp `e(elist)', _col(23)
			}
			if e(estat) == 0 {
di in gr _n "Collinearity/identification problems in restricted equation:"
di in gr "  Endogeneity test statistic not calculated for -endog- option"
			}
		}

		di in smcl in gr "{hline 78}"
* Display AR overid statistic if LIML and not robust
		if "`e(model)'" == "liml" & "`e(vcetype)'" ~= "Robust" & "`e(kernel)'" == "" {
			if "`e(instd)'" != "" {
di in smcl _c "{help `helpfile'##liml:Anderson-Rubin statistic}"
di in gr _c " (overidentification test of all instruments):"
				}
				else {
di in smcl _c "{help `helpfile'##liml:Anderson-Rubin statistic}"
di in gr _c " (LR test of excluded instruments):"
				}
di in ye _col(72) %7.3f e(arubin)
			if e(rankxx) < e(rankzz) {
di in gr _col(52) "Chi-sq(" in ye e(arubindf) /* 
	       			*/  in gr ") P-val =  " in ye _col(73) %6.4f e(arubinp)
			}
			else {
di in gr _col(50) "(equation exactly identified)"
			}
			di in smcl in gr "{hline 78}"
		}
	}

* Display 2nd footer with variable lists
	if "`nofooter'"=="" {

* Warn about dropped instruments if any
* (Re-)calculate number of user-supplied instruments
		local iv1_ct : word count `e(insts)'
		local iv1_ct = `iv1_ct' + `e(cons)'

		if `iv1_ct' > e(rankzz) {
di in gr "Collinearities detected among instruments: " _c
di in gr `iv1_ct'-e(rankzz) " instrument(s) dropped"
		}

		if "`e(collin)'`e(dups)'" != "" | `e(partial_ct)'>0 {
* If collinearities, duplicates or partial, abbreviated varlists saved with a 1 at the end
			local one "1"
		}
		if "`e(instd)'" != "" {
			di in gr "Instrumented:" _c
			Disp `e(instd`one')', _col(23)
		}
		if "`e(inexog)'" != "" {
			di in gr "Included instruments:" _c
			Disp `e(inexog`one')', _col(23)
		}
		if "`e(exexog)'" != "" {
			di in gr "Excluded instruments:" _c
			Disp `e(exexog`one')', _col(23)
		}
		if `e(partial_ct)' > 0 {
			if e(partialcons) {
				local partial "`e(partial`one')' _cons"
			}
			else {
				local partial "`e(partial`one')'"
			}
di in smcl _c "{help `helpfile'##partial:Partialled-out}"
			di in gr ":" _c
			Disp `partial', _col(23)
			if "`e(partialsmall)'"=="" {
di in gr _col(23) "nb: small-sample adjustments do not account for"
di in gr _col(23) "    partialled-out variables"
			}
			else {
di in gr _col(23) "nb: small-sample adjustments account for"
di in gr _col(23) "    partialled-out variables"
			}
		}
		if "`e(dups)'" != "" {
			di in gr "Duplicates:" _c
			Disp `e(dups)', _col(23)
		}
		if "`e(collin)'" != "" {
			di in gr "Dropped collinear:" _c
			Disp `e(collin)', _col(23)
		}
		if "`e(ecollin)'" != "" {
			di in gr "Reclassified as exog:" _c
			Disp `e(ecollin)', _col(23)
		}
		di in smcl in gr "{hline 78}"
	}
end

**************************************************************************************

program define DispRF
	version 8.2
	local eqname "`e(rfeq)'"
	local depvar "`e(depvar)'"
	local strlen : length local depvar
	local strlen = `strlen'+25
di
di in gr "Reduced-form regression: `e(depvar)'"
di in smcl in gr "{hline `strlen'}"
	capture estimates replay `eqname'
	if "`eqname'"=="" | _rc != 0 {
di in ye "Unable to display reduced-form regression of `e(depvar)'."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
	}
	else {
		estimates replay `eqname', noheader
di
	}
end

program define DispFirst
	version 8.2
	args helpfile
	tempname firstmat ivest sheapr2 pr2 F df df_r pvalue APF APFdf1 APFdf2 APFp APr2

	mat `firstmat'=e(first)
	if `firstmat'[1,1] == . {
di
di in ye "Unable to display first-stage estimates; macro e(first) is missing"
		exit
	}
di in gr _newline "First-stage regressions"
di in smcl in gr "{hline 23}"
di
	local endo1 : colnames(`firstmat')
	local nrvars : word count `endo1'
	local firsteqs "`e(firsteqs)'"
	local nreqs : word count `firsteqs'
	if `nreqs' < `nrvars' {
di in ye "Unable to display all first-stage regressions."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
	}
	local robust "`e(vcetype)'"
	local cluster "`e(clustvar)'"
	local kernel "`e(kernel)'"
	foreach eqname of local firsteqs {
		_estimates hold `ivest'
		capture estimates restore `eqname'
		if _rc != 0 {
di
di in ye "Unable to list stored estimation `eqname'."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
		}
		else {
			local vn "`e(depvar)'"
di in gr "First-stage regression of `vn':"
			estimates replay `eqname', noheader
			mat `sheapr2' =`firstmat'["sheapr2","`vn'"]
			mat `pr2'     =`firstmat'["pr2","`vn'"]
			mat `F'       =`firstmat'["F","`vn'"]
			mat `df'      =`firstmat'["df","`vn'"]
			mat `df_r'    =`firstmat'["df_r","`vn'"]
			mat `pvalue'  =`firstmat'["pvalue","`vn'"]
			mat `APF'     =`firstmat'["APF","`vn'"]
			mat `APFdf1'  =`firstmat'["APFdf1","`vn'"]
			mat `APFdf2'  =`firstmat'["APFdf2","`vn'"]
			mat `APFp'    =`firstmat'["APFp","`vn'"]
			mat `APr2'    =`firstmat'["APr2","`vn'"]

di in gr "F test of excluded instruments:"
di in gr "  F(" %3.0f `df'[1,1] "," %6.0f `df_r'[1,1] ") = " in ye %8.2f `F'[1,1]
di in gr "  Prob > F      = " in ye %8.4f `pvalue'[1,1]

di in smcl "{help `helpfile'##apstats:Angrist-Pischke multivariate F test of excluded instruments:}"
di in gr "  F(" %3.0f `APFdf1'[1,1] "," %6.0f `APFdf2'[1,1] ") = " in ye %8.2f `APF'[1,1]
di in gr "  Prob > F      = " in ye %8.4f `APFp'[1,1]

di
		}
		_estimates unhold `ivest'
	}
end

program define DispStored
	args saverf savefirst helpfile
	version 8.2
	if "`saverf'" != "" {
		local eqlist "`e(rfeq)'"
	}
	if "`savefirst'" != "" {
		local eqlist "`eqlist' `e(firsteqs)'"
	}
	local eqlist : list retokenize eqlist
di in gr _newline "Stored estimation results"
di in smcl in gr "{hline 25}" _c
	capture estimates dir `eqlist'
	if "`eqlist'" != "" & _rc == 0 {
* Estimates exist and can be listed
		estimates dir `eqlist'
	}
	else if "`eqlist'" != "" & _rc != 0 {
di
di in ye "Unable to list stored estimations."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
	}
end

program define DispFFirst
	version 8.2
	args helpfile
	tempname firstmat
	tempname sheapr2 pr2 F df df_r pvalue APF APFdf1 APFdf2 APFp APchi2 APchi2p APr2
	mat `firstmat'=e(first)
	if `firstmat'[1,1] == . {
di
di in ye "Unable to display summary of first-stage estimates; macro e(first) is missing"
		exit
	}
	local endo   : colnames(`firstmat')
	local nrvars : word count `endo'
	local robust   "`e(vcetype)'"
	local cluster  "`e(clustvar)'"
	local kernel   "`e(kernel)'"
	local efirsteqs  "`e(firsteqs)'"

	mat `df'      =`firstmat'["df",1]
	mat `df_r'    =`firstmat'["df_r",1]
	mat `APFdf1'  =`firstmat'["APFdf1",1]
	mat `APFdf2'  =`firstmat'["APFdf2",1]

di
di in gr _newline "Summary results for first-stage regressions"
di in smcl in gr "{hline 43}"
di

di _c in smcl _col(44) "{help `helpfile'##apstats:(Underid)}"
di    in smcl _col(65) "{help `helpfile'##apstats:(Weak id)}"

di _c in gr "Variable     |"
di _c in smcl _col(16) "{help `helpfile'##apstats:F}" in gr "("
di _c in ye _col(17) %3.0f `df'[1,1] in gr "," in ye %6.0f `df_r'[1,1] in gr ")  P-val"
di _c in gr _col(37) "|"
di _c in smcl _col(39) "{help `helpfile'##apstats:AP Chi-sq}" in gr "("
di _c in ye %3.0f `APFdf1'[1,1] in gr ") P-val"
di _c in gr _col(60) "|"
di _c in smcl _col(62) "{help `helpfile'##apstats:AP F}" in gr "("
di    in ye _col(67) %3.0f `APFdf1'[1,1] in gr "," in ye %6.0f `APFdf2'[1,1] in gr ")"

	local i = 1
	foreach vn of local endo {
	
		mat `sheapr2' =`firstmat'["sheapr2","`vn'"]
		mat `pr2'     =`firstmat'["pr2","`vn'"]
		mat `F'       =`firstmat'["F","`vn'"]
		mat `df'      =`firstmat'["df","`vn'"]
		mat `df_r'    =`firstmat'["df_r","`vn'"]
		mat `pvalue'  =`firstmat'["pvalue","`vn'"]
		mat `APF'     =`firstmat'["APF","`vn'"]
		mat `APFdf1'  =`firstmat'["APFdf1","`vn'"]
		mat `APFdf2'  =`firstmat'["APFdf2","`vn'"]
		mat `APFp'    =`firstmat'["APFp","`vn'"]
		mat `APchi2'  =`firstmat'["APchi2","`vn'"]
		mat `APchi2p' =`firstmat'["APchi2p","`vn'"]
		mat `APr2'    =`firstmat'["APr2","`vn'"]

		local vnlen : length local vn
		if `vnlen' > 12 {
			local vn : piece 1 12 of "`vn'"
		}
di _c in y %-12s "`vn'" _col(14) in gr "|" _col(18) in y %8.2f `F'[1,1]
di _c _col(28) in y %8.4f  `pvalue'[1,1]
di _c _col(37) in g "|" _col(42) in y %8.2f `APchi2'[1,1] _col(51) in y %8.4f  `APchi2p'[1,1]
di    _col(60) in g "|" _col(65) in y %8.2f `APF'[1,1] 
		local i = `i' + 1
	}
di

	if "`robust'`cluster'" != "" {
		if "`cluster'" != "" {
			local rtype "cluster-robust"
		}
		else if "`kernel'" != "" {
			local rtype "heteroskedasticity and autocorrelation-robust"
		}
		else {
			local rtype "heteroskedasticity-robust"
		}
	}
	else if "`kernel'" != "" {
			local rtype "autocorrelation-robust"
	}
	if "`robust'`cluster'`kernel'" != "" {
di in gr "NB: first-stage test statistics `rtype'"
di
	}

	local k2 = `APFdf1'[1,1]
di in gr "Stock-Yogo weak ID test critical values for single endogenous regressor:"
	local cdmissing=1
	if "`e(model)'"=="iv" | "`e(model)'"=="gmm2s" | "`e(model)'"=="gmmw" {
		cdsy, type(ivbias5) k2(`e(exexog_ct)') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(37) "5% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivbias10) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "10% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivbias20) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "20% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivbias30) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "30% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivsize10) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "10% maximal IV size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivsize15) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "15% maximal IV size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivsize20) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "20% maximal IV size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(ivsize25) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "25% maximal IV size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
	}
	else if ("`e(model)'"=="liml" & e(fuller)==.) | "`e(model)'"=="cue" {
		cdsy, type(limlsize10) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "10% maximal LIML size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(limlsize15) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "15% maximal LIML size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(limlsize20) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "20% maximal LIML size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(limlsize25) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "25% maximal LIML size" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
	}
	else if ("`e(model)'"=="liml" & e(fuller)<.) {
		cdsy, type(fullrel5) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(43) "5% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullrel10) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "10% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullrel20) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "20% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullrel30) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "30% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullmax5) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(43) "5% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullmax10) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "10% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullmax20) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "20% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		cdsy, type(fullmax30) k2(`k2') nendog(1)
		if "`r(cv)'"~="." {
			di in gr _col(36) "30% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
			local cdmissing=0
		}
		di in gr "NB: Critical values based on Fuller parameter=1"
	}
	di in gr "Source: Stock-Yogo (2005).  Reproduced by permission."
	if "`e(vcetype)'`e(kernel)'"~="" {
di in gr "NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors."
di
	}
	else {
di
	}

* Check that AP chi-sq and F denominator are correct and = underid test dof
	if e(iddf)~=`APFdf1'[1,1] {
di in red "Warning: Error in calculating first-stage id statistics above;"
di in red "         dof of AP statistics is " `APFdf1'[1,1] ", should be L-(K-1)=`e(iddf)'."
	}

	tempname iddf idstat idp widstat cdf rkf
	scalar `iddf'=e(iddf)
	scalar `idstat'=e(idstat)
	scalar `idp'=e(idp)
	scalar `widstat'=e(widstat)
	scalar `cdf'=e(cdf)
	capture scalar `rkf'=e(rkf)
di in smcl "{help `helpfile'##idtest:Underidentification test}"
di in gr "Ho: matrix of reduced form coefficients has rank=K1-1 (underidentified)"
di in gr "Ha: matrix has rank=K1 (identified)"
	if "`robust'`kernel'"=="" {
di in ye "Anderson canon. corr. LM statistic" _c
	}
	else {
di in ye "Kleibergen-Paap rk LM statistic" _c
	}
di in gr _col(42) "Chi-sq(" in ye `iddf' in gr ")=" %-7.2f in ye `idstat' /*
	*/ _col(61) in gr "P-val=" %6.4f in ye `idp'

di
di in smcl "{help `helpfile'##widtest:Weak identification test}"
di in gr "Ho: equation is weakly identified"
di in ye "Cragg-Donald Wald F statistic" _col(65) %8.2f `cdf'
	if "`robust'`kernel'"~="" {
di in ye "Kleibergen-Paap Wald rk F statistic"  _col(65) %8.2f `rkf'
	}
di

di in gr "Stock-Yogo weak ID test critical values for K1=`e(endog_ct)' and L1=`e(exexog_ct)':"
			local cdmissing=1
			if "`e(model)'"=="iv" | "`e(model)'"=="gmm2s" | "`e(model)'"=="gmmw" {
				cdsy, type(ivbias5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(37) "5% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "10% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "20% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivbias30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "30% maximal IV relative bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "10% maximal IV size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize15) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "15% maximal IV size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "20% maximal IV size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(ivsize25) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "25% maximal IV size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
			}
			else if ("`e(model)'"=="liml" & e(fuller)==.) | "`e(model)'"=="cue" {
				cdsy, type(limlsize10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "10% maximal LIML size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize15) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "15% maximal LIML size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "20% maximal LIML size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(limlsize25) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "25% maximal LIML size" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
			}
			else if ("`e(model)'"=="liml" & e(fuller)<.) {
				cdsy, type(fullrel5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(43) "5% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "10% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "20% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullrel30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "30% maximal Fuller rel. bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax5) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(43) "5% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax10) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "10% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax20) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "20% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				cdsy, type(fullmax30) k2(`e(exexog_ct)') nendog(`e(endog_ct)')
				if "`r(cv)'"~="." {
					di in gr _col(36) "30% Fuller maximum bias" in ye _col(67) %6.2f r(cv)
					local cdmissing=0
				}
				di in gr "NB: Critical values based on Fuller parameter=1"
			}
			if `cdmissing' {
				di in gr _col(64) "<not available>"
			}
			else {
				di in gr "Source: Stock-Yogo (2005).  Reproduced by permission."
				if "`e(vcetype)'`e(kernel)'"~="" {
di in gr "NB: Critical values are for Cragg-Donald F statistic and i.i.d. errors."
				}
				di
			}

	tempname arf arfp archi2 archi2p ardf ardf_r
	tempname sstat sstatp sstatdf
di in smcl "{help `helpfile'##wirobust:Weak-instrument-robust inference}"
di in gr "Tests of joint significance of endogenous regressors B1 in main equation"
di in gr "Ho: B1=0 and orthogonality conditions are valid"
* Needs to be small so that adjusted dof is reflected in F stat
	scalar `arf'=e(arf)
	scalar `arfp'=e(arfp)
	scalar `archi2'=e(archi2)
	scalar `archi2p'=e(archi2p)
	scalar `ardf'=e(ardf)
	scalar `ardf_r'=e(ardf_r)
	scalar `sstat'=e(sstat)
	scalar `sstatp'=e(sstatp)
	scalar `sstatdf'=e(sstatdf)
di in ye _c "Anderson-Rubin Wald test"
di in gr _col(36) "F(" in ye `ardf' in gr "," in ye `ardf_r' in gr ")=" /*
		*/	_col(49) in ye %7.2f `arf'    _col(61) in gr "P-val=" in ye %6.4f `arfp'
di in ye _c "Anderson-Rubin Wald test"
di in gr _col(36) "Chi-sq(" in ye `ardf' in gr ")=" /*
		*/	_col(49) in ye %7.2f `archi2' _col(61) in gr "P-val=" in ye %6.4f `archi2p'
di in ye _c "Stock-Wright LM S statistic"
di in gr _col(36) "Chi-sq(" in ye `sstatdf' in gr ")=" /*
		*/	_col(49) in ye %7.2f `sstat' _col(61) in gr "P-val=" in ye %6.4f `sstatp'
di
	if "`robust'`cluster'`kernel'" != "" {
di in gr "NB: Underidentification, weak identification and weak-identification-robust"
di in gr "    test statistics `rtype'"
di
	}

	if "`cluster'" != "" {
di in gr "Number of clusters             N_clust  = " in ye %10.0f e(N_clust)
	}
di in gr "Number of observations               N  = " in ye %10.0f e(N)
di in gr "Number of regressors                 K  = " in ye %10.0f e(rankxx)
di in gr "Number of endogenous regressors      K1 = " in ye %10.0f e(endog_ct)
di in gr "Number of instruments                L  = " in ye %10.0f e(rankzz)
di in gr "Number of excluded instruments       L1 = " in ye %10.0f e(ardf)
	if "`e(partial)'" != "" {
di in gr "Number of partialled-out regressors/IVs = " in ye %10.0f e(partial_ct)
di in gr "NB: K & L do not included partialled-out variables"
	}

end

* Performs first-stage regressions

program define doFirst, rclass
	version 8.2
	args    endog		/*  variable list  (including depvar)
		*/  inexog		/*  list of included exogenous
		*/  exexog		/*  list of excluded exogenous
		*/  XXinv		/*
		*/	XPZXinv		/*
		*/  touse		/*  touse sample
		*/  weight		/*  full weight expression w/ []
		*/  nocons		/*
		*/  robust		/*
		*/  clopt		/*
		*/  bwopt		/*
		*/  kernopt		/*
		*/  savefprefix /*
		*/  dofmopt		/*
		*/  sdofmopt	/*
		*/  ivreg2_cmd

* Create fitted values of endogenous regressors
	local endog_hat ""
	tsrevar `endog'
	local ts_endog "`r(varlist)'"
	foreach x of local ts_endog {
		qui regress `x' `inexog' `exexog' `weight' if `touse', `nocons'
		tempname `x'_hat
		qui predict double ``x'_hat', xb
		local endog_hat "`endog_hat' ``x'_hat'"
	}
* inexog and exexog are used with partial() option so must tsrevar them
	tsrevar `inexog'
	local ts_inexog "`r(varlist)'"
	tsrevar `exexog'
	local ts_exexog "`r(varlist)'"

	tempname statmat statmat1
	local i 1
	foreach x of local endog {
		capture `ivreg2_cmd' `x' `inexog' `exexog' `weight' /*
				*/ if `touse', `nocons' `robust' `clopt' `bwopt' `kernopt' /*
				*/ `dofmopt' `sdofmopt' small nocollin
		if _rc ~= 0 {
* First-stage regression failed
di in ye "Unable to estimate first-stage regression of `x'"
			if _rc == 506 {
di in ye "  var-cov matrix of first-stage regression of `x' not positive-definite"
			}
		}
		else {
* First-stage regression successful
* Check if there is enough room to save results; leave one free.  Allow for overwriting.
* Max is 20-1=19 for Stata 9.0 and earlier, 300-1=299 for Stata 9.1+
			local maxest=299
			local vn "`x'"
			local plen : length local savefprefix
			local vlen : length local vn
			if `plen'+`vlen' > 27 {
				local vlen=27-`plen'
				local vn : permname `vn', length(`vlen')
* Must create a variable so that permname doesn't reuse it
				gen `vn'=0
				local dropvn "`dropvn' `vn'"
			}
			local eqname "`savefprefix'`vn'"
			local eqname : subinstr local eqname "." "_"
			qui estimates dir
			local est_list  "`r(names)'"
			Subtract est_list : "`est_list'" "`eqname'"
			local est_ct : word count `est_list'
			if `est_ct' < `maxest' {
				capture est store `eqname', title("First-stage regression: `x'")
				if _rc == 0 {
					local firsteqs "`firsteqs' `eqname'"
				}
			}
			else {
di
di in ye "Unable to store first-stage regression of `x'."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
			}
			tempname rssall rssinc pr2 F p
			scalar `rssall'=e(rss)
			quietly test `exexog'
			scalar `F'=r(F)
			scalar `p'=r(p)
			local df=r(df)
			local df_r=r(df_r)
* 1st stage regression without excluded exogenous
* Use regress since need only RSS and handles all cases, including perverse ones (e.g. no regressors)
			qui regress `x' `inexog' `weight' if `touse', `nocons'
			scalar `rssinc'=e(rss)
* NB: uncentered R2 for main regression is 1-rssall/yy; for restricted is 1-rssinc/yy;
*     squared semipartial correlation=(rssinc-rssall)/yy=diff of 2 R2s
* Squared partial correlation (="partialled-out R2")
			scalar `pr2'=(`rssinc'-`rssall')/`rssinc'

* A-P multivariate F and corresponding r-sq
			tempname APF APFdf1 APFdf2 APFp APchi2 APchi2p APr2
			local x_hat "`endog_hat'"
			tokenize `endog_hat'
			Subtract x_hat : "`x_hat'" "``i''"
			tokenize `ts_endog'
			local ts_x "``i''"
			qui `ivreg2_cmd' `ts_x' `x_hat' `ts_inexog' `ts_exexog' `weight' /*
				*/ if `touse', `nocons' `robust' `clopt' `bwopt' `kernopt' /*
				*/ `dofmopt' `sdofmopt' small nocollin partial(`x_hat' `ts_inexog')
			scalar `APF'    = e(F)
			scalar `APFdf1' = e(Fdf1)
			scalar `APFdf2' = e(Fdf2)
			scalar `APFp'   = e(Fp)
			if "`clopt'"=="" {
				scalar `APchi2' = e(F)*e(Fdf1)/e(Fdf2)*(e(N)-e(dofminus))
			}
			else {
				scalar `APchi2' = e(F)*e(Fdf1)/e(Fdf2)*e(N_clust)/(e(N)-e(rankxx)-e(sdofminus))*(e(N)-1)
			}
			scalar `APchi2p'= chi2tail(e(Fdf1),`APchi2')
			scalar `APr2'   = e(r2)

* End of first-stage successful block
		}

* Godfrey method of Shea partial R2 uses IV and OLS estimates without robust vcvs:
* Partial R2 = OLS V[d,d] / IV V[d,d] * IV s2 / OLS s2
* where d,d is the diagonal element corresponding to the endog regressor
* ... but this simplifies to matrices that have already been calculated:
*            = XXinv[d,d] / XPZXinv[d,d]
		tempname sols siv
		tempname sheapr2
		mat `sols'=`XXinv'["`x'","`x'"]
		mat `siv'=`XPZXinv'["`x'","`x'"]
		scalar `sheapr2' = `sols'[1,1]/`siv'[1,1]

		capture {
			mat `statmat1' = (`sheapr2' \ `pr2' \ `F' \ `df' \ `df_r' \ `p' /*
				*/	\ `APF' \ `APFdf1' \ `APFdf2' \ `APFp' \ `APchi2' \ `APchi2p' \ `APr2')
			mat colname `statmat1' = `x'
			mat `statmat' = nullmat(`statmat') , `statmat1'
		}
		local i = `i' + 1
	}
* Drop any temporarily-created permname variables
	if trim("`dropvn'")~="" {
		foreach vn of varlist `dropvn' {
			capture drop `vn'
		}
	}
	capture mat rowname `statmat' = sheapr2 pr2 F df df_r pvalue APF APFdf1 APFdf2 APFp APchi2 APchi2p APr2
	if _rc==0 {
		return matrix firstmat `statmat'
	}
	return local firsteqs "`firsteqs'"
end

program define doRF, rclass
	version 8.2
	args    lhs		/*
		*/  inexog	/*  list of included exogenous
		*/  exexog	/*  list of excluded exogenous
		*/  touse	/*  touse sample
		*/  weight	/*  full weight expression w/ []
		*/  nocons	/*
		*/  robust	/*
		*/  clopt	/*
		*/  bwopt	/*
		*/  kernopt	/*
		*/  saverfprefix /*
		*/  dofminus	/*
		*/  sdofminus	/*
		*/  ivreg2_cmd

* Anderson-Rubin test of signif of endog regressors (Bo=0)
* In case ivreg2 called with adjusted dof, first stage should adjust dof as well
	tempname arf arfp archi2 archi2p ardf ardf_r tempest
	capture _estimates hold `tempest'
	if _rc==1000 {
di as err "ivreg2 internal error - no room to save temporary estimation results"
di as err "Please drop one or more estimation results using -estimates drop-"
		exit 1000
	}
* Needs to be small so that adjusted dof is reflected in F stat
* capture to prevent not-full-rank error warning
	capture	`ivreg2_cmd' `lhs' `inexog' `exexog' `weight' if `touse', /*
		*/	small `nocons' dofminus(`dofminus') sdofminus(`sdofminus') /*
		*/	`robust' `clopt' `bwopt' `kernopt' nocollin
	if _rc != 0 {
di as err "Error: reduced form estimation failed"
		exit 498
	}
	qui test `exexog'
	scalar `arf'=r(F)
	scalar `arfp'=r(p)
	scalar `ardf'=r(df)
	scalar `ardf_r'=r(df_r)
	if "`clopt'"=="" {
		scalar `archi2'=`arf'*`ardf'*(e(N)-`dofminus')/(e(N)-e(rankxx)-`dofminus'-`sdofminus')
	}
	else {
		scalar `archi2'=`arf'*`ardf'*e(N_clust)/r(df_r)*(e(N)-1)/(e(N)-e(rankxx)-`sdofminus')
	}
	scalar `archi2p'=chiprob(`ardf',`archi2')

* Check if there is enough room to save results; leave one free.  Allow for overwriting.
* Max is 20-1=19 for Stata 9.0 and earlier, 300-1=299 for Stata 9.1+
	local maxest=299
	local vn "`lhs'"
	local plen : length local saverfprefix
	local vlen : length local lhs
	if `plen'+`vlen' > 27 {
		local vlen=27-`plen'
		local vn : permname `vn', length(`vlen')
	}
	local eqname "`saverfprefix'`vn'"
	local eqname : subinstr local eqname "." "_"
	qui estimates dir
	local est_list  "`r(names)'"
	Subtract est_list : "`est_list'" "`eqname'"
	local est_ct : word count `est_list'
	if `est_ct' < `maxest' {
		capture est store `eqname', title("Reduced-form regression: `lhs'")
		return local rfeq "`eqname'"
	}
	else {
di
di in ye "Unable to store reduced-form regression of `lhs'."
di in ye "There may be insufficient room to store results using -estimates store-."
di in ye "Try dropping one or more estimation results using -estimates drop-."
di
	}
	_estimates unhold `tempest'
	return scalar arf=`arf'
	return scalar arfp=`arfp'
	return scalar ardf=`ardf'
	return scalar ardf_r=`ardf_r'
	return scalar archi2=`archi2'
	return scalar archi2p=`archi2p'
end

**************************************************************************************
program define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	version 8.2
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else	sret local stop 0
end

program define Disp 
	version 8.2
	syntax [anything] [, _col(integer 15) ]
	local len = 80-`_col'+1
	local piece : piece 1 `len' of `"`anything'"'
	local i 1
	while "`piece'" != "" {
		di in gr _col(`_col') "`first'`piece'"
		local i = `i' + 1
		local piece : piece `i' `len' of `"`anything'"'
	}
	if `i'==1 { 
		di 
	}
end



*  Remove all tokens in dirt from full
*  Returns "cleaned" full list in cleaned

program define Subtract		/* <cleaned> : <full> <dirt> */
	version 8.2
	args	    cleaned     /*  macro name to hold cleaned list
			*/  colon		/*  ":"
			*/  full		/*  list to be cleaned 
			*/  dirt		/*  tokens to be cleaned from full */
	
	tokenize `dirt'
	local i 1
	while "``i''" != "" {
		local full : subinstr local full "``i''" "", word all
		local i = `i' + 1
	}

	tokenize `full'			/* cleans up extra spaces */
	c_local `cleaned' `*'       
end

program define vecsort		/* Also clears col/row names */
	version 8.2
	args vmat
	tempname hold
	mat `vmat'=`vmat'+J(rowsof(`vmat'),colsof(`vmat'),0)
	local lastcol = colsof(`vmat')
	local i 1
	while `i' < `lastcol' {
		if `vmat'[1,`i'] > `vmat'[1,`i'+1] {
			scalar `hold' = `vmat'[1,`i']
			mat `vmat'[1,`i'] = `vmat'[1,`i'+1]
			mat `vmat'[1,`i'+1] = `hold'
			local i = 1
		}
		else {
			local i = `i' + 1
		}
	}
end

program define matsort
	version 8.2
	args vmat names
	tempname hold
	foreach vn in `names' {
		mat `hold'=nullmat(`hold'), `vmat'[1...,"`vn'"]
	}
	mat `vmat'=`hold'
	mat drop `hold'
	foreach vn in `names' {
		mat `hold'=nullmat(`hold') \ `vmat'["`vn'",1...]
	}
	mat `vmat'=`hold'
end

program define cdsy, rclass
	version 8.2
	syntax , type(string) k2(integer) nendog(integer)

* type() can be ivbias5   (k2<=100, nendog<=3)
*               ivbias10  (ditto)
*               ivbias20  (ditto)
*               ivbias30  (ditto)
*               ivsize10  (k2<=100, nendog<=2)
*               ivsize15  (ditto)
*               ivsize20  (ditto)
*               ivsize25  (ditto)
*               fullrel5  (ditto)
*               fullrel10 (ditto)
*               fullrel20 (ditto)
*               fullrel30 (ditto)
*               fullmax5  (ditto)
*               fullmax10 (ditto)
*               fullmax20 (ditto)
*               fullmax30 (ditto)
*               limlsize10 (ditto)
*               limlsize15 (ditto)
*               limlsize20 (ditto)
*               limlsize25 (ditto)

	tempname temp cv

* Initialize critical value as MV
	scalar `cv'=.

	if "`type'"=="ivbias5" {
		matrix input `temp' = (	/*
	*/	.	,	.	,	.	\ /*
	*/	.	,	.	,	.	\ /*
	*/	13.91	,	.	,	.	\ /*
	*/	16.85	,	11.04	,	.	\ /*
	*/	18.37	,	13.97	,	9.53	\ /*
	*/	19.28	,	15.72	,	12.20	\ /*
	*/	19.86	,	16.88	,	13.95	\ /*
	*/	20.25	,	17.70	,	15.18	\ /*
	*/	20.53	,	18.30	,	16.10	\ /*
	*/	20.74	,	18.76	,	16.80	\ /*
	*/	20.90	,	19.12	,	17.35	\ /*
	*/	21.01	,	19.40	,	17.80	\ /*
	*/	21.10	,	19.64	,	18.17	\ /*
	*/	21.18	,	19.83	,	18.47	\ /*
	*/	21.23	,	19.98	,	18.73	\ /*
	*/	21.28	,	20.12	,	18.94	\ /*
	*/	21.31	,	20.23	,	19.13	\ /*
	*/	21.34	,	20.33	,	19.29	\ /*
	*/	21.36	,	20.41	,	19.44	\ /*
	*/	21.38	,	20.48	,	19.56	\ /*
	*/	21.39	,	20.54	,	19.67	\ /*
	*/	21.40	,	20.60	,	19.77	\ /*
	*/	21.41	,	20.65	,	19.86	\ /*
	*/	21.41	,	20.69	,	19.94	\ /*
	*/	21.42	,	20.73	,	20.01	\ /*
	*/	21.42	,	20.76	,	20.07	\ /*
	*/	21.42	,	20.79	,	20.13	\ /*
	*/	21.42	,	20.82	,	20.18	\ /*
	*/	21.42	,	20.84	,	20.23	\ /*
	*/	21.42	,	20.86	,	20.27	\ /*
	*/	21.41	,	20.88	,	20.31	\ /*
	*/	21.41	,	20.90	,	20.35	\ /*
	*/	21.41	,	20.91	,	20.38	\ /*
	*/	21.40	,	20.93	,	20.41	\ /*
	*/	21.40	,	20.94	,	20.44	\ /*
	*/	21.39	,	20.95	,	20.47	\ /*
	*/	21.39	,	20.96	,	20.49	\ /*
	*/	21.38	,	20.97	,	20.51	\ /*
	*/	21.38	,	20.98	,	20.54	\ /*
	*/	21.37	,	20.99	,	20.56	\ /*
	*/	21.37	,	20.99	,	20.57	\ /*
	*/	21.36	,	21.00	,	20.59	\ /*
	*/	21.35	,	21.00	,	20.61	\ /*
	*/	21.35	,	21.01	,	20.62	\ /*
	*/	21.34	,	21.01	,	20.64	\ /*
	*/	21.34	,	21.02	,	20.65	\ /*
	*/	21.33	,	21.02	,	20.66	\ /*
	*/	21.32	,	21.02	,	20.67	\ /*
	*/	21.32	,	21.03	,	20.68	\ /*
	*/	21.31	,	21.03	,	20.69	\ /*
	*/	21.31	,	21.03	,	20.70	\ /*
	*/	21.30	,	21.03	,	20.71	\ /*
	*/	21.30	,	21.03	,	20.72	\ /*
	*/	21.29	,	21.03	,	20.73	\ /*
	*/	21.28	,	21.03	,	20.73	\ /*
	*/	21.28	,	21.04	,	20.74	\ /*
	*/	21.27	,	21.04	,	20.75	\ /*
	*/	21.27	,	21.04	,	20.75	\ /*
	*/	21.26	,	21.04	,	20.76	\ /*
	*/	21.26	,	21.04	,	20.76	\ /*
	*/	21.25	,	21.04	,	20.77	\ /*
	*/	21.24	,	21.04	,	20.77	\ /*
	*/	21.24	,	21.04	,	20.78	\ /*
	*/	21.23	,	21.04	,	20.78	\ /*
	*/	21.23	,	21.03	,	20.79	\ /*
	*/	21.22	,	21.03	,	20.79	\ /*
	*/	21.22	,	21.03	,	20.79	\ /*
	*/	21.21	,	21.03	,	20.80	\ /*
	*/	21.21	,	21.03	,	20.80	\ /*
	*/	21.20	,	21.03	,	20.80	\ /*
	*/	21.20	,	21.03	,	20.80	\ /*
	*/	21.19	,	21.03	,	20.81	\ /*
	*/	21.19	,	21.03	,	20.81	\ /*
	*/	21.18	,	21.03	,	20.81	\ /*
	*/	21.18	,	21.02	,	20.81	\ /*
	*/	21.17	,	21.02	,	20.82	\ /*
	*/	21.17	,	21.02	,	20.82	\ /*
	*/	21.16	,	21.02	,	20.82	\ /*
	*/	21.16	,	21.02	,	20.82	\ /*
	*/	21.15	,	21.02	,	20.82	\ /*
	*/	21.15	,	21.02	,	20.82	\ /*
	*/	21.15	,	21.02	,	20.83	\ /*
	*/	21.14	,	21.01	,	20.83	\ /*
	*/	21.14	,	21.01	,	20.83	\ /*
	*/	21.13	,	21.01	,	20.83	\ /*
	*/	21.13	,	21.01	,	20.83	\ /*
	*/	21.12	,	21.01	,	20.84	\ /*
	*/	21.12	,	21.01	,	20.84	\ /*
	*/	21.11	,	21.01	,	20.84	\ /*
	*/	21.11	,	21.01	,	20.84	\ /*
	*/	21.10	,	21.00	,	20.84	\ /*
	*/	21.10	,	21.00	,	20.84	\ /*
	*/	21.09	,	21.00	,	20.85	\ /*
	*/	21.09	,	21.00	,	20.85	\ /*
	*/	21.08	,	21.00	,	20.85	\ /*
	*/	21.08	,	21.00	,	20.85	\ /*
	*/	21.07	,	21.00	,	20.85	\ /*
	*/	21.07	,	20.99	,	20.86	\ /*
	*/	21.06	,	20.99	,	20.86	\ /*
	*/	21.06	,	20.99	,	20.86	)

		if `k2'<=100 & `nendog'<=3 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
 

 

 	if "`type'"=="ivbias10" {
		matrix input `temp' = 	/*
	*/	(.,.,.			\	/*
	*/	.,.,.			\	/*
	*/	9.08,.,.		\	/*
	*/	10.27,7.56,.		\	/*
	*/	10.83,8.78,6.61		\	/*
	*/	11.12,9.48,7.77		\	/*
	*/	11.29,9.92,8.5		\	/*
	*/	11.39,10.22,9.01	\	/*
	*/	11.46,10.43,9.37	\	/*
	*/	11.49,10.58,9.64	\	/*
	*/	11.51,10.69,9.85	\	/*
	*/	11.52,10.78,10.01	\	/*
	*/	11.52,10.84,10.14	\	/*
	*/	11.52,10.89,10.25	\	/*
	*/	11.51,10.93,10.33	\	/*
	*/	11.5,10.96,10.41	\	/*
	*/	11.49,10.99,10.47	\	/*
	*/	11.48,11,10.52		\	/*
	*/	11.46,11.02,10.56	\	/*
	*/	11.45,11.03,10.6	\	/*
	*/	11.44,11.04,10.63	\	/*
	*/	11.42,11.05,10.65	\	/*
	*/	11.41,11.05,10.68	\	/*
	*/	11.4,11.05,10.7		\	/*
	*/	11.38,11.06,10.71	\	/*
	*/	11.37,11.06,10.73	\	/*
	*/	11.36,11.06,10.74	\	/*
	*/	11.34,11.05,10.75	\	/*
	*/	11.33,11.05,10.76	\	/*
	*/	11.32,11.05,10.77	\	/*
	*/	11.3,11.05,10.78	\	/*
	*/	11.29,11.05,10.79	\	/*
	*/	11.28,11.04,10.79	\	/*
	*/	11.27,11.04,10.8	\	/*
	*/	11.26,11.04,10.8	\	/*
	*/	11.25,11.03,10.8	\	/*
	*/	11.24,11.03,10.81	\	/*
	*/	11.23,11.02,10.81	\	/*
	*/	11.22,11.02,10.81	\	/*
	*/	11.21,11.02,10.81	\	/*
	*/	11.2,11.01,10.81	\	/*
	*/	11.19,11.01,10.81	\	/*
	*/	11.18,11,10.81		\	/*
	*/	11.17,11,10.81		\	/*
	*/	11.16,10.99,10.81	\	/*
	*/	11.15,10.99,10.81	\	/*
	*/	11.14,10.98,10.81	\	/*
	*/	11.13,10.98,10.81	\	/*
	*/	11.13,10.98,10.81	\	/*
	*/	11.12,10.97,10.81	\	/*
	*/	11.11,10.97,10.81	\	/*
	*/	11.1,10.96,10.81	\	/*
	*/	11.1,10.96,10.81	\	/*
	*/	11.09,10.95,10.81	\	/*
	*/	11.08,10.95,10.81	\	/*
	*/	11.07,10.94,10.8	\	/*
	*/	11.07,10.94,10.8	\	/*
	*/	11.06,10.94,10.8	\	/*
	*/	11.05,10.93,10.8	\	/*
	*/	11.05,10.93,10.8	\	/*
	*/	11.04,10.92,10.8	\	/*
	*/	11.03,10.92,10.79	\	/*
	*/	11.03,10.92,10.79	\	/*
	*/	11.02,10.91,10.79	\	/*
	*/	11.02,10.91,10.79	\	/*
	*/	11.01,10.9,10.79	\	/*
	*/	11,10.9,10.79		\	/*
	*/	11,10.9,10.78		\	/*
	*/	10.99,10.89,10.78	\	/*
	*/	10.99,10.89,10.78	\	/*
	*/	10.98,10.89,10.78	\	/*
	*/	10.98,10.88,10.78	\	/*
	*/	10.97,10.88,10.77	\	/*
	*/	10.97,10.88,10.77	\	/*
	*/	10.96,10.87,10.77	\	/*
	*/	10.96,10.87,10.77	\	/*
	*/	10.95,10.86,10.77	\	/*
	*/	10.95,10.86,10.76	\	/*
	*/	10.94,10.86,10.76	\	/*
	*/	10.94,10.85,10.76	\	/*
	*/	10.93,10.85,10.76	\	/*
	*/	10.93,10.85,10.76	\	/*
	*/	10.92,10.84,10.75	\	/*
	*/	10.92,10.84,10.75	\	/*
	*/	10.91,10.84,10.75	\	/*
	*/	10.91,10.84,10.75	\	/*
	*/	10.91,10.83,10.75	\	/*
	*/	10.9,10.83,10.74	\	/*
	*/	10.9,10.83,10.74	\	/*
	*/	10.89,10.82,10.74	\	/*
	*/	10.89,10.82,10.74	\	/*
	*/	10.89,10.82,10.74	\	/*
	*/	10.88,10.81,10.74	\	/*
	*/	10.88,10.81,10.73	\	/*
	*/	10.87,10.81,10.73	\	/*
	*/	10.87,10.81,10.73	\	/*
	*/	10.87,10.8,10.73	\	/*
	*/	10.86,10.8,10.73	\	/*
	*/	10.86,10.8,10.72	\	/*
	*/	10.86,10.8,10.72)

		if `k2'<=100 & `nendog'<=3 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}


	if "`type'"=="ivbias20" {
		matrix input `temp' = (	/*
	*/	.	,	.	,	.	\ /*
	*/	.	,	.	,	.	\ /*
	*/	6.46	,	.	,	.	\ /*
	*/	6.71	,	5.57	,	.	\ /*
	*/	6.77	,	5.91	,	4.99	\ /*
	*/	6.76	,	6.08	,	5.35	\ /*
	*/	6.73	,	6.16	,	5.56	\ /*
	*/	6.69	,	6.20	,	5.69	\ /*
	*/	6.65	,	6.22	,	5.78	\ /*
	*/	6.61	,	6.23	,	5.83	\ /*
	*/	6.56	,	6.23	,	5.87	\ /*
	*/	6.53	,	6.22	,	5.90	\ /*
	*/	6.49	,	6.21	,	5.92	\ /*
	*/	6.45	,	6.20	,	5.93	\ /*
	*/	6.42	,	6.19	,	5.94	\ /*
	*/	6.39	,	6.17	,	5.94	\ /*
	*/	6.36	,	6.16	,	5.94	\ /*
	*/	6.33	,	6.14	,	5.94	\ /*
	*/	6.31	,	6.13	,	5.94	\ /*
	*/	6.28	,	6.11	,	5.93	\ /*
	*/	6.26	,	6.10	,	5.93	\ /*
	*/	6.24	,	6.08	,	5.92	\ /*
	*/	6.22	,	6.07	,	5.92	\ /*
	*/	6.20	,	6.06	,	5.91	\ /*
	*/	6.18	,	6.05	,	5.90	\ /*
	*/	6.16	,	6.03	,	5.90	\ /*
	*/	6.14	,	6.02	,	5.89	\ /*
	*/	6.13	,	6.01	,	5.88	\ /*
	*/	6.11	,	6.00	,	5.88	\ /*
	*/	6.09	,	5.99	,	5.87	\ /*
	*/	6.08	,	5.98	,	5.87	\ /*
	*/	6.07	,	5.97	,	5.86	\ /*
	*/	6.05	,	5.96	,	5.85	\ /*
	*/	6.04	,	5.95	,	5.85	\ /*
	*/	6.03	,	5.94	,	5.84	\ /*
	*/	6.01	,	5.93	,	5.83	\ /*
	*/	6.00	,	5.92	,	5.83	\ /*
	*/	5.99	,	5.91	,	5.82	\ /*
	*/	5.98	,	5.90	,	5.82	\ /*
	*/	5.97	,	5.89	,	5.81	\ /*
	*/	5.96	,	5.89	,	5.80	\ /*
	*/	5.95	,	5.88	,	5.80	\ /*
	*/	5.94	,	5.87	,	5.79	\ /*
	*/	5.93	,	5.86	,	5.79	\ /*
	*/	5.92	,	5.86	,	5.78	\ /*
	*/	5.91	,	5.85	,	5.78	\ /*
	*/	5.91	,	5.84	,	5.77	\ /*
	*/	5.90	,	5.83	,	5.77	\ /*
	*/	5.89	,	5.83	,	5.76	\ /*
	*/	5.88	,	5.82	,	5.76	\ /*
	*/	5.87	,	5.82	,	5.75	\ /*
	*/	5.87	,	5.81	,	5.75	\ /*
	*/	5.86	,	5.80	,	5.74	\ /*
	*/	5.85	,	5.80	,	5.74	\ /*
	*/	5.85	,	5.79	,	5.73	\ /*
	*/	5.84	,	5.79	,	5.73	\ /*
	*/	5.83	,	5.78	,	5.72	\ /*
	*/	5.83	,	5.78	,	5.72	\ /*
	*/	5.82	,	5.77	,	5.72	\ /*
	*/	5.81	,	5.77	,	5.71	\ /*
	*/	5.81	,	5.76	,	5.71	\ /*
	*/	5.80	,	5.76	,	5.70	\ /*
	*/	5.80	,	5.75	,	5.70	\ /*
	*/	5.79	,	5.75	,	5.70	\ /*
	*/	5.78	,	5.74	,	5.69	\ /*
	*/	5.78	,	5.74	,	5.69	\ /*
	*/	5.77	,	5.73	,	5.68	\ /*
	*/	5.77	,	5.73	,	5.68	\ /*
	*/	5.76	,	5.72	,	5.68	\ /*
	*/	5.76	,	5.72	,	5.67	\ /*
	*/	5.75	,	5.72	,	5.67	\ /*
	*/	5.75	,	5.71	,	5.67	\ /*
	*/	5.75	,	5.71	,	5.66	\ /*
	*/	5.74	,	5.70	,	5.66	\ /*
	*/	5.74	,	5.70	,	5.66	\ /*
	*/	5.73	,	5.70	,	5.65	\ /*
	*/	5.73	,	5.69	,	5.65	\ /*
	*/	5.72	,	5.69	,	5.65	\ /*
	*/	5.72	,	5.68	,	5.65	\ /*
	*/	5.71	,	5.68	,	5.64	\ /*
	*/	5.71	,	5.68	,	5.64	\ /*
	*/	5.71	,	5.67	,	5.64	\ /*
	*/	5.70	,	5.67	,	5.63	\ /*
	*/	5.70	,	5.67	,	5.63	\ /*
	*/	5.70	,	5.66	,	5.63	\ /*
	*/	5.69	,	5.66	,	5.62	\ /*
	*/	5.69	,	5.66	,	5.62	\ /*
	*/	5.68	,	5.65	,	5.62	\ /*
	*/	5.68	,	5.65	,	5.62	\ /*
	*/	5.68	,	5.65	,	5.61	\ /*
	*/	5.67	,	5.65	,	5.61	\ /*
	*/	5.67	,	5.64	,	5.61	\ /*
	*/	5.67	,	5.64	,	5.61	\ /*
	*/	5.66	,	5.64	,	5.60	\ /*
	*/	5.66	,	5.63	,	5.60	\ /*
	*/	5.66	,	5.63	,	5.60	\ /*
	*/	5.65	,	5.63	,	5.60	\ /*
	*/	5.65	,	5.63	,	5.59	\ /*
	*/	5.65	,	5.62	,	5.59	\ /*
	*/	5.65	,	5.62	,	5.59	)

		if `k2'<=100 & `nendog'<=3 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="ivbias30" {
		matrix input `temp' = (	/*
	*/	.	,	.	,	.	\ /*
	*/	.	,	.	,	.	\ /*
	*/	5.39	,	.	,	.	\ /*
	*/	5.34	,	4.73	,	.	\ /*
	*/	5.25	,	4.79	,	4.30	\ /*
	*/	5.15	,	4.78	,	4.40	\ /*
	*/	5.07	,	4.76	,	4.44	\ /*
	*/	4.99	,	4.73	,	4.46	\ /*
	*/	4.92	,	4.69	,	4.46	\ /*
	*/	4.86	,	4.66	,	4.45	\ /*
	*/	4.80	,	4.62	,	4.44	\ /*
	*/	4.75	,	4.59	,	4.42	\ /*
	*/	4.71	,	4.56	,	4.41	\ /*
	*/	4.67	,	4.53	,	4.39	\ /*
	*/	4.63	,	4.50	,	4.37	\ /*
	*/	4.59	,	4.48	,	4.36	\ /*
	*/	4.56	,	4.45	,	4.34	\ /*
	*/	4.53	,	4.43	,	4.32	\ /*
	*/	4.51	,	4.41	,	4.31	\ /*
	*/	4.48	,	4.39	,	4.29	\ /*
	*/	4.46	,	4.37	,	4.28	\ /*
	*/	4.43	,	4.35	,	4.27	\ /*
	*/	4.41	,	4.33	,	4.25	\ /*
	*/	4.39	,	4.32	,	4.24	\ /*
	*/	4.37	,	4.30	,	4.23	\ /*
	*/	4.35	,	4.29	,	4.21	\ /*
	*/	4.34	,	4.27	,	4.20	\ /*
	*/	4.32	,	4.26	,	4.19	\ /*
	*/	4.31	,	4.24	,	4.18	\ /*
	*/	4.29	,	4.23	,	4.17	\ /*
	*/	4.28	,	4.22	,	4.16	\ /*
	*/	4.26	,	4.21	,	4.15	\ /*
	*/	4.25	,	4.20	,	4.14	\ /*
	*/	4.24	,	4.19	,	4.13	\ /*
	*/	4.23	,	4.18	,	4.13	\ /*
	*/	4.22	,	4.17	,	4.12	\ /*
	*/	4.20	,	4.16	,	4.11	\ /*
	*/	4.19	,	4.15	,	4.10	\ /*
	*/	4.18	,	4.14	,	4.09	\ /*
	*/	4.17	,	4.13	,	4.09	\ /*
	*/	4.16	,	4.12	,	4.08	\ /*
	*/	4.15	,	4.11	,	4.07	\ /*
	*/	4.15	,	4.11	,	4.07	\ /*
	*/	4.14	,	4.10	,	4.06	\ /*
	*/	4.13	,	4.09	,	4.05	\ /*
	*/	4.12	,	4.08	,	4.05	\ /*
	*/	4.11	,	4.08	,	4.04	\ /*
	*/	4.11	,	4.07	,	4.03	\ /*
	*/	4.10	,	4.06	,	4.03	\ /*
	*/	4.09	,	4.06	,	4.02	\ /*
	*/	4.08	,	4.05	,	4.02	\ /*
	*/	4.08	,	4.05	,	4.01	\ /*
	*/	4.07	,	4.04	,	4.01	\ /*
	*/	4.06	,	4.03	,	4.00	\ /*
	*/	4.06	,	4.03	,	4.00	\ /*
	*/	4.05	,	4.02	,	3.99	\ /*
	*/	4.05	,	4.02	,	3.99	\ /*
	*/	4.04	,	4.01	,	3.98	\ /*
	*/	4.04	,	4.01	,	3.98	\ /*
	*/	4.03	,	4.00	,	3.97	\ /*
	*/	4.02	,	4.00	,	3.97	\ /*
	*/	4.02	,	3.99	,	3.96	\ /*
	*/	4.01	,	3.99	,	3.96	\ /*
	*/	4.01	,	3.98	,	3.96	\ /*
	*/	4.00	,	3.98	,	3.95	\ /*
	*/	4.00	,	3.97	,	3.95	\ /*
	*/	3.99	,	3.97	,	3.94	\ /*
	*/	3.99	,	3.97	,	3.94	\ /*
	*/	3.99	,	3.96	,	3.94	\ /*
	*/	3.98	,	3.96	,	3.93	\ /*
	*/	3.98	,	3.95	,	3.93	\ /*
	*/	3.97	,	3.95	,	3.93	\ /*
	*/	3.97	,	3.95	,	3.92	\ /*
	*/	3.96	,	3.94	,	3.92	\ /*
	*/	3.96	,	3.94	,	3.92	\ /*
	*/	3.96	,	3.93	,	3.91	\ /*
	*/	3.95	,	3.93	,	3.91	\ /*
	*/	3.95	,	3.93	,	3.91	\ /*
	*/	3.95	,	3.92	,	3.90	\ /*
	*/	3.94	,	3.92	,	3.90	\ /*
	*/	3.94	,	3.92	,	3.90	\ /*
	*/	3.93	,	3.91	,	3.89	\ /*
	*/	3.93	,	3.91	,	3.89	\ /*
	*/	3.93	,	3.91	,	3.89	\ /*
	*/	3.92	,	3.91	,	3.89	\ /*
	*/	3.92	,	3.90	,	3.88	\ /*
	*/	3.92	,	3.90	,	3.88	\ /*
	*/	3.91	,	3.90	,	3.88	\ /*
	*/	3.91	,	3.89	,	3.87	\ /*
	*/	3.91	,	3.89	,	3.87	\ /*
	*/	3.91	,	3.89	,	3.87	\ /*
	*/	3.90	,	3.89	,	3.87	\ /*
	*/	3.90	,	3.88	,	3.86	\ /*
	*/	3.90	,	3.88	,	3.86	\ /*
	*/	3.89	,	3.88	,	3.86	\ /*
	*/	3.89	,	3.87	,	3.86	\ /*
	*/	3.89	,	3.87	,	3.85	\ /*
	*/	3.89	,	3.87	,	3.85	\ /*
	*/	3.88	,	3.87	,	3.85	\ /*
	*/	3.88	,	3.86	,	3.85	)
	
		if `k2'<=100 & `nendog'<=3 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}


	if "`type'"=="ivsize10" {
		matrix input `temp' = /*
	*/	(16.38,.	\	/*
	*/	19.93,7.03	\	/*
	*/	22.3,13.43	\	/*
	*/	24.58,16.87	\	/*
	*/	26.87,19.45	\	/*
	*/	29.18,21.68	\	/*
	*/	31.5,23.72	\	/*
	*/	33.84,25.64	\	/*
	*/	36.19,27.51	\	/*
	*/	38.54,29.32	\	/*
	*/	40.9,31.11	\	/*
	*/	43.27,32.88	\	/*
	*/	45.64,34.62	\	/*
	*/	48.01,36.36	\	/*
	*/	50.39,38.08	\	/*
	*/	52.77,39.8	\	/*
	*/	55.15,41.51	\	/*
	*/	57.53,43.22	\	/*
	*/	59.92,44.92	\	/*
	*/	62.3,46.62	\	/*
	*/	64.69,48.31	\	/*
	*/	67.07,50.01	\	/*
	*/	69.46,51.7	\	/*
	*/	71.85,53.39	\	/*
	*/	74.24,55.07	\	/*
	*/	76.62,56.76	\	/*
	*/	79.01,58.45	\	/*
	*/	81.4,60.13	\	/*
	*/	83.79,61.82	\	/*
	*/	86.17,63.51	\	/*
	*/	88.56,65.19	\	/*
	*/	90.95,66.88	\	/*
	*/	93.33,68.56	\	/*
	*/	95.72,70.25	\	/*
	*/	98.11,71.94	\	/*
	*/	100.5,73.62	\	/*
	*/	102.88,75.31	\	/*
	*/	105.27,76.99	\	/*
	*/	107.66,78.68	\	/*
	*/	110.04,80.37	\	/*
	*/	112.43,82.05	\	/*
	*/	114.82,83.74	\	/*
	*/	117.21,85.42	\	/*
	*/	119.59,87.11	\	/*
	*/	121.98,88.8	\	/*
	*/	124.37,90.48	\	/*
	*/	126.75,92.17	\	/*
	*/	129.14,93.85	\	/*
	*/	131.53,95.54	\	/*
	*/	133.92,97.23	\	/*
	*/	136.3,98.91	\	/*
	*/	138.69,100.6	\	/*
	*/	141.08,102.29	\	/*
	*/	143.47,103.97	\	/*
	*/	145.85,105.66	\	/*
	*/	148.24,107.34	\	/*
	*/	150.63,109.03	\	/*
	*/	153.01,110.72	\	/*
	*/	155.4,112.4	\	/*
	*/	157.79,114.09	\	/*
	*/	160.18,115.77	\	/*
	*/	162.56,117.46	\	/*
	*/	164.95,119.15	\	/*
	*/	167.34,120.83	\	/*
	*/	169.72,122.52	\	/*
	*/	172.11,124.2	\	/*
	*/	174.5,125.89	\	/*
	*/	176.89,127.58	\	/*
	*/	179.27,129.26	\	/*
	*/	181.66,130.95	\	/*
	*/	184.05,132.63	\	/*
	*/	186.44,134.32	\	/*
	*/	188.82,136.01	\	/*
	*/	191.21,137.69	\	/*
	*/	193.6,139.38	\	/*
	*/	195.98,141.07	\	/*
	*/	198.37,142.75	\	/*
	*/	200.76,144.44	\	/*
	*/	203.15,146.12	\	/*
	*/	205.53,147.81	\	/*
	*/	207.92,149.5	\	/*
	*/	210.31,151.18	\	/*
	*/	212.69,152.87	\	/*
	*/	215.08,154.55	\	/*
	*/	217.47,156.24	\	/*
	*/	219.86,157.93	\	/*
	*/	222.24,159.61	\	/*
	*/	224.63,161.3	\	/*
	*/	227.02,162.98	\	/*
	*/	229.41,164.67	\	/*
	*/	231.79,166.36	\	/*
	*/	234.18,168.04	\	/*
	*/	236.57,169.73	\	/*
	*/	238.95,171.41	\	/*
	*/	241.34,173.1	\	/*
	*/	243.73,174.79	\	/*
	*/	246.12,176.47	\	/*
	*/	248.5,178.16	\	/*
	*/	250.89,179.84	\	/*
	*/	253.28,181.53)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="ivsize15" {
		matrix input `temp' = ( /*
	*/	8.96	,	.	\ /*
	*/	11.59	,	4.58	\ /*
	*/	12.83	,	8.18	\ /*
	*/	13.96	,	9.93	\ /*
	*/	15.09	,	11.22	\ /*
	*/	16.23	,	12.33	\ /*
	*/	17.38	,	13.34	\ /*
	*/	18.54	,	14.31	\ /*
	*/	19.71	,	15.24	\ /*
	*/	20.88	,	16.16	\ /*
	*/	22.06	,	17.06	\ /*
	*/	23.24	,	17.95	\ /*
	*/	24.42	,	18.84	\ /*
	*/	25.61	,	19.72	\ /*
	*/	26.80	,	20.60	\ /*
	*/	27.99	,	21.48	\ /*
	*/	29.19	,	22.35	\ /*
	*/	30.38	,	23.22	\ /*
	*/	31.58	,	24.09	\ /*
	*/	32.77	,	24.96	\ /*
	*/	33.97	,	25.82	\ /*
	*/	35.17	,	26.69	\ /*
	*/	36.37	,	27.56	\ /*
	*/	37.57	,	28.42	\ /*
	*/	38.77	,	29.29	\ /*
	*/	39.97	,	30.15	\ /*
	*/	41.17	,	31.02	\ /*
	*/	42.37	,	31.88	\ /*
	*/	43.57	,	32.74	\ /*
	*/	44.78	,	33.61	\ /*
	*/	45.98	,	34.47	\ /*
	*/	47.18	,	35.33	\ /*
	*/	48.38	,	36.19	\ /*
	*/	49.59	,	37.06	\ /*
	*/	50.79	,	37.92	\ /*
	*/	51.99	,	38.78	\ /*
	*/	53.19	,	39.64	\ /*
	*/	54.40	,	40.50	\ /*
	*/	55.60	,	41.37	\ /*
	*/	56.80	,	42.23	\ /*
	*/	58.01	,	43.09	\ /*
	*/	59.21	,	43.95	\ /*
	*/	60.41	,	44.81	\ /*
	*/	61.61	,	45.68	\ /*
	*/	62.82	,	46.54	\ /*
	*/	64.02	,	47.40	\ /*
	*/	65.22	,	48.26	\ /*
	*/	66.42	,	49.12	\ /*
	*/	67.63	,	49.99	\ /*
	*/	68.83	,	50.85	\ /*
	*/	70.03	,	51.71	\ /*
	*/	71.24	,	52.57	\ /*
	*/	72.44	,	53.43	\ /*
	*/	73.64	,	54.30	\ /*
	*/	74.84	,	55.16	\ /*
	*/	76.05	,	56.02	\ /*
	*/	77.25	,	56.88	\ /*
	*/	78.45	,	57.74	\ /*
	*/	79.66	,	58.61	\ /*
	*/	80.86	,	59.47	\ /*
	*/	82.06	,	60.33	\ /*
	*/	83.26	,	61.19	\ /*
	*/	84.47	,	62.05	\ /*
	*/	85.67	,	62.92	\ /*
	*/	86.87	,	63.78	\ /*
	*/	88.07	,	64.64	\ /*
	*/	89.28	,	65.50	\ /*
	*/	90.48	,	66.36	\ /*
	*/	91.68	,	67.22	\ /*
	*/	92.89	,	68.09	\ /*
	*/	94.09	,	68.95	\ /*
	*/	95.29	,	69.81	\ /*
	*/	96.49	,	70.67	\ /*
	*/	97.70	,	71.53	\ /*
	*/	98.90	,	72.40	\ /*
	*/	100.10	,	73.26	\ /*
	*/	101.30	,	74.12	\ /*
	*/	102.51	,	74.98	\ /*
	*/	103.71	,	75.84	\ /*
	*/	104.91	,	76.71	\ /*
	*/	106.12	,	77.57	\ /*
	*/	107.32	,	78.43	\ /*
	*/	108.52	,	79.29	\ /*
	*/	109.72	,	80.15	\ /*
	*/	110.93	,	81.02	\ /*
	*/	112.13	,	81.88	\ /*
	*/	113.33	,	82.74	\ /*
	*/	114.53	,	83.60	\ /*
	*/	115.74	,	84.46	\ /*
	*/	116.94	,	85.33	\ /*
	*/	118.14	,	86.19	\ /*
	*/	119.35	,	87.05	\ /*
	*/	120.55	,	87.91	\ /*
	*/	121.75	,	88.77	\ /*
	*/	122.95	,	89.64	\ /*
	*/	124.16	,	90.50	\ /*
	*/	125.36	,	91.36	\ /*
	*/	126.56	,	92.22	\ /*
	*/	127.76	,	93.08	\ /*
	*/	128.97	,	93.95	)
	
		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="ivsize20" {
		matrix input `temp' = ( /*
	*/	6.66	,	.	\ /*
	*/	8.75	,	3.95	\ /*
	*/	9.54	,	6.40	\ /*
	*/	10.26	,	7.54	\ /*
	*/	10.98	,	8.38	\ /*
	*/	11.72	,	9.10	\ /*
	*/	12.48	,	9.77	\ /*
	*/	13.24	,	10.41	\ /*
	*/	14.01	,	11.03	\ /*
	*/	14.78	,	11.65	\ /*
	*/	15.56	,	12.25	\ /*
	*/	16.35	,	12.86	\ /*
	*/	17.14	,	13.45	\ /*
	*/	17.93	,	14.05	\ /*
	*/	18.72	,	14.65	\ /*
	*/	19.51	,	15.24	\ /*
	*/	20.31	,	15.83	\ /*
	*/	21.10	,	16.42	\ /*
	*/	21.90	,	17.02	\ /*
	*/	22.70	,	17.61	\ /*
	*/	23.50	,	18.20	\ /*
	*/	24.30	,	18.79	\ /*
	*/	25.10	,	19.38	\ /*
	*/	25.90	,	19.97	\ /*
	*/	26.71	,	20.56	\ /*
	*/	27.51	,	21.15	\ /*
	*/	28.31	,	21.74	\ /*
	*/	29.12	,	22.33	\ /*
	*/	29.92	,	22.92	\ /*
	*/	30.72	,	23.51	\ /*
	*/	31.53	,	24.10	\ /*
	*/	32.33	,	24.69	\ /*
	*/	33.14	,	25.28	\ /*
	*/	33.94	,	25.87	\ /*
	*/	34.75	,	26.46	\ /*
	*/	35.55	,	27.05	\ /*
	*/	36.36	,	27.64	\ /*
	*/	37.17	,	28.23	\ /*
	*/	37.97	,	28.82	\ /*
	*/	38.78	,	29.41	\ /*
	*/	39.58	,	30.00	\ /*
	*/	40.39	,	30.59	\ /*
	*/	41.20	,	31.18	\ /*
	*/	42.00	,	31.77	\ /*
	*/	42.81	,	32.36	\ /*
	*/	43.62	,	32.95	\ /*
	*/	44.42	,	33.54	\ /*
	*/	45.23	,	34.13	\ /*
	*/	46.03	,	34.72	\ /*
	*/	46.84	,	35.31	\ /*
	*/	47.65	,	35.90	\ /*
	*/	48.45	,	36.49	\ /*
	*/	49.26	,	37.08	\ /*
	*/	50.06	,	37.67	\ /*
	*/	50.87	,	38.26	\ /*
	*/	51.68	,	38.85	\ /*
	*/	52.48	,	39.44	\ /*
	*/	53.29	,	40.02	\ /*
	*/	54.09	,	40.61	\ /*
	*/	54.90	,	41.20	\ /*
	*/	55.71	,	41.79	\ /*
	*/	56.51	,	42.38	\ /*
	*/	57.32	,	42.97	\ /*
	*/	58.13	,	43.56	\ /*
	*/	58.93	,	44.15	\ /*
	*/	59.74	,	44.74	\ /*
	*/	60.54	,	45.33	\ /*
	*/	61.35	,	45.92	\ /*
	*/	62.16	,	46.51	\ /*
	*/	62.96	,	47.10	\ /*
	*/	63.77	,	47.69	\ /*
	*/	64.57	,	48.28	\ /*
	*/	65.38	,	48.87	\ /*
	*/	66.19	,	49.46	\ /*
	*/	66.99	,	50.05	\ /*
	*/	67.80	,	50.64	\ /*
	*/	68.60	,	51.23	\ /*
	*/	69.41	,	51.82	\ /*
	*/	70.22	,	52.41	\ /*
	*/	71.02	,	53.00	\ /*
	*/	71.83	,	53.59	\ /*
	*/	72.64	,	54.18	\ /*
	*/	73.44	,	54.77	\ /*
	*/	74.25	,	55.36	\ /*
	*/	75.05	,	55.95	\ /*
	*/	75.86	,	56.54	\ /*
	*/	76.67	,	57.13	\ /*
	*/	77.47	,	57.72	\ /*
	*/	78.28	,	58.31	\ /*
	*/	79.08	,	58.90	\ /*
	*/	79.89	,	59.49	\ /*
	*/	80.70	,	60.08	\ /*
	*/	81.50	,	60.67	\ /*
	*/	82.31	,	61.26	\ /*
	*/	83.12	,	61.85	\ /*
	*/	83.92	,	62.44	\ /*
	*/	84.73	,	63.03	\ /*
	*/	85.53	,	63.62	\ /*
	*/	86.34	,	64.21	\ /*
	*/	87.15	,	64.80	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="ivsize25" {
		matrix input `temp' = ( /*
	*/	5.53	,	.	\ /*
	*/	7.25	,	3.63	\ /*
	*/	7.80	,	5.45	\ /*
	*/	8.31	,	6.28	\ /*
	*/	8.84	,	6.89	\ /*
	*/	9.38	,	7.42	\ /*
	*/	9.93	,	7.91	\ /*
	*/	10.50	,	8.39	\ /*
	*/	11.07	,	8.85	\ /*
	*/	11.65	,	9.31	\ /*
	*/	12.23	,	9.77	\ /*
	*/	12.82	,	10.22	\ /*
	*/	13.41	,	10.68	\ /*
	*/	14.00	,	11.13	\ /*
	*/	14.60	,	11.58	\ /*
	*/	15.19	,	12.03	\ /*
	*/	15.79	,	12.49	\ /*
	*/	16.39	,	12.94	\ /*
	*/	16.99	,	13.39	\ /*
	*/	17.60	,	13.84	\ /*
	*/	18.20	,	14.29	\ /*
	*/	18.80	,	14.74	\ /*
	*/	19.41	,	15.19	\ /*
	*/	20.01	,	15.64	\ /*
	*/	20.61	,	16.10	\ /*
	*/	21.22	,	16.55	\ /*
	*/	21.83	,	17.00	\ /*
	*/	22.43	,	17.45	\ /*
	*/	23.04	,	17.90	\ /*
	*/	23.65	,	18.35	\ /*
	*/	24.25	,	18.81	\ /*
	*/	24.86	,	19.26	\ /*
	*/	25.47	,	19.71	\ /*
	*/	26.08	,	20.16	\ /*
	*/	26.68	,	20.61	\ /*
	*/	27.29	,	21.06	\ /*
	*/	27.90	,	21.52	\ /*
	*/	28.51	,	21.97	\ /*
	*/	29.12	,	22.42	\ /*
	*/	29.73	,	22.87	\ /*
	*/	30.33	,	23.32	\ /*
	*/	30.94	,	23.78	\ /*
	*/	31.55	,	24.23	\ /*
	*/	32.16	,	24.68	\ /*
	*/	32.77	,	25.13	\ /*
	*/	33.38	,	25.58	\ /*
	*/	33.99	,	26.04	\ /*
	*/	34.60	,	26.49	\ /*
	*/	35.21	,	26.94	\ /*
	*/	35.82	,	27.39	\ /*
	*/	36.43	,	27.85	\ /*
	*/	37.04	,	28.30	\ /*
	*/	37.65	,	28.75	\ /*
	*/	38.25	,	29.20	\ /*
	*/	38.86	,	29.66	\ /*
	*/	39.47	,	30.11	\ /*
	*/	40.08	,	30.56	\ /*
	*/	40.69	,	31.01	\ /*
	*/	41.30	,	31.47	\ /*
	*/	41.91	,	31.92	\ /*
	*/	42.52	,	32.37	\ /*
	*/	43.13	,	32.82	\ /*
	*/	43.74	,	33.27	\ /*
	*/	44.35	,	33.73	\ /*
	*/	44.96	,	34.18	\ /*
	*/	45.57	,	34.63	\ /*
	*/	46.18	,	35.08	\ /*
	*/	46.78	,	35.54	\ /*
	*/	47.39	,	35.99	\ /*
	*/	48.00	,	36.44	\ /*
	*/	48.61	,	36.89	\ /*
	*/	49.22	,	37.35	\ /*
	*/	49.83	,	37.80	\ /*
	*/	50.44	,	38.25	\ /*
	*/	51.05	,	38.70	\ /*
	*/	51.66	,	39.16	\ /*
	*/	52.27	,	39.61	\ /*
	*/	52.88	,	40.06	\ /*
	*/	53.49	,	40.51	\ /*
	*/	54.10	,	40.96	\ /*
	*/	54.71	,	41.42	\ /*
	*/	55.32	,	41.87	\ /*
	*/	55.92	,	42.32	\ /*
	*/	56.53	,	42.77	\ /*
	*/	57.14	,	43.23	\ /*
	*/	57.75	,	43.68	\ /*
	*/	58.36	,	44.13	\ /*
	*/	58.97	,	44.58	\ /*
	*/	59.58	,	45.04	\ /*
	*/	60.19	,	45.49	\ /*
	*/	60.80	,	45.94	\ /*
	*/	61.41	,	46.39	\ /*
	*/	62.02	,	46.85	\ /*
	*/	62.63	,	47.30	\ /*
	*/	63.24	,	47.75	\ /*
	*/	63.85	,	48.20	\ /*
	*/	64.45	,	48.65	\ /*
	*/	65.06	,	49.11	\ /*
	*/	65.67	,	49.56	\ /*
	*/	66.28	,	50.01	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
	
	if "`type'"=="fullrel5" {
		matrix input `temp' = ( /*
	*/	24.09	,	.	\ /*
	*/	13.46	,	15.50	\ /*
	*/	9.61	,	10.83	\ /*
	*/	7.63	,	8.53	\ /*
	*/	6.42	,	7.16	\ /*
	*/	5.61	,	6.24	\ /*
	*/	5.02	,	5.59	\ /*
	*/	4.58	,	5.10	\ /*
	*/	4.23	,	4.71	\ /*
	*/	3.96	,	4.41	\ /*
	*/	3.73	,	4.15	\ /*
	*/	3.54	,	3.94	\ /*
	*/	3.38	,	3.76	\ /*
	*/	3.24	,	3.60	\ /*
	*/	3.12	,	3.47	\ /*
	*/	3.01	,	3.35	\ /*
	*/	2.92	,	3.24	\ /*
	*/	2.84	,	3.15	\ /*
	*/	2.76	,	3.06	\ /*
	*/	2.69	,	2.98	\ /*
	*/	2.63	,	2.91	\ /*
	*/	2.58	,	2.85	\ /*
	*/	2.52	,	2.79	\ /*
	*/	2.48	,	2.73	\ /*
	*/	2.43	,	2.68	\ /*
	*/	2.39	,	2.63	\ /*
	*/	2.36	,	2.59	\ /*
	*/	2.32	,	2.55	\ /*
	*/	2.29	,	2.51	\ /*
	*/	2.26	,	2.47	\ /*
	*/	2.23	,	2.44	\ /*
	*/	2.20	,	2.41	\ /*
	*/	2.18	,	2.37	\ /*
	*/	2.16	,	2.35	\ /*
	*/	2.13	,	2.32	\ /*
	*/	2.11	,	2.29	\ /*
	*/	2.09	,	2.27	\ /*
	*/	2.07	,	2.24	\ /*
	*/	2.05	,	2.22	\ /*
	*/	2.04	,	2.20	\ /*
	*/	2.02	,	2.18	\ /*
	*/	2.00	,	2.16	\ /*
	*/	1.99	,	2.14	\ /*
	*/	1.97	,	2.12	\ /*
	*/	1.96	,	2.10	\ /*
	*/	1.94	,	2.09	\ /*
	*/	1.93	,	2.07	\ /*
	*/	1.92	,	2.05	\ /*
	*/	1.91	,	2.04	\ /*
	*/	1.89	,	2.02	\ /*
	*/	1.88	,	2.01	\ /*
	*/	1.87	,	2.00	\ /*
	*/	1.86	,	1.98	\ /*
	*/	1.85	,	1.97	\ /*
	*/	1.84	,	1.96	\ /*
	*/	1.83	,	1.95	\ /*
	*/	1.82	,	1.94	\ /*
	*/	1.81	,	1.92	\ /*
	*/	1.80	,	1.91	\ /*
	*/	1.79	,	1.90	\ /*
	*/	1.79	,	1.89	\ /*
	*/	1.78	,	1.88	\ /*
	*/	1.77	,	1.87	\ /*
	*/	1.76	,	1.87	\ /*
	*/	1.75	,	1.86	\ /*
	*/	1.75	,	1.85	\ /*
	*/	1.74	,	1.84	\ /*
	*/	1.73	,	1.83	\ /*
	*/	1.72	,	1.83	\ /*
	*/	1.72	,	1.82	\ /*
	*/	1.71	,	1.81	\ /*
	*/	1.70	,	1.80	\ /*
	*/	1.70	,	1.80	\ /*
	*/	1.69	,	1.79	\ /*
	*/	1.68	,	1.79	\ /*
	*/	1.68	,	1.78	\ /*
	*/	1.67	,	1.77	\ /*
	*/	1.67	,	1.77	\ /*
	*/	1.66	,	1.76	\ /*
	*/	1.65	,	1.76	\ /*
	*/	1.65	,	1.75	\ /*
	*/	1.64	,	1.75	\ /*
	*/	1.64	,	1.74	\ /*
	*/	1.63	,	1.74	\ /*
	*/	1.63	,	1.73	\ /*
	*/	1.62	,	1.73	\ /*
	*/	1.61	,	1.73	\ /*
	*/	1.61	,	1.72	\ /*
	*/	1.60	,	1.72	\ /*
	*/	1.60	,	1.71	\ /*
	*/	1.59	,	1.71	\ /*
	*/	1.59	,	1.71	\ /*
	*/	1.58	,	1.71	\ /*
	*/	1.58	,	1.70	\ /*
	*/	1.57	,	1.70	\ /*
	*/	1.57	,	1.70	\ /*
	*/	1.56	,	1.69	\ /*
	*/	1.56	,	1.69	\ /*
	*/	1.55	,	1.69	\ /*
	*/	1.55	,	1.69	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
	
	if "`type'"=="fullrel10" {
		matrix input `temp' = ( /*
	*/	19.36	,	.	\ /*
	*/	10.89	,	12.55	\ /*
	*/	7.90	,	8.96	\ /*
	*/	6.37	,	7.15	\ /*
	*/	5.44	,	6.07	\ /*
	*/	4.81	,	5.34	\ /*
	*/	4.35	,	4.82	\ /*
	*/	4.01	,	4.43	\ /*
	*/	3.74	,	4.12	\ /*
	*/	3.52	,	3.87	\ /*
	*/	3.34	,	3.67	\ /*
	*/	3.19	,	3.49	\ /*
	*/	3.06	,	3.35	\ /*
	*/	2.95	,	3.22	\ /*
	*/	2.85	,	3.11	\ /*
	*/	2.76	,	3.01	\ /*
	*/	2.69	,	2.92	\ /*
	*/	2.62	,	2.84	\ /*
	*/	2.56	,	2.77	\ /*
	*/	2.50	,	2.71	\ /*
	*/	2.45	,	2.65	\ /*
	*/	2.40	,	2.60	\ /*
	*/	2.36	,	2.55	\ /*
	*/	2.32	,	2.50	\ /*
	*/	2.28	,	2.46	\ /*
	*/	2.24	,	2.42	\ /*
	*/	2.21	,	2.38	\ /*
	*/	2.18	,	2.35	\ /*
	*/	2.15	,	2.31	\ /*
	*/	2.12	,	2.28	\ /*
	*/	2.10	,	2.25	\ /*
	*/	2.07	,	2.23	\ /*
	*/	2.05	,	2.20	\ /*
	*/	2.03	,	2.17	\ /*
	*/	2.01	,	2.15	\ /*
	*/	1.99	,	2.13	\ /*
	*/	1.97	,	2.11	\ /*
	*/	1.95	,	2.09	\ /*
	*/	1.93	,	2.07	\ /*
	*/	1.92	,	2.05	\ /*
	*/	1.90	,	2.03	\ /*
	*/	1.88	,	2.01	\ /*
	*/	1.87	,	2.00	\ /*
	*/	1.86	,	1.98	\ /*
	*/	1.84	,	1.96	\ /*
	*/	1.83	,	1.95	\ /*
	*/	1.82	,	1.93	\ /*
	*/	1.81	,	1.92	\ /*
	*/	1.79	,	1.91	\ /*
	*/	1.78	,	1.89	\ /*
	*/	1.77	,	1.88	\ /*
	*/	1.76	,	1.87	\ /*
	*/	1.75	,	1.86	\ /*
	*/	1.74	,	1.85	\ /*
	*/	1.73	,	1.84	\ /*
	*/	1.72	,	1.83	\ /*
	*/	1.71	,	1.82	\ /*
	*/	1.70	,	1.81	\ /*
	*/	1.70	,	1.80	\ /*
	*/	1.69	,	1.79	\ /*
	*/	1.68	,	1.78	\ /*
	*/	1.67	,	1.77	\ /*
	*/	1.67	,	1.76	\ /*
	*/	1.66	,	1.75	\ /*
	*/	1.65	,	1.75	\ /*
	*/	1.64	,	1.74	\ /*
	*/	1.64	,	1.73	\ /*
	*/	1.63	,	1.72	\ /*
	*/	1.63	,	1.72	\ /*
	*/	1.62	,	1.71	\ /*
	*/	1.61	,	1.70	\ /*
	*/	1.61	,	1.70	\ /*
	*/	1.60	,	1.69	\ /*
	*/	1.60	,	1.68	\ /*
	*/	1.59	,	1.68	\ /*
	*/	1.59	,	1.67	\ /*
	*/	1.58	,	1.67	\ /*
	*/	1.58	,	1.66	\ /*
	*/	1.57	,	1.66	\ /*
	*/	1.57	,	1.65	\ /*
	*/	1.56	,	1.65	\ /*
	*/	1.56	,	1.64	\ /*
	*/	1.56	,	1.64	\ /*
	*/	1.55	,	1.63	\ /*
	*/	1.55	,	1.63	\ /*
	*/	1.54	,	1.62	\ /*
	*/	1.54	,	1.62	\ /*
	*/	1.54	,	1.62	\ /*
	*/	1.53	,	1.61	\ /*
	*/	1.53	,	1.61	\ /*
	*/	1.53	,	1.61	\ /*
	*/	1.52	,	1.60	\ /*
	*/	1.52	,	1.60	\ /*
	*/	1.52	,	1.60	\ /*
	*/	1.52	,	1.59	\ /*
	*/	1.51	,	1.59	\ /*
	*/	1.51	,	1.59	\ /*
	*/	1.51	,	1.59	\ /*
	*/	1.51	,	1.58	\ /*
	*/	1.50	,	1.58	)
		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
	
	if "`type'"=="fullrel20" {
		matrix input `temp' = ( /*
	*/	15.64	,	.	\ /*
	*/	9.00	,	9.72	\ /*
	*/	6.61	,	7.18	\ /*
	*/	5.38	,	5.85	\ /*
	*/	4.62	,	5.04	\ /*
	*/	4.11	,	4.48	\ /*
	*/	3.75	,	4.08	\ /*
	*/	3.47	,	3.77	\ /*
	*/	3.25	,	3.53	\ /*
	*/	3.07	,	3.33	\ /*
	*/	2.92	,	3.17	\ /*
	*/	2.80	,	3.04	\ /*
	*/	2.70	,	2.92	\ /*
	*/	2.61	,	2.82	\ /*
	*/	2.53	,	2.73	\ /*
	*/	2.46	,	2.65	\ /*
	*/	2.39	,	2.58	\ /*
	*/	2.34	,	2.52	\ /*
	*/	2.29	,	2.46	\ /*
	*/	2.24	,	2.41	\ /*
	*/	2.20	,	2.36	\ /*
	*/	2.16	,	2.32	\ /*
	*/	2.13	,	2.28	\ /*
	*/	2.10	,	2.24	\ /*
	*/	2.06	,	2.21	\ /*
	*/	2.04	,	2.18	\ /*
	*/	2.01	,	2.15	\ /*
	*/	1.99	,	2.12	\ /*
	*/	1.96	,	2.09	\ /*
	*/	1.94	,	2.07	\ /*
	*/	1.92	,	2.04	\ /*
	*/	1.90	,	2.02	\ /*
	*/	1.88	,	2.00	\ /*
	*/	1.87	,	1.98	\ /*
	*/	1.85	,	1.96	\ /*
	*/	1.83	,	1.94	\ /*
	*/	1.82	,	1.93	\ /*
	*/	1.80	,	1.91	\ /*
	*/	1.79	,	1.89	\ /*
	*/	1.78	,	1.88	\ /*
	*/	1.76	,	1.86	\ /*
	*/	1.75	,	1.85	\ /*
	*/	1.74	,	1.84	\ /*
	*/	1.73	,	1.82	\ /*
	*/	1.72	,	1.81	\ /*
	*/	1.71	,	1.80	\ /*
	*/	1.70	,	1.79	\ /*
	*/	1.69	,	1.78	\ /*
	*/	1.68	,	1.77	\ /*
	*/	1.67	,	1.76	\ /*
	*/	1.66	,	1.75	\ /*
	*/	1.65	,	1.74	\ /*
	*/	1.65	,	1.73	\ /*
	*/	1.64	,	1.72	\ /*
	*/	1.63	,	1.71	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.62	,	1.69	\ /*
	*/	1.61	,	1.68	\ /*
	*/	1.60	,	1.68	\ /*
	*/	1.60	,	1.67	\ /*
	*/	1.59	,	1.66	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.57	,	1.64	\ /*
	*/	1.57	,	1.63	\ /*
	*/	1.56	,	1.63	\ /*
	*/	1.56	,	1.62	\ /*
	*/	1.55	,	1.62	\ /*
	*/	1.55	,	1.61	\ /*
	*/	1.54	,	1.60	\ /*
	*/	1.54	,	1.60	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.51	,	1.56	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.48	,	1.54	\ /*
	*/	1.48	,	1.54	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.47	,	1.53	\ /*
	*/	1.47	,	1.53	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.46	,	1.52	\ /*
	*/	1.46	,	1.52	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.45	,	1.51	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.44	,	1.50	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.49	)
		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="fullrel30" {
		matrix input `temp' = ( /*
	*/	12.71	,	.	\ /*
	*/	7.49	,	8.03	\ /*
	*/	5.60	,	6.15	\ /*
	*/	4.63	,	5.10	\ /*
	*/	4.03	,	4.44	\ /*
	*/	3.63	,	3.98	\ /*
	*/	3.33	,	3.65	\ /*
	*/	3.11	,	3.39	\ /*
	*/	2.93	,	3.19	\ /*
	*/	2.79	,	3.02	\ /*
	*/	2.67	,	2.88	\ /*
	*/	2.57	,	2.77	\ /*
	*/	2.48	,	2.67	\ /*
	*/	2.41	,	2.58	\ /*
	*/	2.34	,	2.51	\ /*
	*/	2.28	,	2.44	\ /*
	*/	2.23	,	2.38	\ /*
	*/	2.18	,	2.33	\ /*
	*/	2.14	,	2.28	\ /*
	*/	2.10	,	2.23	\ /*
	*/	2.07	,	2.19	\ /*
	*/	2.04	,	2.16	\ /*
	*/	2.01	,	2.12	\ /*
	*/	1.98	,	2.09	\ /*
	*/	1.95	,	2.06	\ /*
	*/	1.93	,	2.03	\ /*
	*/	1.90	,	2.01	\ /*
	*/	1.88	,	1.98	\ /*
	*/	1.86	,	1.96	\ /*
	*/	1.84	,	1.94	\ /*
	*/	1.83	,	1.92	\ /*
	*/	1.81	,	1.90	\ /*
	*/	1.79	,	1.88	\ /*
	*/	1.78	,	1.87	\ /*
	*/	1.76	,	1.85	\ /*
	*/	1.75	,	1.83	\ /*
	*/	1.74	,	1.82	\ /*
	*/	1.72	,	1.80	\ /*
	*/	1.71	,	1.79	\ /*
	*/	1.70	,	1.78	\ /*
	*/	1.69	,	1.77	\ /*
	*/	1.68	,	1.75	\ /*
	*/	1.67	,	1.74	\ /*
	*/	1.66	,	1.73	\ /*
	*/	1.65	,	1.72	\ /*
	*/	1.64	,	1.71	\ /*
	*/	1.63	,	1.70	\ /*
	*/	1.62	,	1.69	\ /*
	*/	1.61	,	1.68	\ /*
	*/	1.60	,	1.67	\ /*
	*/	1.60	,	1.66	\ /*
	*/	1.59	,	1.66	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.57	,	1.64	\ /*
	*/	1.57	,	1.63	\ /*
	*/	1.56	,	1.63	\ /*
	*/	1.55	,	1.62	\ /*
	*/	1.55	,	1.61	\ /*
	*/	1.54	,	1.61	\ /*
	*/	1.54	,	1.60	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.50	,	1.55	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.48	,	1.54	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.47	,	1.53	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.46	,	1.52	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.48	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.42	,	1.47	\ /*
	*/	1.42	,	1.47	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.41	,	1.46	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="fullmax5" {
		matrix input `temp' = ( /*
	*/	23.81	,	.	\ /*
	*/	12.38	,	14.19	\ /*
	*/	8.66	,	10.00	\ /*
	*/	6.81	,	7.88	\ /*
	*/	5.71	,	6.60	\ /*
	*/	4.98	,	5.74	\ /*
	*/	4.45	,	5.13	\ /*
	*/	4.06	,	4.66	\ /*
	*/	3.76	,	4.30	\ /*
	*/	3.51	,	4.01	\ /*
	*/	3.31	,	3.77	\ /*
	*/	3.15	,	3.57	\ /*
	*/	3.00	,	3.41	\ /*
	*/	2.88	,	3.26	\ /*
	*/	2.78	,	3.13	\ /*
	*/	2.69	,	3.02	\ /*
	*/	2.61	,	2.92	\ /*
	*/	2.53	,	2.84	\ /*
	*/	2.47	,	2.76	\ /*
	*/	2.41	,	2.69	\ /*
	*/	2.36	,	2.62	\ /*
	*/	2.31	,	2.56	\ /*
	*/	2.27	,	2.51	\ /*
	*/	2.23	,	2.46	\ /*
	*/	2.19	,	2.42	\ /*
	*/	2.15	,	2.37	\ /*
	*/	2.12	,	2.33	\ /*
	*/	2.09	,	2.30	\ /*
	*/	2.07	,	2.26	\ /*
	*/	2.04	,	2.23	\ /*
	*/	2.02	,	2.20	\ /*
	*/	1.99	,	2.17	\ /*
	*/	1.97	,	2.14	\ /*
	*/	1.95	,	2.12	\ /*
	*/	1.93	,	2.10	\ /*
	*/	1.91	,	2.07	\ /*
	*/	1.90	,	2.05	\ /*
	*/	1.88	,	2.03	\ /*
	*/	1.87	,	2.01	\ /*
	*/	1.85	,	1.99	\ /*
	*/	1.84	,	1.98	\ /*
	*/	1.82	,	1.96	\ /*
	*/	1.81	,	1.94	\ /*
	*/	1.80	,	1.93	\ /*
	*/	1.79	,	1.91	\ /*
	*/	1.78	,	1.90	\ /*
	*/	1.76	,	1.88	\ /*
	*/	1.75	,	1.87	\ /*
	*/	1.74	,	1.86	\ /*
	*/	1.73	,	1.85	\ /*
	*/	1.73	,	1.83	\ /*
	*/	1.72	,	1.82	\ /*
	*/	1.71	,	1.81	\ /*
	*/	1.70	,	1.80	\ /*
	*/	1.69	,	1.79	\ /*
	*/	1.68	,	1.78	\ /*
	*/	1.68	,	1.77	\ /*
	*/	1.67	,	1.76	\ /*
	*/	1.66	,	1.75	\ /*
	*/	1.65	,	1.74	\ /*
	*/	1.65	,	1.74	\ /*
	*/	1.64	,	1.73	\ /*
	*/	1.63	,	1.72	\ /*
	*/	1.63	,	1.71	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.61	,	1.69	\ /*
	*/	1.60	,	1.68	\ /*
	*/	1.60	,	1.68	\ /*
	*/	1.59	,	1.67	\ /*
	*/	1.59	,	1.66	\ /*
	*/	1.58	,	1.66	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.57	,	1.64	\ /*
	*/	1.57	,	1.64	\ /*
	*/	1.56	,	1.63	\ /*
	*/	1.56	,	1.63	\ /*
	*/	1.55	,	1.62	\ /*
	*/	1.55	,	1.62	\ /*
	*/	1.54	,	1.61	\ /*
	*/	1.54	,	1.61	\ /*
	*/	1.53	,	1.60	\ /*
	*/	1.53	,	1.60	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.52	,	1.59	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.51	,	1.58	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.50	,	1.57	\ /*
	*/	1.50	,	1.57	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.49	,	1.56	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.48	,	1.55	\ /*
	*/	1.48	,	1.54	\ /*
	*/	1.47	,	1.54	\ /*
	*/	1.47	,	1.54	\ /*
	*/	1.47	,	1.53	\ /*
	*/	1.46	,	1.53	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
	
	if "`type'"=="fullmax10" {
		matrix input `temp' = ( /*
	*/	19.40	,	.	\ /*
	*/	10.14	,	11.92	\ /*
	*/	7.18	,	8.39	\ /*
	*/	5.72	,	6.64	\ /*
	*/	4.85	,	5.60	\ /*
	*/	4.27	,	4.90	\ /*
	*/	3.86	,	4.40	\ /*
	*/	3.55	,	4.03	\ /*
	*/	3.31	,	3.73	\ /*
	*/	3.12	,	3.50	\ /*
	*/	2.96	,	3.31	\ /*
	*/	2.83	,	3.15	\ /*
	*/	2.71	,	3.01	\ /*
	*/	2.62	,	2.89	\ /*
	*/	2.53	,	2.79	\ /*
	*/	2.46	,	2.70	\ /*
	*/	2.39	,	2.62	\ /*
	*/	2.33	,	2.55	\ /*
	*/	2.28	,	2.49	\ /*
	*/	2.23	,	2.43	\ /*
	*/	2.19	,	2.38	\ /*
	*/	2.15	,	2.33	\ /*
	*/	2.11	,	2.29	\ /*
	*/	2.08	,	2.25	\ /*
	*/	2.05	,	2.21	\ /*
	*/	2.02	,	2.18	\ /*
	*/	1.99	,	2.14	\ /*
	*/	1.97	,	2.11	\ /*
	*/	1.94	,	2.08	\ /*
	*/	1.92	,	2.06	\ /*
	*/	1.90	,	2.03	\ /*
	*/	1.88	,	2.01	\ /*
	*/	1.86	,	1.99	\ /*
	*/	1.85	,	1.97	\ /*
	*/	1.83	,	1.95	\ /*
	*/	1.81	,	1.93	\ /*
	*/	1.80	,	1.91	\ /*
	*/	1.79	,	1.89	\ /*
	*/	1.77	,	1.88	\ /*
	*/	1.76	,	1.86	\ /*
	*/	1.75	,	1.85	\ /*
	*/	1.74	,	1.83	\ /*
	*/	1.72	,	1.82	\ /*
	*/	1.71	,	1.81	\ /*
	*/	1.70	,	1.80	\ /*
	*/	1.69	,	1.78	\ /*
	*/	1.68	,	1.77	\ /*
	*/	1.67	,	1.76	\ /*
	*/	1.66	,	1.75	\ /*
	*/	1.66	,	1.74	\ /*
	*/	1.65	,	1.73	\ /*
	*/	1.64	,	1.72	\ /*
	*/	1.63	,	1.71	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.62	,	1.69	\ /*
	*/	1.61	,	1.69	\ /*
	*/	1.60	,	1.68	\ /*
	*/	1.60	,	1.67	\ /*
	*/	1.59	,	1.66	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.57	,	1.64	\ /*
	*/	1.57	,	1.63	\ /*
	*/	1.56	,	1.63	\ /*
	*/	1.55	,	1.62	\ /*
	*/	1.55	,	1.61	\ /*
	*/	1.54	,	1.61	\ /*
	*/	1.54	,	1.60	\ /*
	*/	1.53	,	1.60	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.52	,	1.59	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.55	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.48	,	1.54	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.47	,	1.53	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.46	,	1.52	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.45	,	1.51	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.44	,	1.50	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.42	,	1.48	\ /*
	*/	1.42	,	1.47	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}
	
	if "`type'"=="fullmax20" {
		matrix input `temp' = ( /*
	*/	15.39	,	.	\ /*
	*/	8.16	,	9.41	\ /*
	*/	5.87	,	6.79	\ /*
	*/	4.75	,	5.47	\ /*
	*/	4.08	,	4.66	\ /*
	*/	3.64	,	4.13	\ /*
	*/	3.32	,	3.74	\ /*
	*/	3.08	,	3.45	\ /*
	*/	2.89	,	3.22	\ /*
	*/	2.74	,	3.03	\ /*
	*/	2.62	,	2.88	\ /*
	*/	2.51	,	2.76	\ /*
	*/	2.42	,	2.65	\ /*
	*/	2.35	,	2.56	\ /*
	*/	2.28	,	2.48	\ /*
	*/	2.22	,	2.40	\ /*
	*/	2.17	,	2.34	\ /*
	*/	2.12	,	2.28	\ /*
	*/	2.08	,	2.23	\ /*
	*/	2.04	,	2.19	\ /*
	*/	2.01	,	2.15	\ /*
	*/	1.98	,	2.11	\ /*
	*/	1.95	,	2.07	\ /*
	*/	1.92	,	2.04	\ /*
	*/	1.89	,	2.01	\ /*
	*/	1.87	,	1.98	\ /*
	*/	1.85	,	1.96	\ /*
	*/	1.83	,	1.93	\ /*
	*/	1.81	,	1.91	\ /*
	*/	1.79	,	1.89	\ /*
	*/	1.77	,	1.87	\ /*
	*/	1.76	,	1.85	\ /*
	*/	1.74	,	1.83	\ /*
	*/	1.73	,	1.82	\ /*
	*/	1.72	,	1.80	\ /*
	*/	1.70	,	1.79	\ /*
	*/	1.69	,	1.77	\ /*
	*/	1.68	,	1.76	\ /*
	*/	1.67	,	1.74	\ /*
	*/	1.66	,	1.73	\ /*
	*/	1.65	,	1.72	\ /*
	*/	1.64	,	1.71	\ /*
	*/	1.63	,	1.70	\ /*
	*/	1.62	,	1.69	\ /*
	*/	1.61	,	1.68	\ /*
	*/	1.60	,	1.67	\ /*
	*/	1.59	,	1.66	\ /*
	*/	1.58	,	1.65	\ /*
	*/	1.58	,	1.64	\ /*
	*/	1.57	,	1.63	\ /*
	*/	1.56	,	1.62	\ /*
	*/	1.56	,	1.62	\ /*
	*/	1.55	,	1.61	\ /*
	*/	1.54	,	1.60	\ /*
	*/	1.54	,	1.59	\ /*
	*/	1.53	,	1.59	\ /*
	*/	1.52	,	1.58	\ /*
	*/	1.52	,	1.57	\ /*
	*/	1.51	,	1.57	\ /*
	*/	1.51	,	1.56	\ /*
	*/	1.50	,	1.56	\ /*
	*/	1.50	,	1.55	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.47	,	1.52	\ /*
	*/	1.47	,	1.51	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.46	,	1.51	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.50	\ /*
	*/	1.45	,	1.49	\ /*
	*/	1.44	,	1.49	\ /*
	*/	1.44	,	1.48	\ /*
	*/	1.44	,	1.48	\ /*
	*/	1.43	,	1.48	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.39	,	1.43	\ /*
	*/	1.39	,	1.43	\ /*
	*/	1.39	,	1.43	\ /*
	*/	1.39	,	1.42	\ /*
	*/	1.38	,	1.42	\ /*
	*/	1.38	,	1.42	\ /*
	*/	1.38	,	1.42	\ /*
	*/	1.38	,	1.41	\ /*
	*/	1.37	,	1.41	\ /*
	*/	1.37	,	1.41	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="fullmax30" {
		matrix input `temp' = ( /*
	*/	12.76	,	.	\ /*
	*/	6.97	,	8.01	\ /*
	*/	5.11	,	5.88	\ /*
	*/	4.19	,	4.78	\ /*
	*/	3.64	,	4.12	\ /*
	*/	3.27	,	3.67	\ /*
	*/	3.00	,	3.35	\ /*
	*/	2.80	,	3.10	\ /*
	*/	2.64	,	2.91	\ /*
	*/	2.52	,	2.76	\ /*
	*/	2.41	,	2.63	\ /*
	*/	2.33	,	2.52	\ /*
	*/	2.25	,	2.43	\ /*
	*/	2.19	,	2.35	\ /*
	*/	2.13	,	2.29	\ /*
	*/	2.08	,	2.22	\ /*
	*/	2.04	,	2.17	\ /*
	*/	2.00	,	2.12	\ /*
	*/	1.96	,	2.08	\ /*
	*/	1.93	,	2.04	\ /*
	*/	1.90	,	2.01	\ /*
	*/	1.87	,	1.97	\ /*
	*/	1.84	,	1.94	\ /*
	*/	1.82	,	1.92	\ /*
	*/	1.80	,	1.89	\ /*
	*/	1.78	,	1.87	\ /*
	*/	1.76	,	1.84	\ /*
	*/	1.74	,	1.82	\ /*
	*/	1.73	,	1.80	\ /*
	*/	1.71	,	1.79	\ /*
	*/	1.70	,	1.77	\ /*
	*/	1.68	,	1.75	\ /*
	*/	1.67	,	1.74	\ /*
	*/	1.66	,	1.72	\ /*
	*/	1.64	,	1.71	\ /*
	*/	1.63	,	1.70	\ /*
	*/	1.62	,	1.68	\ /*
	*/	1.61	,	1.67	\ /*
	*/	1.60	,	1.66	\ /*
	*/	1.59	,	1.65	\ /*
	*/	1.58	,	1.64	\ /*
	*/	1.57	,	1.63	\ /*
	*/	1.57	,	1.62	\ /*
	*/	1.56	,	1.61	\ /*
	*/	1.55	,	1.60	\ /*
	*/	1.54	,	1.59	\ /*
	*/	1.54	,	1.59	\ /*
	*/	1.53	,	1.58	\ /*
	*/	1.52	,	1.57	\ /*
	*/	1.52	,	1.56	\ /*
	*/	1.51	,	1.56	\ /*
	*/	1.50	,	1.55	\ /*
	*/	1.50	,	1.54	\ /*
	*/	1.49	,	1.54	\ /*
	*/	1.49	,	1.53	\ /*
	*/	1.48	,	1.53	\ /*
	*/	1.48	,	1.52	\ /*
	*/	1.47	,	1.51	\ /*
	*/	1.47	,	1.51	\ /*
	*/	1.46	,	1.50	\ /*
	*/	1.46	,	1.50	\ /*
	*/	1.45	,	1.49	\ /*
	*/	1.45	,	1.49	\ /*
	*/	1.44	,	1.48	\ /*
	*/	1.44	,	1.48	\ /*
	*/	1.44	,	1.47	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.43	,	1.47	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.42	,	1.46	\ /*
	*/	1.42	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.45	\ /*
	*/	1.41	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.44	\ /*
	*/	1.40	,	1.43	\ /*
	*/	1.39	,	1.43	\ /*
	*/	1.39	,	1.43	\ /*
	*/	1.39	,	1.42	\ /*
	*/	1.39	,	1.42	\ /*
	*/	1.38	,	1.42	\ /*
	*/	1.38	,	1.41	\ /*
	*/	1.38	,	1.41	\ /*
	*/	1.37	,	1.41	\ /*
	*/	1.37	,	1.40	\ /*
	*/	1.37	,	1.40	\ /*
	*/	1.37	,	1.40	\ /*
	*/	1.36	,	1.40	\ /*
	*/	1.36	,	1.39	\ /*
	*/	1.36	,	1.39	\ /*
	*/	1.36	,	1.39	\ /*
	*/	1.36	,	1.38	\ /*
	*/	1.35	,	1.38	\ /*
	*/	1.35	,	1.38	\ /*
	*/	1.35	,	1.38	\ /*
	*/	1.35	,	1.37	\ /*
	*/	1.34	,	1.37	\ /*
	*/	1.34	,	1.37	\ /*
	*/	1.34	,	1.37	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="limlsize10" {
		matrix input `temp' = ( /*
	*/	16.38	,	.	\ /*
	*/	8.68	,	7.03	\ /*
	*/	6.46	,	5.44	\ /*
	*/	5.44	,	4.72	\ /*
	*/	4.84	,	4.32	\ /*
	*/	4.45	,	4.06	\ /*
	*/	4.18	,	3.90	\ /*
	*/	3.97	,	3.78	\ /*
	*/	3.81	,	3.70	\ /*
	*/	3.68	,	3.64	\ /*
	*/	3.58	,	3.60	\ /*
	*/	3.50	,	3.58	\ /*
	*/	3.42	,	3.56	\ /*
	*/	3.36	,	3.55	\ /*
	*/	3.31	,	3.54	\ /*
	*/	3.27	,	3.55	\ /*
	*/	3.24	,	3.55	\ /*
	*/	3.20	,	3.56	\ /*
	*/	3.18	,	3.57	\ /*
	*/	3.21	,	3.58	\ /*
	*/	3.39	,	3.59	\ /*
	*/	3.57	,	3.60	\ /*
	*/	3.68	,	3.62	\ /*
	*/	3.75	,	3.64	\ /*
	*/	3.79	,	3.65	\ /*
	*/	3.82	,	3.67	\ /*
	*/	3.85	,	3.74	\ /*
	*/	3.86	,	3.87	\ /*
	*/	3.87	,	4.02	\ /*
	*/	3.88	,	4.12	\ /*
	*/	3.89	,	4.19	\ /*
	*/	3.89	,	4.24	\ /*
	*/	3.90	,	4.27	\ /*
	*/	3.90	,	4.31	\ /*
	*/	3.90	,	4.33	\ /*
	*/	3.90	,	4.36	\ /*
	*/	3.90	,	4.38	\ /*
	*/	3.90	,	4.39	\ /*
	*/	3.90	,	4.41	\ /*
	*/	3.90	,	4.43	\ /*
	*/	3.90	,	4.44	\ /*
	*/	3.90	,	4.45	\ /*
	*/	3.90	,	4.47	\ /*
	*/	3.90	,	4.48	\ /*
	*/	3.90	,	4.49	\ /*
	*/	3.90	,	4.50	\ /*
	*/	3.90	,	4.51	\ /*
	*/	3.90	,	4.52	\ /*
	*/	3.90	,	4.53	\ /*
	*/	3.90	,	4.54	\ /*
	*/	3.90	,	4.55	\ /*
	*/	3.90	,	4.56	\ /*
	*/	3.90	,	4.56	\ /*
	*/	3.90	,	4.57	\ /*
	*/	3.90	,	4.58	\ /*
	*/	3.90	,	4.59	\ /*
	*/	3.90	,	4.59	\ /*
	*/	3.90	,	4.60	\ /*
	*/	3.90	,	4.61	\ /*
	*/	3.90	,	4.61	\ /*
	*/	3.90	,	4.62	\ /*
	*/	3.90	,	4.62	\ /*
	*/	3.90	,	4.63	\ /*
	*/	3.90	,	4.63	\ /*
	*/	3.89	,	4.64	\ /*
	*/	3.89	,	4.64	\ /*
	*/	3.89	,	4.64	\ /*
	*/	3.89	,	4.65	\ /*
	*/	3.89	,	4.65	\ /*
	*/	3.89	,	4.65	\ /*
	*/	3.89	,	4.66	\ /*
	*/	3.89	,	4.66	\ /*
	*/	3.89	,	4.66	\ /*
	*/	3.89	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.88	,	4.66	\ /*
	*/	3.87	,	4.66	\ /*
	*/	3.87	,	4.66	\ /*
	*/	3.87	,	4.66	\ /*
	*/	3.87	,	4.66	\ /*
	*/	3.87	,	4.66	\ /*
	*/	3.86	,	4.65	\ /*
	*/	3.86	,	4.65	\ /*
	*/	3.86	,	4.65	\ /*
	*/	3.86	,	4.64	\ /*
	*/	3.85	,	4.64	\ /*
	*/	3.85	,	4.64	\ /*
	*/	3.85	,	4.63	\ /*
	*/	3.85	,	4.63	\ /*
	*/	3.84	,	4.62	\ /*
	*/	3.84	,	4.62	\ /*
	*/	3.84	,	4.61	\ /*
	*/	3.84	,	4.60	\ /*
	*/	3.83	,	4.60	\ /*
	*/	3.83	,	4.59	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="limlsize15" {
		matrix input `temp' = ( /*
	*/	8.96	,	.	\ /*
	*/	5.33	,	4.58	\ /*
	*/	4.36	,	3.81	\ /*
	*/	3.87	,	3.39	\ /*
	*/	3.56	,	3.13	\ /*
	*/	3.34	,	2.95	\ /*
	*/	3.18	,	2.83	\ /*
	*/	3.04	,	2.73	\ /*
	*/	2.93	,	2.66	\ /*
	*/	2.84	,	2.60	\ /*
	*/	2.76	,	2.55	\ /*
	*/	2.69	,	2.52	\ /*
	*/	2.63	,	2.48	\ /*
	*/	2.57	,	2.46	\ /*
	*/	2.52	,	2.44	\ /*
	*/	2.48	,	2.42	\ /*
	*/	2.44	,	2.41	\ /*
	*/	2.41	,	2.40	\ /*
	*/	2.37	,	2.39	\ /*
	*/	2.34	,	2.38	\ /*
	*/	2.32	,	2.38	\ /*
	*/	2.29	,	2.37	\ /*
	*/	2.27	,	2.37	\ /*
	*/	2.25	,	2.37	\ /*
	*/	2.24	,	2.37	\ /*
	*/	2.22	,	2.38	\ /*
	*/	2.21	,	2.38	\ /*
	*/	2.20	,	2.38	\ /*
	*/	2.19	,	2.39	\ /*
	*/	2.18	,	2.39	\ /*
	*/	2.19	,	2.40	\ /*
	*/	2.22	,	2.41	\ /*
	*/	2.33	,	2.42	\ /*
	*/	2.40	,	2.42	\ /*
	*/	2.45	,	2.43	\ /*
	*/	2.48	,	2.44	\ /*
	*/	2.50	,	2.45	\ /*
	*/	2.52	,	2.54	\ /*
	*/	2.53	,	2.55	\ /*
	*/	2.54	,	2.66	\ /*
	*/	2.55	,	2.73	\ /*
	*/	2.56	,	2.78	\ /*
	*/	2.57	,	2.82	\ /*
	*/	2.57	,	2.85	\ /*
	*/	2.58	,	2.87	\ /*
	*/	2.58	,	2.89	\ /*
	*/	2.58	,	2.91	\ /*
	*/	2.59	,	2.92	\ /*
	*/	2.59	,	2.93	\ /*
	*/	2.59	,	2.94	\ /*
	*/	2.59	,	2.95	\ /*
	*/	2.59	,	2.96	\ /*
	*/	2.60	,	2.97	\ /*
	*/	2.60	,	2.98	\ /*
	*/	2.60	,	2.98	\ /*
	*/	2.60	,	2.99	\ /*
	*/	2.60	,	2.99	\ /*
	*/	2.60	,	3.00	\ /*
	*/	2.60	,	3.00	\ /*
	*/	2.60	,	3.01	\ /*
	*/	2.60	,	3.01	\ /*
	*/	2.60	,	3.02	\ /*
	*/	2.61	,	3.02	\ /*
	*/	2.61	,	3.02	\ /*
	*/	2.61	,	3.03	\ /*
	*/	2.61	,	3.03	\ /*
	*/	2.61	,	3.03	\ /*
	*/	2.61	,	3.03	\ /*
	*/	2.61	,	3.04	\ /*
	*/	2.61	,	3.04	\ /*
	*/	2.61	,	3.04	\ /*
	*/	2.60	,	3.04	\ /*
	*/	2.60	,	3.04	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.60	,	3.05	\ /*
	*/	2.59	,	3.05	\ /*
	*/	2.59	,	3.05	\ /*
	*/	2.59	,	3.05	\ /*
	*/	2.59	,	3.05	\ /*
	*/	2.59	,	3.05	\ /*
	*/	2.59	,	3.04	\ /*
	*/	2.58	,	3.04	\ /*
	*/	2.58	,	3.04	\ /*
	*/	2.58	,	3.04	\ /*
	*/	2.58	,	3.04	\ /*
	*/	2.58	,	3.03	\ /*
	*/	2.57	,	3.03	\ /*
	*/	2.57	,	3.03	\ /*
	*/	2.57	,	3.03	\ /*
	*/	2.57	,	3.02	\ /*
	*/	2.56	,	3.02	\ /*
	*/	2.56	,	3.02	)
	
		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="limlsize20" {
		matrix input `temp' = ( /*
	*/	6.66	,	.	\ /*
	*/	4.42	,	3.95	\ /*
	*/	3.69	,	3.32	\ /*
	*/	3.30	,	2.99	\ /*
	*/	3.05	,	2.78	\ /*
	*/	2.87	,	2.63	\ /*
	*/	2.73	,	2.52	\ /*
	*/	2.63	,	2.43	\ /*
	*/	2.54	,	2.36	\ /*
	*/	2.46	,	2.30	\ /*
	*/	2.40	,	2.25	\ /*
	*/	2.34	,	2.21	\ /*
	*/	2.29	,	2.17	\ /*
	*/	2.25	,	2.14	\ /*
	*/	2.21	,	2.11	\ /*
	*/	2.18	,	2.09	\ /*
	*/	2.14	,	2.07	\ /*
	*/	2.11	,	2.05	\ /*
	*/	2.09	,	2.03	\ /*
	*/	2.06	,	2.02	\ /*
	*/	2.04	,	2.01	\ /*
	*/	2.02	,	1.99	\ /*
	*/	2.00	,	1.98	\ /*
	*/	1.98	,	1.98	\ /*
	*/	1.96	,	1.97	\ /*
	*/	1.95	,	1.96	\ /*
	*/	1.93	,	1.96	\ /*
	*/	1.92	,	1.95	\ /*
	*/	1.90	,	1.95	\ /*
	*/	1.89	,	1.95	\ /*
	*/	1.88	,	1.94	\ /*
	*/	1.87	,	1.94	\ /*
	*/	1.86	,	1.94	\ /*
	*/	1.85	,	1.94	\ /*
	*/	1.84	,	1.94	\ /*
	*/	1.83	,	1.94	\ /*
	*/	1.82	,	1.94	\ /*
	*/	1.81	,	1.95	\ /*
	*/	1.81	,	1.95	\ /*
	*/	1.80	,	1.95	\ /*
	*/	1.79	,	1.95	\ /*
	*/	1.79	,	1.96	\ /*
	*/	1.78	,	1.96	\ /*
	*/	1.78	,	1.97	\ /*
	*/	1.80	,	1.97	\ /*
	*/	1.87	,	1.98	\ /*
	*/	1.92	,	1.98	\ /*
	*/	1.95	,	1.99	\ /*
	*/	1.97	,	2.00	\ /*
	*/	1.99	,	2.00	\ /*
	*/	2.00	,	2.01	\ /*
	*/	2.01	,	2.09	\ /*
	*/	2.02	,	2.11	\ /*
	*/	2.03	,	2.18	\ /*
	*/	2.04	,	2.23	\ /*
	*/	2.04	,	2.27	\ /*
	*/	2.05	,	2.29	\ /*
	*/	2.05	,	2.31	\ /*
	*/	2.06	,	2.33	\ /*
	*/	2.06	,	2.34	\ /*
	*/	2.07	,	2.35	\ /*
	*/	2.07	,	2.36	\ /*
	*/	2.07	,	2.37	\ /*
	*/	2.08	,	2.38	\ /*
	*/	2.08	,	2.39	\ /*
	*/	2.08	,	2.39	\ /*
	*/	2.08	,	2.40	\ /*
	*/	2.09	,	2.40	\ /*
	*/	2.09	,	2.41	\ /*
	*/	2.09	,	2.41	\ /*
	*/	2.09	,	2.41	\ /*
	*/	2.09	,	2.42	\ /*
	*/	2.09	,	2.42	\ /*
	*/	2.09	,	2.42	\ /*
	*/	2.09	,	2.43	\ /*
	*/	2.10	,	2.43	\ /*
	*/	2.10	,	2.43	\ /*
	*/	2.10	,	2.43	\ /*
	*/	2.10	,	2.44	\ /*
	*/	2.10	,	2.44	\ /*
	*/	2.10	,	2.44	\ /*
	*/	2.10	,	2.44	\ /*
	*/	2.10	,	2.44	\ /*
	*/	2.09	,	2.44	\ /*
	*/	2.09	,	2.44	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.09	,	2.45	\ /*
	*/	2.08	,	2.45	\ /*
	*/	2.08	,	2.45	\ /*
	*/	2.08	,	2.45	\ /*
	*/	2.08	,	2.45	\ /*
	*/	2.08	,	2.45	\ /*
	*/	2.07	,	2.44	\ /*
	*/	2.07	,	2.44	\ /*
	*/	2.07	,	2.44	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}

	if "`type'"=="limlsize25" {
		matrix input `temp' = ( /*
	*/	5.53	,	.	\ /*
	*/	3.92	,	3.63	\ /*
	*/	3.32	,	3.09	\ /*
	*/	2.98	,	2.79	\ /*
	*/	2.77	,	2.60	\ /*
	*/	2.61	,	2.46	\ /*
	*/	2.49	,	2.35	\ /*
	*/	2.39	,	2.27	\ /*
	*/	2.32	,	2.20	\ /*
	*/	2.25	,	2.14	\ /*
	*/	2.19	,	2.09	\ /*
	*/	2.14	,	2.05	\ /*
	*/	2.10	,	2.02	\ /*
	*/	2.06	,	1.99	\ /*
	*/	2.03	,	1.96	\ /*
	*/	2.00	,	1.93	\ /*
	*/	1.97	,	1.91	\ /*
	*/	1.94	,	1.89	\ /*
	*/	1.92	,	1.87	\ /*
	*/	1.90	,	1.86	\ /*
	*/	1.88	,	1.84	\ /*
	*/	1.86	,	1.83	\ /*
	*/	1.84	,	1.81	\ /*
	*/	1.83	,	1.80	\ /*
	*/	1.81	,	1.79	\ /*
	*/	1.80	,	1.78	\ /*
	*/	1.78	,	1.77	\ /*
	*/	1.77	,	1.77	\ /*
	*/	1.76	,	1.76	\ /*
	*/	1.75	,	1.75	\ /*
	*/	1.74	,	1.75	\ /*
	*/	1.73	,	1.74	\ /*
	*/	1.72	,	1.73	\ /*
	*/	1.71	,	1.73	\ /*
	*/	1.70	,	1.73	\ /*
	*/	1.69	,	1.72	\ /*
	*/	1.68	,	1.72	\ /*
	*/	1.67	,	1.71	\ /*
	*/	1.67	,	1.71	\ /*
	*/	1.66	,	1.71	\ /*
	*/	1.65	,	1.71	\ /*
	*/	1.65	,	1.71	\ /*
	*/	1.64	,	1.70	\ /*
	*/	1.63	,	1.70	\ /*
	*/	1.63	,	1.70	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.62	,	1.70	\ /*
	*/	1.61	,	1.70	\ /*
	*/	1.61	,	1.70	\ /*
	*/	1.61	,	1.70	\ /*
	*/	1.60	,	1.70	\ /*
	*/	1.60	,	1.70	\ /*
	*/	1.59	,	1.70	\ /*
	*/	1.59	,	1.70	\ /*
	*/	1.59	,	1.70	\ /*
	*/	1.58	,	1.70	\ /*
	*/	1.58	,	1.71	\ /*
	*/	1.58	,	1.71	\ /*
	*/	1.57	,	1.71	\ /*
	*/	1.59	,	1.71	\ /*
	*/	1.60	,	1.71	\ /*
	*/	1.63	,	1.72	\ /*
	*/	1.65	,	1.72	\ /*
	*/	1.67	,	1.72	\ /*
	*/	1.69	,	1.72	\ /*
	*/	1.70	,	1.76	\ /*
	*/	1.71	,	1.81	\ /*
	*/	1.72	,	1.87	\ /*
	*/	1.73	,	1.91	\ /*
	*/	1.74	,	1.94	\ /*
	*/	1.74	,	1.96	\ /*
	*/	1.75	,	1.98	\ /*
	*/	1.75	,	1.99	\ /*
	*/	1.76	,	2.01	\ /*
	*/	1.76	,	2.02	\ /*
	*/	1.77	,	2.03	\ /*
	*/	1.77	,	2.04	\ /*
	*/	1.78	,	2.04	\ /*
	*/	1.78	,	2.05	\ /*
	*/	1.78	,	2.06	\ /*
	*/	1.79	,	2.06	\ /*
	*/	1.79	,	2.07	\ /*
	*/	1.79	,	2.07	\ /*
	*/	1.79	,	2.08	\ /*
	*/	1.80	,	2.08	\ /*
	*/	1.80	,	2.09	\ /*
	*/	1.80	,	2.09	\ /*
	*/	1.80	,	2.09	\ /*
	*/	1.80	,	2.09	\ /*
	*/	1.80	,	2.10	\ /*
	*/	1.80	,	2.10	\ /*
	*/	1.80	,	2.10	\ /*
	*/	1.80	,	2.10	\ /*
	*/	1.80	,	2.10	\ /*
	*/	1.80	,	2.11	\ /*
	*/	1.80	,	2.11	\ /*
	*/	1.80	,	2.11	\ /*
	*/	1.80	,	2.11	\ /*
	*/	1.80	,	2.11	\ /*
	*/	1.80	,	2.11	)

		if `k2'<=100 & `nendog'<=2 {
			scalar `cv'=`temp'[`k2',`nendog']
		}
	}


	return scalar cv=`cv'
end

// capt prog drop abw
// abw wants a varlist of [ eps | Z | touse]
// where Z includes all instruments, included and excluded, with constant if
// present as the last column; eps are a suitable set of residuals; and touse
// marks the observations in the data matrix used to generate the residuals
// (e.g. e(sample) of the appropriate model).
// The Noconstant option indicates that no constant term exists in the Z matrix.
// kern is the name of the HAC kernel. -ivregress- only provides definitions
// for Bartlett (default), Parzen, quadratic spectral.

// returns the optimal bandwidth as local abw

// abw 1.0.1  CFB 30jun2007
// 1.0.1 : redefine kernel names (3 instances) to match ivreg2

prog def abw, rclass
	version 9.2
	syntax varlist(ts), [ NOConstant Kernel(string)]
// validate kernel 
	if "`kernel'" == "" {
		local kernel = "Bartlett"
	}
	if !inlist("`kernel'","Bartlett","Parzen","Quadratic spectral") {
		di as err "Error: kernel `kernel' not compatible with bw(auto)"
		return scalar abw = 1
		return local bwchoice "Kernel `kernel' not compatible with bw(auto); bw=1 (default)"
		exit
	}
	else {
// set constant
		local cons 1 
		if "`noconstant'" != "" {
			local cons 0
		}
// deal with ts ops 
		tsrevar `varlist'
		local varlist1 `r(varlist)'

		mata: abw("`varlist1'",`cons',"`kernel'")
		return scalar abw = `abw'
		return local bwchoice "Automatic bw selection according to Newey-West (1994)"
	}
end

mata:
void abw	(string scalar Zulist,				
			real scalar cons,
			string scalar kernel
			)
{
		string rowvector Zunames, tov
		string scalar v, v2
		real matrix uZ
		real rowvector h
		real scalar lenzu, abw
						
// access the Stata variables in Zulist, honoring touse stored as last column
        Zunames = tokens(Zulist)
        lenzu=cols(Zunames)-1
        v = Zunames[|1\lenzu|]
		v2 = Zunames[lenzu+1]
        st_view(uZ,.,v,v2)
      
// assume constant in last col of uZ if it exists
// account for eps as the first column of uZ
		if (cons) {
			nrows1=cols(uZ)-2
			nrows2=1
		}
		else {
			nrows1=cols(uZ)-1
			nrows2=0
		}
// [R] ivregress p.42: referencing Newey-West 1994 REStud 61(4):631-653
// define h indicator rowvector
 		h = J(nrows1,1,1) \ J(nrows2,1,0)
	
// calc mstar per p.43
// Hannan (1971, 296) & Priestley (1981, 58) per Newey-West p. 633
// corrected per Alistair Hall msg to Brian Poi 17jul2008
		T = rows(uZ)
		oneT = 1/T
		expo = 2/9
		q = 1
//		cgamma = 1.4117
		cgamma = 1.1447
		if(kernel == "Parzen") { 
			expo = 4/25
			q = 2
			cgamma = 2.6614
		}
		if(kernel == "Quadratic spectral") {
			expo = 2/25
			q = 2
			cgamma = 1.3221
		}
// per Newey-West p.639, Anderson (1971), Priestley (1981) may provide
// guidance on setting expo for other kernels
		mstar = trunc(20 *(T/100)^expo)

// calc uZ matrix
		u = uZ[.,1]
		Z = uZ[|1,2 \.,.|]
		
// calc f vector: (u_i Z_i) * h
		f =  (u :* Z) * h

// calc sigmahat vector
		sigmahat = J(mstar+1,1,oneT)
		for(j=0;j<=mstar;j++) {
			for(i=j+1;i<=T;i++) {
			sigmahat[j+1] = sigmahat[j+1] + f[i]*f[i-j]
			}
		}
		
// calc shat(q), shat(0)
		shatq = 0
		shat0 = sigmahat[1]
		for(j=1;j<=mstar;j++) {
			shatq = shatq + 2 * sigmahat[j+1] * j^q
			shat0 = shat0 + 2 * sigmahat[j+1]
		}

// calc gammahat
		expon = 1/(2*q+1)
		gammahat = cgamma*( (shatq/shat0)^2 )^expon
		m = gammahat * T^expon

// calc opt lag
		if(kernel == "Bartlett" | kernel == "Parzen") {
			optlag = min((trunc(m),mstar))
		}
		else if(kernel == "Quadratic spectral") {
			optlag = min((m,mstar))
		}
		
// if optlag is the optimal lag to be used, we need to add one to 
// specify bandwidth in ivreg2 terms
		abw = optlag + 1
		st_local("abw",strofreal(abw))
}
end


*************************************** START ****************************************
********************************* livreg2.mlib CODE **********************************
* Code from:
* livreg2 1.1.07  13july2014
* authors cfb & mes
* compiled in Stata 9.2
* Mata library for ranktest.
* Used by later versions of ivreg2 but NOT by ivreg29 - only by ranktest here.
* Introduced with ivreg2 v 3.1.01 and ranktest v 1.3.01.
* Imported into ivreg29 so that ivreg29 is free-standing.
* See end of file for version notes.

version 9.2
mata:

// ********* struct ms_ivreg29_vcvorthog - shared by ivreg2 and ranktest ******************* //
struct ms_ivreg29_vcvorthog {
	string scalar	ename, Znames, touse, weight, wvarname
	string scalar	robust, clustvarname, clustvarname2, clustvarname3, kernel
	string scalar	sw, psd, ivarname, tvarname, tindexname
	real scalar		wf, N, bw, tdelta, dofminus
	real matrix		ZZ
	pointer matrix	e
	pointer matrix	Z
	pointer matrix	wvar
}

// ********* s_ivreg29_vkernel - shared by ivreg2 and ranktest ******************* //
// Program checks whether kernel and bw choices are valid.
// s_ivreg29_vkernel is called from Stata.
// Arguments are the kernel name (req), bandwidth (req) and ivar name (opt).
// All 3 are strings.
// Returns results in r() macros.
// r(kernel) - name of kernel (string)
// r(bw) - bandwidth (scalar)

void s_ivreg29_vkernel(	string scalar kernel,
			string scalar bwstring,
			string scalar ivar
				)
{

// Check bandwidth
	if (bwstring=="auto") {
		bw=-1
	}
	else {
		bw=strtoreal(bwstring)
		if (bw==.) {
			printf("{err}bandwidth option bw() required for HAC-robust estimation\n")
			exit(102)
		}
		if (bw<=0) {
			printf("{err}invalid bandwidth in option bw() - must be real > 0\n")
			exit(198)
		}
	}
	
// Check ivar
	if (bwstring=="auto" & ivar~="") {
			printf("{err}Automatic bandwidth selection not available for panel data\n")
			exit(198)
	}

// Check kernel
// Valid kernel list is abbrev, full name, whether special case if bw=1
// First in list is default kernel = Barlett
	vklist = 	(		("", "bartlett", "0")
				\	("bar", "bartlett", "0")
				\	("bartlett", "bartlett", "0")
				\	("par", "parzen", "0")
				\	("parzen", "parzen", "0")
				\	("tru", "truncated", "1")
				\	("truncated", "truncated", "1")
				\	("thann", "tukey-hanning", "0")
				\	("tukey-hanning", "tukey-hanning", "0")
				\	("thamm", "tukey-hamming", "0")
				\	("tukey-hamming", "tukey-hamming", "0")
				\	("qua", "quadratic spectral", "1")
				\	("qs", "quadratic spectral", "1")
				\	("quadratic-spectral", "quadratic spectral", "1")
				\	("quadratic spectral", "quadratic spectral", "1")
				\	("dan", "danielle", "1")
				\	("danielle", "danielle", "1")
				\	("ten", "tent", "1")
				\	("tent", "tent", "1")
			)
	kname=strltrim(strlower(kernel))
	pos = (vklist[.,1] :== kname)

// Exit with error if not in list
	if (sum(pos)==0) {
		printf("{err}invalid kernel\n")
		exit(198)
		}

	vkname=strproper(select(vklist[.,2],pos))
	st_global("r(kernel)", vkname)
	st_numscalar("r(bw)",bw)

// Warn if kernel is type where bw=1 means no lags are used
	if (bw==1 & select(vklist[.,3],pos)=="0") {
		printf("{result}Note: kernel=%s", vkname)
		printf("{result} and bw=1 implies zero lags used.  Standard errors and\n")
		printf("{result}      test statistics are not autocorrelation-consistent.\n")
	}
}  // end of program s_ivreg29_vkernel

// ********* m_ivreg29_omega - shared by ivreg2 and ranktest ********************* //

// NB: ivreg2 always calls m_ivreg29_omega with e as column vector, i.e., K=1      //
//     ranktest can call m_ivreg29_omega with e as matrix, i.e., K>=1              //

real matrix m_ivreg29_omega(struct ms_ivreg29_vcvorthog scalar vcvo) 
{
	if (vcvo.clustvarname~="") {
		st_view(clustvar, ., vcvo.clustvarname, vcvo.touse)
		info = panelsetup(clustvar, 1)
		N_clust=rows(info)
		if (vcvo.clustvarname2~="") {
			st_view(clustvar2, ., vcvo.clustvarname2, vcvo.touse)
			if (vcvo.kernel=="") {
				st_view(clustvar3, ., vcvo.clustvarname3, vcvo.touse) // needed only if not panel tsset
			}
		}
	}

	if (vcvo.kernel~="") {
		st_view(t,    ., st_tsrevar(vcvo.tvarname),  vcvo.touse)
		T=max(t)-min(t)+1
	}

	if ((vcvo.kernel=="Bartlett") | (vcvo.kernel=="Parzen") | (vcvo.kernel=="Truncated") ///
		 | (vcvo.kernel=="Tukey-Hanning")| (vcvo.kernel=="Tukey-Hamming")) {
		window="lag"
	}
	else if ((vcvo.kernel=="Quadratic Spectral") | (vcvo.kernel=="Danielle") | (vcvo.kernel=="Tent")) {
		window="spectral"
	}
	else if (vcvo.kernel~="") {
// Should never reach this point
printf("\n{error:Error: invalid kernel}\n")
		exit(error(3351))
	}

	L=cols(*vcvo.Z)
	K=cols(*vcvo.e)		// ivreg2 always calls with K=1; ranktest may call with K>=1.

// Covariance matrices
// shat * 1/N is same as estimated S matrix of orthog conditions

// Block for homoskedastic and AC.  dof correction if any incorporated into sigma estimates.
	if ((vcvo.robust=="") & (vcvo.clustvarname=="")) {
// ZZ is already calculated as an external
		ee = quadcross(*vcvo.e, vcvo.wf*(*vcvo.wvar), *vcvo.e)
		sigma2=ee/(vcvo.N-vcvo.dofminus)
		shat=sigma2#vcvo.ZZ
		if (vcvo.kernel~="") {
			if (window=="spectral") {
				TAU=T/vcvo.tdelta-1
			}
			else {
				TAU=vcvo.bw
			}
			tnow=st_data(., vcvo.tindexname)
			for (tau=1; tau<=TAU; tau++) {
				kw = m_ivreg29_calckw(tau, vcvo.bw, vcvo.kernel)
				if (kw~=0) {						// zero weight possible with some kernels
													// save an unnecessary loop if kw=0
													// remember, kw<0 possible with some kernels!
					lstau = "L"+strofreal(tau)
					tlag=st_data(., lstau+"."+vcvo.tindexname)
					tmatrix = tnow, tlag
					svar=(tnow:<.):*(tlag:<.)		// multiply column vectors of 1s and 0s
					tmatrix=select(tmatrix,svar)	// to get intersection, and replace tmatrix
// if no lags exist, tmatrix has zero rows.
					if (rows(tmatrix)>0) {
// col 1 of tmatrix has row numbers of all rows of data with this time period that have a corresponding lag
// col 2 of tmatrix has row numbers of all rows of data with lag tau that have a corresponding ob this time period.
// Should never happen that fweights or iweights make it here,
// but if they did the next line would be sqrt(wvari)*sqrt(wvari1) [with no wf since not needed for fw or iw]
						wv = (*vcvo.wvar)[tmatrix[.,1]]		///
									:* (*vcvo.wvar)[tmatrix[.,2]]*(vcvo.wf^2)	// inner weighting matrix for quadcross
						sigmahat = quadcross((*vcvo.e)[tmatrix[.,1],.],   wv ,(*vcvo.e)[tmatrix[.,2],.])	///
									/ (vcvo.N-vcvo.dofminus)					// large dof correction
						ZZhat    = quadcross((*vcvo.Z)[tmatrix[.,1],.], wv, (*vcvo.Z)[tmatrix[.,2],.])
						ghat = sigmahat#ZZhat
						shat=shat+kw*(ghat+ghat')
					}
				}	// end non-zero kernel weight block
			}	// end tau loop
		}  // end kernel code
// Note large dof correction (if there is one) has already been incorporated
	shat=shat/vcvo.N
	}  // end homoskedastic, AC code

// Block for robust HC and HAC but not Stock-Watson and single clustering.
// Need to enter for double-clustering if one cluster is time.
	if ( (vcvo.robust~="") & (vcvo.sw=="") & ((vcvo.clustvarname=="")		///
			| ((vcvo.clustvarname2~="") & (vcvo.kernel~="")))  ) {
		if (K==1) {										// simple/fast where e is a column vector
			if ((vcvo.weight=="fweight") | (vcvo.weight=="iweight")) {
				wv = (*vcvo.e:^2) :* *vcvo.wvar
			}
			else {
				wv = (*vcvo.e :* *vcvo.wvar * vcvo.wf):^2		// wf needed for aweights and pweights
			}
			shat=quadcross(*vcvo.Z, wv, *vcvo.Z)		// basic Eicker-Huber-White-sandwich-robust vce
		}
		else {											// e is a matrix so must loop
			shat=J(L*K,L*K,0)
			for (i=1; i<=rows(*vcvo.e); i++) {
				eZi=((*vcvo.e)[i,.])#((*vcvo.Z)[i,.])
				if ((vcvo.weight=="fweight") | (vcvo.weight=="iweight")) {
// wvar is a column vector. wf not needed for fw and iw (=1 by dfn so redundant).
					shat=shat+quadcross(eZi,eZi)*((*vcvo.wvar)[i])
				}
				else {
					shat=shat+quadcross(eZi,eZi)*((*vcvo.wvar)[i] * vcvo.wf)^2	//  **** ADDED *vcvo.wf
				}
			}
		}
		if (vcvo.kernel~="") {
// Spectral windows require looping through all T-1 autocovariances
			if (window=="spectral") {
				TAU=T/vcvo.tdelta-1
			}
			else {
				TAU=vcvo.bw
			}
			tnow=st_data(., vcvo.tindexname)
			for (tau=1; tau<=TAU; tau++) {
				kw = m_ivreg29_calckw(tau, vcvo.bw, vcvo.kernel)
				if (kw~=0) {						// zero weight possible with some kernels
													// save an unnecessary loop if kw=0
													// remember, kw<0 possible with some kernels!
					lstau = "L"+strofreal(tau)
					tlag=st_data(., lstau+"."+vcvo.tindexname)
					tmatrix = tnow, tlag
					svar=(tnow:<.):*(tlag:<.)		// multiply column vectors of 1s and 0s
					tmatrix=select(tmatrix,svar)	// to get intersection, and replace tmatrix

// col 1 of tmatrix has row numbers of all rows of data with this time period that have a corresponding lag
// col 2 of tmatrix has row numbers of all rows of data with lag tau that have a corresponding ob this time period.
// if no lags exist, tmatrix has zero rows
					if (rows(tmatrix)>0) {
						if (K==1) {										// simple/fast where e is a column vector
// wv is inner weighting matrix for quadcross
							wv   = (*vcvo.e)[tmatrix[.,1]] :* (*vcvo.e)[tmatrix[.,2]]		///
								:* (*vcvo.wvar)[tmatrix[.,1]] :* (*vcvo.wvar)[tmatrix[.,2]] * (vcvo.wf^2)
							ghat = quadcross((*vcvo.Z)[tmatrix[.,1],.], wv, (*vcvo.Z)[tmatrix[.,2],.])
						}
						else {										// e is a matrix so must loop
							ghat=J(L*K,L*K,0)
							for (i=1; i<=rows(tmatrix); i++) {
								wvari =(*vcvo.wvar)[tmatrix[i,1]]
								wvari1=(*vcvo.wvar)[tmatrix[i,2]]
								ei    =(*vcvo.e)[tmatrix[i,1],.]
								ei1   =(*vcvo.e)[tmatrix[i,2],.]
								Zi    =(*vcvo.Z)[tmatrix[i,1],.]
								Zi1   =(*vcvo.Z)[tmatrix[i,2],.]
								eZi =ei#Zi
								eZi1=ei1#Zi1
// Should never happen that fweights or iweights make it here, but if they did
// the next line would be ghat=ghat+eZi'*eZi1*sqrt(wvari)*sqrt(wvari1)
// [without *vcvo.wf since wf=1 for fw and iw]
								ghat=ghat+quadcross(eZi,eZi1)*wvari*wvari1 * (vcvo.wf^2)	// ADDED * (vcvo.wf^2)
							}
						}
						shat=shat+kw*(ghat+ghat')
					}	// end non-zero-obs accumulation block
				}	// end non-zero kernel weight block
			}	// end tau loop
		}  // end kernel code
// Incorporate large dof correction if there is one
	shat=shat/(vcvo.N-vcvo.dofminus)
	}  // end HC/HAC code

	if (vcvo.clustvarname~="") {
// Block for cluster-robust
// 2-level clustering: S = S(level 1) + S(level 2) - S(level 3 = intersection of levels 1 & 2)
// Prepare shat3 if 2-level clustering
		if (vcvo.clustvarname2~="") {
			if (vcvo.kernel~="") {	// second cluster variable is time
									// shat3 was already calculated above as shat
				shat3=shat*(vcvo.N-vcvo.dofminus)
			}
			else {					// calculate shat3
									// data were sorted on clustvar3-clustvar1 so
									// clustvar3 is nested in clustvar1 and Mata panel functions
									// work for both.
				info3 = panelsetup(clustvar3, 1)
				if (rows(info3)==rows(*vcvo.e)) {	// intersection of levels 1 & 2 are all single obs
													// so no need to loop through row by row
					if (K==1) {										// simple/fast where e is a column vector
						wv = (*vcvo.e :* *vcvo.wvar * vcvo.wf):^2
						shat3=quadcross(*vcvo.Z, wv, *vcvo.Z)		// basic Eicker-Huber-White-sandwich-robust vce
					}
					else {											// e is a matrix so must loop
						shat3=J(L*K,L*K,0)
						for (i=1; i<=rows(*vcvo.e); i++) {
							eZi=((*vcvo.e)[i,.])#((*vcvo.Z)[i,.])
							shat3=shat3+quadcross(eZi,eZi)*((*vcvo.wvar)[i] * vcvo.wf)^2	//  **** ADDED *vcvo.wf
							}
						}
				}
				else {								// intersection of levels 1 & 2 includes some groups of obs
					N_clust3=rows(info3)
					shat3=J(L*K,L*K,0)
					for (i=1; i<=N_clust3; i++) {
						esub=panelsubmatrix(*vcvo.e,i,info3)
						Zsub=panelsubmatrix(*vcvo.Z,i,info3)
						wsub=panelsubmatrix(*vcvo.wvar,i,info3)
						wv = esub :* wsub * vcvo.wf
						if (K==1) {							// simple/fast where e is a column vector
							eZ = quadcross(1, wv, Zsub)		// equivalent to colsum(wv :* Zsub)
						}
						else {
							eZ = J(1,L*K,0)
							for (j=1; j<=rows(esub); j++) {
								eZ=eZ+(esub[j,.]#Zsub[j,.])*wsub[j,.] * vcvo.wf	//  **** ADDED *vcvo.wf
							}
						}
						shat3=shat3+quadcross(eZ,eZ)
					}
				}
			}
		}

// 1st level of clustering, no kernel-robust
// Entered unless 1-level clustering and kernel-robust
		if (!((vcvo.kernel~="") & (vcvo.clustvarname2==""))) {
			shat=J(L*K,L*K,0)
			for (i=1; i<=N_clust; i++) {		// loop through clusters, adding Z'ee'Z
												// for indiv cluster in each loop
				esub=panelsubmatrix(*vcvo.e,i,info)
				Zsub=panelsubmatrix(*vcvo.Z,i,info)
				wsub=panelsubmatrix(*vcvo.wvar,i,info)
				if (K==1) {						// simple/fast if e is a column vector
					wv = esub :* wsub * vcvo.wf
					eZ = quadcross(1, wv, Zsub)		// equivalent to colsum(wv :* Zsub)
				}
				else {
					eZ=J(1,L*K,0)
					for (j=1; j<=rows(esub); j++) {
						eZ=eZ+(esub[j,.]#Zsub[j,.])*wsub[j,.]*vcvo.wf	//  **** ADDED *vcvo.wf
					}
				}
				shat=shat+quadcross(eZ,eZ)
			}	// end loop through clusters
		}

// 2-level clustering, no kernel-robust
		if ((vcvo.clustvarname2~="") & (vcvo.kernel=="")) {
			imax=max(clustvar2)					// clustvar2 is numbered 1..N_clust2
			shat2=J(L*K,L*K,0)
			for (i=1; i<=imax; i++) {			// loop through clusters, adding Z'ee'Z
												// for indiv cluster in each loop
				svar=(clustvar2:==i)			// mimics panelsubmatrix but doesn't require sorted data
				esub=select(*vcvo.e,svar)		// it is, however, noticably slower.
				Zsub=select(*vcvo.Z,svar)
				wsub=select(*vcvo.wvar,svar)
				if (K==1) {						// simple/fast if e is a column vector
					wv = esub :* wsub * vcvo.wf
					eZ = quadcross(1, wv, Zsub)		// equivalent to colsum(wv :* Zsub)
				}
				else {
					eZ=J(1,L*K,0)
					for (j=1; j<=rows(esub); j++) {
						eZ=eZ+(esub[j,.]#Zsub[j,.])*wsub[j,.]*vcvo.wf	//  **** ADDED *vcvo.wf
					}
				}
				shat2=shat2+quadcross(eZ,eZ)
			}
		}

// 1st level of cluster, kernel-robust OR
// 2-level clustering, kernel-robust and time is 2nd cluster variable
		if (vcvo.kernel~="") {
			shat2=J(L*K,L*K,0)
// First, standard cluster-robust, i.e., no lags.
			i=min(t)
			while (i<=max(t)) {  				// loop through all T clusters, adding Z'ee'Z
												// for indiv cluster in each loop
				eZ=J(1,L*K,0)
				svar=(t:==i)					// select obs with t=i
				if (colsum(svar)>0) {			// there are obs with t=i
					esub=select(*vcvo.e,svar)
					Zsub=select(*vcvo.Z,svar)
					wsub=select(*vcvo.wvar,svar)
					if (K==1) {						// simple/fast if e is a column vector
						wv = esub :* wsub * vcvo.wf
						eZ = quadcross(1, wv, Zsub)		// equivalent to colsum(wv :* Zsub)
					}
					else {
// MISSING LINE IS NEXT
						eZ=J(1,L*K,0)
						for (j=1; j<=rows(esub); j++) {
							eZ=eZ+(esub[j,.]#Zsub[j,.])*wsub[j,.]*vcvo.wf	//  **** ADDED *vcvo.wf
						}
					}
					shat2=shat2+quadcross(eZ,eZ)
				}
				i=i+vcvo.tdelta
			} // end i loop through all T clusters

// Spectral windows require looping through all T-1 autocovariances
			if (window=="spectral") {
				TAU=T/vcvo.tdelta-1
			}
			else {
				TAU=vcvo.bw
			}

			for (tau=1; tau<=TAU; tau++) {
				kw = m_ivreg29_calckw(tau, vcvo.bw, vcvo.kernel)	// zero weight possible with some kernels
															// save an unnecessary loop if kw=0
															// remember, kw<0 possible with some kernels!
				if (kw~=0) {
					i=min(t)+tau*vcvo.tdelta				// Loop through all possible ts (time clusters)
					while (i<=max(t)) {						// Start at earliest possible t
						svar=t[.,]:==i						// svar is current, svar1 is tau-th lag
						svar1=t[.,]:==(i-tau*vcvo.tdelta)	// tau*vcvo.tdelta is usually just tau
						if ((colsum(svar)>0)				// there are current & lagged obs
								& (colsum(svar1)>0))	 {
							wv  = select((*vcvo.e),svar)  :* select((*vcvo.wvar),svar)  * vcvo.wf
							wv1 = select((*vcvo.e),svar1) :* select((*vcvo.wvar),svar1) * vcvo.wf
							Zsub =select((*vcvo.Z),svar)
							Zsub1=select((*vcvo.Z),svar1)
							if (K==1) {						// simple/fast, e is column vector
								eZsub = quadcross(1, wv, Zsub)		// equivalent to colsum(wv :* Zsub)
								eZsub1= quadcross(1, wv1, Zsub1)	// equivalent to colsum(wv :* Zsub)
							}
							else {
								eZsub=J(1,L*K,0)
								for (j=1; j<=rows(Zsub); j++) {
									wvj =wv[j,.]
									Zj  =Zsub[j,.]
									eZsub=eZsub+(wvj#Zj)
								}
								eZsub1=J(1,L*K,0)
								for (j=1; j<=rows(Zsub1); j++) {
									wv1j =wv1[j,.]
									Z1j  =Zsub1[j,.]
									eZsub1=eZsub1+(wv1j#Z1j)
								}
							}
							ghat=quadcross(eZsub,eZsub1)
							shat2=shat2+kw*(ghat+ghat')
						}
						i=i+vcvo.tdelta
					}
				}	// end non-zero kernel weight block
			}	// end tau loop

// If 1-level clustering, shat2 just calculated above is actually the desired shat
			if (vcvo.clustvarname2=="") {
				shat=shat2
			}
		}

// 2-level clustering, completion
// Cameron-Gelbach-Miller/Thompson method:
// Add 2 cluster variance matrices and subtract 3rd
		if (vcvo.clustvarname2~="") {
			shat = shat+shat2-shat3
		}		

// Note no dof correction required for cluster-robust
	shat=shat/vcvo.N
	} // end cluster-robust code

	if (vcvo.sw~="") {
// Stock-Watson adjustment.  Calculate Bhat in their equation (6).  Also need T=panel length.
// They define for balanced panels.  Since T is not constant for unbalanced panels, need
// to incorporate panel-varying 1/T, 1/(T-1) and 1/(T-2) as weights in summation.

		st_view(ivar, ., st_tsrevar(vcvo.ivarname), vcvo.touse)
		info_ivar = panelsetup(ivar, 1)

		shat=J(L*K,L*K,0)
		bhat=J(L*K,L*K,0)
		N_panels=0
		for (i=1; i<=rows(info_ivar); i++) {
			esub=panelsubmatrix(*vcvo.e,i,info_ivar)
			Zsub=panelsubmatrix(*vcvo.Z,i,info_ivar)
			wsub=panelsubmatrix(*vcvo.wvar,i,info_ivar)
			Tsub=rows(esub)
			if (Tsub>2) {			// SW cov estimator defined only for T>2
				N_panels=N_panels+1
				sigmahatsub=J(K,K,0)
				ZZsub=J(L*K,L*K,0)
				shatsub=J(L*K,L*K,0)
				for (j=1; j<=rows(esub); j++) {
					eZi=esub[j,1]#Zsub[j,.]
					if ((vcvo.weight=="fweight") | (vcvo.weight=="iweight")) {
						shatsub=shatsub+quadcross(eZi,eZi)*wsub[j]*vcvo.wf
						sigmahatsub=sigmahatsub + quadcross(esub[j,1],esub[j,1])*wsub[j]*vcvo.wf
						ZZsub=ZZsub+quadcross(Zsub[j,.],Zsub[j,.])*wsub[j]*vcvo.wf
					}
					else {
						shatsub=shatsub+quadcross(eZi,eZi)*((wsub[j]*vcvo.wf)^2)
						sigmahatsub=sigmahatsub + quadcross(esub[j,1],esub[j,1])*((wsub[j]*vcvo.wf)^2)
						ZZsub=ZZsub+quadcross(Zsub[j,.],Zsub[j,.])*((wsub[j]*vcvo.wf)^2)
					}
				} // end loop through j obs of panel i
				shat=shat + shatsub*(Tsub-1)/(Tsub-2)
				bhat=bhat + ZZsub/Tsub#sigmahatsub/(Tsub-1)/(Tsub-2)
			}
		} // end loop through i panels

// Note that Stock-Watson incorporate an N-n-k degrees of freedom correction in their eqn 4
// for what we call shat.  We use only an N-n degrees of freedom correction, i.e., we ignore
// the k regressors.  This is because this is an estimate of S, the VCV of orthogonality conditions,
// independently of its use to obtain an estimate of the variance of beta.  Makes no diff aysmptotically.
// Ignore dofminus correction since this is explicitly handled here.
// Use number of valid panels in denominator (SW cov estimator defined only for panels with T>2).
		shat=shat/(vcvo.N-N_panels)
		bhat=bhat/N_panels
		shat=shat-bhat
	} // end Stock-Watson block

	_makesymmetric(shat)

// shat may not be positive-definite.  Use spectral decomposition to obtain an invertable version.
// Extract Eigenvector and Eigenvalues, replace EVs, and reassemble shat.
// psda option: Stock-Watson 2008 Econometrica, Remark 8, say replace neg EVs with abs(EVs).
// psd0 option: Politis (2007) says replace neg EVs with zeros.
	if (vcvo.psd~="") {
		symeigensystem(shat,Evec,Eval)
		if (vcvo.psd=="psda") {
			Eval = abs(Eval)
		}
		else {
			Eval = Eval + (abs(Eval) - Eval)/2
		}
		shat = Evec*diag(Eval)*Evec'
		_makesymmetric(shat)
	}

	return(shat)

} // end of program m_ivreg29_omega

// *********************************************************************** //
// ********* m_ivreg29_calckw - shared by ivreg2 and ranktest ********************* //
// *********************************************************************** //

real scalar m_ivreg29_calckw(	real scalar tau,
						real scalar bw,
						string scalar kernel) 
	{
				karg = tau / bw
				if (kernel=="Truncated") {
					kw=1
				}
				if (kernel=="Bartlett") {
					kw=(1-karg)
				}
				if (kernel=="Parzen") {
					if (karg <= 0.5) {
						kw = 1-6*karg^2+6*karg^3
					}
					else {
						kw = 2*(1-karg)^3
					}
				}
				if (kernel=="Tukey-Hanning") {
					kw=0.5+0.5*cos(pi()*karg)
				}
				if (kernel=="Tukey-Hamming") {
					kw=0.54+0.46*cos(pi()*karg)
				}
				if (kernel=="Tent") {
					kw=2*(1-cos(tau*karg)) / (karg^2)
				}
				if (kernel=="Danielle") {
					kw=sin(pi()*karg) / (pi()*karg)
				}
				if (kernel=="Quadratic Spectral") {
					kw=25/(12*pi()^2*karg^2) /*
						*/ * ( sin(6*pi()*karg/5)/(6*pi()*karg/5) /*
						*/     - cos(6*pi()*karg/5) )
				}
				return(kw)
	}  // end kw

// *********************************************************************** //
// ********* END CODE SHARED BY ivreg2 AND ranktest ******************** //
// *********************************************************************** //


end

****************************************** END ***************************************
*********************************** livreg2.mlib CODE ********************************

***************************************** START **************************************
*********************************** ranktest.ado CODE ********************************
* Code from:
* ranktest 1.3.04  24aug2014
* author mes, based on code by fk
* Imported into ivreg29 so that ivreg29 is free-standing.
* See end of file for version notes.

program define ivreg29_ranktest, rclass sortpreserve
	version 9.2
	local lversion 01.3.04

	if substr("`1'",1,1)== "," {
		if "`2'"=="version" {
			di in ye "`lversion'"
			return local version `lversion'
			exit
		}
		else {
di as err "invalid syntax"
			exit 198
		}
	}

* If varlist 1 or varlist 2 have a single element, parentheses optional

	if substr("`1'",1,1)=="(" {
		GetVarlist `0'
		local y `s(varlist)'
		local K : word count `y'
		local 0 `"`s(rest)'"'
		sret clear
	}
	else {
		local y `1'
		local K 1
		mac shift 1
		local 0 `"`*'"'
	}

	if substr("`1'",1,1)=="(" {
		GetVarlist `0'
		local z `s(varlist)'
		local L : word count `z'
		local 0 `"`s(rest)'"'
		sret clear
	}
	else {
		local z `1'
		local K 1
		mac shift 1
* Need to reinsert comma before options (if any) for -syntax- command to work
		local 0 `", `*'"'
	}

* Option version ignored here if varlists were provided
	syntax [if] [in] [aw fw pw iw/] [, partial(varlist ts) fwl(varlist ts)			/*
		*/	NOConstant wald ALLrank NULLrank FULLrank ROBust cluster(varlist)		/*
		*/	BW(string) kernel(string) Tvar(varname) Ivar(varname) sw psd version		/*
		*/	dofminus(integer 0) ]

	local partial "`partial' `fwl'"

	if "`noconstant'"=="" {
		tempvar one
		gen byte `one' = 1
		local partial "`partial' `one'"
	}

	if "`wald'"~="" {
		local LMWald "Wald"
	}
	else {
		local LMWald "LM"
	}
	
	local optct : word count `allrank' `nullrank' `fullrank'
	if `optct' > 1 {
di as err "Incompatible options: `allrank' `nullrank' `fullrank'"
		error 198
	}
	else if `optct' == 0 {
* Default
		local allrank "allrank"
	}

* Note that by tsrevar-ing here, subsequent disruption to the sort doesn't matter
* for TS operators.
	tsrevar `y'
	local vl1 `r(varlist)'
	tsrevar `z'
	local vl2 `r(varlist)'
	tsrevar `partial'
	local partial `r(varlist)'

	foreach vn of varlist `vl1' {
		tempvar tv
		qui gen double `tv' = .
		local tempvl1 "`tempvl1' `tv'"
	}
	foreach vn of varlist `vl2' {
		tempvar tv
		qui gen double `tv' = .
		local tempvl2 "`tempvl2' `tv'"
	}

	marksample touse
	markout `touse' `vl1' `vl2' `partial' `cluster', strok

* Stock-Watson and cluster imply robust.
	if "`sw'`cluster'" ~= "" {
		local robust "robust"
	}

	tempvar wvar
	if "`weight'" == "fweight" | "`weight'"=="aweight" {
		local wtexp `"[`weight'=`exp']"'
		gen double `wvar'=`exp'
	}
	if "`fsqrt(wf)*(wvar^0.5):*'" == "fweight" & "`kernel'" !="" {
		di in red "fweights not allowed (data are -tsset-)"
		exit 101
	}
	if "`weight'" == "fweight" & "`sw'" != "" {
		di in red "fweights currently not supported with -sw- option"
		exit 101
	}
	if "`weight'" == "iweight" {
		if "`robust'`cluster'`bw'" !="" {
			di in red "iweights not allowed with robust, cluster, AC or HAC"
			exit 101
		}
		else {
			local wtexp `"[`weight'=`exp']"'
			gen double `wvar'=`exp'
		}
	}
	if "`weight'" == "pweight" {
		local wtexp `"[aweight=`exp']"'
		gen double `wvar'=`exp'
		local robust "robust"
	}
	if "`weight'" == "" {
* If no weights, define neutral weight variable
		qui gen byte `wvar'=1
	}


* Every time a weight is used, must multiply by scalar wf ("weight factor")
* wf=1 for no weights, fw and iw, wf = scalar that normalizes sum to be N if aw or pw
		sum `wvar' if `touse' `wtexp', meanonly
* Weight statement
		if "`weight'" ~= "" {
di in gr "(sum of wgt is " %14.4e `r(sum_w)' ")"
		}
		if "`weight'"=="" | "`weight'"=="fweight" | "`weight'"=="iweight" {
* If weight is "", weight var must be column of ones and N is number of rows.
* With fw and iw, effective number of observations is sum of weight variable.
			local wf=1
			local N=r(sum_w)
		}
		else if "`weight'"=="aweight" | "`weight'"=="pweight" {
* With aw and pw, N is number of obs, unadjusted.
			local wf=r(N)/r(sum_w)
			local N=r(N)
		}
		else {
* Should never reach here
di as err "ivreg29_ranktest error - misspecified weights"
			exit 198
		}

* HAC estimation.
* If bw is omitted, default `bw' is empty string.
* If bw or kernel supplied, check/set `kernel'.
* Macro `kernel' is also used for indicating HAC in use.
	if "`bw'" == "" & "`kernel'" == "" {
		local bw=0
	}
	else {
* Need tvar for markout with time-series stuff
* Data must be tsset for time-series operators in code to work
* User-supplied tvar checked if consistent with tsset
		capture tsset
		if "`r(timevar)'" == "" {
di as err "must tsset data and specify timevar"
			exit 5
		}
		if "`tvar'" == "" {
			local tvar "`r(timevar)'"
		}
		else if "`tvar'"!="`r(timevar)'" {
di as err "invalid tvar() option - data already -tsset-"
			exit 5
		}
* If no panel data, ivar will still be empty
		if "`ivar'" == "" {
			local ivar "`r(panelvar)'"
		}
		else if "`ivar'"!="`r(panelvar)'" {
di as err "invalid ivar() option - data already -tsset-"
			exit 5
		}
		local tdelta `r(tdelta)'
		tsreport if `touse', panel
		if `r(N_gaps)' != 0 {
di in gr "Warning: time variable " in ye "`tvar'" in gr " has " /*
	*/ in ye "`r(N_gaps)'" in gr " gap(s) in relevant range"
		}

* Check it's a valid kernel and replace with unabbreviated kernel name; check bw.
* Automatic kernel selection allowed by ivreg2 but not ranktest so must trap.
* s_ivreg29_vkernel is in livreg2 mlib.
		if "`bw'"=="auto" {
di as err "invalid bandwidth in option bw() - must be real > 0"
			exit 198
		}
		mata: s_ivreg29_vkernel("`kernel'", "`bw'", "`ivar'")
		local kernel `r(kernel)'
		local bw = `r(bw)'
	}

* tdelta missing if version 9 or if not tsset			
	if "`tdelta'"=="" {
		local tdelta=1
	}

	if "`sw'"~="" {
		capture xtset
		if "`ivar'" == "" {
			local ivar "`r(panelvar)'"
		}
		else if "`ivar'"!="`r(panelvar)'" {
di as err "invalid ivar() option - data already tsset or xtset"
			exit 5
		}
* Exit with error if ivar is neither supplied nor tsset nor xtset
		if "`ivar'"=="" {
di as err "Must -xtset- or -tsset- data or specify -ivar- with -sw- option"
			exit 198
		}
		qui describe, short varlist
		local sortlist "`r(sortlist)'"
		tokenize `sortlist'
		if "`ivar'"~="`1'" {
di as err "Error - dataset must be sorted on panel var with -sw- option"
			exit 198
		}
	}

* Create variable used for getting lags etc. in Mata
	tempvar tindex
	qui gen `tindex'=1 if `touse'
	qui replace `tindex'=sum(`tindex') if `touse'

********** CLUSTER SETUP **********************************************

* Mata code requires data are sorted on (1) the first var cluster if there
* is only one cluster var; (2) on the 3rd and then 1st if two-way clustering,
* unless (3) two-way clustering is combined with kernel option, in which case
* the data are tsset and sorted on panel id (first cluster variable) and time
* id (second cluster variable).
* Second cluster var is optional and requires an identifier numbered 1..N_clust2,
* unless combined with kernel option, in which case it's the time variable.
* Third cluster var is the intersection of 1 and 2, unless combined with kernel
* opt, in which case it's unnecessary.
* Sorting on "cluster3 cluster1" means that in Mata, panelsetup works for
* both, since cluster1 nests cluster3.
* Note that it is possible to cluster on time but not panel, in which case
* cluster1 is time, cluster2 is empty and data are sorted on panel-time.
* Note also that if no kernel-robust, sorting will disrupt any tsset-ing,
* but data are tsrevar-ed earlier to avoid any problems.
	if "`cluster'"!="" {
		local clopt "cluster(`cluster')"
		tokenize `cluster'
		local cluster1 "`1'"
		local cluster2 "`2'"
		if "`kernel'"~="" {
* kernel requires either that cluster1 is time var and cluster2 is empty
* or that cluster1 is panel var and cluster2 is time var.
* Either way, data must be tsset and sorted for panel data.
			if "`cluster2'"~="" {
* Allow backwards order
				if "`cluster1'"=="`tvar'" & "`cluster2'"=="`ivar'" {
					local cluster1 "`2'"
					local cluster2 "`1'"
				}
				if "`cluster1'"~="`ivar'" | "`cluster2'"~="`tvar'" {
di as err "Error: cluster kernel-robust requires clustering on tsset panel & time vars."
di as err "       tsset panel var=`ivar'; tsset time var=`tvar'; cluster vars=`cluster1',`cluster2'"
					exit 198
				}
			}
			else {
				if "`cluster1'"~="`tvar'" {
di as err "Error: cluster kernel-robust requires clustering on tsset time variable."
di as err "       tsset time var=`tvar'; cluster var=`cluster1'"
					exit 198
				}
			}
		}
* Simple way to get quick count of 1st cluster variable without disrupting sort
* clusterid1 is numbered 1.._Nclust1.
		tempvar clusterid1
		qui egen `clusterid1'=group(`cluster1') if `touse'
		sum `clusterid1' if `touse', meanonly
		if "`cluster2'"=="" {
			local N_clust=r(max)
			local N_clust1=.
			local N_clust2=.
			if "`kernel'"=="" {
* Single level of clustering and no kernel-robust, so sort on single cluster var.
* kernel-robust already sorted via tsset.
				sort `cluster1'
			}
		}
		else {
			local N_clust1=r(max)
			if "`kernel'"=="" {
				tempvar clusterid2 clusterid3
* New cluster id vars are numbered 1..N_clust2 and 1..N_clust3
				qui egen `clusterid2'=group(`cluster2') if `touse'
				qui egen `clusterid3'=group(`cluster1' `cluster2') if `touse'
* Two levels of clustering and no kernel-robust, so sort on cluster3/nested in/cluster1
* kernel-robust already sorted via tsset.
				sort `clusterid3' `cluster1'
				sum `clusterid2' if `touse', meanonly
				local N_clust2=r(max)
			}
			else {
* Need to create this only to count the number of clusters
				tempvar clusterid2
				qui egen `clusterid2'=group(`cluster2') if `touse'
				sum `clusterid2' if `touse', meanonly
				local N_clust2=r(max)
* Now replace with original variable
				local clusterid2 `cluster2'
			}
			local N_clust=min(`N_clust1',`N_clust2')
		}
	}

************************************************************************************************

* Note that bw is passed as a value, not as a string
	mata: ivreg29_rkstat(	"`vl1'",			/*
				*/	"`vl2'",			/*
				*/	"`partial'",		/*
				*/	"`wvar'",			/*
				*/	"`weight'",			/*
				*/	`wf',				/*
				*/	`N',				/*
				*/	"`touse'",			/*
				*/	"`LMWald'",			/*
				*/	"`allrank'",		/*
				*/	"`nullrank'",		/*
				*/	"`fullrank'",		/*
				*/	"`robust'",			/*
				*/	"`clusterid1'",		/*
				*/	"`clusterid2'",		/*
				*/	"`clusterid3'",		/*
				*/	`bw',				/*
				*/	"`tvar'",			/*
				*/	"`ivar'",			/*
				*/	"`tindex'",			/*
				*/	`tdelta',			/*
				*/	`dofminus',			/*
				*/	"`kernel'",			/*
				*/	"`sw'",				/*
				*/	"`psd'",			/*
				*/	"`tempvl1'",		/*
				*/	"`tempvl2'")

	tempname rkmatrix chi2 df df_r p rank ccorr eval
	mat `rkmatrix'=r(rkmatrix)
	mat `ccorr'=r(ccorr)
	mat `eval'=r(eval)
	mat colnames `rkmatrix' = "rk" "df" "p" "rank" "eval" "ccorr"
	
di
di "Kleibergen-Paap rk `LMWald' test of rank of matrix"
	if "`robust'"~="" & "`kernel'"~= "" & "`cluster'"=="" {
di "  Test statistic robust to heteroskedasticity and autocorrelation"
di "  Kernel: `kernel'   Bandwidth: `bw'"
	}
	else if "`kernel'"~="" & "`cluster'"=="" {
di "  Test statistic robust to autocorrelation"
di "  Kernel: `kernel'   Bandwidth: `bw'"
	}
	else if "`cluster'"~="" {
di "  Test statistic robust to heteroskedasticity and clustering on `cluster'"
		if "`kernel'"~="" {
di "  and kernel-robust to common correlated disturbances"
di "  Kernel: `kernel'   Bandwidth: `bw'"
		}
	}
	else if "`robust'"~="" {
di "  Test statistic robust to heteroskedasticity"
	}
	else if "`LMWald'"=="LM" {
di "  Test assumes homoskedasticity (Anderson canonical correlations test)"
	}
	else {
di "  Test assumes homoskedasticity (Cragg-Donald test)"
	}
		
	local numtests = rowsof(`rkmatrix')
	forvalues i=1(1)`numtests' {
di "Test of rank=" %3.0f `rkmatrix'[`i',4] "  rk=" %8.2f `rkmatrix'[`i',1] /*
	*/	"  Chi-sq(" %3.0f `rkmatrix'[`i',2] ") pvalue=" %8.6f `rkmatrix'[`i',3]
	}
	scalar `chi2' = `rkmatrix'[`numtests',1]
	scalar `p' = `rkmatrix'[`numtests',3]
	scalar `df' = `rkmatrix'[`numtests',2]
	scalar `rank' = `rkmatrix'[`numtests',4]
	local N `r(N)'
	return scalar df = `df'
	return scalar chi2 = `chi2'
	return scalar p = `p'
	return scalar rank = `rank'
	if "`cluster'"~="" {
		return scalar N_clust = `N_clust'
	}
	if "`cluster2'"~="" {
		return scalar N_clust1 = `N_clust1'
		return scalar N_clust2 = `N_clust2'
	}
	return scalar N = `N'
	return matrix rkmatrix `rkmatrix'
	return matrix ccorr `ccorr'
	return matrix eval `eval'
	
	tempname S V Omega
	if `K' > 1 {
		foreach en of local y {
* Remove "." from equation name
			local en1 : subinstr local en "." "_", all
			foreach vn of local z {
				local cn "`cn' `en1':`vn'"
			}
		}
	}
	else {
		foreach vn of local z {
		local cn "`cn' `vn'"
		}
	}
	mat `V'=r(V)
	matrix colnames `V' = `cn'
	matrix rownames `V' = `cn'
	return matrix V `V'
	mat `S'=r(S)
	matrix colnames `S' = `cn'
	matrix rownames `S' = `cn'
	return matrix S `S'	
end

* Adopted from -canon-
program define GetVarlist, sclass 
	sret clear
	gettoken open 0 : 0, parse("(") 
	if `"`open'"' != "(" {
		error 198
	}
	gettoken next 0 : 0, parse(")")
	while `"`next'"' != ")" {
		if `"`next'"'=="" { 
			error 198
		}
		local list `list'`next'
		gettoken next 0 : 0, parse(")")
	}
	sret local rest `"`0'"'
	tokenize `list'
	local 0 `*'
	sret local varlist "`0'"
end


*******************************************************************************
*************************** BEGIN MATA CODE ***********************************
*******************************************************************************



version 9.2
mata:

void ivreg29_rkstat(	string scalar vl1,
				string scalar vl2,
				string scalar partial,
				string scalar wvarname,
				string scalar weight,
				scalar wf,
				scalar N,
				string scalar touse,
				string scalar LMWald,
				string scalar allrank,
				string scalar nullrank,
				string scalar fullrank,
				string scalar robust,
				string scalar clustvarname,
				string scalar clustvarname2,
				string scalar clustvarname3,
				bw,
				string scalar tvarname,
				string scalar ivarname,
				string scalar tindexname,
				tdelta,
				dofminus,
				string scalar kernel,
				string scalar sw,
				string scalar psd,
				string scalar tempvl1,
				string scalar tempvl2)
{

// tempx, tempy and tempz are the Stata names of temporary variables that will be changed by rkstat
	if (partial~="") {
		tempx=tokens(partial)
	}
	tempy=tokens(tempvl1)
	tempz=tokens(tempvl2)

	st_view(y=.,.,tokens(vl1),touse)
	st_view(z=.,.,tokens(vl2),touse)
	st_view(yhat=.,.,tempy,touse)
	st_view(zhat=.,.,tempz,touse)
	st_view(mtouse=.,.,tokens(touse),touse)
	st_view(wvar=.,.,tokens(wvarname),touse)
	noweight=(st_vartype(wvarname)=="byte")

// Note that we now use wf*wvar instead of wvar
// because wvar is raw weighting variable and
// wf*wvar normalizes so that sum(wf*wvar)=N.

// Partial out the X variables
// Note that this is entered if there is a constant,
//   i.e., variables are centered
	if (partial~="") {
		st_view(x=.,.,tempx,touse)
		xx = quadcross(x, wf*wvar, x)
		xy = quadcross(x, wf*wvar, y)
		xz = quadcross(x, wf*wvar, z)

		by = invsym(xx)*xy
		bz = invsym(xx)*xz

		yhat[.,.] = y-x*by
		zhat[.,.] = z-x*bz
	}
	else {
		yhat[.,.] = y
		zhat[.,.] = z
	}
	K=cols(y)
	L=cols(z)

	zhzh = quadcross(zhat, wf*wvar, zhat)
	zhyh = quadcross(zhat, wf*wvar, yhat)
	yhyh = quadcross(yhat, wf*wvar, yhat)

	pihat = invsym(zhzh)*zhyh
// rzhat is F in paper (p. 103)
// iryhat is G in paper (p. 103)
	ryhat=cholesky(yhyh)
	rzhat=cholesky(zhzh)
	iryhat=luinv(ryhat')
	irzhat=luinv(rzhat')
	that=rzhat'*pihat*iryhat

// cc is canonical correlations.  Squared cc is eigenvalues.
	fullsvd(that, ut, cc, vt)
	vt=vt'
	vecth=vec(that)
	ev = cc:^2
// S matrix in paper (p. 100).  Not used in code below.
//	smat=fullsdiag(cc, rows(that)-cols(that))

	if (abs(1-cc[1,1])<1e-10) {
printf("\n{text:Warning: collinearities detected between (varlist1) and (varlist2)}\n")
	}
	if ((missing(ryhat)>0) | (missing(iryhat)>0) | (missing(rzhat)>0) | (missing(irzhat)>0)) {
printf("\n{error:Error: non-positive-definite matrix. May be caused by collinearities.}\n")
		exit(error(3351))
	}

// If Wald, yhat is residuals
	if (LMWald=="Wald") {
		yhat[.,.]=yhat-zhat*pihat
		yhyh = quadcross(yhat, wvar, yhat)
	}

// Covariance matrices
// vhat is W in paper (eqn below equation 17, p. 103)
// shat is V in paper (eqn below eqn 15, p. 103)

// ************************************************************************************* //
// shat calculated using struct and programs m_ivreg29_omega, m_ivreg29_calckw shared with ivreg2        //

	struct ms_ivreg29_vcvorthog scalar vcvo


	vcvo.ename			= tempy		// ivreg2 has = ename //
	vcvo.Znames			= tempz		// ivreg2 has = Znames //
	vcvo.touse			= touse
	vcvo.weight			= weight
	vcvo.wvarname		= wvarname
	vcvo.robust			= robust
	vcvo.clustvarname	= clustvarname
	vcvo.clustvarname2	= clustvarname2
	vcvo.clustvarname3	= clustvarname3
	vcvo.kernel			= kernel
	vcvo.sw				= sw
	vcvo.psd			= psd
	vcvo.ivarname		= ivarname
	vcvo.tvarname		= tvarname
	vcvo.tindexname		= tindexname
	vcvo.wf				= wf
	vcvo.N				= N
	vcvo.bw				= bw
	vcvo.tdelta			= tdelta
	vcvo.dofminus		= dofminus
	vcvo.ZZ				= zhzh		// ivreg2 has = st_matrix(ZZmatrix) //
	
	vcvo.e		= &yhat				// ivreg2 has = &e	//
	vcvo.Z		= &zhat				// ivreg2 has = &Z //
	vcvo.wvar	= &wvar

	shat=m_ivreg29_omega(vcvo)

// ***************************************************************************************

// Finally, calcluate vhat	
	if ((LMWald=="LM") & (kernel=="") & (robust=="") & (clustvarname=="")) {
// Homoskedastic, iid LM case means vcv is identity matrix
// Generates canonical correlation stats.  Default.
		vhat=I(L*K,L*K)/N
	}
	else {
		vhat=(iryhat'#irzhat')*shat*(iryhat'#irzhat')' * N
		_makesymmetric(vhat)
	}

// ready to start collecting test stats
	if (allrank~="") {
		firstrank=1
		lastrank=min((K,L))
	}
	else if (nullrank~="") {
		firstrank=1
		lastrank=1
	}
	else if (fullrank~="") {
		firstrank=min((K,L))
		lastrank=min((K,L))
	}
	else {
// should never reach this point
printf("ivreg29_ranktest error\n")
		exit
	}

	rkmatrix=J(lastrank-firstrank+1,6,.)
	for (i=firstrank; i<=lastrank; i++) {

		if (i>1) {
			u12=ut[(1::i-1),(i..L)]
			v12=vt[(1::i-1),(i..K)]
		}
		u22=ut[(i::L),(i..L)]
		v22=vt[(i::K),(i..K)]
		
		symeigensystem(u22*u22', evec, eval)
		u22v=evec
		u22d=diag(eval)
		u22h=u22v*(u22d:^0.5)*u22v'

		symeigensystem(v22*v22', evec, eval)
		v22v=evec
		v22d=diag(eval)
		v22h=v22v*(v22d:^0.5)*v22v'

		if (i>1) {
			aq=(u12 \ u22)*luinv(u22)*u22h
			bq=v22h*luinv(v22')*(v12 \ v22)'
		}
		else {
			aq=u22*luinv(u22)*u22h
			bq=v22h*luinv(v22')*v22'
		}

// lab is lambda_q in paper (eqn below equation 21, p. 104)
// vlab is omega_q in paper (eqn 19 in paper, p. 104)
		lab=(bq#aq')*vecth
		vlab=(bq#aq')*vhat*(bq#aq')'

// Symmetrize if numerical inaccuracy means it isn't
		_makesymmetric(vlab)
		vlabinv=invsym(vlab)
// rk stat Assumption 2: vlab (omega_q in paper) is nonsingular.  Detected by a zero on the diagonal,
// since when returning a generalized inverse, Stata/Mata choose the generalized inverse that
// sets entire column(s)/row(s) to zeros.
// Save df and rank even if test stat not available.
		df=(L-i+1)*(K-i+1)
		rkmatrix[i-firstrank+1,2]=df
		rkmatrix[i-firstrank+1,4]=i-1
		if (diag0cnt(vlabinv)>0) {
printf("\n{text:Warning: covariance matrix omega_%f}", i-1)
printf("{text: not full rank; test of rank %f}", i-1)
printf("{text: unavailable}\n")
		}
// Note not multiplying by N - already incorporated in vhat.
		else {
			rk=lab'*vlabinv*lab
			pvalue=chi2tail(df, rk)
			rkmatrix[i-firstrank+1,1]=rk
			rkmatrix[i-firstrank+1,3]=pvalue
		}
// end of test loop
	}

// insert squared (=eigenvalues if canon corr) and unsquared canon correlations
	for (i=firstrank; i<=lastrank; i++) {
		rkmatrix[i-firstrank+1,6]=cc[i-firstrank+1,1]
		rkmatrix[i-firstrank+1,5]=ev[i-firstrank+1,1]
	}
	st_matrix("r(rkmatrix)", rkmatrix)
	st_matrix("r(ccorr)", cc')
	st_matrix("r(eval)",ev')
// Save V matrix as in paper, without factor of 1/N
	vhat=N*vhat*wf
	st_matrix("r(V)", vhat)
// Save S matrix as in ivreg2, with factor of 1/N
	st_matrix("r(S)", shat)
	st_numscalar("r(N)", N)
	if (clustvarname~="") {
		st_numscalar("r(N_clust)", N_clust)
	}
	if (clustvarname2~="") {
		st_numscalar("r(N_clust2)", N_clust2)
	}
// end of program
}


end

****************************************** END ***************************************
*********************************** ranktest.ado CODE ********************************

exit

********************************** VERSION COMMENTS **********************************
*  Initial version cloned from official ivreg version 5.0.9  19Dec2001
*  1.0.2:  add logic for reg3. Sargan test
*  1.0.3:  add prunelist to ensure that count of excluded exogeneous is correct 
*  1.0.4:  revise option to exog(), allow included exog to be specified as well
*  1.0.5:  switch from reg3 to regress, many options and output changes
*  1.0.6:  fixed treatment of nocons in Sargan and C-stat, and corrected problems
*          relating to use of nocons combined with a constant as an IV
*  1.0.7:  first option reports F-test of excluded exogenous; prunelist bug fix
*  1.0.8:  dropped prunelist and switched to housekeeping of variable lists
*  1.0.9:  added collinearity checks; C-stat calculated with recursive call;
*          added ffirst option to report only F-test of excluded exogenous
*          from 1st stage regressions
*  1.0.10: 1st stage regressions also report partial R2 of excluded exogenous
*  1.0.11: complete rewrite of collinearity approach - no longer uses calls to
*          _rmcoll, does not track specific variables dropped; prunelist removed
*  1.0.12: reorganised display code and saved results to enable -replay()-
*  1.0.13: -robust- and -cluster- now imply -small-
*  1.0.14: fixed hascons bug; removed ivreg predict fn (it didn't work); allowed
*          robust and cluster with z stats and correct dofs
*  1.0.15: implemented robust Sargan stat; changed to only F-stat, removed chi-sq;
*          removed exog option (only orthog works)
*  1.0.16: added clusterised Sargan stat; robust Sargan handles collinearities;
*          predict now works with standard SE options plus resids; fixed orthog()
*          so it accepts time series operators etc.
*  1.0.17: fixed handling of weights.  fw, aw, pw & iw all accepted.
*  1.0.18: fixed bug in robust Sargan code relating to time series variables.
*  1.0.19: fixed bugs in reporting ranks of X'X and Z'Z
*          fixed bug in reporting presence of constant
*  1.0.20: added GMM option and replaced robust Sargan with (equivalent) J;
*          added saved statistics of 1st stage regressions
*  1.0.21: added Cragg HOLS estimator, including allowing empty endog list;
*          -regress- syntax now not allowed; revised code searching for "_cons"
*  1.0.22: modified cluster output message; fixed bug in replay for Sargan/Hansen stat;
*          exactly identified Sargan/Hansen now exactly zero and p-value not saved as e();
*          cluster multiplier changed to 1 (from buggy multiplier), in keeping with
*          eg Wooldridge 2002 p. 193.
*  1.0.23: fixed orthog option to prevent abort when restricted equation is underid.
*  1.0.24: fixed bug if 1st stage regressions yielded missing values for saving in e().
*  1.0.25: Added Shea version of partial R2
*  1.0.26: Replaced Shea algorithm with Godfrey algorithm
*  1.0.27: Main call to regress is OLS form if OLS or HOLS is specified; error variance
*          in Sargan and C statistics use small-sample adjustment if -small- option is
*          specified; dfn of S matrix now correctly divided by sample size
*  1.0.28: HAC covariance estimation implemented
*          Symmetrize all matrices before calling syminv
*          Added hack to catch F stats that ought to be missing but actually have a
*          huge-but-not-missing value
*          Fixed dof of F-stat - was using rank of ZZ, should have used rank of XX (couldn't use df_r
*          because it isn't always saved.  This is because saving df_r triggers small stats
*          (t and F) even when -post- is called without dof() option, hence df_r saved only
*          with -small- option and hence a separate saved macro Fdf2 is needed.
*          Added rankS to saved macros
*          Fixed trap for "no regressors specified"
*          Added trap to catch gmm option with no excluded instruments
*          Allow OLS syntax (no endog or excluded IVs specified)
*          Fixed error messages and traps for rank-deficient robust cov matrix; includes
*          singleton dummy possibility
*          Capture error if posting estimated VCV that isn't pos def and report slightly
*          more informative error message
*          Checks 3 variable lists (endo, inexog, exexog) separately for collinearities
*          Added AC (autocorrelation-consistent but conditionally-homoskedastic) option
*          Sargan no longer has small-sample correction if -small- option
*          robust, cluster, AC, HAC all passed on to first-stage F-stat
*          bw must be < T
*  1.0.29  -orthog- also displays Hansen-Sargan of unrestricted equation
*          Fixed collinearity check to include nocons as well as hascons
*          Fixed small bug in Godfrey-Shea code - macros were global rather than local
*          Fixed larger bug in Godfrey-Shea code - was using mixture of sigma-squares from IV and OLS
*            with and without small-sample corrections
*          Added liml and kclass
*  1.0.30  Changed order of insts macro to match saved matrices S and W
*  2.0.00  Collinearities no longer -qui-
*          List of instruments tested in -orthog- option prettified
*  2.0.01  Fixed handling of nocons with no included exogenous, including LIML code
*  2.0.02  Allow C-test if unrestricted equation is just-identified.  Implemented by
*          saving Hansen-Sargan dof as = 0 in e() if just-identified.
*  2.0.03  Added score() option per latest revision to official ivreg
*  2.0.04  Changed score() option to pscore() per new official ivreg
*  2.0.05  Fixed est hold bug in first-stage regressions
*          Fixed F-stat finite sample adjustment with cluster option to match official Stata
*          Fixed F-stat so that it works with hascons (collinearity with constant is removed)
*          Fixed bug in F-stat code - wasn't handling failed posting of vcv
*          No longer allows/ignores nonsense options
*  2.0.06  Modified lsStop to sync with official ivreg 5.1.3
*  2.0.07a Working version of CUE option
*          Added sortpreserve, ivar and tvar options
*          Fixed smalls bug in calculation of T for AC/HAC - wasn't using the last ob
*          in QS kernel, and didn't take account of possible dropped observations
*  2.0.07b Fixed macro bug that truncated long varlists
*  2.0.07c Added dof option.
*          Changed display of RMSE so that more digits are displayed (was %8.1g)
*          Fixed small bug where cstat was local macro and should have been scalar
*          Fixed bug where C stat failed with cluster.  NB: wmatrix option and cluster are not compatible!
*  2.0.7d  Fixed bug in dof option
*  2.1.0   Added first-stage identification, weak instruments, and redundancy stats
*  2.1.01  Tidying up cue option checks, reporting of cue in output header, etc.
*  2.1.02  Used Poskitt-Skeels (2002) result that C-D eval = cceval / (1-cceval)
*  2.1.03  Added saved lists of separate included and excluded exogenous IVs
*  2.1.04  Added Anderson-Rubin test of signif of endog regressors
*  2.1.05  Fix minor bugs relating to cluster and new first-stage stats
*  2.1.06  Fix bug in cue: capture estimates hold without corresponding capture on estimates unhold
*  2.1.07  Minor fix to ereturn local wexp, promote to version 8.2
*  2.1.08  Added dofminus option, removed dof option.  Added A-R test p-values to e().
*          Minor bug fix to A-R chi2 test - was N chi2, should have been N-L chi2.
*          Changed output to remove potentially misleading refs to N-L etc.
*          Bug fix to rhs count - sometimes regressors could have exact zero coeffs
*          Bug fix related to cluster - if user omitted -robust-, orthog would use Sargan and not J
*          Changed output of Shea R2 to make clearer that F and p-values do not refer to it
*          Improved handling of collinearites to check across inexog, exexog and endo lists
*          Total weight statement moved to follow summ command
*          Added traps to catch errors if no room to save temporary estimations with _est hold
*          Added -savefirst- option. Removed -hascons-, now synonymous with -nocons-.
*  2.1.09  Fixes to dof option with cluster so it no longer mimics incorrect areg behavior
*          Local ivreg2_cmd to allow testing under name ivreg2
*          If wmatrix supplied, used (previously not used if non-robust sargan stat generated)
*          Allowed OLS using (=) syntax (empty endo and exexog lists)
*          Clarified error message when S matrix is not of full rank
*          cdchi2p, ardf, ardf_r added to saved macros
*          first and ffirst replay() options; DispFirst and DispFFirst separately codes 1st stage output
*          Added savefprefix, macro with saved first-stage equation names.
*          Added version option.
*          Added check for duplicate variables to collinearity checks
*          Rewrote/simplified Godfrey-Shea partial r2 code
* 2.1.10   Added NOOUTput option
*          Fixed rf bug so that first does not trigger unnecessary saved rf
*          Fixed cue bug - was not starting with robust 2-step gmm if robust/cluster
* 2.1.11   Dropped incorrect/misleading dofminus adjustments in first-stage output summary
* 2.1.12   Collinearity check now checks across inexog/exexog/endog simultaneously
* 2.1.13   Added check to catch failed first-stage regressions
*          Fixed misleading failed C-stat message
* 2.1.14   Fixed mishandling of missing values in AC (non-robust) block
* 2.1.15   Fixed bug in RF - was ignoring weights
*          Added -endog- option
*          Save W matrix for all cases; ensured copy is posted with wmatrix option so original isn't zapped
*          Fixed cue bug - with robust, was entering IV block and overwriting correct VCV
* 2.1.16   Added -fwl- option
*          Saved S is now robust cov matrix of orthog conditions if robust, whereas W is possibly non-robust
*          weighting matrix used by estmator.  inv(S)=W if estimator is efficient GMM.
*          Removed pscore option (dropped by official ivreg).
*          Fixed bug where -post- would fail because of missing values in vcv
*          Remove hascons as synonym for nocons
*          OLS now outputs 2nd footer with variable lists
* 2.1.17   Reorganization of code
*          Added ll() macro
*          Fixed N bug where weights meant a non-integer ob count that was rounded down
*          Fixed -fwl- option so it correctly handles weights (must include when partialling-out)
*          smatrix option takes over from wmatrix option.  Consistent treatment of both.
*          Saved smatrix and wmatrix now differ in case of inefficient GMM.
*          Added title() and subtitle() options.
*          b0 option returns a value for the Sargan/J stat even if exactly id'd.
*          (Useful for S-stat = value of GMM objective function.)
*          HAC and AC now allowed with LIML and k-class.
*          Collinearity improvements: bug fixed because collinearity was mistakenly checked across
*          inexog/exexog/endog simultaneously; endog predicted exactly by IVs => reclassified as inexog;
*          _rmcollright enforces inexog>endo>exexog priority for collinearities, if Stata 9.2 or later.
*          K-class, LIML now report Sargan and J.  C-stat based on Sargan/J.  LIML reports AR if homosked.
*          nb: can always easily get a C-stat for LIML based on diff of two AR stats.
*          Always save Sargan-Hansen as e(j); also save as e(sargan) if homoskedastic.
*          Added Stock-Watson robust SEs options sw()
* 2.1.18   Added Cragg-Donald-Stock-Yogo weak ID statistic critical values to main output
*          Save exexog_ct, inexog_ct and endog_ct as macros
*          Stock-Watson robust SEs now assume ivar is group variable
*          Option -sw- is standard SW.  Option -swpsd- is PSD version a la page 6 point 10.
*          Added -noid- option.  Suppresses all first-stage and identification statistics.
*          Internal calls to ivreg2 use noid option.
*          Added hyperlinks to ivreg2.hlp and helpfile argument to display routines to enable this.
* 2.1.19   Added matrix rearrangement and checks for smatrix and wmatrix options
*          Recursive calls to cstat simplified - no matrix rearrangement or separate robust/nonrobust needed
*          Reintroduced weak ID stats to ffirst output
*          Added robust ID stats to ffirst output for case of single endogenous regressor
*          Fixed obscure bug in reporting 1st stage partial r2 - would report zero if no included exogenous vars
*          Removed "HOLS" in main output (misleading if, e.g., estimation is AC but not HAC)
*          Removed "ML" in main output if no endogenous regressors - now all ML is labelled LIML
*          model=gmm is now model=gmm2s; wmatrix estimation is model=gmm
*          wmatrix relates to gmm estimator; smatrix relates to gmm var-cov matrix; b0 behavior equiv to wmatrix
*          b0 option implies nooutput and noid options
*          Added nocollin option to skip collinearity checks
*          Fixed minor display bug in ffirst output for endog vars with varnames > 12 characters
*          Fixed bug in saved rf and first-stage results for vars with long varnames; uses permname
*          Fixed bug in model df - had counted RHS, now calculates rank(V) since latter may be rank-deficient
*          Rank of V now saved as macro rankV
*          fwl() now allows partialling-out of just constant with _cons
*          Added Stock-Wright S statistic (but adds overhead - calls preserve)
*          Properties now include svyj.
*          Noted only: fwl bug doesn't allow time-series operators.
* 2.1.20   Fixed Stock-Wright S stat bug - didn't allow time-series operators
* 2.1.21   Fixed Stock-Wright S stat to allow for no exog regressors cases
* 2.2.00   CUE partials out exog regressors, estimates endog coeffs, then exog regressors separately - faster
*          gmm2s becomes standard option, gmm supported as legacy option
* 2.2.01   Added explanatory messages if gmm2s used.
*          States if estimates efficient for/stats consistent for het, AC, etc.
*          Fixed small bug that prevented "{help `helpfile'##fwl:fwl}" from displaying when -capture-d.
*          Error message in footer about insuff rank of S changed to warning message with more informative message.
*          Fixed bug in CUE with weights.
* 2.2.02   Removed CUE partialling-out; still available with fwl
*          smatrix and wmatrix become documented options. e(model)="gmmw" means GMM with arbitrary W
* 2.2.03   Fixed bug in AC with aweights; was weighting zi'zi but not ei'ei.
* 2.2.04   Added abw code for bw(), removed properties(svyj)
* 2.2.05   Fixed bug in AC; need to clear variable vt1 at start of loop
*          If iweights, Nprec (#obs with precision) rounded to nearest integer to mimic official Stata treatment
*          and therefore don't need Nprec scalar at all - will be same as N
*          Saves fwl_ct as macro.
*          -ffirst- output, weak id stat, etc. now adjust for number of partialled-out variables.
*          Related changes: df_m, df_r include adjustments for partialled-out variables.
*          Option nofwlsmall introduced - suppresses above adjustments.  Undocumented in ivreg2.hlp.
*          Replaced ID tests based on canon corr with Kleibergen-Paap rk-based stats if not homoskedastic
*          Replaced LR ID test stats with LM test stats.
*          Checks that -ranktest- is installed.
* 2.2.06   Fixed bug with missing F df when cue called; updated required version of ranktest 
* 2.2.07   Modified redundancy test statistic to match standard regression-based LM tests
*          Change name of -fwl- option to -partial-.
*          Use of b0 means e(model)=CUE.  Added informative b0 option titles. b0 generates output but noid.
*          Removed check for integer bandwidth if auto option used.
* 2.2.08   Add -nocollin- to internal calls and to -ivreg2_cue- to speed performance.
* 2.2.09   Per msg from Brian Poi, Alastair Hall verifies that Newey-West cited constant of 1.1447
*          is correct. Corrected mata abw() function. Require -ranktest- 1.1.03.
* 2.2.10   Added Angrist-Pischke multivariate f stats.  Rewrite of first and ffirst output.
*          Added Cragg-Donald to weak ID output even when non-iid.
*          Fixed small bug in non-robust HAC code whereby extra obs could be used even if dep var missing.
*             (required addition of  L`tau'.(`s1resid') in creation of second touse variable)
*          Fixed bugs that zapped varnames with "_cons" in them
*          Changed tvar and ivar setup so that data must be tsset or xtset; tvar and ivar can still be supplied
*             but are only checked for consistency.
*          Fixed bug in redundancy test stat when called by xtivreg2+cluster - no dofminus adj needed in this case
*          Removed undocumented and unverified Stock-Watson option
*          Bug in vecaccum meant that if there is only 1 observation it will crash with insufficient obs.
*            Affected kernel-robust AC/HAC if there were gaps in the data.  Fixed by replacing missings with zeros.
*          Fixed bug in LIML with AC but not HAC that meant non-robust VCV was reported.
*          Changed reporting so that gaps between panels are not reported as such.
*          Changed Stock-Wright S statistic so that it uses straight partialling-out of exog regressors
*            (had been, in effect, doing 2SGMM partialling-out)
*          Fixed xtivreg2-related bug in AC (not HAC) where dofminus correction was not used in calc of sigmas.
*          Fixed xtivreg2-related bug where IV weighting matrix didn't incorporate dofminus correction.
*          Added check that weight variable is not transformed by partialling out.
*          Fixed bug where dropped collinear endogenous didn't get a warning or listing
*          Removed N*CDEV Wald chi-sq statistic from ffirst output (LM stat enough)
*          Revised eigenvalue code of LIML with Mata version
* 2.2.11   -capture- instead of -qui- before reduced form to suppress not-full-rank error warning
*          Repaired bug in Stock-Wright S stat so that it handles partialling-out consistently.
* 2.2.12   Disabled auto bandwidth selection with panel data
* 2.2.13   Fixed partial bug - partialcons macro saved =0 unless _cons explicitly in partial() varlist
* 2.2.14   Incorporated ranktest and Mata library code into ivreg29.ado - no longer needs separate installation.

* Version notes for imported version of ranktest:
* 1.0.00  First distributed version
* 1.0.01  With iweights, rkstat truncates N to mimic official Stata treatment of noninteger iweights
*         Added warning if shat/vhat/vlab not of full rank.
* 1.0.02  Added NULLrank option
*         Added eq names to saved V and S matrices
* 1.0.03  Added error catching for collinearities between varlists
*         Not saving S matrix; V matrix now as in paper (without 1/N factor)
*         Statistic, p-value etc set to missing if vcv not of full rank (Assumpt 2 in paper fails)
* 1.0.04  Fixed touse bug - was treating missings as touse-able
*         Change some cross-products in robust loops to quadcross
* 1.0.05  Fixed bug with col/row names and ts operators.  Added eval to saved matrices.
* 1.1.00  First ssc-ideas version.  Added version 9.2 prior to Mata compiled section.
* 1.1.01  Allow non-integer bandwidth
* 1.1.02  Changed calc of yhat, zhat and pihat to avoid needlessly large intermediate matrices
*         and to use more accurate qrsolve instead of inverted X'X.
* 1.1.03  Fixed touse bug that didn't catch missing cluster variable
*         Fixed cluster bug - data needed to be sorted by cluster for Mata panel functions to work properly
* 1.2.00  Changed reporting so that gaps between panels are not reported as such.
*         Added support for tdelta in tsset data.
*         Changed tvar and ivar setup so that data must be tsset or xtset.
*         Removed unnecessary loops through panel data with spectral kernels
*         shat vcv now also saved.
*         Added support for Thompson/Cameron-Gelbach-Miller 2-level cluster-robust vcvv
*         Added support for Stock-Watson vcv - but requires data to have FEs partialled out, & doesn't support fweights
*         Removed mimicking of Stata mistake of truncated N with iweights to nearest integer
*         Fixed small bug with quadratic kernel (wasn't using negative weights)
*         Optimised code dealing with time-series data
* 1.2.01  Fixed bug that always used Stock-Watson spectral decomp to create invertible shat
*         instead of only when (undocumented) spsd option is called.
* 1.2.02  Fixed bug that did not allow string cluster variables
* 1.2.03  Fixed bug in code for cluster+kernel robust (typo in imported code from ivreg2=>crash)
* 1.2.04  Replaced code for S with ivreg2 code modified to support e matrix (cols > 1)
*         Code block (m_omega, m_calckw, struct definition) now shared by ranktest and ivreg2.
*         Renamed spsd option to psd following ivreg2 3.0.07
*         Added wf ("weight factor") and statement about sum of weights, as in ivreg2
*         Added dofminus option, as in ivreg2
*         Fixed minor reporting bug - was reporting gaps in entire panel, not just touse-d portion
*         Recoded kernel & bw checks to use shared ivreg2 subroutine vkernel
* 1.2.05  Fixed weighting bug introduced in 1.2.04.  All weights were affected.
*         Was result of incompatibility of code shared with ivreg2.
* 1.3.01  First ranktest version with accompanying Mata library (shared with -ivreg2-).
*         Mata library includes struct ms_vcvorthog, m_omega, m_calckw, s_vkernel.
*         Fixed bug in 2-way cluster code (now in m_omega in Mata library) - would crash if K>1.
* 1.3.02  Improved partialling out and matrix inversion - switched from qrsolve to invsym.
*         Use _makesymmetric() instead of symmetrizing by hand.
* 1.3.03  01Jan14. Fixed reporting bug with 2-way clustering and kernel-robust that would give
*         wrong count for 2nd cluster variable.
* 1.3.04  24Aug14. Fixed bug in markout - would include obs where some vars were missing

* Version notes for imported version of Mata library
* 1.1.01     First version of library.
*            Contains struct ms_vcvorthog, m_omega, m_calckw, s_vkernel.
*            Compiled in Stata 9.2 for compatibility with ranktest 1.3.01 (a 9.2 program).
* 1.1.02     Add routine cdsy. Standardized spelling/caps/etc. of QS as "Quadratic Spectral"
* 1.1.03     Corrected spelling of "Danielle" kernel in m_omega()
* 1.1.04     Fixed weighting bugs in robust and cluster code of m_omega where K>1
* 1.1.05     Added whichlivreg2(.) to aid in version control
* 1.1.06     Fixed remaining weighting bug (see 1.1.04) in 2-way clustering when interection
*            of clustering levels is groups
* 1.1.07     Fixed HAC bug that crashed m_omega(.) when there were no obs for a particular lag
