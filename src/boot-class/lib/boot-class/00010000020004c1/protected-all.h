#define _PROTECTED_ALL_00010000020004c1_H

#ifndef _OZ00010000020004c1P_H_
#define _OZ00010000020004c1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004c0 1
#define OZClassPart0001000002fffffe_0_in_00010000020004c0 1
#define OZClassPart00010000020004c0_0_in_00010000020004c0 0

typedef struct OZ00010000020004c1Part_Rec {
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
} OZ00010000020004c1Part_Rec, *OZ00010000020004c1Part;

#ifdef OZ_ObjectPart_SimpleArray_global_ConfiguredClassID_
#undef OZ_ObjectPart_SimpleArray_global_ConfiguredClassID_
#endif
#define OZ_ObjectPart_SimpleArray_global_ConfiguredClassID_ OZ00010000020004c1Part

#endif _OZ00010000020004c1P_H_


#endif _PROTECTED_ALL_00010000020004c1_H
