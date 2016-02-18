#define _OZ00010000020001fcP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001fb 1
#define OZClassPart0001000002fffffe_0_in_00010000020001fb 1
#define OZClassPart000100000200020a_0_in_00010000020001fb -3
#define OZClassPart000100000200020b_0_in_00010000020001fb -3
#define OZClassPart00010000020002d6_0_in_00010000020001fb -2
#define OZClassPart00010000020002d7_0_in_00010000020001fb -2
#define OZClassPart00010000020001ec_0_in_00010000020001fb -1
#define OZClassPart00010000020001ed_0_in_00010000020001fb -1
#define OZClassPart00010000020001fb_0_in_00010000020001fb 0

typedef struct OZ00010000020001fcPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozStrm;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001fcPart_Rec, *OZ00010000020001fcPart;

#ifdef OZ_ObjectPart_IOTextSun
#undef OZ_ObjectPart_IOTextSun
#endif
#define OZ_ObjectPart_IOTextSun OZ00010000020001fcPart

#endif _OZ00010000020001fcP_H_
