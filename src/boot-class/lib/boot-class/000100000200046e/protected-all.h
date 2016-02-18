#define _PROTECTED_ALL_000100000200046e_H

#ifndef _OZ000100000200046eP_H_
#define _OZ000100000200046eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200046d 1
#define OZClassPart0001000002fffffe_0_in_000100000200046d 1
#define OZClassPart000100000200046d_0_in_000100000200046d 0

typedef struct OZ000100000200046ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200046ePart_Rec, *OZ000100000200046ePart;

#ifdef OZ_ObjectPart_Iterator_String_
#undef OZ_ObjectPart_Iterator_String_
#endif
#define OZ_ObjectPart_Iterator_String_ OZ000100000200046ePart

#endif _OZ000100000200046eP_H_


#endif _PROTECTED_ALL_000100000200046e_H
