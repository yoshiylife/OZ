#define _PROTECTED_ALL_0001000002000030_H

#ifndef _OZ0001000002000030P_H_
#define _OZ0001000002000030P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200002f 1
#define OZClassPart0001000002fffffe_0_in_000100000200002f 1
#define OZClassPart000100000200002f_0_in_000100000200002f 0

typedef struct OZ0001000002000030Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozAccessing;

  /* protected (zero) */
  OZ_ConditionRec ozLock;
} OZ0001000002000030Part_Rec, *OZ0001000002000030Part;

#ifdef OZ_ObjectPart_BinarySemaphore
#undef OZ_ObjectPart_BinarySemaphore
#endif
#define OZ_ObjectPart_BinarySemaphore OZ0001000002000030Part

#endif _OZ0001000002000030P_H_


#endif _PROTECTED_ALL_0001000002000030_H
