/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <varargs.h>

#ifndef CFE
#include "ozc.h"
#include "emit-common2.h"
#include "error.h"

void 
InternalError (char *format, ...)
{
  va_list pvar;
  
  fprintf (stderr,"%s at %d: ", yyfile, yylineno);
  Emit (stderr, "Internal Error: ");
  va_start (pvar);
  Emit2 (stderr, format, pvar);
  va_end (pvar);
  Error = 1;
}
#endif CFE

void
FatalError (char *format, ...)
{
  va_list pvar;
  
  fprintf (stderr,"%s at %d: ", yyfile, yylineno);
  va_start (pvar);
  Emit2 (stderr, format, pvar);
  va_end (pvar);
  Error = 1;
}  

#ifndef CFE
void
Warning (char *format, ...)
{
  va_list pvar;
  
  fprintf (stderr, "warning: %d: ", yylineno);
  va_start (pvar);
  Emit2 (stderr, format, pvar);
  va_end (pvar);
}  

void
WarningMsg (char *format, ...)
{
  va_list pvar;
  
  va_start (pvar);
  Emit2 (stderr, format, pvar);
  va_end (pvar);
}  
#endif CFE
