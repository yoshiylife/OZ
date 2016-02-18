#define _OZ000100000200054aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000549 1
#define OZClassPart0001000002fffffe_0_in_0001000002000549 1
#define OZClassPart000100000200054e_0_in_0001000002000549 -1
#define OZClassPart000100000200054f_0_in_0001000002000549 -1
#define OZClassPart0001000002000549_0_in_0001000002000549 0

typedef struct OZ000100000200054aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200054aPart_Rec, *OZ000100000200054aPart;

#ifdef OZ_ObjectPart_Set_OIDAsKey_global_ClassID__
#undef OZ_ObjectPart_Set_OIDAsKey_global_ClassID__
#endif
#define OZ_ObjectPart_Set_OIDAsKey_global_ClassID__ OZ000100000200054aPart

#endif _OZ000100000200054aP_H_
