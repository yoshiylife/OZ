#define _PROTECTED_ALL_000100000200057b_H

#ifndef _PROTECTED_ALL_0001000002000580_H
#define _PROTECTED_ALL_0001000002000580_H

#ifndef _PROTECTED_ALL_000100000200058a_H
#define _PROTECTED_ALL_000100000200058a_H

#ifndef _OZ000100000200058aP_H_
#define _OZ000100000200058aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000589 1
#define OZClassPart0001000002fffffe_0_in_0001000002000589 1
#define OZClassPart0001000002000589_0_in_0001000002000589 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200058aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200058aPart_Rec, *OZ000100000200058aPart;

#ifdef OZ_ObjectPart_Collection_Assoc_String_0__
#undef OZ_ObjectPart_Collection_Assoc_String_0__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_0__ OZ000100000200058aPart

#endif _OZ000100000200058aP_H_


#endif _PROTECTED_ALL_000100000200058a_H
#ifndef _OZ0001000002000580P_H_
#define _OZ0001000002000580P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200057f 1
#define OZClassPart0001000002fffffe_0_in_000100000200057f 1
#define OZClassPart0001000002000589_0_in_000100000200057f -1
#define OZClassPart000100000200058a_0_in_000100000200057f -1
#define OZClassPart000100000200057f_0_in_000100000200057f 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000580Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000580Part_Rec, *OZ0001000002000580Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_0__
#undef OZ_ObjectPart_Set_Assoc_String_0__
#endif
#define OZ_ObjectPart_Set_Assoc_String_0__ OZ0001000002000580Part

#endif _OZ0001000002000580P_H_


#endif _PROTECTED_ALL_0001000002000580_H
#ifndef _OZ000100000200057bP_H_
#define _OZ000100000200057bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200057a 1
#define OZClassPart0001000002fffffe_0_in_000100000200057a 1
#define OZClassPart0001000002000589_0_in_000100000200057a -2
#define OZClassPart000100000200058a_0_in_000100000200057a -2
#define OZClassPart000100000200057f_0_in_000100000200057a -1
#define OZClassPart0001000002000580_0_in_000100000200057a -1
#define OZClassPart000100000200057a_0_in_000100000200057a 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200057bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200057bPart_Rec, *OZ000100000200057bPart;

#ifdef OZ_ObjectPart_Dictionary_String_0_
#undef OZ_ObjectPart_Dictionary_String_0_
#endif
#define OZ_ObjectPart_Dictionary_String_0_ OZ000100000200057bPart

#endif _OZ000100000200057bP_H_


#endif _PROTECTED_ALL_000100000200057b_H
