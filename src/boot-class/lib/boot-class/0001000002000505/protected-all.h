#define _PROTECTED_ALL_0001000002000505_H

#ifndef _PROTECTED_ALL_000100000200050a_H
#define _PROTECTED_ALL_000100000200050a_H

#ifndef _OZ000100000200050aP_H_
#define _OZ000100000200050aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000509 1
#define OZClassPart0001000002fffffe_0_in_0001000002000509 1
#define OZClassPart0001000002000509_0_in_0001000002000509 0

typedef struct OZ000100000200050aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200050aPart_Rec, *OZ000100000200050aPart;

#ifdef OZ_ObjectPart_Collection_Linkable_
#undef OZ_ObjectPart_Collection_Linkable_
#endif
#define OZ_ObjectPart_Collection_Linkable_ OZ000100000200050aPart

#endif _OZ000100000200050aP_H_


#endif _PROTECTED_ALL_000100000200050a_H
#ifndef _OZ0001000002000505P_H_
#define _OZ0001000002000505P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000504 1
#define OZClassPart0001000002fffffe_0_in_0001000002000504 1
#define OZClassPart0001000002000509_0_in_0001000002000504 -1
#define OZClassPart000100000200050a_0_in_0001000002000504 -1
#define OZClassPart0001000002000504_0_in_0001000002000504 0

typedef struct OZ0001000002000505Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000505Part_Rec, *OZ0001000002000505Part;

#ifdef OZ_ObjectPart_SequencedCollection_Linkable_
#undef OZ_ObjectPart_SequencedCollection_Linkable_
#endif
#define OZ_ObjectPart_SequencedCollection_Linkable_ OZ0001000002000505Part

#endif _OZ0001000002000505P_H_


#endif _PROTECTED_ALL_0001000002000505_H
