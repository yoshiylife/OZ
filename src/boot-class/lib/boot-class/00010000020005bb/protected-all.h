#define _PROTECTED_ALL_00010000020005bb_H

#ifndef _OZ00010000020005bbP_H_
#define _OZ00010000020005bbP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005ba 1
#define OZClassPart0001000002fffffe_0_in_00010000020005ba 1
#define OZClassPart00010000020005ba_0_in_00010000020005ba 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ00010000020005bbPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005bbPart_Rec, *OZ00010000020005bbPart;

#ifdef OZ_ObjectPart_Collection_Assoc_OIDAsKey_0__0__
#undef OZ_ObjectPart_Collection_Assoc_OIDAsKey_0__0__
#endif
#define OZ_ObjectPart_Collection_Assoc_OIDAsKey_0__0__ OZ00010000020005bbPart

#endif _OZ00010000020005bbP_H_


#endif _PROTECTED_ALL_00010000020005bb_H
