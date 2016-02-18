/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _GENERIC_H_
#define _GENERIC_H_

typedef struct ParameterListRec
{
  struct ParameterListRec *next;
  int len;
  char *type1;
  char *type2;
  char *type3;
  char param[1];
} ParameterListRec, *ParameterList;

#endif _GENERIC_H_
