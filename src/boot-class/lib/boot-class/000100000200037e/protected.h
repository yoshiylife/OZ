#define _OZ000100000200037eP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200037d 1
#define OZClassPart0001000002fffffe_0_in_000100000200037d 1
#define OZClassPart000100000200037d_0_in_000100000200037d 0

typedef struct OZ000100000200037ePart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  int ozAccessing;
  int ozNumberOfAccessor;

  /* protected (zero) */
} OZ000100000200037ePart_Rec, *OZ000100000200037ePart;

#ifdef OZ_ObjectPart_SharedAndExclusiveSemaphore
#undef OZ_ObjectPart_SharedAndExclusiveSemaphore
#endif
#define OZ_ObjectPart_SharedAndExclusiveSemaphore OZ000100000200037ePart

#endif _OZ000100000200037eP_H_
