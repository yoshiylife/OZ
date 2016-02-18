#define _OZ00010000020005e2P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005e1 1
#define OZClassPart0001000002fffffe_0_in_00010000020005e1 1
#define OZClassPart00010000020005e1_0_in_00010000020005e1 0

typedef struct OZ00010000020005e2Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005e2Part_Rec, *OZ00010000020005e2Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_int__
#undef OZ_ObjectPart_Collection_Assoc_String_int__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_int__ OZ00010000020005e2Part

#endif _OZ00010000020005e2P_H_
