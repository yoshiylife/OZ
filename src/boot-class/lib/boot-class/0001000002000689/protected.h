#define _OZ0001000002000689P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000688 1
#define OZClassPart0001000002fffffe_0_in_0001000002000688 1
#define OZClassPart0001000002000692_0_in_0001000002000688 -1
#define OZClassPart0001000002000693_0_in_0001000002000688 -1
#define OZClassPart0001000002000688_0_in_0001000002000688 0

typedef struct OZ0001000002000689Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000689Part_Rec, *OZ0001000002000689Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_Directory_Package___
#undef OZ_ObjectPart_Set_Assoc_String_Directory_Package___
#endif
#define OZ_ObjectPart_Set_Assoc_String_Directory_Package___ OZ0001000002000689Part

#endif _OZ0001000002000689P_H_
