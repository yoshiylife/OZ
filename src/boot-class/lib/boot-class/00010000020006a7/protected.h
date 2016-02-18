#define _OZ00010000020006a7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006a6 1
#define OZClassPart0001000002fffffe_0_in_00010000020006a6 1
#define OZClassPart00010000020006a6_0_in_00010000020006a6 0

typedef struct OZ00010000020006a7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020006a7Part_Rec, *OZ00010000020006a7Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_global_DirectoryServer_Package___ OZ00010000020006a7Part

#endif _OZ00010000020006a7P_H_
