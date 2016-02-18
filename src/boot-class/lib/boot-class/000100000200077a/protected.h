#ifndef _OZ000100000200077aP_H_
#define _OZ000100000200077aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000779 1
#define OZClassPart0001000002fffffe_0_in_0001000002000779 1
#define OZClassPart00010000020001b5_0_in_0001000002000779 -1
#define OZClassPart00010000020001b6_0_in_0001000002000779 -1
#define OZClassPart0001000002000779_0_in_0001000002000779 0

typedef struct OZ000100000200077aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozPath;
  int pad0;

  /* protected (data) */
  OID ozaDirectory;
  OID ozOwner;

  /* protected (zero) */
} OZ000100000200077aPart_Rec, *OZ000100000200077aPart;

#ifdef OZ_ObjectPart_DirectoryBrowser_Catalog_Package_
#undef OZ_ObjectPart_DirectoryBrowser_Catalog_Package_
#endif
#define OZ_ObjectPart_DirectoryBrowser_Catalog_Package_ OZ000100000200077aPart

#endif _OZ000100000200077aP_H_
