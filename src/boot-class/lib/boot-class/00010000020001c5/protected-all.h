#define _PROTECTED_ALL_00010000020001c5_H

#ifndef _PROTECTED_ALL_0001000002000201_H
#define _PROTECTED_ALL_0001000002000201_H

#ifndef _OZ0001000002000201P_H_
#define _OZ0001000002000201P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000200 1
#define OZClassPart0001000002fffffe_0_in_0001000002000200 1
#define OZClassPart0001000002000200_0_in_0001000002000200 0

typedef struct OZ0001000002000201Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ0001000002000201Part_Rec, *OZ0001000002000201Part;

#ifdef OZ_ObjectPart_IStream
#undef OZ_ObjectPart_IStream
#endif
#define OZ_ObjectPart_IStream OZ0001000002000201Part

#endif _OZ0001000002000201P_H_


#endif _PROTECTED_ALL_0001000002000201_H
#ifndef _PROTECTED_ALL_00010000020001ac_H
#define _PROTECTED_ALL_00010000020001ac_H

#ifndef _OZ00010000020001acP_H_
#define _OZ00010000020001acP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001ab 1
#define OZClassPart0001000002fffffe_0_in_00010000020001ab 1
#define OZClassPart00010000020001ab_0_in_00010000020001ab 0

typedef struct OZ00010000020001acPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozFname;
  int pad0;

  /* protected (data) */
  int ozFd;

  /* protected (zero) */
} OZ00010000020001acPart_Rec, *OZ00010000020001acPart;

#ifdef OZ_ObjectPart_FStream
#undef OZ_ObjectPart_FStream
#endif
#define OZ_ObjectPart_FStream OZ00010000020001acPart

#endif _OZ00010000020001acP_H_


#endif _PROTECTED_ALL_00010000020001ac_H
#ifndef _OZ00010000020001c5P_H_
#define _OZ00010000020001c5P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020001c4 1
#define OZClassPart0001000002fffffe_0_in_00010000020001c4 1
#define OZClassPart0001000002000200_0_in_00010000020001c4 -2
#define OZClassPart0001000002000201_0_in_00010000020001c4 -2
#define OZClassPart00010000020001ab_0_in_00010000020001c4 -1
#define OZClassPart00010000020001ac_0_in_00010000020001c4 -1
#define OZClassPart00010000020001c4_0_in_00010000020001c4 0

typedef struct OZ00010000020001c5Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020001c5Part_Rec, *OZ00010000020001c5Part;

#ifdef OZ_ObjectPart_IFStream
#undef OZ_ObjectPart_IFStream
#endif
#define OZ_ObjectPart_IFStream OZ00010000020001c5Part

#endif _OZ00010000020001c5P_H_


#endif _PROTECTED_ALL_00010000020001c5_H
