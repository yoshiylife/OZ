#define _OZ0001000002000079P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000078 1
#define OZClassPart0001000002fffffe_0_in_0001000002000078 1
#define OZClassPart0001000002000336_0_in_0001000002000078 -2
#define OZClassPart0001000002000337_0_in_0001000002000078 -2
#define OZClassPart0001000002000064_0_in_0001000002000078 -1
#define OZClassPart0001000002000065_0_in_0001000002000078 -1
#define OZClassPart0001000002000078_0_in_0001000002000078 0

typedef struct OZ0001000002000079Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaNotifierWindow;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000079Part_Rec, *OZ0001000002000079Part;

#ifdef OZ_ObjectPart_ClassWithNotifier
#undef OZ_ObjectPart_ClassWithNotifier
#endif
#define OZ_ObjectPart_ClassWithNotifier OZ0001000002000079Part

#endif _OZ0001000002000079P_H_
