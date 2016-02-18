#define _OZ0001000002000337P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000336 1
#define OZClassPart0001000002fffffe_0_in_0001000002000336 1
#define OZClassPart0001000002000336_0_in_0001000002000336 0

typedef struct OZ0001000002000337Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozNames;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000337Part_Rec, *OZ0001000002000337Part;

#ifdef OZ_ObjectPart_ResolvableObject
#undef OZ_ObjectPart_ResolvableObject
#endif
#define OZ_ObjectPart_ResolvableObject OZ0001000002000337Part

#endif _OZ0001000002000337P_H_
