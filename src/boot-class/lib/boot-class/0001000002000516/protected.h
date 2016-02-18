#define _OZ0001000002000516P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000515 1
#define OZClassPart0001000002fffffe_0_in_0001000002000515 1
#define OZClassPart0001000002000515_0_in_0001000002000515 0

typedef struct OZ0001000002000516Part_Rec {
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
} OZ0001000002000516Part_Rec, *OZ0001000002000516Part;

#ifdef OZ_ObjectPart_SimpleArray_char_A_
#undef OZ_ObjectPart_SimpleArray_char_A_
#endif
#define OZ_ObjectPart_SimpleArray_char_A_ OZ0001000002000516Part

#endif _OZ0001000002000516P_H_
