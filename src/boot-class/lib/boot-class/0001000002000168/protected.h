#define _OZ0001000002000168P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000167 1
#define OZClassPart0001000002fffffe_0_in_0001000002000167 1
#define OZClassPart0001000002000336_0_in_0001000002000167 -3
#define OZClassPart0001000002000337_0_in_0001000002000167 -3
#define OZClassPart00010000020007a3_0_in_0001000002000167 -2
#define OZClassPart00010000020007a4_0_in_0001000002000167 -2
#define OZClassPart0001000002000254_0_in_0001000002000167 -1
#define OZClassPart0001000002000255_0_in_0001000002000167 -1
#define OZClassPart0001000002000167_0_in_0001000002000167 0

typedef struct OZ0001000002000168Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozDomainMap;
  OZ_Object ozRootDirectoryPath;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000168Part_Rec, *OZ0001000002000168Part;

#ifdef OZ_ObjectPart_DNSResolver
#undef OZ_ObjectPart_DNSResolver
#endif
#define OZ_ObjectPart_DNSResolver OZ0001000002000168Part

#endif _OZ0001000002000168P_H_
