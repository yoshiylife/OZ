#define _PROTECTED_ALL_000100000200042d_H

#ifndef _OZ000100000200042dP_H_
#define _OZ000100000200042dP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200042c 1
#define OZClassPart0001000002fffffe_0_in_000100000200042c 1
#define OZClassPart000100000200042c_0_in_000100000200042c 0

typedef struct OZ000100000200042dPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozerrorMessage;
  int pad0;

  /* protected (data) */
  int ozStatus;
  int ozWork;

  /* protected (zero) */
} OZ000100000200042dPart_Rec, *OZ000100000200042dPart;

#ifdef OZ_ObjectPart_WorkingObjectInClass
#undef OZ_ObjectPart_WorkingObjectInClass
#endif
#define OZ_ObjectPart_WorkingObjectInClass OZ000100000200042dPart

#endif _OZ000100000200042dP_H_


#endif _PROTECTED_ALL_000100000200042d_H
