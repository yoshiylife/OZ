#define _OZ0001000002000241P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000240 1
#define OZClassPart0001000002fffffe_0_in_0001000002000240 1
#define OZClassPart0001000002000499_0_in_0001000002000240 -2
#define OZClassPart000100000200049a_0_in_0001000002000240 -2
#define OZClassPart0001000002000494_0_in_0001000002000240 -1
#define OZClassPart0001000002000495_0_in_0001000002000240 -1
#define OZClassPart0001000002000240_0_in_0001000002000240 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000241Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozLocked;
  int pad0;

  /* protected (data) */
  OID ozID;

  /* protected (zero) */
} OZ0001000002000241Part_Rec, *OZ0001000002000241Part;

#ifdef OZ_ObjectPart_LockSet_0_
#undef OZ_ObjectPart_LockSet_0_
#endif
#define OZ_ObjectPart_LockSet_0_ OZ0001000002000241Part

#endif _OZ0001000002000241P_H_
