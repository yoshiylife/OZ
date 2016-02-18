#define _PROTECTED_ALL_0001000002000116_H

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
#ifndef _OZ0001000002000116P_H_
#define _OZ0001000002000116P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000115 1
#define OZClassPart0001000002fffffe_0_in_0001000002000115 1
#define OZClassPart0001000002000187_0_in_0001000002000115 -1
#define OZClassPart0001000002000188_0_in_0001000002000115 -1
#define OZClassPart0001000002000115_0_in_0001000002000115 0

typedef struct OZ0001000002000116Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozTable;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000116Part_Rec, *OZ0001000002000116Part;

#ifdef OZ_ObjectPart_ConfigurationTable
#undef OZ_ObjectPart_ConfigurationTable
#endif
#define OZ_ObjectPart_ConfigurationTable OZ0001000002000116Part

#endif _OZ0001000002000116P_H_


#endif _PROTECTED_ALL_0001000002000116_H
