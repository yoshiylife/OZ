#define _OZ00010000020005aaP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005a9 1
#define OZClassPart0001000002fffffe_0_in_00010000020005a9 1
#define OZClassPart00010000020005a9_0_in_00010000020005a9 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005aaPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020005aaPart_Rec, *OZ00010000020005aaPart;

#ifdef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_0___
#undef OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Iterator_Assoc_String_global_DirectoryServer_0___ OZ00010000020005aaPart

#endif _OZ00010000020005aaP_H_
