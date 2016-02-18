#define _OZ00010000020004dcP_H_


#define OZClassPart0001000002fffffd_0_in_00010000020004db 1
#define OZClassPart0001000002fffffe_0_in_00010000020004db 1
#define OZClassPart00010000020004db_0_in_00010000020004db 0

typedef struct OZ00010000020004dcPart_Rec {
  OZ_AllocateInfoRec alloc_info;

  /* protected (pointer) */
  OZ_Object ozaCollection;
  int pad0;

  /* protected (data) */
  int ozIndex;
  unsigned int ozNum;

  /* protected (zero) */
} OZ00010000020004dcPart_Rec, *OZ00010000020004dcPart;

#ifdef OZ_ObjectPart_Iterator_ProjectLinkSS_
#undef OZ_ObjectPart_Iterator_ProjectLinkSS_
#endif
#define OZ_ObjectPart_Iterator_ProjectLinkSS_ OZ00010000020004dcPart

#endif _OZ00010000020004dcP_H_
