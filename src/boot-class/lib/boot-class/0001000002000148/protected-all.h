#define _PROTECTED_ALL_0001000002000148_H

#ifndef _PROTECTED_ALL_0001000002000188_H
#define _PROTECTED_ALL_0001000002000188_H

#ifndef _OZ0001000002000188P_H_
#define _OZ0001000002000188P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000187 1
#define OZClassPart0001000002fffffe_0_in_0001000002000187 1
#define OZClassPart0001000002000187_0_in_0001000002000187 0

typedef struct OZ0001000002000188Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozLocking;

  /* protected (zero) */
  OZ_ConditionRec ozLockCondition;
} OZ0001000002000188Part_Rec, *OZ0001000002000188Part;

#ifdef OZ_ObjectPart_Exclusive
#undef OZ_ObjectPart_Exclusive
#endif
#define OZ_ObjectPart_Exclusive OZ0001000002000188Part

#endif _OZ0001000002000188P_H_


#endif _PROTECTED_ALL_0001000002000188_H
#ifndef _OZ0001000002000148P_H_
#define _OZ0001000002000148P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000147 1
#define OZClassPart0001000002fffffe_0_in_0001000002000147 1
#define OZClassPart0001000002000187_0_in_0001000002000147 -1
#define OZClassPart0001000002000188_0_in_0001000002000147 -1
#define OZClassPart0001000002000147_0_in_0001000002000147 0

typedef struct OZ0001000002000148Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaBroadcastReceiver;
  OZ_Object ozaCodeFaultDaemon;
  OZ_Object ozaLayoutFaultDaemon;
  OZ_Object ozaClassRequestDaemon;
  OZ_Object ozanObjectFaultDaemon;
  OZ_Object ozaDebuggerClassRequestDaemon;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000148Part_Rec, *OZ0001000002000148Part;

#ifdef OZ_ObjectPart_Daemons
#undef OZ_ObjectPart_Daemons
#endif
#define OZ_ObjectPart_Daemons OZ0001000002000148Part

#endif _OZ0001000002000148P_H_


#endif _PROTECTED_ALL_0001000002000148_H
