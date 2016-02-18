/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _LANG_STATEMENT_H_
#define _LANG_STATEMENT_H_

extern OO_Statement CreateExceptionName (OO_Symbol, OO_Symbol);
extern OO_Statement CreateExceptionHandler ();
extern OO_Statement SetExceptionNames (OO_ExceptionHandler, OO_ExceptionName);
extern OO_Statement SetExceptionHandler (OO_ExceptionHandler, OO_Statement);
extern OO_Statement CreateCaseLabel (OO_Expr);
extern OO_Statement CreateCompoundStatement (OO_Block);
extern OO_Statement SetCompoundStatement (OO_CompoundStatement, OO_Statement);
extern OO_Statement CreateExprStatement (OO_Expr);
extern OO_Statement CreateIfStatement (OO_Expr);
extern OO_Statement 
  SetIfStatement (OO_IfStatement, OO_Statement, OO_Statement);
extern OO_Statement CreateWhileStatement (OO_Expr);
extern OO_Statement SetWhileStatement (OO_WhileStatement, OO_Statement);
extern OO_Statement CreateDoStatement ();
extern OO_Statement SetDoStatement (OO_DoStatement, OO_Statement, OO_Expr);
extern OO_Statement CreateForStatement (OO_Expr, OO_Expr, OO_Expr);
extern OO_Statement SetForStatement (OO_ForStatement, OO_Statement);
extern OO_Statement CreateSwitchStatement (OO_Expr);
extern OO_Statement SetSwitchStatement (OO_SwitchStatement, OO_Statement);
extern OO_Statement CreateJumpStatement (char);
extern OO_Statement CreateInlineStatement (char *, char *);
extern OO_Statement CreateWithExprStatement (char, OO_Expr, OO_Expr);
extern OO_Statement CreateNoExprStatement (char);
extern OO_Statement CreateExceptionStatement ();
extern OO_Statement SetExceptionTry (OO_ExceptionStatement, OO_Statement);
extern OO_Statement 
  SetExceptionHandlerList (OO_ExceptionStatement, OO_ExceptionHandler);
extern OO_Statement CreateDebugPrintStatement (OO_Expr, char *, OO_List);
extern OO_Statement CreateDebugBlockStatement ();
extern OO_Statement SetDebugBlock (OO_DebugBlockStatement, OO_Statement);

extern void DestroyStatement (OO_Statement);
extern void DestroyStatements (OO_Statement);
extern void CheckReturnStatement (OO_Statement);

#endif _LANG_STATEMENT_H_
