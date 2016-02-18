/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZ_CLASS_TYPE_H_
#define _OZ_CLASS_TYPE_H_

#include "oz++/object-type.h"

typedef OID ClassID;
typedef ClassID OZ_ClassID;

typedef struct OZ_FunctionEntryRec {
  unsigned int function_no;
  OZ_ClassID class_part_id; /* determined at runtime */
} OZ_FunctionEntryRec, *OZ_FunctionEntry;

typedef struct OZ_ClassPartRec {
  unsigned int number_of_entries;

  OZ_ClassID cid;
  OZ_ClassID compiled_vid;

  OZ_AllocateInfoRec info;

  OZ_FunctionEntryRec entry[1]; /* must be last */
} OZ_ClassPartRec, *OZ_ClassPart;

typedef struct OZ_ClassInfoRec {
  unsigned int number_of_parts;
  OZ_ClassPart parts[1]; /* must be last */
} OZ_ClassInfoRec, *OZ_ClassInfo;

#endif _OZ_CLASS_TYPE_H_
