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
