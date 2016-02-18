#define _OZ0001000002000559P_H_


#define OZClassPart0001000002fffffd_0_in_0001000002000558 1
#define OZClassPart0001000002fffffe_0_in_0001000002000558 1
#define OZClassPart0001000002000558_0_in_0001000002000558 0

typedef struct OZ0001000002000559Part_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ0001000002000559Part_Rec, *OZ0001000002000559Part;

#ifdef OZ_ObjectPart_Iterator_OIDAsKey_global_ClassID__
#undef OZ_ObjectPart_Iterator_OIDAsKey_global_ClassID__
#endif
#define OZ_ObjectPart_Iterator_OIDAsKey_global_ClassID__ OZ0001000002000559Part

#endif _OZ0001000002000559P_H_
