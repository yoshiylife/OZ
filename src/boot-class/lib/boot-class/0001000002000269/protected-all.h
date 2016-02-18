#define _PROTECTED_ALL_0001000002000269_H

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
#ifndef _PROTECTED_ALL_00010000020008cc_H
#define _PROTECTED_ALL_00010000020008cc_H

#ifndef _OZ00010000020008ccP_H_
#define _OZ00010000020008ccP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008cb 1
#define OZClassPart0001000002fffffe_0_in_00010000020008cb 1
#define OZClassPart00010000020008cb_0_in_00010000020008cb 0

typedef struct OZ00010000020008ccPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020008ccPart_Rec, *OZ00010000020008ccPart;

#ifdef OZ_ObjectPart_Alarmable
#undef OZ_ObjectPart_Alarmable
#endif
#define OZ_ObjectPart_Alarmable OZ00010000020008ccPart

#endif _OZ00010000020008ccP_H_


#endif _PROTECTED_ALL_00010000020008cc_H
#ifndef _OZ0001000002000269P_H_
#define _OZ0001000002000269P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000268 1
#define OZClassPart0001000002fffffe_0_in_0001000002000268 1
#define OZClassPart0001000002000187_0_in_0001000002000268 -2
#define OZClassPart0001000002000188_0_in_0001000002000268 -2
#define OZClassPart00010000020008cb_0_in_0001000002000268 -1
#define OZClassPart00010000020008cc_0_in_0001000002000268 -1
#define OZClassPart0001000002000268_0_in_0001000002000268 0

typedef struct OZ0001000002000269Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozBroadcastManager;
  OZ_Array ozDomainName;
  OZ_Array ozDomainPath;
  OZ_Object ozaTimer;

  /* protected (data) */
  OID ozaNameDirectory;
  int ozAlreadyCaptured;
  int ozSearching;

  /* protected (zero) */
} OZ0001000002000269Part_Rec, *OZ0001000002000269Part;

#ifdef OZ_ObjectPart_NameDirectoryHolder
#undef OZ_ObjectPart_NameDirectoryHolder
#endif
#define OZ_ObjectPart_NameDirectoryHolder OZ0001000002000269Part

#endif _OZ0001000002000269P_H_


#endif _PROTECTED_ALL_0001000002000269_H
