#define _OZ000100000200012aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000129 1
#define OZClassPart0001000002fffffe_0_in_0001000002000129 1
#define OZClassPart0001000002000073_0_in_0001000002000129 -6
#define OZClassPart0001000002000074_0_in_0001000002000129 -6
#define OZClassPart0001000002000138_0_in_0001000002000129 -5
#define OZClassPart0001000002000139_0_in_0001000002000129 -5
#define OZClassPart00010000020003ff_0_in_0001000002000129 -4
#define OZClassPart0001000002000400_0_in_0001000002000129 -4
#define OZClassPart0001000002000073_1_in_0001000002000129 -3
#define OZClassPart0001000002000074_1_in_0001000002000129 -3
#define OZClassPart0001000002000138_1_in_0001000002000129 -2
#define OZClassPart0001000002000139_1_in_0001000002000129 -2
#define OZClassPart000100000200024a_0_in_0001000002000129 -1
#define OZClassPart000100000200024b_0_in_0001000002000129 -1
#define OZClassPart0001000002000129_0_in_0001000002000129 0

typedef struct OZ000100000200012aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozConfiguredClassIDList;
  int pad0;

  /* protected (data) */
  unsigned int ozInitialLengthOfConfiguredClassIDList;
  OID ozDefaultConfiguredClassID;
  unsigned int ozKind;

  /* protected (zero) */
} OZ000100000200012aPart_Rec, *OZ000100000200012aPart;

#ifdef OZ_ObjectPart_PublicPart
#undef OZ_ObjectPart_PublicPart
#endif
#define OZ_ObjectPart_PublicPart OZ000100000200012aPart

#endif _OZ000100000200012aP_H_
