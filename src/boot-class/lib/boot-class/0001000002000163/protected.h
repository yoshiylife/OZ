#define _OZ0001000002000163P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000162 1
#define OZClassPart0001000002fffffe_0_in_0001000002000162 1
#define OZClassPart0001000002000162_0_in_0001000002000162 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000163Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozSubdirectories;
  OZ_Object ozEntries;
  OZ_Object ozDebug;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000163Part_Rec, *OZ0001000002000163Part;

#ifdef OZ_ObjectPart_Directory_0_
#undef OZ_ObjectPart_Directory_0_
#endif
#define OZ_ObjectPart_Directory_0_ OZ0001000002000163Part

#endif _OZ0001000002000163P_H_
