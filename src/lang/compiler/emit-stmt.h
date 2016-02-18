/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_STATEMENT_H_
#define _EMIT_STATEMENT_H_

extern void EmitStatement (OO_Statement);
extern void EmitFreeRecordArgs (OO_List);

extern FILE *PrivateOutputFileC;

#endif _EMIT_STATEMENT_H_
