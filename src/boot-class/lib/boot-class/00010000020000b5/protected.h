#define _OZ00010000020000b5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020000b4 1
#define OZClassPart0001000002fffffe_0_in_00010000020000b4 1
#define OZClassPart00010000020000b4_0_in_00010000020000b4 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020000b5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020000b5Part_Rec, *OZ00010000020000b5Part;

#ifdef OZ_ObjectPart_Collection_0_
#undef OZ_ObjectPart_Collection_0_
#endif
#define OZ_ObjectPart_Collection_0_ OZ00010000020000b5Part

#endif _OZ00010000020000b5P_H_
