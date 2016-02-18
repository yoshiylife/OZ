#ifndef _PROTECTED_ALL_00010000020008c7_H
#define _PROTECTED_ALL_00010000020008c7_H

#ifndef _OZ00010000020008c7P_H_
#define _OZ00010000020008c7P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020008c6 1
#define OZClassPart0001000002fffffe_0_in_00010000020008c6 1
#define OZClassPart00010000020008c6_0_in_00010000020008c6 0

typedef struct OZ00010000020008c7Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020008c7Part_Rec, *OZ00010000020008c7Part;

#ifdef OZ_ObjectPart_Timer
#undef OZ_ObjectPart_Timer
#endif
#define OZ_ObjectPart_Timer OZ00010000020008c7Part

#endif _OZ00010000020008c7P_H_


#endif _PROTECTED_ALL_00010000020008c7_H
