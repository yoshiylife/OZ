#define _PROTECTED_ALL_000100000200004b_H

#ifndef _PROTECTED_ALL_0001000002000419_H
#define _PROTECTED_ALL_0001000002000419_H

#ifndef _OZ0001000002000419P_H_
#define _OZ0001000002000419P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000418 1
#define OZClassPart0001000002fffffe_0_in_0001000002000418 1
#define OZClassPart0001000002000418_0_in_0001000002000418 0

typedef struct OZ0001000002000419Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozUI;
  int pad0;

  /* protected (data) */
  OID ozaClass;

  /* protected (zero) */
} OZ0001000002000419Part_Rec, *OZ0001000002000419Part;

#ifdef OZ_ObjectPart_WorkbenchTools
#undef OZ_ObjectPart_WorkbenchTools
#endif
#define OZ_ObjectPart_WorkbenchTools OZ0001000002000419Part

#endif _OZ0001000002000419P_H_


#endif _PROTECTED_ALL_0001000002000419_H
#ifndef _OZ000100000200004bP_H_
#define _OZ000100000200004bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200004a 1
#define OZClassPart0001000002fffffe_0_in_000100000200004a 1
#define OZClassPart0001000002000418_0_in_000100000200004a -1
#define OZClassPart0001000002000419_0_in_000100000200004a -1
#define OZClassPart000100000200004a_0_in_000100000200004a 0

typedef struct OZ000100000200004bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200004bPart_Rec, *OZ000100000200004bPart;

#ifdef OZ_ObjectPart_CompilerFrontend
#undef OZ_ObjectPart_CompilerFrontend
#endif
#define OZ_ObjectPart_CompilerFrontend OZ000100000200004bPart

#endif _OZ000100000200004bP_H_


#endif _PROTECTED_ALL_000100000200004b_H
