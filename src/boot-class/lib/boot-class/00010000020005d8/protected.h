#define _OZ00010000020005d8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005d7 1
#define OZClassPart0001000002fffffe_0_in_00010000020005d7 1
#define OZClassPart00010000020005e1_0_in_00010000020005d7 -1
#define OZClassPart00010000020005e2_0_in_00010000020005d7 -1
#define OZClassPart00010000020005d7_0_in_00010000020005d7 0

typedef struct OZ00010000020005d8Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020005d8Part_Rec, *OZ00010000020005d8Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_int__
#undef OZ_ObjectPart_Set_Assoc_String_int__
#endif
#define OZ_ObjectPart_Set_Assoc_String_int__ OZ00010000020005d8Part

#endif _OZ00010000020005d8P_H_
