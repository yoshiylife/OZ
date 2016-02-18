#define _PROTECTED_ALL_00010000020003a8_H

#ifndef _PROTECTED_ALL_0001000002000516_H
#define _PROTECTED_ALL_0001000002000516_H

#ifndef _OZ0001000002000516P_H_
#define _OZ0001000002000516P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000515 1
#define OZClassPart0001000002fffffe_0_in_0001000002000515 1
#define OZClassPart0001000002000515_0_in_0001000002000515 0

typedef struct OZ0001000002000516Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Array ozTable;
  int pad0;

  /* protected (data) */
  unsigned int ozExpansionFactor;
  unsigned int ozInitialTableSize;
  int ozShrinkFactor;
  int ozShrinkThreshold;
  unsigned int ozNumberOfElement;

  /* protected (zero) */
} OZ0001000002000516Part_Rec, *OZ0001000002000516Part;

#ifdef OZ_ObjectPart_SimpleArray_char_A_
#undef OZ_ObjectPart_SimpleArray_char_A_
#endif
#define OZ_ObjectPart_SimpleArray_char_A_ OZ0001000002000516Part

#endif _OZ0001000002000516P_H_


#endif _PROTECTED_ALL_0001000002000516_H
#ifndef _OZ00010000020003a8P_H_
#define _OZ00010000020003a8P_H_


#define OZClassPart0001000002fffffd_0_in_00010000020003a7 1
#define OZClassPart0001000002fffffe_0_in_00010000020003a7 1
#define OZClassPart0001000002000515_0_in_00010000020003a7 -1
#define OZClassPart0001000002000516_0_in_00010000020003a7 -1
#define OZClassPart00010000020003a7_0_in_00010000020003a7 0

typedef struct OZ00010000020003a8Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */

  /* protected (data) */

  /* protected (zero) */
} OZ00010000020003a8Part_Rec, *OZ00010000020003a8Part;

#ifdef OZ_ObjectPart_StringArray
#undef OZ_ObjectPart_StringArray
#endif
#define OZ_ObjectPart_StringArray OZ00010000020003a8Part

#endif _OZ00010000020003a8P_H_


#endif _PROTECTED_ALL_00010000020003a8_H
