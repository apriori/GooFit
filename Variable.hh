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

  /*
  template<typename iter>
  iter begin();

  template<typename iter>
  iter end();
  */

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
  SetVariable(const std::string& name);
  SetVariable (const SetVariable& other);
  SetVariable (const RooCategory& category);
  std::map<fptype, std::string> valueMap;
  typedef std::map<fptype, std::string>::iterator valueIter;

  valueIter begin() { return valueMap.begin(); }
  valueIter end() { return valueMap.end(); }
  void addEntry(const std::string& name, fptype value);
};


bool variableIndexCompare(const Variable* v1, const Variable* v2);

#endif
