#ifndef _PROTECTED_ALL_00010000020008cc_H
#define _PROTECTED_ALL_00010000020008cc_H

#ifndef _OZ00010000020008ccP_H_
#define _OZ00010000020008ccP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008cb 1
#define OZClassPart0001000002fffffe_0_in_00010000020008cb 1
#define OZClassPart00010000020008cb_0_in_00010000020008cb 0

typedef struct OZ00010000020008ccPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020008ccPart_Rec, *OZ00010000020008ccPart;

#ifdef OZ_ObjectPart_Alarmable
#undef OZ_ObjectPart_Alarmable
#endif
#define OZ_ObjectPart_Alarmable OZ00010000020008ccPart

#endif _OZ00010000020008ccP_H_


#endif _PROTECTED_ALL_00010000020008cc_H
