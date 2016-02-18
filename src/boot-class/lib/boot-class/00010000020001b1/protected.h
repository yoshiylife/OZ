#define _OZ00010000020001b1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001b0 1
#define OZClassPart0001000002fffffe_0_in_00010000020001b0 1
#define OZClassPart00010000020001b0_0_in_00010000020001b0 0

typedef struct OZ00010000020001b1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001b1Part_Rec, *OZ00010000020001b1Part;

#ifdef OZ_ObjectPart_StreamFunctions
#undef OZ_ObjectPart_StreamFunctions
#endif
#define OZ_ObjectPart_StreamFunctions OZ00010000020001b1Part

#endif _OZ00010000020001b1P_H_
