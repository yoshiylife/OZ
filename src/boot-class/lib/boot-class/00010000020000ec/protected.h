#define _OZ00010000020000ecP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000eb 1
#define OZClassPart0001000002fffffe_0_in_00010000020000eb 1
#define OZClassPart000100000200043f_0_in_00010000020000eb -1
#define OZClassPart0001000002000440_0_in_00010000020000eb -1
#define OZClassPart00010000020000eb_0_in_00010000020000eb 0

typedef struct OZ00010000020000ecPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozName;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000ecPart_Rec, *OZ00010000020000ecPart;

#ifdef OZ_ObjectPart_Command
#undef OZ_ObjectPart_Command
#endif
#define OZ_ObjectPart_Command OZ00010000020000ecPart

#endif _OZ00010000020000ecP_H_
