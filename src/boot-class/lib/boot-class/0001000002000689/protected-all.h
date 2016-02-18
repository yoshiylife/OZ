#define _PROTECTED_ALL_0001000002000689_H

#ifndef _PROTECTED_ALL_0001000002000693_H
#define _PROTECTED_ALL_0001000002000693_H

#ifndef _OZ0001000002000693P_H_
#define _OZ0001000002000693P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000692 1
#define OZClassPart0001000002fffffe_0_in_0001000002000692 1
#define OZClassPart0001000002000692_0_in_0001000002000692 0

typedef struct OZ0001000002000693Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ0001000002000693Part_Rec, *OZ0001000002000693Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_Directory_Package___
#undef OZ_ObjectPart_Collection_Assoc_String_Directory_Package___
#endif
#define OZ_ObjectPart_Collection_Assoc_String_Directory_Package___ OZ0001000002000693Part

#endif _OZ0001000002000693P_H_


#endif _PROTECTED_ALL_0001000002000693_H
#ifndef _OZ0001000002000689P_H_
#define _OZ0001000002000689P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000688 1
#define OZClassPart0001000002fffffe_0_in_0001000002000688 1
#define OZClassPart0001000002000692_0_in_0001000002000688 -1
#define OZClassPart0001000002000693_0_in_0001000002000688 -1
#define OZClassPart0001000002000688_0_in_0001000002000688 0

typedef struct OZ0001000002000689Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ0001000002000689Part_Rec, *OZ0001000002000689Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_Directory_Package___
#undef OZ_ObjectPart_Set_Assoc_String_Directory_Package___
#endif
#define OZ_ObjectPart_Set_Assoc_String_Directory_Package___ OZ0001000002000689Part

#endif _OZ0001000002000689P_H_


#endif _PROTECTED_ALL_0001000002000689_H
