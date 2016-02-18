#define _PROTECTED_ALL_0001000002000332_H

#ifndef _OZ0001000002000332P_H_
#define _OZ0001000002000332P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000331 1
#define OZClassPart0001000002fffffe_0_in_0001000002000331 1
#define OZClassPart0001000002000331_0_in_0001000002000331 0

typedef struct OZ0001000002000332Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozFirst;
  int ozLen;

  /* protected (zero) */
} OZ0001000002000332Part_Rec, *OZ0001000002000332Part;

#ifdef OZ_ObjectPart_Range
#undef OZ_ObjectPart_Range
#endif
#define OZ_ObjectPart_Range OZ0001000002000332Part

#endif _OZ0001000002000332P_H_


#endif _PROTECTED_ALL_0001000002000332_H
