#define _PROTECTED_ALL_0001000002000565_H

#ifndef _PROTECTED_ALL_000100000200056f_H
#define _PROTECTED_ALL_000100000200056f_H

#ifndef _OZ000100000200056fP_H_
#define _OZ000100000200056fP_H_


#define OZClassPart0001000002fffffd_0_in_000100000200056e 1
#define OZClassPart0001000002fffffe_0_in_000100000200056e 1
#define OZClassPart000100000200056e_0_in_000100000200056e 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ000100000200056fPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ000100000200056fPart_Rec, *OZ000100000200056fPart;

#ifdef OZ_ObjectPart_Collection_Assoc_String_Directory_0___
#undef OZ_ObjectPart_Collection_Assoc_String_Directory_0___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_Directory_0___ OZ000100000200056fPart

#endif _OZ000100000200056fP_H_


#endif _PROTECTED_ALL_000100000200056f_H
#ifndef _OZ0001000002000565P_H_
#define _OZ0001000002000565P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000564 1
#define OZClassPart0001000002fffffe_0_in_0001000002000564 1
#define OZClassPart000100000200056e_0_in_0001000002000564 -1
#define OZClassPart000100000200056f_0_in_0001000002000564 -1
#define OZClassPart0001000002000564_0_in_0001000002000564 0
#define OZClassPart0000000000000000_0_in_0000000000000000 999

typedef struct OZ0001000002000565Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000565Part_Rec, *OZ0001000002000565Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_Directory_0___
#undef OZ_ObjectPart_Set_Assoc_String_Directory_0___
#endif
#define OZ_ObjectPart_Set_Assoc_String_Directory_0___ OZ0001000002000565Part

#endif _OZ0001000002000565P_H_


#endif _PROTECTED_ALL_0001000002000565_H
