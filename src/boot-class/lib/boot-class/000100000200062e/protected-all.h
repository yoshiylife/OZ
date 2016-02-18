#define _PROTECTED_ALL_000100000200062e_H

#ifndef _OZ000100000200062eP_H_
#define _OZ000100000200062eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200062d 1
#define OZClassPart0001000002fffffe_0_in_000100000200062d 1
#define OZClassPart000100000200062d_0_in_000100000200062d 0

typedef struct OZ000100000200062ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200062ePart_Rec, *OZ000100000200062ePart;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_ProjectLinkSS__
#undef OZ_ObjectPart_Iterator_Assoc_String_ProjectLinkSS__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_ProjectLinkSS__ OZ000100000200062ePart

#endif _OZ000100000200062eP_H_


#endif _PROTECTED_ALL_000100000200062e_H
