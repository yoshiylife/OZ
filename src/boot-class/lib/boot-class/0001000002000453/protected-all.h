#define _PROTECTED_ALL_0001000002000453_H

#ifndef _PROTECTED_ALL_0001000002000458_H
#define _PROTECTED_ALL_0001000002000458_H

#ifndef _OZ0001000002000458P_H_
#define _OZ0001000002000458P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000457 1
#define OZClassPart0001000002fffffe_0_in_0001000002000457 1
#define OZClassPart0001000002000457_0_in_0001000002000457 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000458Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000458Part_Rec, *OZ0001000002000458Part;

#ifdef OZ_ObjectPart_Collection_Assoc_0_0__
#undef OZ_ObjectPart_Collection_Assoc_0_0__
#endif
#define OZ_ObjectPart_Collection_Assoc_0_0__ OZ0001000002000458Part

#endif _OZ0001000002000458P_H_


#endif _PROTECTED_ALL_0001000002000458_H
#ifndef _OZ0001000002000453P_H_
#define _OZ0001000002000453P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000452 1
#define OZClassPart0001000002fffffe_0_in_0001000002000452 1
#define OZClassPart0001000002000457_0_in_0001000002000452 -1
#define OZClassPart0001000002000458_0_in_0001000002000452 -1
#define OZClassPart0001000002000452_0_in_0001000002000452 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000453Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000453Part_Rec, *OZ0001000002000453Part;

#ifdef OZ_ObjectPart_Set_Assoc_0_0__
#undef OZ_ObjectPart_Set_Assoc_0_0__
#endif
#define OZ_ObjectPart_Set_Assoc_0_0__ OZ0001000002000453Part

#endif _OZ0001000002000453P_H_


#endif _PROTECTED_ALL_0001000002000453_H
