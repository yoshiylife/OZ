/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _ERROR_H_
#define _ERROR_H_

extern void FatalError (char *, ...);
extern void InternalError (char *, ...);
extern void Warning (char *, ...);
extern void WarningMsg (char *, ...);

#endif _ERROR_H_
