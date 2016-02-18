#define _OZ0001000002000400P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003ff 1
#define OZClassPart0001000002fffffe_0_in_00010000020003ff 1
#define OZClassPart0001000002000073_0_in_00010000020003ff -2
#define OZClassPart0001000002000074_0_in_00010000020003ff -2
#define OZClassPart0001000002000138_0_in_00010000020003ff -1
#define OZClassPart0001000002000139_0_in_00010000020003ff -1
#define OZClassPart00010000020003ff_0_in_00010000020003ff 0

typedef struct OZ0001000002000400Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozLowerVersions;
  OZ_Object ozVisibleLowerVersions;

  /* protected (data) */
  OID ozDefaultLowerVersion;

  /* protected (zero) */
} OZ0001000002000400Part_Rec, *OZ0001000002000400Part;

#ifdef OZ_ObjectPart_UpperPart
#undef OZ_ObjectPart_UpperPart
#endif
#define OZ_ObjectPart_UpperPart OZ0001000002000400Part

#endif _OZ0001000002000400P_H_
