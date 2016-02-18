#define _PROTECTED_ALL_000100000200053b_H

#ifndef _OZ000100000200053bP_H_
#define _OZ000100000200053bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200053a 1
#define OZClassPart0001000002fffffe_0_in_000100000200053a 1
#define OZClassPart000100000200053a_0_in_000100000200053a 0

typedef struct OZ000100000200053bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200053bPart_Rec, *OZ000100000200053bPart;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_String__
#undef OZ_ObjectPart_Iterator_Assoc_String_String__
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_String__ OZ000100000200053bPart

#endif _OZ000100000200053bP_H_


#endif _PROTECTED_ALL_000100000200053b_H
