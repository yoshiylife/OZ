#define _OZ000100000200030fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200030e 1
#define OZClassPart0001000002fffffe_0_in_000100000200030e 1
#define OZClassPart000100000200030e_0_in_000100000200030e 0

typedef struct OZ000100000200030fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozPreloadingCodes;
  OZ_Object ozPreloadingConfiguredClasses;
  OZ_Object ozPreloadingLayouts;
  OZ_Object ozPreloadingObjects;
  OZ_Object ozanExecutor;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ000100000200030fPart_Rec, *OZ000100000200030fPart;

#ifdef OZ_ObjectPart_Preloader
#undef OZ_ObjectPart_Preloader
#endif
#define OZ_ObjectPart_Preloader OZ000100000200030fPart

#endif _OZ000100000200030fP_H_
