#define _OZ000100000200050fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200050e 1
#define OZClassPart0001000002fffffe_0_in_000100000200050e 1
#define OZClassPart000100000200050e_0_in_000100000200050e 0

typedef struct OZ000100000200050fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200050fPart_Rec, *OZ000100000200050fPart;

#ifdef OZ_ObjectPart_Iterator_Linkable_
#undef OZ_ObjectPart_Iterator_Linkable_
#endif
#define OZ_ObjectPart_Iterator_Linkable_ OZ000100000200050fPart

#endif _OZ000100000200050fP_H_
