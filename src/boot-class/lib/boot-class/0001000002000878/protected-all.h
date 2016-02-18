#ifndef _PROTECTED_ALL_0001000002000878_H
#define _PROTECTED_ALL_0001000002000878_H

#ifndef _OZ0001000002000878P_H_
#define _OZ0001000002000878P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000877 1
#define OZClassPart0001000002fffffe_0_in_0001000002000877 1
#define OZClassPart0001000002000877_0_in_0001000002000877 0

typedef struct OZ0001000002000878Part_Rec {
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
} OZ0001000002000878Part_Rec, *OZ0001000002000878Part;

#ifdef OZ_ObjectPart_SimpleTable_global_ClassID_Date_
#undef OZ_ObjectPart_SimpleTable_global_ClassID_Date_
#endif
#define OZ_ObjectPart_SimpleTable_global_ClassID_Date_ OZ0001000002000878Part

#endif _OZ0001000002000878P_H_


#endif _PROTECTED_ALL_0001000002000878_H
