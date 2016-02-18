#define _OZ000100000200024bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200024a 1
#define OZClassPart0001000002fffffe_0_in_000100000200024a 1
#define OZClassPart0001000002000073_0_in_000100000200024a -2
#define OZClassPart0001000002000074_0_in_000100000200024a -2
#define OZClassPart0001000002000138_0_in_000100000200024a -1
#define OZClassPart0001000002000139_0_in_000100000200024a -1
#define OZClassPart000100000200024a_0_in_000100000200024a 0

typedef struct OZ000100000200024bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  OID ozUpperPart;

  /* protected (zero) */
} OZ000100000200024bPart_Rec, *OZ000100000200024bPart;

#ifdef OZ_ObjectPart_LowerPart
#undef OZ_ObjectPart_LowerPart
#endif
#define OZ_ObjectPart_LowerPart OZ000100000200024bPart

#endif _OZ000100000200024bP_H_
