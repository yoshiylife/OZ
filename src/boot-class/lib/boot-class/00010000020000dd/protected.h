#define _OZ00010000020000ddP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000dc 1
#define OZClassPart0001000002fffffe_0_in_00010000020000dc 1
#define OZClassPart000100000200043f_0_in_00010000020000dc -3
#define OZClassPart0001000002000440_0_in_00010000020000dc -3
#define OZClassPart00010000020000eb_0_in_00010000020000dc -2
#define OZClassPart00010000020000ec_0_in_00010000020000dc -2
#define OZClassPart0001000002000220_0_in_00010000020000dc -1
#define OZClassPart0001000002000221_0_in_00010000020000dc -1
#define OZClassPart00010000020000dc_0_in_00010000020000dc 0

typedef struct OZ00010000020000ddPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000ddPart_Rec, *OZ00010000020000ddPart;

#ifdef OZ_ObjectPart_ComGetSub
#undef OZ_ObjectPart_ComGetSub
#endif
#define OZ_ObjectPart_ComGetSub OZ00010000020000ddPart

#endif _OZ00010000020000ddP_H_
