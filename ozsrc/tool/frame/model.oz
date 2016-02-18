/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class Model{
 public:
  ButtonPressed, FieldEntered;

  void ButtonPressed( Series aSeries, Button aButton ){}
  void FieldEntered( Series aSeries, Field aField, String value ){}
}
