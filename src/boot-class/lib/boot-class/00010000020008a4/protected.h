#ifndef _OZ00010000020008a4P_H_
#define _OZ00010000020008a4P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008a3 1
#define OZClassPart0001000002fffffe_0_in_00010000020008a3 1
#define OZClassPart00010000020008a3_0_in_00010000020008a3 0

typedef struct OZ00010000020008a4Part_Rec {
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
} OZ00010000020008a4Part_Rec, *OZ00010000020008a4Part;

#ifdef OZ_ObjectPart_SimpleTable_global_Class_FIFO_MirrorOperation__
#undef OZ_ObjectPart_SimpleTable_global_Class_FIFO_MirrorOperation__
#endif
#define OZ_ObjectPart_SimpleTable_global_Class_FIFO_MirrorOperation__ OZ00010000020008a4Part

#endif _OZ00010000020008a4P_H_
