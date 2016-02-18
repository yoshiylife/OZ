/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#define CFE

#include "cb.h"
#include "cfe.h"

#include "../compiler/class.c"

void
  DestroyClass (OO_ClassType cl)
{
  if (!cl)
    return;

  DestroyList (cl->public_list);
  DestroyList (cl->protected_list);
  DestroyList (cl->private_list);
  DestroySymbol (cl->symbol);
  free (cl);
}
