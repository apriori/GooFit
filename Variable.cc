#include "Variable.hh"
#include <cmath> 

#include "RooRealVar.h"
#include "RooCategory.h"

Indexable::Indexable(const Indexable &other)
{
  name = other.name;
  value = other.value;
  index = other.index;
}

Variable::Variable (const RooRealVar& var)
  : Indexable(var.GetName())
  , error(var.getError())
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(var.getVal())
  , lowerlimit(var.getVal())
  , numbins(100)
  , fixed(var.isConstant())
  , blind(false)
{
  value = var.getVal();

  if (!fixed) {
      lowerlimit = var.getMin();
      upperlimit = var.getMax();
  }
}

Variable::Variable (const Variable& other) : Indexable(other) {
  error = other.error;
  error_pos = other.error_pos;
  error_neg = other.error_neg;
  gcc = other.gcc;
  upperlimit = other.upperlimit;
  lowerlimit = other.lowerlimit;
  numbins = other.numbins;
  fixed = other.fixed;
  blind = other.blind;
}

Variable::Variable (std::string n) 
  : Indexable(n) 
  , error(0.0)
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(0.0)
  , lowerlimit(0.0)
  , numbins(100)
  , fixed(false)
  , blind(0)
{
} 

Variable::Variable (std::string n, fptype v) 
  : Indexable(n, v)
  , error(0.002) 
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(v + 0.01)
  , lowerlimit(v - 0.01)
  , numbins(100)
  , fixed(true)
  , blind(0)
{
}

Variable::Variable (std::string n, fptype dn, fptype up) 
  : Indexable(n)
  , error(0.0)
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(up)
  , lowerlimit(dn)
  , numbins(100)
  , fixed(false)
  , blind(0)
{
}

Variable::Variable (std::string n, fptype v, fptype dn, fptype up) 
  : Indexable(n, v)
  , error(0.1*(up-dn))
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(up)
  , lowerlimit(dn)
  , numbins(100)
  , fixed(false)
  , blind(0)
{
}

Variable::Variable (std::string n, fptype v, fptype e, fptype dn, fptype up) 
  : Indexable(n, v)
  , error(e)
  , error_pos(0.0)
  , error_neg(0.0)
  , gcc(0.0)
  , upperlimit(up)
  , lowerlimit(dn)
  , numbins(100)
  , fixed(false)
  , blind(0)
{
}

Variable::~Variable () {
}

Variable Variable::fromRooRealVar(const RooRealVar& var) {
  if (var.getMin() == var.getMax()) {
      return Variable(var.GetName(), var.getVal());
  }
  return Variable(var.GetName(), var.getVal(), var.getMin(), var.getMax());
}
