#define _OZ0001000002000432P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000431 1
#define OZClassPart0001000002fffffe_0_in_0001000002000431 1
#define OZClassPart0001000002000431_0_in_0001000002000431 0

typedef struct OZ0001000002000432Part_Rec {
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
} OZ0001000002000432Part_Rec, *OZ0001000002000432Part;

#ifdef OZ_ObjectPart_SimpleTable_global_ClassID_ClassPart_
#undef OZ_ObjectPart_SimpleTable_global_ClassID_ClassPart_
#endif
#define OZ_ObjectPart_SimpleTable_global_ClassID_ClassPart_ OZ0001000002000432Part

#endif _OZ0001000002000432P_H_
