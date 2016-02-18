#define _PROTECTED_ALL_000100000200058f_H

#ifndef _OZ000100000200058fP_H_
#define _OZ000100000200058fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200058e 1
#define OZClassPart0001000002fffffe_0_in_000100000200058e 1
#define OZClassPart000100000200058e_0_in_000100000200058e 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200058fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200058fPart_Rec, *OZ000100000200058fPart;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_0__
#undef OZ_ObjectPart_Iterator_Assoc_String_0__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_0__ OZ000100000200058fPart

#endif _OZ000100000200058fP_H_


#endif _PROTECTED_ALL_000100000200058f_H
