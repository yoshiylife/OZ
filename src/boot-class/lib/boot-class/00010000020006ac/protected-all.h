#define _PROTECTED_ALL_00010000020006ac_H

#ifndef _OZ00010000020006acP_H_
#define _OZ00010000020006acP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006ab 1
#define OZClassPart0001000002fffffe_0_in_00010000020006ab 1
#define OZClassPart00010000020006ab_0_in_00010000020006ab 0

typedef struct OZ00010000020006acPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020006acPart_Rec, *OZ00010000020006acPart;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_Package___ OZ00010000020006acPart

#endif _OZ00010000020006acP_H_


#endif _PROTECTED_ALL_00010000020006ac_H
