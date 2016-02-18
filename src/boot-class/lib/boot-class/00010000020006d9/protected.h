#ifndef _OZ00010000020006d9P_H_
#define _OZ00010000020006d9P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006d8 1
#define OZClassPart0001000002fffffe_0_in_00010000020006d8 1
#define OZClassPart00010000020006b0_0_in_00010000020006d8 -2
#define OZClassPart00010000020006b1_0_in_00010000020006d8 -2
#define OZClassPart000100000200067e_0_in_00010000020006d8 -1
#define OZClassPart000100000200067f_0_in_00010000020006d8 -1
#define OZClassPart00010000020006d8_0_in_00010000020006d8 0

typedef struct OZ00010000020006d9Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozLocked;
  int pad0;

  /* protected (data) */
  OID ozID;

  /* protected (zero) */
} OZ00010000020006d9Part_Rec, *OZ00010000020006d9Part;

#ifdef OZ_ObjectPart_LockSet_global_DirectoryServer_Package__
#undef OZ_ObjectPart_LockSet_global_DirectoryServer_Package__
#endif
#define OZ_ObjectPart_LockSet_global_DirectoryServer_Package__ OZ00010000020006d9Part

#endif _OZ00010000020006d9P_H_
