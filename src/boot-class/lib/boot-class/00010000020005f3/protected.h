#define _OZ00010000020005f3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005f2 1
#define OZClassPart0001000002fffffe_0_in_00010000020005f2 1
#define OZClassPart00010000020005fc_0_in_00010000020005f2 -1
#define OZClassPart00010000020005fd_0_in_00010000020005f2 -1
#define OZClassPart00010000020005f2_0_in_00010000020005f2 0

typedef struct OZ00010000020005f3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020005f3Part_Rec, *OZ00010000020005f3Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_Command__
#undef OZ_ObjectPart_Set_Assoc_String_Command__
#endif
#define OZ_ObjectPart_Set_Assoc_String_Command__ OZ00010000020005f3Part

#endif _OZ00010000020005f3P_H_
