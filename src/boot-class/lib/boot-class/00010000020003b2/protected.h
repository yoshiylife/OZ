#define _OZ00010000020003b2P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003b1 1
#define OZClassPart0001000002fffffe_0_in_00010000020003b1 1
#define OZClassPart00010000020003d8_0_in_00010000020003b1 -1
#define OZClassPart00010000020003d9_0_in_00010000020003b1 -1
#define OZClassPart00010000020003b1_0_in_00010000020003b1 0

typedef struct OZ00010000020003b2Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozBufferSize;

  /* protected (zero) */
} OZ00010000020003b2Part_Rec, *OZ00010000020003b2Part;

#ifdef OZ_ObjectPart_StringExtractor
#undef OZ_ObjectPart_StringExtractor
#endif
#define OZ_ObjectPart_StringExtractor OZ00010000020003b2Part

#endif _OZ00010000020003b2P_H_
