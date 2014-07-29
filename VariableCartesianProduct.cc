#include "VariableCartesianProduct.hh"
#include "Variable.hh"

VariableCartesianProduct::VariableCartesianProduct(VariableSet& variables)
  : variables(variables) {
}

VariableValuesSet VariableCartesianProduct::calculateCartersianProduct() {
  VariableSet::iterator it = variables.begin();

  size_t outputSize = 1;
  for (; it != variables.end(); ++it) {
    outputSize *= (*it)->valueMap.size();
  }
  VariableValuesSet productResult;

  if (outputSize == 0) {
    return productResult;
  }

  productResult.resize(outputSize);

  it = variables.begin();
  size_t currentOutputSize = outputSize;


  //for all variables
  for (size_t i = 0; i < variables.size(); ++i) {
    //dimension reduction for each Variable
    SetVariable* var = variables[i];
    assert(var->valueMap.size() != 0);
    currentOutputSize /= var->valueMap.size();

    for(size_t pidx = 0; pidx < productResult.size(); pidx++) {
      SetVariable::valueIter valueIter = var->begin();
      for (; valueIter != var->end(); ++valueIter) {
        for (size_t j = 0; j < currentOutputSize; ++j, pidx++) {
          VariableValues& currentSet = productResult[pidx];
          currentSet.push_back(valueIter->first);
        }
      }
      pidx--;
    }
  }
  return productResult;
}

