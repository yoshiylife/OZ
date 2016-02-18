#ifndef _PROTECTED_ALL_00010000020007d1_H
#define _PROTECTED_ALL_00010000020007d1_H

#ifndef _OZ00010000020007d1P_H_
#define _OZ00010000020007d1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007d0 1
#define OZClassPart0001000002fffffe_0_in_00010000020007d0 1
#define OZClassPart00010000020007d0_0_in_00010000020007d0 0

typedef struct OZ00010000020007d1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020007d1Part_Rec, *OZ00010000020007d1Part;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#undef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_global_ResolvableObject___ OZ00010000020007d1Part

#endif _OZ00010000020007d1P_H_


#endif _PROTECTED_ALL_00010000020007d1_H
