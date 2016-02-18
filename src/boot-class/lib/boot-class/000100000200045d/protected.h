#define _OZ000100000200045dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200045c 1
#define OZClassPart0001000002fffffe_0_in_000100000200045c 1
#define OZClassPart000100000200045c_0_in_000100000200045c 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200045dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ000100000200045dPart_Rec, *OZ000100000200045dPart;

#ifdef OZ_ObjectPart_Iterator_Assoc_0_0__
#undef OZ_ObjectPart_Iterator_Assoc_0_0__
#endif
#define OZ_ObjectPart_Iterator_Assoc_0_0__ OZ000100000200045dPart

#endif _OZ000100000200045dP_H_
