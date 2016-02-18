#define _PROTECTED_ALL_0001000002000079_H

#ifndef _PROTECTED_ALL_0001000002000065_H
#define _PROTECTED_ALL_0001000002000065_H

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
#ifndef _OZ0001000002000065P_H_
#define _OZ0001000002000065P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000064 1
#define OZClassPart0001000002fffffe_0_in_0001000002000064 1
#define OZClassPart0001000002000336_0_in_0001000002000064 -1
#define OZClassPart0001000002000337_0_in_0001000002000064 -1
#define OZClassPart0001000002000064_0_in_0001000002000064 0

typedef struct OZ0001000002000065Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozClassListFile;
  OZ_Array ozClassDirectoryPath;
  OZ_Object ozClassTable;
  OZ_Object ozLogger;
  OZ_Object ozDumpPath;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000065Part_Rec, *OZ0001000002000065Part;

#ifdef OZ_ObjectPart_Class
#undef OZ_ObjectPart_Class
#endif
#define OZ_ObjectPart_Class OZ0001000002000065Part

#endif _OZ0001000002000065P_H_


#endif _PROTECTED_ALL_0001000002000065_H
#ifndef _OZ0001000002000079P_H_
#define _OZ0001000002000079P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000078 1
#define OZClassPart0001000002fffffe_0_in_0001000002000078 1
#define OZClassPart0001000002000336_0_in_0001000002000078 -2
#define OZClassPart0001000002000337_0_in_0001000002000078 -2
#define OZClassPart0001000002000064_0_in_0001000002000078 -1
#define OZClassPart0001000002000065_0_in_0001000002000078 -1
#define OZClassPart0001000002000078_0_in_0001000002000078 0

typedef struct OZ0001000002000079Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaNotifierWindow;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000079Part_Rec, *OZ0001000002000079Part;

#ifdef OZ_ObjectPart_ClassWithNotifier
#undef OZ_ObjectPart_ClassWithNotifier
#endif
#define OZ_ObjectPart_ClassWithNotifier OZ0001000002000079Part

#endif _OZ0001000002000079P_H_


#endif _PROTECTED_ALL_0001000002000079_H
