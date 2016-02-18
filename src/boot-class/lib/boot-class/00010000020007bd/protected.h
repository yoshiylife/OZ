#ifndef _OZ00010000020007bdP_H_
#define _OZ00010000020007bdP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020007bc 1
#define OZClassPart0001000002fffffe_0_in_00010000020007bc 1
#define OZClassPart00010000020007e9_0_in_00010000020007bc -1
#define OZClassPart00010000020007ea_0_in_00010000020007bc -1
#define OZClassPart00010000020007bc_0_in_00010000020007bc 0

typedef struct OZ00010000020007bdPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020007bdPart_Rec, *OZ00010000020007bdPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_Directory_global_ResolvableObject___
#undef OZ_ObjectPart_Set_Assoc_String_Directory_global_ResolvableObject___
#endif
#define OZ_ObjectPart_Set_Assoc_String_Directory_global_ResolvableObject___ OZ00010000020007bdPart

#endif _OZ00010000020007bdP_H_
