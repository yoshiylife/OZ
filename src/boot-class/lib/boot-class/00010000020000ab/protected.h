#define _OZ00010000020000abP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000aa 1
#define OZClassPart0001000002fffffe_0_in_00010000020000aa 1
#define OZClassPart000100000200013d_0_in_00010000020000aa -2
#define OZClassPart000100000200013e_0_in_00010000020000aa -2
#define OZClassPart0001000002000142_0_in_00010000020000aa -1
#define OZClassPart0001000002000143_0_in_00010000020000aa -1
#define OZClassPart00010000020000aa_0_in_00010000020000aa 0

typedef struct OZ00010000020000abPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020000abPart_Rec, *OZ00010000020000abPart;

#ifdef OZ_ObjectPart_CodeFaultDaemon
#undef OZ_ObjectPart_CodeFaultDaemon
#endif
#define OZ_ObjectPart_CodeFaultDaemon OZ00010000020000abPart

#endif _OZ00010000020000abP_H_
