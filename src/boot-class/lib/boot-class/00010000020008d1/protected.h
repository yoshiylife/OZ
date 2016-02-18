#ifndef _OZ00010000020008d1P_H_
#define _OZ00010000020008d1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008d0 1
#define OZClassPart0001000002fffffe_0_in_00010000020008d0 1
#define OZClassPart00010000020008d0_0_in_00010000020008d0 0

typedef struct OZ00010000020008d1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozTable;
  int pad0;

  /* protected (data) */
  unsigned int ozExpansionFactor;
  unsigned int ozInitialTableSize;
  int ozShrinkFactor;
  int ozShrinkThreshold;
  unsigned int ozNumberOfElement;

  /* protected (zero) */
} OZ00010000020008d1Part_Rec, *OZ00010000020008d1Part;

#ifdef OZ_ObjectPart_SimpleArray_Alarmable_
#undef OZ_ObjectPart_SimpleArray_Alarmable_
#endif
#define OZ_ObjectPart_SimpleArray_Alarmable_ OZ00010000020008d1Part

#endif _OZ00010000020008d1P_H_
