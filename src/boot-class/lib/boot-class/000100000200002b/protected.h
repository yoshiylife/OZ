#define _OZ000100000200002bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200002a 1
#define OZClassPart0001000002fffffe_0_in_000100000200002a 1
#define OZClassPart0001000002000187_0_in_000100000200002a -1
#define OZClassPart0001000002000188_0_in_000100000200002a -1
#define OZClassPart000100000200002a_0_in_000100000200002a 0

typedef struct OZ000100000200002bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozValue;

  /* protected (zero) */
} OZ000100000200002bPart_Rec, *OZ000100000200002bPart;

#ifdef OZ_ObjectPart_BooleanHolder
#undef OZ_ObjectPart_BooleanHolder
#endif
#define OZ_ObjectPart_BooleanHolder OZ000100000200002bPart

#endif _OZ000100000200002bP_H_
