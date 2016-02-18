#define _OZ0001000002000644P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000643 1
#define OZClassPart0001000002fffffe_0_in_0001000002000643 1
#define OZClassPart0001000002000643_0_in_0001000002000643 0

typedef struct OZ0001000002000644Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000644Part_Rec, *OZ0001000002000644Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_global_ResolvableObject__
#undef OZ_ObjectPart_Collection_Assoc_String_global_ResolvableObject__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_global_ResolvableObject__ OZ0001000002000644Part

#endif _OZ0001000002000644P_H_
