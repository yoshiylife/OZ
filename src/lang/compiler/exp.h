/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXP_H_
#define _EXP_H_

extern OO_Expr CreateExp0 (OO_Expr, int);
extern OO_Expr CreateExp1 (OO_Expr, int);
extern OO_Expr CreateExp2 (OO_Expr, OO_Expr, int);
extern OO_Expr CreateExp3 (OO_Expr, OO_Expr, OO_Expr);
extern OO_Expr CreateExpAssign (OO_Expr, OO_Expr, int);
extern OO_Expr CreateExpConstant (int, char *, int, char *);
extern OO_Expr CreateExpMethodCall (OO_Expr, char *, OO_List, int, OO_Expr);
extern OO_Expr CreateExpArray (OO_Expr, OO_Expr);
extern OO_Expr CreateExpFork (OO_Expr);
extern OO_Expr CreateExpJoin (OO_Expr);
extern OO_Expr CreateExpNarrow (OO_Expr, OO_Expr);
extern OO_Expr CreateExpMember (OO_Expr, char *);

extern void DestroyExp (OO_Expr);

extern OO_Constant GetConstant (OO_Expr);

#endif _EXP_H_
