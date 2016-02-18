#define _OZ000100000200067fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200067e 1
#define OZClassPart0001000002fffffe_0_in_000100000200067e 1
#define OZClassPart00010000020006b0_0_in_000100000200067e -1
#define OZClassPart00010000020006b1_0_in_000100000200067e -1
#define OZClassPart000100000200067e_0_in_000100000200067e 0

typedef struct OZ000100000200067fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200067fPart_Rec, *OZ000100000200067fPart;

#ifdef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_Package___ OZ000100000200067fPart

#endif _OZ000100000200067fP_H_
