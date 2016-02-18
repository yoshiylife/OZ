#define _PROTECTED_ALL_000100000200011b_H

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
#ifndef _OZ000100000200011bP_H_
#define _OZ000100000200011bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200011a 1
#define OZClassPart0001000002fffffe_0_in_000100000200011a 1
#define OZClassPart0001000002000187_0_in_000100000200011a -1
#define OZClassPart0001000002000188_0_in_000100000200011a -1
#define OZClassPart000100000200011a_0_in_000100000200011a 0

typedef struct OZ000100000200011bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozTable;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200011bPart_Rec, *OZ000100000200011bPart;

#ifdef OZ_ObjectPart_ConfigurationTables
#undef OZ_ObjectPart_ConfigurationTables
#endif
#define OZ_ObjectPart_ConfigurationTables OZ000100000200011bPart

#endif _OZ000100000200011bP_H_


#endif _PROTECTED_ALL_000100000200011b_H
