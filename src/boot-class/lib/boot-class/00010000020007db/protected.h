#ifndef _OZ00010000020007dbP_H_
#define _OZ00010000020007dbP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007da 1
#define OZClassPart0001000002fffffe_0_in_00010000020007da 1
#define OZClassPart00010000020007e4_0_in_00010000020007da -1
#define OZClassPart00010000020007e5_0_in_00010000020007da -1
#define OZClassPart00010000020007da_0_in_00010000020007da 0

typedef struct OZ00010000020007dbPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020007dbPart_Rec, *OZ00010000020007dbPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007dbPart

#endif _OZ00010000020007dbP_H_
