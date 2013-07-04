\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{gladbookssalesinvoice}[2013/07/04 Gladbooks Invoice Class]
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{letter}}
\ProcessOptions\relax
\LoadClass[a4paper]{letter}
\RequirePackage{color}
\RequirePackage{fontspec}
\RequirePackage{fancyhdr}
\RequirePackage{lipsum}
\usepackage{longtable}

% set up page layout
\pagestyle{fancy}
\topmargin -58pt
\headheight 85pt
\headsep 18pt
\oddsidemargin -30pt
\textwidth 525pt
\headwidth 525pt
\textheight 420pt
\renewcommand{\headrulewidth}{1pt}
\renewcommand{\footrulewidth}{1pt}

% declare our fonts
\font\gslogoglad="FreeSerifBoldItalic" at 48pt
\font\gslogoserv="FreeSerifBoldItalic" at 46pt
\font\gsboldserif="FreeSerifBold" at 12pt
\font\gsheading="FreeSerifBold" at 18pt
\font\gsletter="FreeSerif" at 11pt
\font\gsfixedwidth="FreeMono" at 10pt

% define our pretty colours
\definecolor{gsblue}{rgb}{0.1640625,0.1640625,0.8671875}
\definecolor{gsbluelt}{rgb}{0.6953125,0.80078125,0.875}
\definecolor{gsbluegrey}{rgb}{0.4296875,0.53515625,0.64453125}
\definecolor{gsred}{rgb}{0.84375,0.00390625,0.1328125}

\def\gslogo{
    \vspace{0pt}
    \color{gsblue}
    \bf\gslogoglad{glad}%
    \color{black}
    \bf\gslogoserv{books}\\
    \normalfont
    \vspace{18pt}
}
\def\gsaddress{
    \bf\gsboldserif
    Gladbooks Limited (SC411989)\\
    272 Bath Street\\
    Glasgow\\
    G2 4JR\\
    UNITED KINGDOM\\
    \normalfont
}
\def\gsterms{
    \vspace{10pt}
    \bf\gsboldserif
    VAT
    \normalfont

    \vspace{10pt}

    \vspace{10pt}

    \bf\gsboldserif
    Terms
    \normalfont

    \vspace{10pt}
    Invoices are due to be paid in cleared funds on or before the due date indicated.  Please note, late fees and interest will be applied if payment is received after the due date.  Please allow enough time for payment to clear by your chosen method before the due date.

    \vspace{10pt}

    \bf\gsboldserif
    Payment
    \normalfont

    \vspace{10pt}
    We accept payment by the following methods: \\

    \vspace{10pt}
    \begin{tabular}{ll}
    \bf Bank \bf Transfer \\
    Account Name: & Gladbooks Limited \\
    Sort Code: & 00-00-00 \\
    Account Number: & 01234567 \\
    Bank: & A Big Bank \\
    \end{tabular}

    \vspace{12pt}
    \gsboldserif
    \begin{center}
    PLEASE DO NOT SEND CHEQUES
    \end{center}

}

\newcommand{\gsdocheading}[1]{
    \begin{center}
    \gsheading
    #1
    \end{center}
}

\newcommand{\customertable}[7]{
    \begin{tabular}{p{150pt}p{190pt}ll}
    Attn: #1 & & Telephone: & +44 (0)131 510 0340 \\
    #2 & & Email: & billing@gladbooks.com \\
    #3 \\
    #4 & & VAT \#: & GB 155 0518 27 \\
    #5 \\
    #6 \\
    #7 \\
    \end{tabular}
}

\newcommand{\gsdocmeta}[5]{
    \gsboldserif
    \begin{tabular}{ll}
    Date (Tax Point): & #1 \\
    Issued: & #2 \\
    Due: & #3 \\
    Ref: & #4 \\
    Your Ref: & #5 \\
    \end{tabular}
}

\newcommand{\gslineitems}[4]{
    \gsfixedwidth
    \begin{longtable}{|p{460pt}|r|}
    \hline
    \bf Item & \bf Amount \\
    \hline\hline
    \endfirsthead
    \hline
    \bf Item & \bf Amount \\
    \hline\hline
    \endhead
    \hline
    \multicolumn{2}{|c|}{{Continued on Next Page\ldots}} \\
    \hline
    \multicolumn{2}{c}{{}} \\
    \endfoot
    \endlastfoot
    #1
    & \\
    \hline
    #2
    \hline
    \end{longtable}
}

\lhead{\gslogo}
\rhead{\gsaddress}
\lfoot{\gsterms}
\cfoot{}
\rfoot{}
\bf\gsletter
