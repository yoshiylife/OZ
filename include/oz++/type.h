/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZ_TYPE_H_
#define _OZ_TYPE_H_

/*
 * constant values for type info.
 */

#define OZ_CHAR 1
#define OZ_SHORT 2
#define OZ_INT 3
#define OZ_LONG_LONG 4
#define OZ_FLOAT 5
#define OZ_DOUBLE 6
#define OZ_CONDITION 8
#define OZ_LOCAL_OBJECT 14
#define OZ_RECORD 15
#define OZ_STATIC_OBJECT 16
#define OZ_GLOBAL_OBJECT 17
#define OZ_ARRAY 18
#define OZ_PROCESS 19
#define OZ_PADDING 99

typedef int OZ_ProcessID;
typedef int OZ_Generic;

#define OZ_Long long long

#endif _OZ_TYPE_H_



