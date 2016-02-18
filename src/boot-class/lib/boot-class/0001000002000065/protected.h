#define _OZ0001000002000065P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000064 1
#define OZClassPart0001000002fffffe_0_in_0001000002000064 1
#define OZClassPart0001000002000336_0_in_0001000002000064 -1
#define OZClassPart0001000002000337_0_in_0001000002000064 -1
#define OZClassPart0001000002000064_0_in_0001000002000064 0

typedef struct OZ0001000002000065Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozClassListFile;
  OZ_Array ozClassDirectoryPath;
  OZ_Object ozClassTable;
  OZ_Object ozLogger;
  OZ_Object ozDumpPath;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000065Part_Rec, *OZ0001000002000065Part;

#ifdef OZ_ObjectPart_Class
#undef OZ_ObjectPart_Class
#endif
#define OZ_ObjectPart_Class OZ0001000002000065Part

#endif _OZ0001000002000065P_H_
