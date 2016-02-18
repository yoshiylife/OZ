#define _PROTECTED_ALL_00010000020005d3_H

#ifndef _PROTECTED_ALL_00010000020005d8_H
#define _PROTECTED_ALL_00010000020005d8_H

#ifndef _PROTECTED_ALL_00010000020005e2_H
#define _PROTECTED_ALL_00010000020005e2_H

#ifndef _OZ00010000020005e2P_H_
#define _OZ00010000020005e2P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005e1 1
#define OZClassPart0001000002fffffe_0_in_00010000020005e1 1
#define OZClassPart00010000020005e1_0_in_00010000020005e1 0

typedef struct OZ00010000020005e2Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */
  unsigned int ozDefaultCapacity;
  unsigned int ozExpansionFactor;
  unsigned int ozExpansionIncrement;

  /* protected (zero) */
} OZ00010000020005e2Part_Rec, *OZ00010000020005e2Part;

#ifdef OZ_ObjectPart_Collection_Assoc_String_int__
#undef OZ_ObjectPart_Collection_Assoc_String_int__
#endif
#define OZ_ObjectPart_Collection_Assoc_String_int__ OZ00010000020005e2Part

#endif _OZ00010000020005e2P_H_


#endif _PROTECTED_ALL_00010000020005e2_H
#ifndef _OZ00010000020005d8P_H_
#define _OZ00010000020005d8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005d7 1
#define OZClassPart0001000002fffffe_0_in_00010000020005d7 1
#define OZClassPart00010000020005e1_0_in_00010000020005d7 -1
#define OZClassPart00010000020005e2_0_in_00010000020005d7 -1
#define OZClassPart00010000020005d7_0_in_00010000020005d7 0

typedef struct OZ00010000020005d8Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozContents;
  int pad0;

  /* protected (data) */
  unsigned int ozMask;

  /* protected (zero) */
} OZ00010000020005d8Part_Rec, *OZ00010000020005d8Part;

#ifdef OZ_ObjectPart_Set_Assoc_String_int__
#undef OZ_ObjectPart_Set_Assoc_String_int__
#endif
#define OZ_ObjectPart_Set_Assoc_String_int__ OZ00010000020005d8Part

#endif _OZ00010000020005d8P_H_


#endif _PROTECTED_ALL_00010000020005d8_H
#ifndef _OZ00010000020005d3P_H_
#define _OZ00010000020005d3P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020005d2 1
#define OZClassPart0001000002fffffe_0_in_00010000020005d2 1
#define OZClassPart00010000020005e1_0_in_00010000020005d2 -2
#define OZClassPart00010000020005e2_0_in_00010000020005d2 -2
#define OZClassPart00010000020005d7_0_in_00010000020005d2 -1
#define OZClassPart00010000020005d8_0_in_00010000020005d2 -1
#define OZClassPart00010000020005d2_0_in_00010000020005d2 0

typedef struct OZ00010000020005d3Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020005d3Part_Rec, *OZ00010000020005d3Part;

#ifdef OZ_ObjectPart_Dictionary_String_int_
#undef OZ_ObjectPart_Dictionary_String_int_
#endif
#define OZ_ObjectPart_Dictionary_String_int_ OZ00010000020005d3Part

#endif _OZ00010000020005d3P_H_


#endif _PROTECTED_ALL_00010000020005d3_H
