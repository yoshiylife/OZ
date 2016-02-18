#define _PROTECTED_ALL_000100000200039c_H

#ifndef _PROTECTED_ALL_0001000002000314_H
#define _PROTECTED_ALL_0001000002000314_H

#ifndef _OZ0001000002000314P_H_
#define _OZ0001000002000314P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000313 1
#define OZClassPart0001000002fffffe_0_in_0001000002000313 1
#define OZClassPart0001000002000313_0_in_0001000002000313 0

typedef struct OZ0001000002000314Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozPid;
  int ozExitStatus;
  int ozStatusFlg;

  /* protected (zero) */
  OZ_ConditionRec ozFinished;
} OZ0001000002000314Part_Rec, *OZ0001000002000314Part;

#ifdef OZ_ObjectPart_ExternalProcess
#undef OZ_ObjectPart_ExternalProcess
#endif
#define OZ_ObjectPart_ExternalProcess OZ0001000002000314Part

#endif _OZ0001000002000314P_H_


#endif _PROTECTED_ALL_0001000002000314_H
#ifndef _OZ000100000200039cP_H_
#define _OZ000100000200039cP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200039b 1
#define OZClassPart0001000002fffffe_0_in_000100000200039b 1
#define OZClassPart0001000002000313_0_in_000100000200039b -1
#define OZClassPart0001000002000314_0_in_000100000200039b -1
#define OZClassPart000100000200039b_0_in_000100000200039b 0

typedef struct OZ000100000200039cPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200039cPart_Rec, *OZ000100000200039cPart;

#ifdef OZ_ObjectPart_ExternalSpawnedProcess
#undef OZ_ObjectPart_ExternalSpawnedProcess
#endif
#define OZ_ObjectPart_ExternalSpawnedProcess OZ000100000200039cPart

#endif _OZ000100000200039cP_H_


#endif _PROTECTED_ALL_000100000200039c_H
