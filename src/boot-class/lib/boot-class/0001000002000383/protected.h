#define _OZ0001000002000383P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000382 1
#define OZClassPart0001000002fffffe_0_in_0001000002000382 1
#define OZClassPart00010000020000b4_0_in_0001000002000382 -1
#define OZClassPart00010000020000b5_0_in_0001000002000382 -1
#define OZClassPart0001000002000382_0_in_0001000002000382 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000383Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000383Part_Rec, *OZ0001000002000383Part;

#ifdef OZ_ObjectPart_Set_0_
#undef OZ_ObjectPart_Set_0_
#endif
#define OZ_ObjectPart_Set_0_ OZ0001000002000383Part

#endif _OZ0001000002000383P_H_
