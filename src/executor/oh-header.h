/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OH_HEADER_H_
#define _OH_HEADER_H_

typedef struct HashHeaderRec {
  void *key;
  struct HashHeaderRec *prev;
  struct HashHeaderRec *next;
  struct HashHeaderRec **entry;
} HashHeaderRec, *HashHeader;

#endif _OH_HEADER_H_
