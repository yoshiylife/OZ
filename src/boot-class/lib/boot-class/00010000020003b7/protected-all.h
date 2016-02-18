#define _PROTECTED_ALL_00010000020003b7_H

#ifndef _OZ00010000020003b7P_H_
#define _OZ00010000020003b7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003b6 1
#define OZClassPart0001000002fffffe_0_in_00010000020003b6 1
#define OZClassPart00010000020003b6_0_in_00010000020003b6 0

typedef struct OZ00010000020003b7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozBuffer;
  OZ_Array ozUngotten;

  /* protected (data) */
  unsigned int ozFileDescriptor;
  unsigned int ozSize;
  unsigned int ozPointer;
  int ozRunOut;

  /* protected (zero) */
} OZ00010000020003b7Part_Rec, *OZ00010000020003b7Part;

#ifdef OZ_ObjectPart_Stream
#undef OZ_ObjectPart_Stream
#endif
#define OZ_ObjectPart_Stream OZ00010000020003b7Part

#endif _OZ00010000020003b7P_H_


#endif _PROTECTED_ALL_00010000020003b7_H
