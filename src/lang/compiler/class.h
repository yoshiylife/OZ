/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CLASS_H_
#define _CLASS_H_

extern OO_ClassType CreateClass (char *, int, int);
extern void AddParent (char *);
extern void AddRenameAlias (char *, char *, int);
extern void LoadClass (char *, char *, char *);
extern void CreateMember (OO_Symbol);
extern void SetParentMethods ();
extern int CheckAccessCtrls ();
extern int CheckParents ();
extern OO_ClassType SearchParentClass (char *);
extern void SetParents ();
extern void CheckMembers ();
extern void CreateObjectClass ();

extern OO_ClassType ObjectClass;

inline static long long 
  str2oid(char *str)
{
  int l, h;

  if (!str)
    return 0LL;

  sscanf(str, "%08x%08x", &l, &h);
  return (long long)((long long)l << 32) + (h & 0xffffffff);
}

#endif _CLASS_H_
