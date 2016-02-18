#define _OZ0001000002000143P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000142 1
#define OZClassPart0001000002fffffe_0_in_0001000002000142 1
#define OZClassPart000100000200013d_0_in_0001000002000142 -1
#define OZClassPart000100000200013e_0_in_0001000002000142 -1
#define OZClassPart0001000002000142_0_in_0001000002000142 0

typedef struct OZ0001000002000143Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozAID;
  OZ_Object ozClassDirectoryPath;

  /* protected (data) */
  int ozStandAlone;

  /* protected (zero) */
} OZ0001000002000143Part_Rec, *OZ0001000002000143Part;

#ifdef OZ_ObjectPart_DaemonForClass
#undef OZ_ObjectPart_DaemonForClass
#endif
#define OZ_ObjectPart_DaemonForClass OZ0001000002000143Part

#endif _OZ0001000002000143P_H_
