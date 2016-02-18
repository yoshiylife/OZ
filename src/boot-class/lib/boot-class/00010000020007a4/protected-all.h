#ifndef _PROTECTED_ALL_00010000020007a4_H
#define _PROTECTED_ALL_00010000020007a4_H

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
#ifndef _OZ00010000020007a4P_H_
#define _OZ00010000020007a4P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007a3 1
#define OZClassPart0001000002fffffe_0_in_00010000020007a3 1
#define OZClassPart0001000002000336_0_in_00010000020007a3 -1
#define OZClassPart0001000002000337_0_in_00010000020007a3 -1
#define OZClassPart00010000020007a3_0_in_00010000020007a3 0

typedef struct OZ00010000020007a4Part_Rec {
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
} OZ00010000020007a4Part_Rec, *OZ00010000020007a4Part;

#ifdef OZ_ObjectPart_DirectoryServer_global_ResolvableObject_
#undef OZ_ObjectPart_DirectoryServer_global_ResolvableObject_
#endif
#define OZ_ObjectPart_DirectoryServer_global_ResolvableObject_ OZ00010000020007a4Part

#endif _OZ00010000020007a4P_H_


#endif _PROTECTED_ALL_00010000020007a4_H
