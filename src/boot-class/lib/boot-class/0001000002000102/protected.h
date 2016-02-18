#define _OZ0001000002000102P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000101 1
#define OZClassPart0001000002fffffe_0_in_0001000002000101 1
#define OZClassPart0001000002000073_0_in_0001000002000101 -1
#define OZClassPart0001000002000074_0_in_0001000002000101 -1
#define OZClassPart0001000002000101_0_in_0001000002000101 0

typedef struct OZ0001000002000102Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  OID ozVersionIDOfPublicPart;

  /* protected (zero) */
} OZ0001000002000102Part_Rec, *OZ0001000002000102Part;

#ifdef OZ_ObjectPart_ConfiguredClass
#undef OZ_ObjectPart_ConfiguredClass
#endif
#define OZ_ObjectPart_ConfiguredClass OZ0001000002000102Part

#endif _OZ0001000002000102P_H_
