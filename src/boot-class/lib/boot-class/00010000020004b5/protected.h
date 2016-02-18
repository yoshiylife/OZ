#define _OZ00010000020004b5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004b4 1
#define OZClassPart0001000002fffffe_0_in_00010000020004b4 1
#define OZClassPart00010000020004b4_0_in_00010000020004b4 0

typedef struct OZ00010000020004b5Part_Rec {
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
} OZ00010000020004b5Part_Rec, *OZ00010000020004b5Part;

#ifdef OZ_ObjectPart_SimpleTable_global_Object_ObjectTableEntry_
#undef OZ_ObjectPart_SimpleTable_global_Object_ObjectTableEntry_
#endif
#define OZ_ObjectPart_SimpleTable_global_Object_ObjectTableEntry_ OZ00010000020004b5Part

#endif _OZ00010000020004b5P_H_
