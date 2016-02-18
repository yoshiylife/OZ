#define _OZ00010000020003beP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003bd 1
#define OZClassPart0001000002fffffe_0_in_00010000020003bd 1
#define OZClassPart00010000020003bd_0_in_00010000020003bd 0

typedef struct OZ00010000020003bePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozStr;
  int pad0;

  /* protected (data) */
  char  ozACO[0];
  unsigned int ozLen;

  /* protected (zero) */
} OZ00010000020003bePart_Rec, *OZ00010000020003bePart;

#ifdef OZ_ObjectPart_String
#undef OZ_ObjectPart_String
#endif
#define OZ_ObjectPart_String OZ00010000020003bePart

#endif _OZ00010000020003beP_H_
