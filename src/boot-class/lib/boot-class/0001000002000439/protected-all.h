#define _PROTECTED_ALL_0001000002000439_H

#ifndef _OZ0001000002000439P_H_
#define _OZ0001000002000439P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000438 1
#define OZClassPart0001000002fffffe_0_in_0001000002000438 1
#define OZClassPart0001000002000438_0_in_0001000002000438 0

typedef struct OZ0001000002000439Part_Rec {
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
} OZ0001000002000439Part_Rec, *OZ0001000002000439Part;

#ifdef OZ_ObjectPart_SimpleArray_global_Class_
#undef OZ_ObjectPart_SimpleArray_global_Class_
#endif
#define OZ_ObjectPart_SimpleArray_global_Class_ OZ0001000002000439Part

#endif _OZ0001000002000439P_H_


#endif _PROTECTED_ALL_0001000002000439_H
