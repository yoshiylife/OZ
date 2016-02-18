#define _OZ0001000002000520P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200051f 1
#define OZClassPart0001000002fffffe_0_in_000100000200051f 1
#define OZClassPart0001000002000529_0_in_000100000200051f -2
#define OZClassPart000100000200052a_0_in_000100000200051f -2
#define OZClassPart0001000002000524_0_in_000100000200051f -1
#define OZClassPart0001000002000525_0_in_000100000200051f -1
#define OZClassPart000100000200051f_0_in_000100000200051f 0

typedef struct OZ0001000002000520Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000520Part_Rec, *OZ0001000002000520Part;

#ifdef OZ_ObjectPart_OrderedCollection_Token_
#undef OZ_ObjectPart_OrderedCollection_Token_
#endif
#define OZ_ObjectPart_OrderedCollection_Token_ OZ0001000002000520Part

#endif _OZ0001000002000520P_H_
