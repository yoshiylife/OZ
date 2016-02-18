#define _PROTECTED_ALL_00010000020002e1_H

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
#ifndef _OZ00010000020002e1P_H_
#define _OZ00010000020002e1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002e0 1
#define OZClassPart0001000002fffffe_0_in_00010000020002e0 1
#define OZClassPart0001000002000187_0_in_00010000020002e0 -1
#define OZClassPart0001000002000188_0_in_00010000020002e0 -1
#define OZClassPart00010000020002e0_0_in_00010000020002e0 0

typedef struct OZ00010000020002e1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozanExecutor;
  OZ_Object ozTable;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020002e1Part_Rec, *OZ00010000020002e1Part;

#ifdef OZ_ObjectPart_ObjectTableManager
#undef OZ_ObjectPart_ObjectTableManager
#endif
#define OZ_ObjectPart_ObjectTableManager OZ00010000020002e1Part

#endif _OZ00010000020002e1P_H_


#endif _PROTECTED_ALL_00010000020002e1_H
