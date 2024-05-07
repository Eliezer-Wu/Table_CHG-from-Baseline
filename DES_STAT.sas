%macro DES_STAT(_DATSRC =, _OUT = CHG_F_BASELINE, _AP =, _GROUP =, _OVERALL_NEED = Y, _OVERALL_EXCLUDE= %str(), 
                _STAT = %str(N MEAN STD MEDIAN MIN MAX Q1 Q3), _DEC_SPE = %str(), _ROUND = N, _OV = Y);

****************************************************************************************************************************************************************
*** _DATSRC         : Input Dataset                                                                                                                          ***
*** _OUT            : Name of the output dataset                                                                                                             ***
*** _AP             : Analysis Praramter, their values should be common across all subject                                                                   ***
*** _GROUP          : Column of the table, usually TRT                                                                                                       ***
*** _OVERALL_NEED   : _OVERALL_NEED takes value as Y or N (default as Y) to indicate whether a summary group "Overall" is needed.                            ***
*** _OVERALL_EXCLUDE: If a a summary group "Overall" is needed, specify group(s)                                                                             ***
***                   (if multiple, seperated by blank) to be excluded from "Overall" group. e.g. _OVERALL_EXCLUDE = %str(Placebo)                           ***
*** _STAT           : list of statistics                                                                                                                     ***
*** _DEC_SPE        : Specify appropriate decimal for PARAMCD(s), seperate PARAMCD and decimal wuth blank                                                    ***
***                   (if multiple, seperated by "|" between each PARAMCD-decimal pairs).                                                                    ***
***                   If not specified, detect the longest decimal for each PARAMCD automatically. e.g. _DEC_SPE = %str(BMI 1|TEMP 1)                        ***
*** _DIRECTION      : _DIRECTION takes value as Y or N (default as N) to indicate whether to maintain the direction of a rounded 0 value such as -0.00       ***
*** _OV             : preserve original value for (min, max), take value as (Y, N)                                                                           ***
****************************************************************************************************************************************************************;

*** input checking ***;
%if %bquote(&_DATSRC.) eq %str() %then %do;
    %put %str(WAR)NING: Required parameter _DATSRC is not given, please provide for change from baseline informarion (eg. ADLB, ADVS, ADPE). Macro stop.;
    %return;
%end;

%if %bquote(&_AP.   ) eq %str() %then %do;
    %put %str(WAR)NING: Required parameter _AP is not given, please provide to indicate structure of table;
    %put %str(WAR)NING:  (eg. APERIOD APERIODC AVISITN AVISIT ATPTN ATPT PARAMN PARAMCD PARAM). Macro stop.;
    %return;
%end;

%if %bquote(&_GROUP.) eq %str() %then %do;
    %put %str(WAR)NING: Required parameter _GROUP is not given, please provide to indicate group variable in _DATSRC (usually TRTP/A, TRTSEQP/A). Macro stop.;
    %return;
%end;

%if %bquote(%upcase(&_OVERALL_NEED.)) eq %str(Y) %then %do;
    %put If there is/are any group(s) specify in _GROUP you want to exclude from OVERALL, fill in _OVERALL_EXCLUDE, e.g. _OVERALL_EXCLUDE = %str(Placebo);
    %put If multiple, seperated by blank, e.g. _OVERALL_EXCLUDE = %str(Placebo DOSE1);
%end;
%else %if %bquote(%upcase(&_OVERALL_NEED.)) eq %str(N) %then %do;
%end;
%else %do;
    %put %str(WAR)NING: _OVERALL_NEED takes value as Y or N (default as N). Macro stop.;
    %return;
%end;

%if %bquote(&_STAT. ) eq %str() %then %do;
    %put %str(WAR)NING: Required parameter _STAT is not given, please provide to indicate statistics needed;
    %put %str(WAR)NING: Currently supported statistics : (N MEAN STD MEDIAN MIN MAX Q1 Q3). Macro stop.;
    %return;
%end;

%if %bquote(%upcase(&_ROUND.)) eq %str(Y) %then %do;
%end;
%else %if %bquote(%upcase(&_ROUND.)) eq %str(N) %then %do;
%end;
%else %do;
    %put %str(WAR)NING: _ROUND takes value as Y or N (default as N). Macro stop.;
    %return;
%end;

%if %bquote(%upcase(&_OV.)) eq %str(Y) %then %do;
%end;
%else %if %bquote(%upcase(&_OV.)) eq %str(N) %then %do;
%end;
%else %do;
    %put %str(WAR)NING: _OV takes value as Y or N (default as N). Macro stop.;
    %return;
%end;


%local VAR_LIST I ELEMANT COUNT _NE_LIST _STAT_LIST _STAT_LISTX;
%let COUNT = 0;
%let _STAT = %upcase(&_STAT);

*** check if every _AP exist ***;
    *** get variable list of input dataset ***;
proc sql noprint;
    select NAME into :VAR_LIST separated by "|"
    from dictionary.columns
    where libname = "WORK" and memname = "&_DATSRC"
    ;
quit;
    *** done ***;

    *** put error to log and stop macro if any of _AP not exist ***;
%do i = 1 %to %sysfunc(countw(&_AP &_GROUP, " "));
    %let ELEMENT = %upcase(%scan(&_AP &_GROUP, &i, " "));
    %if %sysfunc(findw(&VAR_LIST, &ELEMENT, |)) = 0 %then %do;
        %if %length(&_NE_LIST) %then %do;
            %let _NE_LIST = &_NE_LIST, &ELEMENT;
        %end;
        %else %do;
            %let _NE_LIST = &ELEMENT;
        %end;
    %end;
    %else %do;
        %let COUNT = &COUNT + 1;
    %end;
%end;

%put &_NE_LIST;
%if %length(&_NE_LIST) > 0 %then %put %sysfunc(catx(, ERR, OR:)) &_NE_LIST not exist in dataset &_DATSRC, please check. Macro stop;
%if &COUNT < %sysfunc(countw(&_AP &_GROUP, " ")) %then %return;
    *** done ***;
*** done ***;

*** statistic list for proc means later ***;
%do i = 1 %to %sysfunc(countw(&_STAT, " "));
    %let ELEMENT = %upcase(%scan(&_STAT, &i, " "));
        %if %length(&_STAT_LIST) %then %do;
            %let _STAT_LIST = &_STAT_LIST &ELEMENT = &ELEMENT;
        %end;
        %else %do;
            %let _STAT_LIST = &ELEMENT = &ELEMENT;
        %end;
%end;
*** done ***;

%local _OVERALL_EXCLUDE_LIST;
%do i = 1 %to %sysfunc(countw(&_OVERALL_EXCLUDE., " "));
    %let ELEMENT = %upcase(%scan(&_OVERALL_EXCLUDE., &i, " "));
        %if %length(&_OVERALL_EXCLUDE_LIST) %then %do;
            %let _OVERALL_EXCLUDE_LIST = &_OVERALL_EXCLUDE_LIST, "&ELEMENT";
        %end;
        %else %do;
            %let _OVERALL_EXCLUDE_LIST = "&ELEMENT";
        %end;
%end;

%put &_OVERALL_EXCLUDE_LIST;

data _DS01;
    set &_DATSRC;
    if ANL01FL = "Y";
    %if %bquote(%upcase(&_OVERALL_NEED)) eq Y %then %do;
    output;
        %if %bquote(&_OVERALL_EXCLUDE.) eq %str() %then %do;
            &_GROUP = "Overall"; output;
        %end;
        %if %bquote(&_OVERALL_EXCLUDE.) ne %str() %then %do;
            if upcase(&_GROUP) not in (&_OVERALL_EXCLUDE_LIST) then do; 
                &_GROUP = "Overall"; output; 
            end;
        %end;
    %end;
run;

*** find max decimal for each PARAM ***;
%if &_DEC_SPE eq %str() %then %do;
proc sql noprint;
    create table _DEC as
    select distinct PARAMCD, PARAM, PARAMN, DEC from (
    select PARAMCD, PARAM, PARAMN, AVAL, lengthn(scan(strip(put(AVAL, best.)), 2, ".")) as DEC
    from _DS01
    group by PARAMCD, PARAM, PARAMN
    having DEC = max(DEC)
    )
    ;
quit;
%end;
%if &_DEC_SPE ne %str() %then %do;
proc sql noprint;
    create table _DEC01 as
    select distinct PARAMCD, PARAM, PARAMN, DEC from (
    select PARAMCD, PARAM, PARAMN, AVAL, lengthn(scan(strip(put(AVAL, best.)), 2, ".")) as DEC
    from _DS01
    group by PARAMCD, PARAM, PARAMN
    having DEC = max(DEC)
    )
    ;
quit;

data _DEC_LIST;
    length PARAMCD $8. DEC 8.;
%do i = 1 %to %sysfunc(countw(&_DEC_SPE., "|"));
    %let ELEMENT = %upcase(%scan(&_DEC_SPE., &i, "|"));
    %let _PARAMCD = %scan(&ELEMENT., 1, " ");
    %let _DEC = %scan(&ELEMENT., 2, " ");
    PARAMCD = "&_PARAMCD";
    DEC = &_DEC;
    output;
%end;
run;

proc sql noprint;
    create table _DEC(drop = DEC rename = (DECX = DEC)) as
    select a.*, coalesce(b.DEC, a.DEC) as DECX
    from _DEC01 a left join _DEC_LIST b
    on a.PARAMCD = b.PARAMCD
    ;
quit;
%end;

proc sql noprint;
    create table _DS02 as
    select a.*, b.DEC
    from _DS01 a left join _DEC b
    on a.PARAMCD = b.PARAMCD
    ;
quit;
*** done ***;

*** construct statistics by proc means ***;
proc sort data = _DS02 out = _DS03;
    by &_AP &_GROUP DEC SUBJID;
run;

proc means data = _DS03 noprint;
    by &_AP &_GROUP DEC;
    var AVAL;
    output out = _DS04_AVAL &_STAT_LIST;
run;
proc means data = _DS03(where = (missing(ABLFL) and upcase(AVISIT) ^= "BASELINE")) noprint;
    by &_AP &_GROUP DEC;
    var CHG;
    output out = _DS04_CHG &_STAT_LIST;
run;
*** done ***;

*** modify value into proper decimal format ***;
data _DS05;
    set _DS04_AVAL(in = INA) _DS04_CHG(in = INC);
    CATEGORY = ifc(INA, "AVAL", "CHG");
%if %bquote(%upcase(&_ROUND.)) eq %str(Y) %then %do;

    %if %index(&_STAT, N) %then %do;
        NX = strip(put(N, best.));
    %end;
    %if %index(&_STAT, MEAN) %then %do;
        MEANX = strip(putn(MEAN, 10 + 0.1 * (DEC + 1)));
    %end;
    %if %index(&_STAT, STD) %then %do;
        STDX = strip(putn(STD, 10 + 0.1 * (DEC + 2)));
    %end;
    %if %index(&_STAT, STDERR) %then %do;
        STDERRX = strip(putn(STDERR, 10 + 0.1 * (DEC + 2)));
    %end;
    %if %index(&_STAT, MEDIAN) %then %do;
        MEDIANX = strip(putn(MEDIAN, 10 + 0.1 * (DEC + 1)));
    %end;
    %if %index(&_STAT, MIN) %then %do;
        %if %bquote(%upcase(&_OV)) eq Y  %then %do;
            MINX = strip(put(MIN, best.));
            MAXX = strip(put(MAX, best.));
        %end;
        %else %if %bquote(%upcase(&_OV)) eq N %then %do;
            MINX = strip(putn(MIN, 10 + 0.1 * DEC));
            MAXX = strip(putn(MAX, 10 + 0.1 * DEC));
        %end;
        %else %do;
            %put _OV should be Y or N, macro stop;
            %return;
        %end;
    %end;
    %if %index(&_STAT, Q1) %then %do;
        Q1X = strip(put(Q1, best.));
    %end;
    %if %index(&_STAT, Q3) %then %do;
        Q3X = strip(put(Q3, best.));
    %end;

%end;

%else %if %bquote(%upcase(&_ROUND.)) eq %str(N) %then %do;

    %if %index(&_STAT, N) %then %do;
        NX = strip(put(N, best.));
    %end;
    %if %index(&_STAT, MEAN) %then %do;
        MEANX = strip(putn(round(MEAN, 10**(-1 * (DEC + 1))), 10 + 0.1 * (DEC + 1)));
    %end;
    %if %index(&_STAT, STD) %then %do;
        STDX = strip(putn(round(STD, 10**(-1 * (DEC + 1))), 10 + 0.1 * (DEC + 2)));
    %end;
    %if %index(&_STAT, STDERR) %then %do;
        STDERRX = strip(putn(round(STDERR, 10**(-1 * (DEC + 1))), 10 + 0.1 * (DEC + 2)));
    %end;
    %if %index(&_STAT, MEDIAN) %then %do;
        MEDIANX = strip(putn(round(MEDIAN, 10**(-1 * (DEC + 1))), 10 + 0.1 * (DEC + 1)));
    %end;
    %if %index(&_STAT, MIN) %then %do;
        %if %bquote(%upcase(&_OV)) eq Y  %then %do;
            MINX = strip(put(MIN, best.));
            MAXX = strip(put(MAX, best.));
            %if &_DEC_SPE ne %str() %then %do;
                %do i = 1 %to %sysfunc(countw(&_DEC_SPE., "|"));
                    %let ELEMENT = %upcase(%scan(&_DEC_SPE., &i, "|"));
                    %let _PARAMCD = %scan(&ELEMENT., 1, " ");
                    if PARAMCD = "&_PARAMCD." then do;
                        MINX = strip(putn(round(MINX, 10**(-1 * (DEC + 1))), 10 + 0.1 * DEC));
                        MAXX = strip(putn(round(MAXX, 10**(-1 * (DEC + 1))), 10 + 0.1 * DEC));
                    end;
                %end;
            %end;
        %end;
        %else %if %bquote(%upcase(&_OV)) eq N %then %do;
            MINX = strip(putn(round(MIN, 10**(-1 * (DEC + 1))), 10 + 0.1 * DEC));
            MAXX = strip(putn(round(MAX, 10**(-1 * (DEC + 1))), 10 + 0.1 * DEC));
        %end;
        %else %do;
            %put _OV should be Y or N, macro stop;
            %return;
        %end;
    %end;
    %if %index(&_STAT, Q1) %then %do;
        Q1X = strip(put(round(Q1, 10**(-1 * (DEC + 1))), best.));
    %end;
    %if %index(&_STAT, Q3) %then %do;
        Q3X = strip(put(round(Q2, 10**(-1 * (DEC + 1))), best.));
    %end;

%end;
run;
*** done ***;

*** transpose ***;

%do i = 1 %to %sysfunc(countw(&_STAT, " "));
    %let ELEMENT = %upcase(%scan(&_STAT, &i, " "));
        %if %length(&_STAT_LISTX) %then %do;
            %let _STAT_LISTX = &_STAT_LISTX &ELEMENT.X;
        %end;
        %else %do;
            %let _STAT_LISTX = &ELEMENT.X;
        %end;
%end;

%let _STAT_LISTX = %sysfunc(tranwrd(&_STAT_LISTX, %str(MEANX STDX), MEAN_STDX));
%let _STAT_LISTX = %sysfunc(tranwrd(&_STAT_LISTX, %str(MEANX STDERRX), MEAN_STDERRX));
%let _STAT_LISTX = %sysfunc(tranwrd(&_STAT_LISTX, %str(Q1X Q3X)   , Q1Q3     ));
%let _STAT_LISTX = %sysfunc(tranwrd(&_STAT_LISTX, %str(MINX MAXX) , MINMAX   ));



data _DS06;
    retain CATEGORY &_AP &_GROUP &_STAT_LISTX;
    set _DS05;
%if %index(&_STAT, STD) %then %do;
        MEAN_STDX = ifc(NX = 1, strip(MEANX)||" (-)", strip(MEANX)||" ("||strip(STDX)||")");
%end;
%if %index(&_STAT, STDERR) %then %do;
        MEAN_STDERRX = ifc(NX = 1, strip(MEANX)||" (-)", strip(MEANX)||" ("||strip(STDERRX)||")");
%end;
    Q1Q3      = strip(Q1X )||", "||strip(Q3X );
    MINMAX    = strip(MINX)||", "||strip(MAXX);
    keep CATEGORY &_AP &_GROUP &_STAT_LISTX;
run;

proc transpose data = _DS06 out = _DS07;
    by CATEGORY &_AP;
    id &_GROUP;
    var &_STAT_LISTX;
run;

data &_OUT.;
    set _DS07;
    select(_NAME_);
        when("NX"       )    _NAME_ = "N"        ;
        when("MEAN_STDX")    _NAME_ = "Mean (SD)";
        when("MEAN_STDERRX") _NAME_ = "Mean (SE)";
        when("MEDIANX"  )    _NAME_ = "Median"   ;
        when("MINMAX"   )    _NAME_ = "Min, Max" ;
        when("Q1Q3"     )    _NAME_ = "Q1, Q3"   ;
    end;
    rename _NAME_ = STATISTICS;
run;
*** done ***;

%put output datasets: &_OUT., check table shell for your next step.;

%mend DES_STAT;
