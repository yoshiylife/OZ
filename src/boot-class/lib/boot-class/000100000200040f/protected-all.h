#define _PROTECTED_ALL_000100000200040f_H

#ifndef _OZ000100000200040fP_H_
#define _OZ000100000200040fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200040e 1
#define OZClassPart0001000002fffffe_0_in_000100000200040e 1
#define OZClassPart000100000200040e_0_in_000100000200040e 0

typedef struct OZ000100000200040fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozAborted;
  int ozFinished;

  /* protected (zero) */
  OZ_ConditionRec ozLock;
} OZ000100000200040fPart_Rec, *OZ000100000200040fPart;

#ifdef OZ_ObjectPart_Waiter
#undef OZ_ObjectPart_Waiter
#endif
#define OZ_ObjectPart_Waiter OZ000100000200040fPart

#endif _OZ000100000200040fP_H_


#endif _PROTECTED_ALL_000100000200040f_H
