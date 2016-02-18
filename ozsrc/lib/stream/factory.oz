/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TextFactory{
 constructor: New;
 public: GetIText, GetOText, GetIOText;

   void New(){}

   IText   GetIText(){ ITextSun it => New(); return it; }
   OText   GetOText(){ OTextSun ot => New(); return ot; }
   IOText  GetIOText(){ IOTextSun iot => New(); return iot; }
}
