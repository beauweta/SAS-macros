/*
Original from: Mike Zdeb, Maps Made Easy with SAS
*/

%macro centroid(
   map            /* Name of map data set, must have X and Y variables */
  ,type           /* Name of map region/subdivision variable, optional */ 
  ,copy  =        /* Name of map variables to simply copy to output    */
  ,xc    =XC      /* Name of output X centroid variable                */
  ,yc    =YC      /* Name of output Y centroid variable                */ 
  ,minmax=0       /* Boolean. Include XMIN, XMAX, YMIN, YMAX in output */
  ,out   =CENTERS /* Name of output data set                           */
  );

*-- Create two data sets - number of points per area and points;
data __CENTROID_MAP(drop=NPOINTS)
     __CENTROID_POINTS(keep=X Y NPOINTS &copy. rename=(X=XLAST Y=YLAST));
  set &map. end=LASTOBS;
  %if %length(&type.) %then by &type.;;
  where X ne .;
  output __CENTROID_MAP;
  NPOINTS+1;

  if %sysfunc(ifc( %length(&type.), last.&type., LASTOBS)) then do;
    output __CENTROID_POINTS;
    NPOINTS=0;
  end;
run;

*-- Calculate centroids;
data &out(keep=&type. X Y &copy. rename=(X=&xc. Y=&yc.));
  retain SAVPTR 1 XOLD YOLD 0;
  set __CENTROID_POINTS;

  XCG     =0; 
  YCG     =0;
  ARESUM  =0;
  FIRSTPNT=1;
  ENDPTR  =SAVPTR + NPOINTS - 1;
  do PTRM=SAVPTR to ENDPTR;
    set __CENTROID_MAP point=PTRM nobs=NOBSM;
    if FIRSTPNT then do;
      XOLD=X; YOLD=Y;
      SAVPTR=PTRM + NPOINTS;
      FIRSTPNT=0;
    end;
    ARETRI=(XLAST-X)*(YOLD-YLAST) + (XOLD-XLAST)*(Y-YLAST);
    XCG + (ARETRI*(X+XOLD));
    YCG + (ARETRI*(Y+YOLD));
    ARESUM+ARETRI;
    XOLD=X; YOLD=Y;
  end;
  AREINV=1 / ARESUM;
  X=( XCG*AREINV +XLAST) * 1/3;
  Y=( YCG*AREINV +YLAST) * 1/3;
  output;
  label X='X centroid'
        Y='Y centroid';
run;

%if &minmax. %then %do;
  proc summary data=&map. nway;
    %if %length(&type.) %then class &type.;;
    var X Y;
    output out=_CENTROID_MINMAX min=XMIN YMIN max=XMAX YMAX;
  run;  
  data &out.;
    merge &out __CENTROID_MINMAX(drop=_TYPE_ _FREQ_);
    %if %length(&type) %then by &type.;;
  run;  
%end;

proc datasets nolist nowarn;
  delete __CENTROID:;
quit;
%mend;

/*
%centroid(maps.states,state);
*/
