/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _GENERIC_H_
#define _GENERIC_H_

typedef struct TypeParameterList_Rec {
  struct TypeParameterList_Rec *next;
  char param[1];
} TypeParameterList_Rec, *TypeParameterList;

extern SetTypeParameter (char *);

extern int SearchTypeParameter (char *);

#endif _GENERIC_H_

