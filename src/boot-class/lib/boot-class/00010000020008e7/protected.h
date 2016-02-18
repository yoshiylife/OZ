#ifndef _OZ00010000020008e7P_H_
#define _OZ00010000020008e7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008e6 1
#define OZClassPart0001000002fffffe_0_in_00010000020008e6 1
#define OZClassPart00010000020008e6_0_in_00010000020008e6 0

typedef struct OZ00010000020008e7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozKeyTable;
  OZ_Array ozTable;

  /* protected (data) */
  unsigned int ozExpansionFactor;
  unsigned int ozInitialTableSize;
  unsigned int ozNbits;
  unsigned int ozNumberOfElement;

  /* protected (zero) */
} OZ00010000020008e7Part_Rec, *OZ00010000020008e7Part;

#ifdef OZ_ObjectPart_SimpleTable_unsigned_int_SimpleArray_Alarmable__
#undef OZ_ObjectPart_SimpleTable_unsigned_int_SimpleArray_Alarmable__
#endif
#define OZ_ObjectPart_SimpleTable_unsigned_int_SimpleArray_Alarmable__ OZ00010000020008e7Part

#endif _OZ00010000020008e7P_H_
