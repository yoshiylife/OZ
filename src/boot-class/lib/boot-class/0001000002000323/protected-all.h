#define _PROTECTED_ALL_0001000002000323_H

#ifndef _OZ0001000002000323P_H_
#define _OZ0001000002000323P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000322 1
#define OZClassPart0001000002fffffe_0_in_0001000002000322 1
#define OZClassPart0001000002000322_0_in_0001000002000322 0

typedef struct OZ0001000002000323Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozParent;
  OZ_Object ozName;

  /* protected (data) */
  int ozType;

  /* protected (zero) */
} OZ0001000002000323Part_Rec, *OZ0001000002000323Part;

#ifdef OZ_ObjectPart_ProjectLinkSS
#undef OZ_ObjectPart_ProjectLinkSS
#endif
#define OZ_ObjectPart_ProjectLinkSS OZ0001000002000323Part

#endif _OZ0001000002000323P_H_


#endif _PROTECTED_ALL_0001000002000323_H
