#ifndef _OZ00010000020007e5P_H_
#define _OZ00010000020007e5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007e4 1
#define OZClassPart0001000002fffffe_0_in_00010000020007e4 1
#define OZClassPart00010000020007e4_0_in_00010000020007e4 0

typedef struct OZ00010000020007e5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020007e5Part_Rec, *OZ00010000020007e5Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007e5Part

#endif _OZ00010000020007e5P_H_
