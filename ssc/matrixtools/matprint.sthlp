{smcl}
{* *! version 0.23}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help matlist" "help matlist"}{...}
{vieweralsosee "Help log2markup (if installed)" "help log2markup"}{...}
{vieweralsosee "Help sumat (Is installed with matprint" "help sumat"}{...}
{vieweralsosee "Help estout (if installed)" "help estout"}{...}
{vieweralsosee "Help mat2txt (if installed)" "help mat2txt"}{...}
{vieweralsosee "Help outtable (if installed)" "help outtable"}{...}
{viewerjumpto "Syntax" "matprint##syntax"}{...}
{viewerjumpto "Description" "matprint##description"}{...}
{viewerjumpto "Examples" "matprint##examples"}{...}
{viewerjumpto "Author and support" "matprint##author"}{...}
{title:Title}
{phang}
{bf:matprint} {hline 2} Printing and styling a Stata matrix

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:matprint} matrixname [{help using}] [[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt s:tyle(string)}} Style for output. One of the values {bf:smcl} (default), 
{bf:csv} (semicolon separated style), 
{bf:latex or tex} (latex style),
{bf:html} (html style) and
{bf:md} (markdown style) 
.{p_end}
{synopt:{opt d:ecimals(string)}} Matrix of integers specifying numbers of 
decimals at cell level. If the matrix is smaller than the data matrix the right
most column is copied to get the same number of columns. 
And likewise for the bottom row.{p_end}
{synopt:{opt ti:tle(string)}} Title/caption for the matrix output.{p_end}
{synopt:{opt to:p(string)}} String containing text prior to table content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt u:ndertop(string)}} String containing text between header and table 
content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt b:ottom(string)}} String containing text after to table content.
Default is dependent of the value of the style option.{p_end}
{synopt:{opt r:eplace}} Delete an existing {help using:using} file before adding table.{p_end}
{synopt:{opt noe:qstrip}} Do not remove duplicate successive roweq or coleq values.{p_end}
{synopt:{opt h:idesmall(integer)}} If set hide all values below the set value.
Default is the value 0, ie no hidding.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:matprint} prints and styles a matrix. The styles can be {help smcl:smcl} 
for nice outlook in the log (and when eg saved in the using file the output can 
be used in smcl documentation files), csv for a semicolon separated output
html, tex/latex and md (markdown).

{pstd}
The styles can be added non standard style code pre table (option {opt to:p}), 
post header (option {opt u:ndertop}) and post table (option {opt b:ottom}).

{pstd}
A title/caption for the table can be added as well as a column title for roweq 
names (option {opt r:owtitle1})

{pstd}
Number of decimals can be set at cell level in option {opt d:ecimals} by 
specifying a matrix of integers. If the decimal matrix is smaller than the data
matrix first the right most column of integers are copied and then the bottom
row is also copied to get the same size.
If the decimal matrix is too big only the top left part of the decimals numbers
matching the size of the data matrix is used.

{pstd}
{cmd:matprint} is a mix of {help matlist:matlist} and if installed 
{help estout:estout} for matrices.
The command {help matlist:matlist} to me is too detailed with respect to 
controlling the smcl output and too little detailed with respect to styles.
The command {help estout:estout} has the concept of styles and a simple setting
of decimals. However presenting and styling matrices is not the main focus.
And also here there are too much functionality.

{pstd}
{cmd:matprint} is highly integrated with {help log2markup:log2markup} such that
a matrix in a layout of eg html or latex can be merged to the final document
generated by log2markup in the same style as the end document.

{marker examples}{...}
{title:Examples}

{pstd}Below is a set of examples. You can copy the code and insert it in the 
command window or you can just click once on each blue line below.
Then the command is automatically moved to the command window and executed.{p_end}
{pstd}Note that there is progression in the examples such a command line may require 
some of the previous lines to show the intended properly.{p_end}

{pstd}In this example estimates and their confidence intervals for two regression
models are combined into one summary matrix.{p_end}
{phang}{stata `"sysuse auto ,clear"'}{p_end}

{phang}First regession and matrix part b1:{p_end}
{phang}{stata `"regress price mpg turn weight"'}{p_end}
{phang}{stata `"matrix b1 = r(table)"'}{p_end}
{phang}{stata `"matrix b1 = b1["b", 1...] \ b1["ll".."ul", 1...]"'}{p_end}
{phang}{stata `"matrix roweq b1 = M1"'}{p_end}

{phang}Second regession and matrix part b2:{p_end}
{phang}{stata `"regress price gear_ratio mpg foreign"'}{p_end}
{phang}{stata `"matrix b2 = r(table)"'}{p_end}
{phang}{stata `"matrix b2 = b2["b", 1...] \ b2["ll".."ul", 1...]"'}{p_end}
{phang}{stata `"matrix roweq b2 = M2"'}{p_end}

{phang}Combine the two regression summaries using {help mat_rapp:mat_rapp}:{p_end}
{phang}{stata `"mat_rapp b12 : b1 b2, miss(.) cons"'}{p_end}
{phang}{stata "matrix b12 = b12'"}{p_end}

{phang}To see the matrix in the log window in smcl style and 3 decimals for the
first column and 2 decimals for the rest.{p_end}
{phang}{stata `"matprint b12, title(Regression summary table) decimals((3, 2))"'}{p_end}

{phang}Sometimes eg when using {help log2markup:log2markup (if installed)} it is
preferred that the output in the log is in latex/tex or html like below:{p_end}
{phang}{stata `"matprint b12, title(Regression summary table) decimals(3) style(html)"'}{p_end}
{phang}{stata `"matprint b12, title(Regression summary table) decimals(3) style(tex)"'}{p_end}

{phang}Show replicated roweq and coleg values:{p_end}
{phang}{stata `"matprint b12, noe"'}{p_end}

{phang}Hide values less than 5:{p_end}
{phang}{stata `"matprint b12, hidesmall(5)"'}{p_end}

{phang}The use of matprint is also demonstrated in {help sumat##examples:sumat examples}.{p_end}

{browse "http://www.bruunisejs.dk/StataHacks/My%20commands/matprint/matprint_demo/":To see more examples}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Section for General Practice, {break}
	Dept. Of Public Health, {break}
	Aarhus University
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:nhbr@ph.au.dk":nhbr@ph.au.dk}
{p_end}