/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZ_OBJECT_TYPE_H_
#define _OZ_OBJECT_TYPE_H_

typedef char *OZ_Pointer;
typedef long long OID;

typedef struct OZ_HeaderRec{
    int          h;
    unsigned int e;
    long long    a;
    void        *d;
    int          t;
    unsigned int g;
    int 	 p;
}OZ_HeaderRec,*OZ_Header;

typedef struct OZ_AllocateInfoRec{
  unsigned short data_size_protected;
  unsigned short data_size_private;
  unsigned short number_of_pointer_protected;
  unsigned short number_of_pointer_private;
  unsigned short zero_protected;
  unsigned short zero_private;

  char pad[4];
}OZ_AllocateInfoRec,*OZ_AllocateInfo;

typedef struct OZ_ObjectPartRec{
  OZ_AllocateInfoRec info;
  unsigned char      mem[1];
}OZ_ObjectPartRec, *OZ_ObjectPart;

/*  
 *    kind_of_object (head.h) = number_of_elements;
 *    size           (head.e) = part_number;
 *    type           (head.a) = class_part_id;
 *    pointer        (head.d) = part;
 */

typedef struct OZ_ObjectRec{
  OZ_HeaderRec head;
}OZ_ObjectRec,*OZ_Object;

/* 
 *    kind_of_object (head.h) = number_of_parts;
 *    size           (head.e) = memory_size;
 *    type           (head.a) = class_id;
 *    pointer        (head.d) = gc;
 */

typedef struct OZ_ObjectAllRec{
  OZ_HeaderRec head[1];
}OZ_ObjectAllRec,*OZ_ObjectAll;

/* 
 *    kind_of_object (head.h) = number_of_elements;
 *    size           (head.e) = memory_size;
 *    type           (head.a) = type_of_elements;
 *    pointer        (head.d) = gc;
 */

typedef struct OZ_ArrayRec{
  OZ_HeaderRec head;
  unsigned char mem[1];
}OZ_ArrayRec, *OZ_Array;


/* 
 *    kind_of_object (head.h) = number_of_elements;
 *    size           (head.e) = memory_size;
 *    type           (head.a) = class_id;
 *    pointer        (head.d) = gc;
 */

typedef struct OZ_StaticObjectRec{
  OZ_HeaderRec head;
  OZ_AllocateInfoRec info;
  unsigned char mem[1];
}OZ_StaticObjectRec, *OZ_StaticObject;

#endif _OZ_OBJECT_TYPE_H_
