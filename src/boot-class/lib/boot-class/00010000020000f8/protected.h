#define _OZ00010000020000f8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000f7 1
#define OZClassPart0001000002fffffe_0_in_00010000020000f7 1
#define OZClassPart000100000200043f_0_in_00010000020000f7 -3
#define OZClassPart0001000002000440_0_in_00010000020000f7 -3
#define OZClassPart00010000020000eb_0_in_00010000020000f7 -2
#define OZClassPart00010000020000ec_0_in_00010000020000f7 -2
#define OZClassPart0001000002000220_0_in_00010000020000f7 -1
#define OZClassPart0001000002000221_0_in_00010000020000f7 -1
#define OZClassPart00010000020000f7_0_in_00010000020000f7 0

typedef struct OZ00010000020000f8Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000f8Part_Rec, *OZ00010000020000f8Part;

#ifdef OZ_ObjectPart_ComShutdown
#undef OZ_ObjectPart_ComShutdown
#endif
#define OZ_ObjectPart_ComShutdown OZ00010000020000f8Part

#endif _OZ00010000020000f8P_H_
