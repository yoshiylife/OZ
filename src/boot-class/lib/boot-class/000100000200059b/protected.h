#define _OZ000100000200059bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200059a 1
#define OZClassPart0001000002fffffe_0_in_000100000200059a 1
#define OZClassPart00010000020005a4_0_in_000100000200059a -1
#define OZClassPart00010000020005a5_0_in_000100000200059a -1
#define OZClassPart000100000200059a_0_in_000100000200059a 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200059bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ000100000200059bPart_Rec, *OZ000100000200059bPart;

#ifdef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___
#undef OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Set_Assoc_String_global_DirectoryServer_0___ OZ000100000200059bPart

#endif _OZ000100000200059bP_H_
