#define _OZ000100000200066bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200066a 1
#define OZClassPart0001000002fffffe_0_in_000100000200066a 1
#define OZClassPart0001000002000479_0_in_000100000200066a -2
#define OZClassPart000100000200047a_0_in_000100000200066a -2
#define OZClassPart0001000002000474_0_in_000100000200066a -1
#define OZClassPart0001000002000475_0_in_000100000200066a -1
#define OZClassPart000100000200066a_0_in_000100000200066a 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200066bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozLocked;
  int pad0;

  /* protected (data) */
  OID ozID;

  /* protected (zero) */
} OZ000100000200066bPart_Rec, *OZ000100000200066bPart;

#ifdef OZ_ObjectPart_LockSet_global_DirectoryServer_0__
#undef OZ_ObjectPart_LockSet_global_DirectoryServer_0__
#endif
#define OZ_ObjectPart_LockSet_global_DirectoryServer_0__ OZ000100000200066bPart

#endif _OZ000100000200066bP_H_
