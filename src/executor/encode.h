/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _ENCODE_H_
#define _ENCODE_H_
  
#include "oz++/object-type.h"
  
#define ENC_FILE		1
#define ENC_COMM		2
#define ENC_MALLOC_ERROR	(-1)
#define ENC_WRITE_ERROR		(-2)

#define NOT_POINTERARRAY(v) ((v!=OZ_ARRAY)&&(v!=OZ_LOCAL_OBJECT)&&(v!=OZ_STATIC_OBJECT))
/* POINTER_ALIGN.	*/
/* Number of pointers including padding is provided by MACRO CEILING	*/
#define	CEILING(v)	(v+(v&1))

typedef struct {
  void    *fifo;
  void    *hash;
  int     (*writefunc)();
  void    *arg;
  int     curr_value;
  int     kind;
  int     dmfResetFlag;
} ENC_CONTEXT;

extern int	
  OzEncode(int (*writefunc)(), void *func_arg, OZ_Header entry, int kind);

#endif /* _ENCODE_H_ */
