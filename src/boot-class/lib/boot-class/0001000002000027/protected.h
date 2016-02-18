#define _OZ0001000002000027P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000026 1
#define OZClassPart0001000002fffffe_0_in_0001000002000026 1
#define OZClassPart0001000002000026_0_in_0001000002000026 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000027Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ0001000002000027Part_Rec, *OZ0001000002000027Part;

#ifdef OZ_ObjectPart_Iterator_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___
#undef OZ_ObjectPart_Iterator_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___
#endif
#define OZ_ObjectPart_Iterator_OIDAsKey_global_CopyOfPrimaryCopyScheme_0___ OZ0001000002000027Part

#endif _OZ0001000002000027P_H_
