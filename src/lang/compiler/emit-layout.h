/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMPILER_EMIT_LAYOUT_H
#define _COMPILER_EMIT_LAYOUT_H

#include "lang/internal.h"
#include "oz++/object-type.h"
#include "oz++/layout-info.h"
#include "lang/types.h"

extern struct OZ_LayoutRec *EmitLayout ();
extern int GetRecordSize (struct OO_ClassType_Rec *);
extern void EmitExceptions ();

#endif _COMPILER_EMIT_LAYOUT_H
