#ifndef _OZ00010000020006bbP_H_
#define _OZ00010000020006bbP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020006ba 1
#define OZClassPart0001000002fffffe_0_in_00010000020006ba 1
#define OZClassPart00010000020006ba_0_in_00010000020006ba 0

typedef struct OZ00010000020006bbPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020006bbPart_Rec, *OZ00010000020006bbPart;

#ifdef OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_Package___
#undef OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_Package___
#endif
#define OZ_ObjectPart_Iterator_OIDAsKey_global_DirectoryServer_Package___ OZ00010000020006bbPart

#endif _OZ00010000020006bbP_H_
