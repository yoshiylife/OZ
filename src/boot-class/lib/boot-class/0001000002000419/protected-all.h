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
