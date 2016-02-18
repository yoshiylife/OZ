#define _PROTECTED_ALL_000100000200061a_H

#ifndef _PROTECTED_ALL_000100000200061f_H
#define _PROTECTED_ALL_000100000200061f_H

#ifndef _PROTECTED_ALL_0001000002000629_H
#define _PROTECTED_ALL_0001000002000629_H

#ifndef _OZ0001000002000629P_H_
#define _OZ0001000002000629P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000628 1
#define OZClassPart0001000002fffffe_0_in_0001000002000628 1
#define OZClassPart0001000002000628_0_in_0001000002000628 0

typedef struct OZ0001000002000629Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000629Part_Rec, *OZ0001000002000629Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__
#undef OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_ProjectLinkSS__ OZ0001000002000629Part

#endif _OZ0001000002000629P_H_


#endif _PROTECTED_ALL_0001000002000629_H
#ifndef _OZ000100000200061fP_H_
#define _OZ000100000200061fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200061e 1
#define OZClassPart0001000002fffffe_0_in_000100000200061e 1
#define OZClassPart0001000002000628_0_in_000100000200061e -1
#define OZClassPart0001000002000629_0_in_000100000200061e -1
#define OZClassPart000100000200061e_0_in_000100000200061e 0

typedef struct OZ000100000200061fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200061fPart_Rec, *OZ000100000200061fPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_ProjectLinkSS__
#undef OZ_ObjectPart_Set_Assoc_String_ProjectLinkSS__
#endif
#define OZ_ObjectPart_Set_Assoc_String_ProjectLinkSS__ OZ000100000200061fPart

#endif _OZ000100000200061fP_H_


#endif _PROTECTED_ALL_000100000200061f_H
#ifndef _OZ000100000200061aP_H_
#define _OZ000100000200061aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000619 1
#define OZClassPart0001000002fffffe_0_in_0001000002000619 1
#define OZClassPart0001000002000628_0_in_0001000002000619 -2
#define OZClassPart0001000002000629_0_in_0001000002000619 -2
#define OZClassPart000100000200061e_0_in_0001000002000619 -1
#define OZClassPart000100000200061f_0_in_0001000002000619 -1
#define OZClassPart0001000002000619_0_in_0001000002000619 0

typedef struct OZ000100000200061aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200061aPart_Rec, *OZ000100000200061aPart;

#ifdef OZ_ObjectPart_Dictionary_String_ProjectLinkSS_
#undef OZ_ObjectPart_Dictionary_String_ProjectLinkSS_
#endif
#define OZ_ObjectPart_Dictionary_String_ProjectLinkSS_ OZ000100000200061aPart

#endif _OZ000100000200061aP_H_


#endif _PROTECTED_ALL_000100000200061a_H
