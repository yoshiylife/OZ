#define _PROTECTED_ALL_000100000200003f_H

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
#ifndef _OZ000100000200003fP_H_
#define _OZ000100000200003fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200003e 1
#define OZClassPart0001000002fffffe_0_in_000100000200003e 1
#define OZClassPart00010000020008cb_0_in_000100000200003e -1
#define OZClassPart00010000020008cc_0_in_000100000200003e -1
#define OZClassPart000100000200003e_0_in_000100000200003e 0

typedef struct OZ000100000200003fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozKeyTable;
  OZ_Array ozConditionIndex;
  OZ_Array ozWritten;
  OZ_Array ozAnswerTable;
  OZ_Array ozCountTable;
  OZ_Object ozanExecutor;

  /* protected (data) */
  unsigned int ozInitialTableSize;
  unsigned int ozSize;
  unsigned int ozMask;
  unsigned int ozNbits;

  /* protected (zero) */
} OZ000100000200003fPart_Rec, *OZ000100000200003fPart;

#ifdef OZ_ObjectPart_ClassBroadcastManager
#undef OZ_ObjectPart_ClassBroadcastManager
#endif
#define OZ_ObjectPart_ClassBroadcastManager OZ000100000200003fPart

#endif _OZ000100000200003fP_H_


#endif _PROTECTED_ALL_000100000200003f_H
