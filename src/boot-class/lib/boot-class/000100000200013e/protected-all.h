#define _PROTECTED_ALL_000100000200013e_H

#ifndef _OZ000100000200013eP_H_
#define _OZ000100000200013eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200013d 1
#define OZClassPart0001000002fffffe_0_in_000100000200013d 1
#define OZClassPart000100000200013d_0_in_000100000200013d 0

typedef struct OZ000100000200013ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozOM;
  OZ_Object ozanExecutor;

  /* protected (data) */
  unsigned int ozNumberOfProcesses;

  /* protected (zero) */
} OZ000100000200013ePart_Rec, *OZ000100000200013ePart;

#ifdef OZ_ObjectPart_Daemon
#undef OZ_ObjectPart_Daemon
#endif
#define OZ_ObjectPart_Daemon OZ000100000200013ePart

#endif _OZ000100000200013eP_H_


#endif _PROTECTED_ALL_000100000200013e_H
