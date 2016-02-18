#ifndef _PROTECTED_ALL_00010000020007c2_H
#define _PROTECTED_ALL_00010000020007c2_H

#ifndef _PROTECTED_ALL_00010000020007b3_H
#define _PROTECTED_ALL_00010000020007b3_H

#ifndef _PROTECTED_ALL_00010000020007e0_H
#define _PROTECTED_ALL_00010000020007e0_H

#ifndef _OZ00010000020007e0P_H_
#define _OZ00010000020007e0P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007df 1
#define OZClassPart0001000002fffffe_0_in_00010000020007df 1
#define OZClassPart00010000020007df_0_in_00010000020007df 0

typedef struct OZ00010000020007e0Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020007e0Part_Rec, *OZ00010000020007e0Part;

#ifdef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007e0Part

#endif _OZ00010000020007e0P_H_


#endif _PROTECTED_ALL_00010000020007e0_H
#ifndef _OZ00010000020007b3P_H_
#define _OZ00010000020007b3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007b2 1
#define OZClassPart0001000002fffffe_0_in_00010000020007b2 1
#define OZClassPart00010000020007df_0_in_00010000020007b2 -1
#define OZClassPart00010000020007e0_0_in_00010000020007b2 -1
#define OZClassPart00010000020007b2_0_in_00010000020007b2 0

typedef struct OZ00010000020007b3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020007b3Part_Rec, *OZ00010000020007b3Part;

#ifdef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Set_OIDAsKey_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007b3Part

#endif _OZ00010000020007b3P_H_


#endif _PROTECTED_ALL_00010000020007b3_H
#ifndef _OZ00010000020007c2P_H_
#define _OZ00010000020007c2P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007c1 1
#define OZClassPart0001000002fffffe_0_in_00010000020007c1 1
#define OZClassPart00010000020007df_0_in_00010000020007c1 -2
#define OZClassPart00010000020007e0_0_in_00010000020007c1 -2
#define OZClassPart00010000020007b2_0_in_00010000020007c1 -1
#define OZClassPart00010000020007b3_0_in_00010000020007c1 -1
#define OZClassPart00010000020007c1_0_in_00010000020007c1 0

typedef struct OZ00010000020007c2Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozLocked;
  int pad0;

  /* protected (data) */
  OID ozID;

  /* protected (zero) */
} OZ00010000020007c2Part_Rec, *OZ00010000020007c2Part;

#ifdef OZ_ObjectPart_LockSet_global_DirectoryServer_global_ResolvableObject__
#undef OZ_ObjectPart_LockSet_global_DirectoryServer_global_ResolvableObject__
#endif
#define OZ_ObjectPart_LockSet_global_DirectoryServer_global_ResolvableObject__ OZ00010000020007c2Part

#endif _OZ00010000020007c2P_H_


#endif _PROTECTED_ALL_00010000020007c2_H
