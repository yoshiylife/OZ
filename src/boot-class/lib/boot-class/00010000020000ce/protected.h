#define _OZ00010000020000ceP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000cd 1
#define OZClassPart0001000002fffffe_0_in_00010000020000cd 1
#define OZClassPart000100000200043f_0_in_00010000020000cd -3
#define OZClassPart0001000002000440_0_in_00010000020000cd -3
#define OZClassPart00010000020000eb_0_in_00010000020000cd -2
#define OZClassPart00010000020000ec_0_in_00010000020000cd -2
#define OZClassPart0001000002000220_0_in_00010000020000cd -1
#define OZClassPart0001000002000221_0_in_00010000020000cd -1
#define OZClassPart00010000020000cd_0_in_00010000020000cd 0

typedef struct OZ00010000020000cePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000cePart_Rec, *OZ00010000020000cePart;

#ifdef OZ_ObjectPart_ComFlush
#undef OZ_ObjectPart_ComFlush
#endif
#define OZ_ObjectPart_ComFlush OZ00010000020000cePart

#endif _OZ00010000020000ceP_H_
