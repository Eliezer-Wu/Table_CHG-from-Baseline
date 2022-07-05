title; footnote; proc delete data = _all_; run;
data ADaM_ADSL; set ADS12.ADSL; run;
data ADaM_ADVS; set ADS12.ADVS; run;

*** N ***;
%let n1 = 0; %let n2 = 0;
%put &n1. &n2.;

data pop;
    set ADaM_ADSL;
    length TRT $100.;
    if TRT01A = "Placebo"             then do; ORD = 1; TRT = "&_hr0."; end;
    if TRT01A = "A4250 120 ug/kg/day" then do; ORD = 2; TRT = "&_hr1."; end;
run;

proc freq data = pop noprint; tables TRT*ORD / out = N; run;

data _NULL_;
    set N;
    call symput("n"||strip(ORD), strip(COUNT));
run;
%put &n1. &n2.;

*** VS modification ***;
    *** identify decimal ***;
data VS01;
    set ADaM_ADVS;
    length TRT $100.;
    if TRT01A = "Placebo"             then do; ORD = 1; TRT = "&_hr0."; end;
    if TRT01A = "A4250 120 ug/kg/day" then do; ORD = 2; TRT = "&_hr1."; end;
    if PARCAT1 = "VITAL SIGNS";
    if PARAMCD ^= "BODLNGTH";
    if not missing(AVAL);
    if ANL01FL = "Y";
run;

data DECIMAL;
    set VS01;
    DEC = lengthn(scan(AVAL, 2, "."));
    keep PARAMCD PARAM DEC;
proc sort;
    by PARAMCD descending DEC;
proc sort nodupkey;
    by PARAMCD;
run;
    *** merge decimal for each PARAM ***;
proc sql;
    create table VS02 as
    select a.*, b.DEC
    from VS01 as a left join DECIMAL as b
    on a.PARAMCD = b.PARAMCD
;
quit;
proc sort data = VS02; by AVISITN AVISIT PARAMN PARAM ORD DEC; run;

    *** find out LAST VISIT for each USUBJID and set together ***;
data LAST;
    set VS02;
    AVISITN = 999;
    AVISIT = "Last Visit [2]";
proc sort; by ORD USUBJID PARAMN ADY; run;
data LAST2;
    set LAST;
    by ORD USUBJID PARAMN ADY;
    if last. PARAMN;
proc sort; by AVISITN AVISIT PARAMN PARAM ORD DEC;
run;
data VS03;
    set VS02 LAST2;
run;

*** DONE ***;



*** construct statistic with proper deciaml: n, mean(std), median, range ***;

%macro CR_STAT(DATA = , CONDITION = , VAR = , TYPE = );
proc means data = &DATA (where = (&CONDITION)) noprint;
    by    AVISITN AVISIT PARAMN PARAM ORD DEC;
    var     &VAR;
    output n = n mean = mean std = std median = median min = min max = max out = &TYPE.01;
run;
data &TYPE.02;
    set &TYPE.01;
    length NX MEANX STDX MEDIANX MEANSTD RANGE $100.;
    NX = strip(put(N, 4.0));

    select(DEC);
        when(0) do;
            MEANX   = strip(put(MEAN, 7.1));
            STDX    = ifc(N > 1 ,strip(put(STD, 8.2)), "-");
            MEDIANX = strip(put(MEDIAN, 7.1));
        end;
        when(1) do;
            MEANX   = strip(put(MEAN, 7.2));
            STDX    = ifc(N > 1 ,strip(put(STD, 8.3)), "-");
            MEDIANX = strip(put(MEDIAN, 7.2));
        end;
        otherwise;
    end;
    
    MEANSTD = strip(MEANX)||" ("||strip(STDX)||")";
    RANGE = strip(MIN)||", "||strip(MAX);
run;
proc transpose out = &TYPE.02_T;
    by AVISITN AVISIT PARAMN PARAM;
    id ORD;
    var NX MEANSTD MEDIANX RANGE;
run;
%mend;

    *** BASELINE ***;

%CR_STAT(DATA = VS03, CONDITION = ABLFL = "Y" and AVISIT = "Baseline", VAR = AVAL, TYPE = BASE);

    *** POST-BASELINE VISIT ***;

%CR_STAT(DATA = VS03, CONDITION = ABLFL ^= "Y" and AVISIT ^= "Last Visit [2]", VAR = AVAL, TYPE = WEEK);

    *** LAST VISIT ***;

%CR_STAT(DATA = VS03, CONDITION = ABLFL ^= "Y" and AVISIT = "Last Visit [2]", VAR = AVAL, TYPE = LAST);

    *** POST-BASELINE chg from BASELNE ***;

%CR_STAT(DATA = VS03, CONDITION = ABLFL ^= "Y" and AVISIT ^= "Last Visit [2]", VAR = CHG, TYPE = WEEKCHG);

    *** LAST VISIT chg from BASELNE ***;

%CR_STAT(DATA = VS03, CONDITION = ABLFL ^= "Y" and AVISIT = "Last Visit [2]", VAR = CHG, TYPE = LASTCHG);

*** DONE ***;
