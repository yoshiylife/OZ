#ifndef _OZ000100000200088eP_H_
#define _OZ000100000200088eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200088d 1
#define OZClassPart0001000002fffffe_0_in_000100000200088d 1
#define OZClassPart0001000002000897_0_in_000100000200088d -2
#define OZClassPart0001000002000898_0_in_000100000200088d -2
#define OZClassPart0001000002000892_0_in_000100000200088d -1
#define OZClassPart0001000002000893_0_in_000100000200088d -1
#define OZClassPart000100000200088d_0_in_000100000200088d 0

typedef struct OZ000100000200088ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200088ePart_Rec, *OZ000100000200088ePart;

#ifdef OZ_ObjectPart_OrderedCollection_MirrorOperation_
#undef OZ_ObjectPart_OrderedCollection_MirrorOperation_
#endif
#define OZ_ObjectPart_OrderedCollection_MirrorOperation_ OZ000100000200088ePart

#endif _OZ000100000200088eP_H_
