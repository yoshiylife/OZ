#ifndef _OZ00010000020007c7P_H_
#define _OZ00010000020007c7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007c6 1
#define OZClassPart0001000002fffffe_0_in_00010000020007c6 1
#define OZClassPart00010000020007c6_0_in_00010000020007c6 0

typedef struct OZ00010000020007c7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020007c7Part_Rec, *OZ00010000020007c7Part;

#ifdef OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007c7Part

#endif _OZ00010000020007c7P_H_
