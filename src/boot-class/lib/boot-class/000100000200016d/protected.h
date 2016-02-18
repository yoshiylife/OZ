#define _OZ000100000200016dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200016c 1
#define OZClassPart0001000002fffffe_0_in_000100000200016c 1
#define OZClassPart0001000002000336_0_in_000100000200016c -1
#define OZClassPart0001000002000337_0_in_000100000200016c -1
#define OZClassPart000100000200016c_0_in_000100000200016c 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200016dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozOwnMap;
  OZ_Object ozSystemMap;
  OZ_Object ozMembers;
  OZ_Object ozOwnTops;
  OZ_Object ozDelimiter;
  OZ_Object ozSystemName;

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200016dPart_Rec, *OZ000100000200016dPart;

#ifdef OZ_ObjectPart_DirectoryServer_0_
#undef OZ_ObjectPart_DirectoryServer_0_
#endif
#define OZ_ObjectPart_DirectoryServer_0_ OZ000100000200016dPart

#endif _OZ000100000200016dP_H_
