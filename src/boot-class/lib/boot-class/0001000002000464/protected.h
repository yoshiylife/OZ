#define _OZ0001000002000464P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000463 1
#define OZClassPart0001000002fffffe_0_in_0001000002000463 1
#define OZClassPart0001000002000468_0_in_0001000002000463 -1
#define OZClassPart0001000002000469_0_in_0001000002000463 -1
#define OZClassPart0001000002000463_0_in_0001000002000463 0

typedef struct OZ0001000002000464Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000464Part_Rec, *OZ0001000002000464Part;

#ifdef OZ_ObjectPart_Set_String_
#undef OZ_ObjectPart_Set_String_
#endif
#define OZ_ObjectPart_Set_String_ OZ0001000002000464Part

#endif _OZ0001000002000464P_H_
