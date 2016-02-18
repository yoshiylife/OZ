#ifndef _OZ0001000002000858P_H_
#define _OZ0001000002000858P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000857 1
#define OZClassPart0001000002fffffe_0_in_0001000002000857 1
#define OZClassPart0001000002000857_0_in_0001000002000857 0

typedef struct OZ0001000002000858Part_Rec {
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
} OZ0001000002000858Part_Rec, *OZ0001000002000858Part;

#ifdef OZ_ObjectPart_SimpleTable_global_Class_Waiter_
#undef OZ_ObjectPart_SimpleTable_global_Class_Waiter_
#endif
#define OZ_ObjectPart_SimpleTable_global_Class_Waiter_ OZ0001000002000858Part

#endif _OZ0001000002000858P_H_
