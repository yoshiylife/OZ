#ifndef _PROTECTED_ALL_0001000002000867_H
#define _PROTECTED_ALL_0001000002000867_H

#ifndef _OZ0001000002000867P_H_
#define _OZ0001000002000867P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000866 1
#define OZClassPart0001000002fffffe_0_in_0001000002000866 1
#define OZClassPart0001000002000866_0_in_0001000002000866 0

typedef struct OZ0001000002000867Part_Rec {
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
} OZ0001000002000867Part_Rec, *OZ0001000002000867Part;

#ifdef OZ_ObjectPart_SimpleArray_global_ClassPackageID_
#undef OZ_ObjectPart_SimpleArray_global_ClassPackageID_
#endif
#define OZ_ObjectPart_SimpleArray_global_ClassPackageID_ OZ0001000002000867Part

#endif _OZ0001000002000867P_H_


#endif _PROTECTED_ALL_0001000002000867_H
