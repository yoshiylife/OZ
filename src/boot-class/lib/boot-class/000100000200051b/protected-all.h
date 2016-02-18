#define _PROTECTED_ALL_000100000200051b_H

#ifndef _PROTECTED_ALL_0001000002000520_H
#define _PROTECTED_ALL_0001000002000520_H

#ifndef _PROTECTED_ALL_0001000002000525_H
#define _PROTECTED_ALL_0001000002000525_H

#ifndef _PROTECTED_ALL_000100000200052a_H
#define _PROTECTED_ALL_000100000200052a_H

#ifndef _OZ000100000200052aP_H_
#define _OZ000100000200052aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000529 1
#define OZClassPart0001000002fffffe_0_in_0001000002000529 1
#define OZClassPart0001000002000529_0_in_0001000002000529 0

typedef struct OZ000100000200052aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200052aPart_Rec, *OZ000100000200052aPart;

#ifdef OZ_ObjectPart_Collection_Token_
#undef OZ_ObjectPart_Collection_Token_
#endif
#define OZ_ObjectPart_Collection_Token_ OZ000100000200052aPart

#endif _OZ000100000200052aP_H_


#endif _PROTECTED_ALL_000100000200052a_H
#ifndef _OZ0001000002000525P_H_
#define _OZ0001000002000525P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000524 1
#define OZClassPart0001000002fffffe_0_in_0001000002000524 1
#define OZClassPart0001000002000529_0_in_0001000002000524 -1
#define OZClassPart000100000200052a_0_in_0001000002000524 -1
#define OZClassPart0001000002000524_0_in_0001000002000524 0

typedef struct OZ0001000002000525Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000525Part_Rec, *OZ0001000002000525Part;

#ifdef OZ_ObjectPart_SequencedCollection_Token_
#undef OZ_ObjectPart_SequencedCollection_Token_
#endif
#define OZ_ObjectPart_SequencedCollection_Token_ OZ0001000002000525Part

#endif _OZ0001000002000525P_H_


#endif _PROTECTED_ALL_0001000002000525_H
#ifndef _OZ0001000002000520P_H_
#define _OZ0001000002000520P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200051f 1
#define OZClassPart0001000002fffffe_0_in_000100000200051f 1
#define OZClassPart0001000002000529_0_in_000100000200051f -2
#define OZClassPart000100000200052a_0_in_000100000200051f -2
#define OZClassPart0001000002000524_0_in_000100000200051f -1
#define OZClassPart0001000002000525_0_in_000100000200051f -1
#define OZClassPart000100000200051f_0_in_000100000200051f 0

typedef struct OZ0001000002000520Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000520Part_Rec, *OZ0001000002000520Part;

#ifdef OZ_ObjectPart_OrderedCollection_Token_
#undef OZ_ObjectPart_OrderedCollection_Token_
#endif
#define OZ_ObjectPart_OrderedCollection_Token_ OZ0001000002000520Part

#endif _OZ0001000002000520P_H_


#endif _PROTECTED_ALL_0001000002000520_H
#ifndef _OZ000100000200051bP_H_
#define _OZ000100000200051bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200051a 1
#define OZClassPart0001000002fffffe_0_in_000100000200051a 1
#define OZClassPart0001000002000529_0_in_000100000200051a -3
#define OZClassPart000100000200052a_0_in_000100000200051a -3
#define OZClassPart0001000002000524_0_in_000100000200051a -2
#define OZClassPart0001000002000525_0_in_000100000200051a -2
#define OZClassPart000100000200051f_0_in_000100000200051a -1
#define OZClassPart0001000002000520_0_in_000100000200051a -1
#define OZClassPart000100000200051a_0_in_000100000200051a 0

typedef struct OZ000100000200051bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200051bPart_Rec, *OZ000100000200051bPart;

#ifdef OZ_ObjectPart_FIFO_Token_
#undef OZ_ObjectPart_FIFO_Token_
#endif
#define OZ_ObjectPart_FIFO_Token_ OZ000100000200051bPart

#endif _OZ000100000200051bP_H_


#endif _PROTECTED_ALL_000100000200051b_H
