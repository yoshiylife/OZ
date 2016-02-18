#define _OZ00010000020000a1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000a0 1
#define OZClassPart0001000002fffffe_0_in_00010000020000a0 1
#define OZClassPart00010000020000a0_0_in_00010000020000a0 0

typedef struct OZ00010000020000a1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000a1Part_Rec, *OZ00010000020000a1Part;

#ifdef OZ_ObjectPart_NotifierWindow
#undef OZ_ObjectPart_NotifierWindow
#endif
#define OZ_ObjectPart_NotifierWindow OZ00010000020000a1Part

#endif _OZ00010000020000a1P_H_
