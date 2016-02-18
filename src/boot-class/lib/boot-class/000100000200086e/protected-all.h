#ifndef _PROTECTED_ALL_000100000200086e_H
#define _PROTECTED_ALL_000100000200086e_H

#ifndef _OZ000100000200086eP_H_
#define _OZ000100000200086eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200086d 1
#define OZClassPart0001000002fffffe_0_in_000100000200086d 1
#define OZClassPart000100000200086d_0_in_000100000200086d 0

typedef struct OZ000100000200086ePart_Rec {
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
} OZ000100000200086ePart_Rec, *OZ000100000200086ePart;

#ifdef OZ_ObjectPart_SimpleTable_global_ClassPackageID_MirroredClassPackage_
#undef OZ_ObjectPart_SimpleTable_global_ClassPackageID_MirroredClassPackage_
#endif
#define OZ_ObjectPart_SimpleTable_global_ClassPackageID_MirroredClassPackage_ OZ000100000200086ePart

#endif _OZ000100000200086eP_H_


#endif _PROTECTED_ALL_000100000200086e_H
