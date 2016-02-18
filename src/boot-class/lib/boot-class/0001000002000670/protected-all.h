#define _PROTECTED_ALL_0001000002000670_H

#ifndef _PROTECTED_ALL_0001000002000337_H
#define _PROTECTED_ALL_0001000002000337_H

#ifndef _OZ0001000002000337P_H_
#define _OZ0001000002000337P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000336 1
#define OZClassPart0001000002fffffe_0_in_0001000002000336 1
#define OZClassPart0001000002000336_0_in_0001000002000336 0

typedef struct OZ0001000002000337Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozNames;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000337Part_Rec, *OZ0001000002000337Part;

#ifdef OZ_ObjectPart_ResolvableObject
#undef OZ_ObjectPart_ResolvableObject
#endif
#define OZ_ObjectPart_ResolvableObject OZ0001000002000337Part

#endif _OZ0001000002000337P_H_


#endif _PROTECTED_ALL_0001000002000337_H
#ifndef _OZ0001000002000670P_H_
#define _OZ0001000002000670P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200066f 1
#define OZClassPart0001000002fffffe_0_in_000100000200066f 1
#define OZClassPart0001000002000336_0_in_000100000200066f -1
#define OZClassPart0001000002000337_0_in_000100000200066f -1
#define OZClassPart000100000200066f_0_in_000100000200066f 0

typedef struct OZ0001000002000670Part_Rec {
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
} OZ0001000002000670Part_Rec, *OZ0001000002000670Part;

#ifdef OZ_ObjectPart_DirectoryServer_Package_
#undef OZ_ObjectPart_DirectoryServer_Package_
#endif
#define OZ_ObjectPart_DirectoryServer_Package_ OZ0001000002000670Part

#endif _OZ0001000002000670P_H_


#endif _PROTECTED_ALL_0001000002000670_H
