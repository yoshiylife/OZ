#define _PROTECTED_ALL_00010000020001d4_H

#ifndef _OZ00010000020001d4P_H_
#define _OZ00010000020001d4P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001d3 1
#define OZClassPart0001000002fffffe_0_in_00010000020001d3 1
#define OZClassPart00010000020001d3_0_in_00010000020001d3 0

typedef struct OZ00010000020001d4Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001d4Part_Rec, *OZ00010000020001d4Part;

#ifdef OZ_ObjectPart_IntAsKey
#undef OZ_ObjectPart_IntAsKey
#endif
#define OZ_ObjectPart_IntAsKey OZ00010000020001d4Part

#endif _OZ00010000020001d4P_H_


#endif _PROTECTED_ALL_00010000020001d4_H
