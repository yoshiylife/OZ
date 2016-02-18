/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _TYPES_H_
#define _TYPES_H_

#include "oz++/type.h"

#define ALINMENT_1 4
#define ALINMENT_2 8

/*
 * memory size for each type (byte)
 */

static unsigned char oz_size_of_type[] = { 
  0,
  1, 
  2, 
  4, 8, 
  4, 8, 
  0,
  8,
  0,
  0, 0, 0,
  0,
  4,  
  0,
  4,
 
  8, 
  4,
  4,
};

static unsigned char oz_type[] = { 
  0,
  OZ_CHAR, 
  OZ_SHORT, 
  OZ_INT, OZ_LONG_LONG, 
  OZ_FLOAT, OZ_DOUBLE, 
  0, 
  OZ_CONDITION, 
  0, 
  0, 0, 0,
  0, 
  OZ_LOCAL_OBJECT,   
  OZ_RECORD, 
  OZ_STATIC_OBJECT, 

  OZ_GLOBAL_OBJECT,  
  OZ_ARRAY,  
  OZ_PROCESS,
};

static char format_char_of_type[] = { 
  'v',
  'c', 
  's', 
  'i', 'l', 
  'f', 'd', 
  ' ', 
  'C', 
  ' ', 
  ' ', ' ', ' ',
  ' ', 
  'O',   
  'R', 
  'S', 

  'G',  
  'A',  
  'P',
};

#endif _TYPES_H_



