#define _PROTECTED_ALL_00010000020003ad_H

#ifndef _OZ00010000020003adP_H_
#define _OZ00010000020003adP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003ac 1
#define OZClassPart0001000002fffffe_0_in_00010000020003ac 1
#define OZClassPart00010000020003ac_0_in_00010000020003ac 0

typedef struct OZ00010000020003adPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozName;
  int pad0;

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020003adPart_Rec, *OZ00010000020003adPart;

#ifdef OZ_ObjectPart_Station
#undef OZ_ObjectPart_Station
#endif
#define OZ_ObjectPart_Station OZ00010000020003adPart

#endif _OZ00010000020003adP_H_


#endif _PROTECTED_ALL_00010000020003ad_H
