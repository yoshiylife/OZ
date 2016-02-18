#define _OZ0001000002000255P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000254 1
#define OZClassPart0001000002fffffe_0_in_0001000002000254 1
#define OZClassPart0001000002000336_0_in_0001000002000254 -2
#define OZClassPart0001000002000337_0_in_0001000002000254 -2
#define OZClassPart00010000020007a3_0_in_0001000002000254 -1
#define OZClassPart00010000020007a4_0_in_0001000002000254 -1
#define OZClassPart0001000002000254_0_in_0001000002000254 0

typedef struct OZ0001000002000255Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozDomainName;
  OZ_Object ozMyName;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000255Part_Rec, *OZ0001000002000255Part;

#ifdef OZ_ObjectPart_NameDirectory
#undef OZ_ObjectPart_NameDirectory
#endif
#define OZ_ObjectPart_NameDirectory OZ0001000002000255Part

#endif _OZ0001000002000255P_H_
