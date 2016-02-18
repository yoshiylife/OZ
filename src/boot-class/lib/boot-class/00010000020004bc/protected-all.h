#define _PROTECTED_ALL_00010000020004bc_H

#ifndef _OZ00010000020004bcP_H_
#define _OZ00010000020004bcP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004bb 1
#define OZClassPart0001000002fffffe_0_in_00010000020004bb 1
#define OZClassPart00010000020004bb_0_in_00010000020004bb 0

typedef struct OZ00010000020004bcPart_Rec {
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
} OZ00010000020004bcPart_Rec, *OZ00010000020004bcPart;

#ifdef OZ_ObjectPart_SimpleArray_global_VersionID_
#undef OZ_ObjectPart_SimpleArray_global_VersionID_
#endif
#define OZ_ObjectPart_SimpleArray_global_VersionID_ OZ00010000020004bcPart

#endif _OZ00010000020004bcP_H_


#endif _PROTECTED_ALL_00010000020004bc_H
