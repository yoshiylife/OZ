#ifndef _PROTECTED_ALL_00010000020006d9_H
#define _PROTECTED_ALL_00010000020006d9_H

#ifndef _PROTECTED_ALL_000100000200067f_H
#define _PROTECTED_ALL_000100000200067f_H

#ifndef _PROTECTED_ALL_00010000020006b1_H
#define _PROTECTED_ALL_00010000020006b1_H

#ifndef _OZ00010000020006b1P_H_
#define _OZ00010000020006b1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006b0 1
#define OZClassPart0001000002fffffe_0_in_00010000020006b0 1
#define OZClassPart00010000020006b0_0_in_00010000020006b0 0

typedef struct OZ00010000020006b1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020006b1Part_Rec, *OZ00010000020006b1Part;

#ifdef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_Package___ OZ00010000020006b1Part

#endif _OZ00010000020006b1P_H_


#endif _PROTECTED_ALL_00010000020006b1_H
#ifndef _OZ000100000200067fP_H_
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


#endif _PROTECTED_ALL_000100000200067f_H
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


#endif _PROTECTED_ALL_00010000020006d9_H
