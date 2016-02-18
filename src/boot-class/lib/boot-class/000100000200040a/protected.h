#define _OZ000100000200040aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000409 1
#define OZClassPart0001000002fffffe_0_in_0001000002000409 1
#define OZClassPart0001000002000409_0_in_0001000002000409 0

typedef struct OZ000100000200040aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozPublicPart;
  unsigned int ozProtectedPart;
  unsigned int ozImplementationPart;

  /* protected (zero) */
} OZ000100000200040aPart_Rec, *OZ000100000200040aPart;

#ifdef OZ_ObjectPart_VersionString
#undef OZ_ObjectPart_VersionString
#endif
#define OZ_ObjectPart_VersionString OZ000100000200040aPart

#endif _OZ000100000200040aP_H_
