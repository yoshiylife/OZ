/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMM_BUFF_H_
#define _COMM_BUFF_H_

#include "comm.h"
extern void InitCommBuff();
extern void FreeCommBuff(commBuff b);
extern commBuff GetCommBuff();

#endif /* _COMM_BUFF_H_ */
