/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _DECODE_H_
#define _DECODE_H_
#include "switch.h"
  
extern void
  OzDecode(void (*fetchFunction)(),void (*readFunction)(),void *funcArg
	   ,char fmt,void *result,Heap heap
#ifdef INTERSITE
	   ,unsigned int foreign_flag
#endif
);

#endif /* _DECODE_H_ */

