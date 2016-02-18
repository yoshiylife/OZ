#define _OZ00010000020002e1P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020002e0 1
#define OZClassPart0001000002fffffe_0_in_00010000020002e0 1
#define OZClassPart0001000002000187_0_in_00010000020002e0 -1
#define OZClassPart0001000002000188_0_in_00010000020002e0 -1
#define OZClassPart00010000020002e0_0_in_00010000020002e0 0

typedef struct OZ00010000020002e1Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozanExecutor;
  OZ_Object ozTable;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020002e1Part_Rec, *OZ00010000020002e1Part;

#ifdef OZ_ObjectPart_ObjectTableManager
#undef OZ_ObjectPart_ObjectTableManager
#endif
#define OZ_ObjectPart_ObjectTableManager OZ00010000020002e1Part

#endif _OZ00010000020002e1P_H_
