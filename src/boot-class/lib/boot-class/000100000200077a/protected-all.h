#ifndef _PROTECTED_ALL_000100000200077a_H
#define _PROTECTED_ALL_000100000200077a_H

#ifndef _PROTECTED_ALL_00010000020001b6_H
#define _PROTECTED_ALL_00010000020001b6_H

#ifndef _OZ00010000020001b6P_H_
#define _OZ00010000020001b6P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001b5 1
#define OZClassPart0001000002fffffe_0_in_00010000020001b5 1
#define OZClassPart00010000020001b5_0_in_00010000020001b5 0

typedef struct OZ00010000020001b6Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001b6Part_Rec, *OZ00010000020001b6Part;

#ifdef OZ_ObjectPart_GUI
#undef OZ_ObjectPart_GUI
#endif
#define OZ_ObjectPart_GUI OZ00010000020001b6Part

#endif _OZ00010000020001b6P_H_


#endif _PROTECTED_ALL_00010000020001b6_H
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


#endif _PROTECTED_ALL_000100000200077a_H
