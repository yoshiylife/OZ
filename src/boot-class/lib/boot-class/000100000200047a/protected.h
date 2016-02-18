#define _OZ000100000200047aP_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000479 1
#define OZClassPart0001000002fffffe_0_in_0001000002000479 1
#define OZClassPart0001000002000479_0_in_0001000002000479 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200047aPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200047aPart_Rec, *OZ000100000200047aPart;

#ifdef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_0___
#undef OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_0___
#endif
#define OZ_ObjectPart_Collection_OIDAsKey_global_DirectoryServer_0___ OZ000100000200047aPart

#endif _OZ000100000200047aP_H_
