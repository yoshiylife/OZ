#define _OZ000100000200011bP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200011a 1
#define OZClassPart0001000002fffffe_0_in_000100000200011a 1
#define OZClassPart0001000002000187_0_in_000100000200011a -1
#define OZClassPart0001000002000188_0_in_000100000200011a -1
#define OZClassPart000100000200011a_0_in_000100000200011a 0

typedef struct OZ000100000200011bPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozTable;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200011bPart_Rec, *OZ000100000200011bPart;

#ifdef OZ_ObjectPart_ConfigurationTables
#undef OZ_ObjectPart_ConfigurationTables
#endif
#define OZ_ObjectPart_ConfigurationTables OZ000100000200011bPart

#endif _OZ000100000200011bP_H_
