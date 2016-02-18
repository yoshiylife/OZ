/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZ_LAYOUT_INFO_H_
#define _OZ_LAYOUT_INFO_H_

#include "oz++/object-type.h"

typedef struct OZ_LayoutPartRec {
  unsigned short order;
  OID type;
} OZ_LayoutPartRec, *OZ_LayoutPart;

typedef struct OZ_LayoutRec {
  /* allocation info */
  struct OZ_AllocateInfoRec info;

  /* layout info */
  unsigned int number_of_common_entries;
  unsigned int number_of_own_entries;
  OZ_LayoutPart common;
  OZ_LayoutPartRec own[1];
} OZ_LayoutRec, *OZ_Layout;

#endif _OZ_LAYOUT_INFO_H_
