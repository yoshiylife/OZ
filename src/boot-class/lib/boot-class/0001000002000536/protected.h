#define _OZ0001000002000536P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000535 1
#define OZClassPart0001000002fffffe_0_in_0001000002000535 1
#define OZClassPart0001000002000468_0_in_0001000002000535 -2
#define OZClassPart0001000002000469_0_in_0001000002000535 -2
#define OZClassPart000100000200048a_0_in_0001000002000535 -1
#define OZClassPart000100000200048b_0_in_0001000002000535 -1
#define OZClassPart0001000002000535_0_in_0001000002000535 0

typedef struct OZ0001000002000536Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000536Part_Rec, *OZ0001000002000536Part;

#ifdef OZ_ObjectPart_OrderedCollection_String_
#undef OZ_ObjectPart_OrderedCollection_String_
#endif
#define OZ_ObjectPart_OrderedCollection_String_ OZ0001000002000536Part

#endif _OZ0001000002000536P_H_
