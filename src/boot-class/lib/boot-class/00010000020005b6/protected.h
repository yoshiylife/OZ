#define _OZ00010000020005b6P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005b5 1
#define OZClassPart0001000002fffffe_0_in_00010000020005b5 1
#define OZClassPart00010000020005ba_0_in_00010000020005b5 -1
#define OZClassPart00010000020005bb_0_in_00010000020005b5 -1
#define OZClassPart00010000020005b5_0_in_00010000020005b5 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005b6Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020005b6Part_Rec, *OZ00010000020005b6Part;

#ifdef OZ_ObjectPart_Set_Assoc_OIDAsKey_0__0__
#undef OZ_ObjectPart_Set_Assoc_OIDAsKey_0__0__
#endif
#define OZ_ObjectPart_Set_Assoc_OIDAsKey_0__0__ OZ00010000020005b6Part

#endif _OZ00010000020005b6P_H_
