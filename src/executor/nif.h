/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _NIF_H_
#define _NIF_H_

extern int NifWriteToNcl(char *buf, int len);
extern int NifGetFirstPacketFromNcl(void);
extern void NifSetPortNumber(void);
extern void NifInit(void);
extern void NifStarted(int status);

#endif  _NIF_H_
