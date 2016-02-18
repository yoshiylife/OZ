#define _OZ00010000020001deP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001dd 1
#define OZClassPart0001000002fffffe_0_in_00010000020001dd 1
#define OZClassPart00010000020003e2_0_in_00010000020001dd -1
#define OZClassPart00010000020003e3_0_in_00010000020001dd -1
#define OZClassPart00010000020001dd_0_in_00010000020001dd 0

typedef struct OZ00010000020001dePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  OZ_Long ozContent;

  /* protected (zero) */
} OZ00010000020001dePart_Rec, *OZ00010000020001dePart;

#ifdef OZ_ObjectPart_IntegerToken
#undef OZ_ObjectPart_IntegerToken
#endif
#define OZ_ObjectPart_IntegerToken OZ00010000020001dePart

#endif _OZ00010000020001deP_H_
