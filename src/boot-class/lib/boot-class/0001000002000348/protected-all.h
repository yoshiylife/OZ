#define _PROTECTED_ALL_0001000002000348_H

#ifndef _OZ0001000002000348P_H_
#define _OZ0001000002000348P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000347 1
#define OZClassPart0001000002fffffe_0_in_0001000002000347 1
#define OZClassPart0001000002000347_0_in_0001000002000347 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000348Part_Rec {
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
} OZ0001000002000348Part_Rec, *OZ0001000002000348Part;

#ifdef OZ_ObjectPart_SimpleArray_0_
#undef OZ_ObjectPart_SimpleArray_0_
#endif
#define OZ_ObjectPart_SimpleArray_0_ OZ0001000002000348Part

#endif _OZ0001000002000348P_H_


#endif _PROTECTED_ALL_0001000002000348_H
