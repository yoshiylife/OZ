#define _PROTECTED_ALL_0001000002000264_H

#ifndef _OZ0001000002000264P_H_
#define _OZ0001000002000264P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000263 1
#define OZClassPart0001000002fffffe_0_in_0001000002000263 1
#define OZClassPart0001000002000263_0_in_0001000002000263 0

typedef struct OZ0001000002000264Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozanExecutor;
  int pad0;

  /* protected (data) */
  int ozStatus;
  unsigned int ozNumberOfReaders;
  OID ozValue;

  /* protected (zero) */
  OZ_ConditionRec ozWritten;
} OZ0001000002000264Part_Rec, *OZ0001000002000264Part;

#ifdef OZ_ObjectPart_NameDirectoryBroadcastManager
#undef OZ_ObjectPart_NameDirectoryBroadcastManager
#endif
#define OZ_ObjectPart_NameDirectoryBroadcastManager OZ0001000002000264Part

#endif _OZ0001000002000264P_H_


#endif _PROTECTED_ALL_0001000002000264_H
