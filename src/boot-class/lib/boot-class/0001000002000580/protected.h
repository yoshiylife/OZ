#define _OZ0001000002000580P_H_


#define OZClassPart0001000002fffffd_0_in_000100000200057f 1
#define OZClassPart0001000002fffffe_0_in_000100000200057f 1
#define OZClassPart0001000002000589_0_in_000100000200057f -1
#define OZClassPart000100000200058a_0_in_000100000200057f -1
#define OZClassPart000100000200057f_0_in_000100000200057f 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000580Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000580Part_Rec, *OZ0001000002000580Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_0__
#undef OZ_ObjectPart_Set_Assoc_String_0__
#endif
#define OZ_ObjectPart_Set_Assoc_String_0__ OZ0001000002000580Part

#endif _OZ0001000002000580P_H_
