#define _PROTECTED_ALL_00010000020005a5_H

#ifndef _OZ00010000020005a5P_H_
#define _OZ00010000020005a5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005a4 1
#define OZClassPart0001000002fffffe_0_in_00010000020005a4 1
#define OZClassPart00010000020005a4_0_in_00010000020005a4 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005a5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005a5Part_Rec, *OZ00010000020005a5Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___
#undef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_0___ OZ00010000020005a5Part

#endif _OZ00010000020005a5P_H_


#endif _PROTECTED_ALL_00010000020005a5_H
