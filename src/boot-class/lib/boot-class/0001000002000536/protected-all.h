#define _PROTECTED_ALL_0001000002000536_H

#ifndef _PROTECTED_ALL_000100000200048b_H
#define _PROTECTED_ALL_000100000200048b_H

#ifndef _PROTECTED_ALL_0001000002000469_H
#define _PROTECTED_ALL_0001000002000469_H

#ifndef _OZ0001000002000469P_H_
#define _OZ0001000002000469P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000468 1
#define OZClassPart0001000002fffffe_0_in_0001000002000468 1
#define OZClassPart0001000002000468_0_in_0001000002000468 0

typedef struct OZ0001000002000469Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000469Part_Rec, *OZ0001000002000469Part;

#ifdef OZ_ObjectPart_Collection_String_
#undef OZ_ObjectPart_Collection_String_
#endif
#define OZ_ObjectPart_Collection_String_ OZ0001000002000469Part

#endif _OZ0001000002000469P_H_


#endif _PROTECTED_ALL_0001000002000469_H
#ifndef _OZ000100000200048bP_H_
#define _OZ000100000200048bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200048a 1
#define OZClassPart0001000002fffffe_0_in_000100000200048a 1
#define OZClassPart0001000002000468_0_in_000100000200048a -1
#define OZClassPart0001000002000469_0_in_000100000200048a -1
#define OZClassPart000100000200048a_0_in_000100000200048a 0

typedef struct OZ000100000200048bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200048bPart_Rec, *OZ000100000200048bPart;

#ifdef OZ_ObjectPart_SequencedCollection_String_
#undef OZ_ObjectPart_SequencedCollection_String_
#endif
#define OZ_ObjectPart_SequencedCollection_String_ OZ000100000200048bPart

#endif _OZ000100000200048bP_H_


#endif _PROTECTED_ALL_000100000200048b_H
#ifndef _OZ0001000002000536P_H_
#define _OZ0001000002000536P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000535 1
#define OZClassPart0001000002fffffe_0_in_0001000002000535 1
#define OZClassPart0001000002000468_0_in_0001000002000535 -2
#define OZClassPart0001000002000469_0_in_0001000002000535 -2
#define OZClassPart000100000200048a_0_in_0001000002000535 -1
#define OZClassPart000100000200048b_0_in_0001000002000535 -1
#define OZClassPart0001000002000535_0_in_0001000002000535 0

typedef struct OZ0001000002000536Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000536Part_Rec, *OZ0001000002000536Part;

#ifdef OZ_ObjectPart_OrderedCollection_String_
#undef OZ_ObjectPart_OrderedCollection_String_
#endif
#define OZ_ObjectPart_OrderedCollection_String_ OZ0001000002000536Part

#endif _OZ0001000002000536P_H_


#endif _PROTECTED_ALL_0001000002000536_H
