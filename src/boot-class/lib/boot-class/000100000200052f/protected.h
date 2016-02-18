#define _OZ000100000200052fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200052e 1
#define OZClassPart0001000002fffffe_0_in_000100000200052e 1
#define OZClassPart000100000200052e_0_in_000100000200052e 0

typedef struct OZ000100000200052fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200052fPart_Rec, *OZ000100000200052fPart;

#ifdef OZ_ObjectPart_Iterator_Token_
#undef OZ_ObjectPart_Iterator_Token_
#endif
#define OZ_ObjectPart_Iterator_Token_ OZ000100000200052fPart

#endif _OZ000100000200052fP_H_
