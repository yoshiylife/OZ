#define _OZ00010000020001caP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001c9 1
#define OZClassPart0001000002fffffe_0_in_00010000020001c9 1
#define OZClassPart00010000020001c9_0_in_00010000020001c9 0

typedef struct OZ00010000020001caPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozParent;
  OZ_Object ozBrother;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001caPart_Rec, *OZ00010000020001caPart;

#ifdef OZ_ObjectPart_InheritanceHierarchyNode
#undef OZ_ObjectPart_InheritanceHierarchyNode
#endif
#define OZ_ObjectPart_InheritanceHierarchyNode OZ00010000020001caPart

#endif _OZ00010000020001caP_H_
