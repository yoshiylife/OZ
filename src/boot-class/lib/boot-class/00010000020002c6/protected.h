#define _OZ00010000020002c6P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002c5 1
#define OZClassPart0001000002fffffe_0_in_00010000020002c5 1
#define OZClassPart00010000020000b4_0_in_00010000020002c5 -2
#define OZClassPart00010000020000b5_0_in_00010000020002c5 -2
#define OZClassPart0001000002000378_0_in_00010000020002c5 -1
#define OZClassPart0001000002000379_0_in_00010000020002c5 -1
#define OZClassPart00010000020002c5_0_in_00010000020002c5 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020002c6Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020002c6Part_Rec, *OZ00010000020002c6Part;

#ifdef OZ_ObjectPart_OrderedCollection_0_
#undef OZ_ObjectPart_OrderedCollection_0_
#endif
#define OZ_ObjectPart_OrderedCollection_0_ OZ00010000020002c6Part

#endif _OZ00010000020002c6P_H_
