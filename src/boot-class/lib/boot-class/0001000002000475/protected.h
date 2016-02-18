#define _OZ0001000002000475P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000474 1
#define OZClassPart0001000002fffffe_0_in_0001000002000474 1
#define OZClassPart0001000002000479_0_in_0001000002000474 -1
#define OZClassPart000100000200047a_0_in_0001000002000474 -1
#define OZClassPart0001000002000474_0_in_0001000002000474 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000475Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000475Part_Rec, *OZ0001000002000475Part;

#ifdef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_0___
#undef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_0___ OZ0001000002000475Part

#endif _OZ0001000002000475P_H_
