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
