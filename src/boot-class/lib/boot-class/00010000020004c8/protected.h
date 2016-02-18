#define _OZ00010000020004c8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004c7 1
#define OZClassPart0001000002fffffe_0_in_00010000020004c7 1
#define OZClassPart00010000020004c7_0_in_00010000020004c7 0

typedef struct OZ00010000020004c8Part_Rec {
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
} OZ00010000020004c8Part_Rec, *OZ00010000020004c8Part;

#ifdef OZ_ObjectPart_SimpleArray_global_Object_
#undef OZ_ObjectPart_SimpleArray_global_Object_
#endif
#define OZ_ObjectPart_SimpleArray_global_Object_ OZ00010000020004c8Part

#endif _OZ00010000020004c8P_H_
