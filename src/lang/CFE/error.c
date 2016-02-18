/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <varargs.h>

#include "cb.h"

void
  FatalError (char *format, ...)
{
  va_list pvar;

  va_start (pvar);
  Emit2 (stderr, format, pvar);
  va_end (pvar);
}  
