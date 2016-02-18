#define _PROTECTED_ALL_0001000002000201_H

#ifndef _OZ0001000002000201P_H_
#define _OZ0001000002000201P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000200 1
#define OZClassPart0001000002fffffe_0_in_0001000002000200 1
#define OZClassPart0001000002000200_0_in_0001000002000200 0

typedef struct OZ0001000002000201Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000201Part_Rec, *OZ0001000002000201Part;

#ifdef OZ_ObjectPart_IStream
#undef OZ_ObjectPart_IStream
#endif
#define OZ_ObjectPart_IStream OZ0001000002000201Part

#endif _OZ0001000002000201P_H_


#endif _PROTECTED_ALL_0001000002000201_H
