/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "../compiler/emit-common2.c"

void
  Emit (FILE *fp, char *format, ...)
{
  va_list pvar;

  if (!fp)
    return;

  va_start (pvar);
  Emit2 (fp, format, pvar);
  va_end (pvar);
}
