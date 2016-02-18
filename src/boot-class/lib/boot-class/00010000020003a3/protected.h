#define _OZ00010000020003a3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003a2 1
#define OZClassPart0001000002fffffe_0_in_00010000020003a2 1
#define OZClassPart00010000020003a2_0_in_00010000020003a2 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020003a3Part_Rec {
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
} OZ00010000020003a3Part_Rec, *OZ00010000020003a3Part;

#ifdef OZ_ObjectPart_SimpleTable_0_0_
#undef OZ_ObjectPart_SimpleTable_0_0_
#endif
#define OZ_ObjectPart_SimpleTable_0_0_ OZ00010000020003a3Part

#endif _OZ00010000020003a3P_H_
