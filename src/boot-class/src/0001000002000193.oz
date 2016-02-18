/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
 */
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

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
