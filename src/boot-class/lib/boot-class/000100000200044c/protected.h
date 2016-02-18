#define _OZ000100000200044cP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200044b 1
#define OZClassPart0001000002fffffe_0_in_000100000200044b 1
#define OZClassPart000100000200044b_0_in_000100000200044b 0

typedef struct OZ000100000200044cPart_Rec {
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
} OZ000100000200044cPart_Rec, *OZ000100000200044cPart;

#ifdef OZ_ObjectPart_SimpleTable_global_ConfigurationID_ConfigurationTable_
#undef OZ_ObjectPart_SimpleTable_global_ConfigurationID_ConfigurationTable_
#endif
#define OZ_ObjectPart_SimpleTable_global_ConfigurationID_ConfigurationTable_ OZ000100000200044cPart

#endif _OZ000100000200044cP_H_
