#define _OZ00010000020003deP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003dd 1
#define OZClassPart0001000002fffffe_0_in_00010000020003dd 1
#define OZClassPart00010000020003dd_0_in_00010000020003dd 0

typedef struct OZ00010000020003dePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int oztheClock;

  /* protected (zero) */
} OZ00010000020003dePart_Rec, *OZ00010000020003dePart;

#ifdef OZ_ObjectPart_Time
#undef OZ_ObjectPart_Time
#endif
#define OZ_ObjectPart_Time OZ00010000020003dePart

#endif _OZ00010000020003deP_H_
