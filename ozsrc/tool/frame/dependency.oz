/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class Dependency {
 protected:
  MyModel;
 public:
  GetModel, SetModel;

  /* instance varibales */
  Model     MyModel;

  /* methods */
  Model GetModel() : abstract;
  void SetModel( Model m ){ MyModel = m; }
}
