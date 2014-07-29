#ifndef VARIABLECARTESIANPRODUCT_HH
#define VARIABLECARTESIANPRODUCT_HH

#include "GlobalCudaDefines.hh"
#include <vector>

struct SetVariable;
struct Variable;
typedef std::vector<SetVariable*> VariableSet;
typedef std::vector<fptype> VariableValues;
typedef std::vector<VariableValues> VariableValuesSet;

class VariableCartesianProduct {
public:
  VariableCartesianProduct(VariableSet& variables);
  VariableValuesSet calculateCartersianProduct();

private:
  VariableSet& variables;
};

#endif // VARIABLECARTESIANPRODUCT_HH
