#define _OZ00010000020004feP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004fd 1
#define OZClassPart0001000002fffffe_0_in_00010000020004fd 1
#define OZClassPart00010000020004fd_0_in_00010000020004fd 0

typedef struct OZ00010000020004fePart_Rec {
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
} OZ00010000020004fePart_Rec, *OZ00010000020004fePart;

#ifdef OZ_ObjectPart_SimpleTable_char_A_SchoolValue_
#undef OZ_ObjectPart_SimpleTable_char_A_SchoolValue_
#endif
#define OZ_ObjectPart_SimpleTable_char_A_SchoolValue_ OZ00010000020004fePart

#endif _OZ00010000020004feP_H_
