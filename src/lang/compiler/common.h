/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMMON_H_
#define _COMMON_H_

extern void DestroyObject (OO_Object);
extern OO_List CreateList (OO_Object, OO_Object);
extern OO_List AppendList (OO_List *, OO_List);
extern void DestroyList (OO_List);
extern int CountList (OO_List);
extern void CheckList (OO_List, OO_List);
extern void CheckSymInList (OO_List, OO_Symbol);

#endif _COMMON_H_
