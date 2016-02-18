#define _OZ0001000002000157P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000156 1
#define OZClassPart0001000002fffffe_0_in_0001000002000156 1
#define OZClassPart00010000020003e2_0_in_0001000002000156 -1
#define OZClassPart00010000020003e3_0_in_0001000002000156 -1
#define OZClassPart0001000002000156_0_in_0001000002000156 0

typedef struct OZ0001000002000157Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozContent;

  /* protected (zero) */
} OZ0001000002000157Part_Rec, *OZ0001000002000157Part;

#ifdef OZ_ObjectPart_DefaultToken
#undef OZ_ObjectPart_DefaultToken
#endif
#define OZ_ObjectPart_DefaultToken OZ0001000002000157Part

#endif _OZ0001000002000157P_H_
