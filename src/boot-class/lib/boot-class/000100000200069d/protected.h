#define _OZ000100000200069dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200069c 1
#define OZClassPart0001000002fffffe_0_in_000100000200069c 1
#define OZClassPart00010000020006a6_0_in_000100000200069c -1
#define OZClassPart00010000020006a7_0_in_000100000200069c -1
#define OZClassPart000100000200069c_0_in_000100000200069c 0

typedef struct OZ000100000200069dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200069dPart_Rec, *OZ000100000200069dPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_Package___ OZ000100000200069dPart

#endif _OZ000100000200069dP_H_
