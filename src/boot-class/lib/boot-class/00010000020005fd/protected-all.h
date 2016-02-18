#define _PROTECTED_ALL_00010000020005fd_H

#ifndef _OZ00010000020005fdP_H_
#define _OZ00010000020005fdP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005fc 1
#define OZClassPart0001000002fffffe_0_in_00010000020005fc 1
#define OZClassPart00010000020005fc_0_in_00010000020005fc 0

typedef struct OZ00010000020005fdPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005fdPart_Rec, *OZ00010000020005fdPart;

#ifdef OZ_ObjectPart_Collection_Assoc_String_Command__
#undef OZ_ObjectPart_Collection_Assoc_String_Command__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_Command__ OZ00010000020005fdPart

#endif _OZ00010000020005fdP_H_


#endif _PROTECTED_ALL_00010000020005fd_H
