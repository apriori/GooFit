#ifndef VARIABLE_HH
#define VARIABLE_HH

#include <string> 
#include <map> 
#include <iostream> 
#include <cassert> 
#include "GlobalCudaDefines.hh"
#include <set>


struct Indexable {
  Indexable (const Indexable& other);
  Indexable (std::string n, fptype val = 0) : name(n), value(val), index(-1) {}

  int getIndex () const {return index;}
  std::string name;  
  fptype value;
  int index; 
};

class RooRealVar;
struct Variable : Indexable { 
  // Contains information about a parameter allowed
  // to vary in MINUIT, or an observable passed to a
  // data set. The index can refer either to cudaArray
  // or to an event. 

  static Variable fromRooRealVar(const RooRealVar& var);

  Variable (const RooRealVar& var);
  Variable (const Variable& other);
  Variable (std::string n); 
  Variable (std::string n, fptype val); 
  Variable (std::string n, fptype dn, fptype up);
  Variable (std::string n, fptype v, fptype dn, fptype up);
  Variable (std::string n, fptype v, fptype e, fptype dn, fptype up);
  template<typename valueIter>
  valueIter begin();

  template<typename valueIter>
  valueIter end();

  virtual ~Variable ();

  fptype error, error_pos, error_neg, gcc;
  fptype upperlimit;
  fptype lowerlimit;
  int numbins; 
  bool fixed;
  bool isCategoryConstant;
  bool isDiscrete;
  fptype blind; 
}; 


struct Constant : Indexable { 
  // This is similar to Variable, but the index points
  // to functorConstants instead of cudaArray. 

  Constant (std::string n, fptype val) : Indexable(n, val) {}
  virtual ~Constant () {}
}; 

class RooCategory;
struct SetVariable : Variable {
  SetVariable (const SetVariable& other);
  SetVariable (const RooCategory& category);
  std::map<fptype, std::string> valueMap;

  template<typename valueIter>
  valueIter begin() { return valueMap.begin(); }
  template<typename valueIter>
  valueIter end() { return valueMap.end(); }
  void addEntry(const std::string& name, fptype value);
};

#endif
