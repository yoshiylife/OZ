#ifndef _OZ0001000002000770P_H_
#define _OZ0001000002000770P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200076f 1
#define OZClassPart0001000002fffffe_0_in_000100000200076f 1
#define OZClassPart00010000020001b5_0_in_000100000200076f -1
#define OZClassPart00010000020001b6_0_in_000100000200076f -1
#define OZClassPart000100000200076f_0_in_000100000200076f 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000770Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozPath;
  int pad0;

  /* protected (data) */
  OZ_Generic ozaDirectory;
  OID ozOwner;

  /* protected (zero) */
} OZ0001000002000770Part_Rec, *OZ0001000002000770Part;

#ifdef OZ_ObjectPart_DirectoryBrowser_0_0_
#undef OZ_ObjectPart_DirectoryBrowser_0_0_
#endif
#define OZ_ObjectPart_DirectoryBrowser_0_0_ OZ0001000002000770Part

#endif _OZ0001000002000770P_H_
