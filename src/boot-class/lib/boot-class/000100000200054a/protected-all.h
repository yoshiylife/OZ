#define _PROTECTED_ALL_000100000200054a_H

#ifndef _PROTECTED_ALL_000100000200054f_H
#define _PROTECTED_ALL_000100000200054f_H

#ifndef _OZ000100000200054fP_H_
#define _OZ000100000200054fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200054e 1
#define OZClassPart0001000002fffffe_0_in_000100000200054e 1
#define OZClassPart000100000200054e_0_in_000100000200054e 0

typedef struct OZ000100000200054fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200054fPart_Rec, *OZ000100000200054fPart;

#ifdef OZ_ObjectPart_Collection_OIDAsKey_global_ClassID__
#undef OZ_ObjectPart_Collection_OIDAsKey_global_ClassID__
#endif
#define OZ_ObjectPart_Collection_OIDAsKey_global_ClassID__ OZ000100000200054fPart

#endif _OZ000100000200054fP_H_


#endif _PROTECTED_ALL_000100000200054f_H
#ifndef _OZ000100000200054aP_H_
#define _OZ000100000200054aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000549 1
#define OZClassPart0001000002fffffe_0_in_0001000002000549 1
#define OZClassPart000100000200054e_0_in_0001000002000549 -1
#define OZClassPart000100000200054f_0_in_0001000002000549 -1
#define OZClassPart0001000002000549_0_in_0001000002000549 0

typedef struct OZ000100000200054aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200054aPart_Rec, *OZ000100000200054aPart;

#ifdef OZ_ObjectPart_Set_OIDAsKey_global_ClassID__
#undef OZ_ObjectPart_Set_OIDAsKey_global_ClassID__
#endif
#define OZ_ObjectPart_Set_OIDAsKey_global_ClassID__ OZ000100000200054aPart

#endif _OZ000100000200054aP_H_


#endif _PROTECTED_ALL_000100000200054a_H
