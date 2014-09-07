#include "AddPdf.hh"

#include <thrust/functional.h>
#include <thrust/execution_policy.h>
#include <thrust/iterator/transform_iterator.h>

#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_BACKEND_OMP
EXEC_TARGET fptype device_AddPdfs (fptype* evt, fptype* p, unsigned long* indices) {
  long numParameters = indices[0];
  fptype ret = 0;
  fptype totalWeight = 0;
  for (long i = 1; i < numParameters-3; i += 3) {
    totalWeight += p[indices[i+2]];
    fptype curr = callFunction(evt, indices[i], indices[i+1]);
    fptype weight = p[indices[i+2]];
    ret += weight * curr * normalisationFactors[indices[i+1]];

    //if ((gpuDebug & 1) && (0 == THREADIDX) && (0 == BLOCKIDX))
    //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
    //printf("Add comp %i: %f * %f * %f = %f (%f)\n", i, weight, curr, normalisationFactors[indices[i+1]], weight*curr*normalisationFactors[indices[i+1]], ret);

  }
  // numParameters does not count itself. So the array structure for two functions is
  // nP | F P w | F P
  // in which nP = 5. Therefore the parameter index for the last function pointer is nP, and the function index is nP-1.
  //fptype last = (*(reinterpret_cast<device_function_ptr>(device_function_table[indices[numParameters-1]])))(evt, p, paramIndices + indices[numParameters]);
  fptype last = callFunction(evt, indices[numParameters - 1], indices[numParameters]);
  ret += (1 - totalWeight) * last * normalisationFactors[indices[numParameters]];

  //if ((THREADIDX < 50) && (isnan(ret))) printf("NaN final component %f %f\n", last, totalWeight);

  //if ((gpuDebug & 1) && (0 == THREADIDX) && (0 == BLOCKIDX))
  //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
  //printf("Add final: %f * %f * %f = %f (%f)\n", (1 - totalWeight), last, normalisationFactors[indices[numParameters]], (1 - totalWeight) *last* normalisationFactors[indices[numParameters]], ret);

  return ret;
}

EXEC_TARGET fptype device_AddPdfsExt (fptype* evt, fptype* p, unsigned long* indices) {
  // numParameters does not count itself. So the array structure for two functions is
  // nP | F P w | F P w
  // in which nP = 6.

  long numParameters = indices[0];
  fptype ret = 0;
  fptype totalWeight = 0;
  for (long i = 1; i < numParameters; i += 3) {
    //fptype curr = (*(reinterpret_cast<device_function_ptr>(device_function_table[indices[i]])))(evt, p, paramIndices + indices[i+1]);
    fptype curr = callFunction(evt, indices[i], indices[i+1]);
    fptype weight = p[indices[i+2]];
    ret += weight * curr * normalisationFactors[indices[i+1]];

    totalWeight += weight;
    //if ((gpuDebug & 1) && (THREADIDX == 0) && (0 == BLOCKIDX))
    //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
    //printf("AddExt: %i %E %f %f %f %f %f %f\n", i, curr, weight, ret, totalWeight, normalisationFactors[indices[i+1]], evt[0], evt[8]);
  }
  ret /= totalWeight;
  //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
  //if ((gpuDebug & 1) && (THREADIDX == 0) && (0 == BLOCKIDX))
  //printf("AddExt result: %f\n", ret);

  return ret;
}


#else
#include <thrust/system/cuda/detail/bulk.h>
using namespace thrust::system::cuda::detail;
EXEC_TARGET fptype device_AddPdfs (fptype* evt, fptype* p, unsigned long* indices) {
  /*
  int components = indices[0];
  fptype ret = 0;
  fptype totalWeight = 0;
  for (int i = 1; i < numParameters-3; i += 3) {
    totalWeight += p[indices[i+2]];
    //fptype curr = callFunction(evt, indices[i], indices[i+1]);
    fptype weight = p[indices[i+2]];
    ret += weight * curr * normalisationFactors[indices[i+1]];

    //if ((gpuDebug & 1) && (0 == THREADIDX) && (0 == BLOCKIDX))
    //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
    //printf("Add comp %i: %f * %f * %f = %f (%f)\n", i, weight, curr, normalisationFactors[indices[i+1]], weight*curr*normalisationFactors[indices[i+1]], ret);

  }
  // numParameters does not count itself. So the array structure for two functions is
  // nP | F P w | F P
  // in which nP = 5. Therefore the parameter index for the last function pointer is nP, and the function index is nP-1.
  //fptype last = (*(reinterpret_cast<device_function_ptr>(device_function_table[indices[numParameters-1]])))(evt, p, paramIndices + indices[numParameters]);
  //fptype last = callFunction(evt, indices[numParameters - 1], indices[numParameters]);
  ret += (1 - totalWeight) * last * normalisationFactors[indices[numParameters]];

  //if ((THREADIDX < 50) && (isnan(ret))) printf("NaN final component %f %f\n", last, totalWeight);

  //if ((gpuDebug & 1) && (0 == THREADIDX) && (0 == BLOCKIDX))
  //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
  //printf("Add final: %f * %f * %f = %f (%f)\n", (1 - totalWeight), last, normalisationFactors[indices[numParameters]], (1 - totalWeight) *last* normalisationFactors[indices[numParameters]], ret);
  */

  return 0;
  //return ret;
}

EXEC_TARGET fptype device_AddPdfsExt (fptype* evt, fptype* p, size_t* indices) {
  size_t components = indices[1];
  size_t valueStartAddress = indices[2];
  size_t eventStartAddress = indices[3];
  size_t numEvents = indices[4];
  size_t numObs = indices[indices[0]+1];
  size_t eventIndex = (size_t)(evt - (fptype*)eventStartAddress)/numObs;
  fptype* valueStart = reinterpret_cast<fptype*>(valueStartAddress);

  printf("addr valuestart is %lx\n", valueStart);
  //printf("numobs is %lu\n", numObs);
  printf("evt index is %lu\n", (size_t)eventIndex);
  //printf("components in gpu %lu\n", components);
  //printf("event addr in gpu %lx\n", eventStartAddress);
  //printf("value addr in gpu %lx\n", valueStartAddress);
  //printf("numEvents in gpu %lu\n", numEvents);

  fptype ret = 0;
  fptype totalWeight = 0;
  for (size_t i = 0; i < components; i ++) {
    size_t inComponentValueIndex = i * numEvents + eventIndex;
    //printf("in comp idx %lu\n", inComponentValueIndex);
    fptype curr = valueStart[inComponentValueIndex];
    //printf("curr is %f\n", curr);

    fptype weight = p[indices[i+4]];
    ret += weight * curr * normalisationFactors[indices[i+1]];

    totalWeight += weight;
    //if ((gpuDebug & 1) && (THREADIDX == 0) && (0 == BLOCKIDX))
    //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
    //printf("AddExt: %i %E %f %f %f %f %f %f\n", i, curr, weight, ret, totalWeight, normalisationFactors[indices[i+1]], evt[0], evt[8]);
  }
  ret /= totalWeight;
  //if ((1 > (int) floor(0.5 + evt[8])) && (gpuDebug & 1) && (paramIndices + debugParamIndex == indices))
  //if ((gpuDebug & 1) && (THREADIDX == 0) && (0 == BLOCKIDX))
  //printf("AddExt result: %f\n", ret);

  return ret;
}
#endif

MEM_DEVICE device_function_ptr ptr_to_AddPdfs = device_AddPdfs; 
MEM_DEVICE device_function_ptr ptr_to_AddPdfsExt = device_AddPdfsExt; 

AddPdf::AddPdf (std::string n, std::vector<Variable*> weights, std::vector<PdfBase*> comps) 
  : GooPdf(0, n)
  , componentValues(0)
  , eventArrayAddressParamIndex(-1)
  , componentValuesAddressParamIndex(-1)
  , numEventsParamIndex(-1)
  , weights(weights)
  , extended(true) {

  assert((weights.size() == comps.size()) || (weights.size() + 1 == comps.size())); 

  // Indices stores (components count)(component values start)(weight index_1, ... index_n) tuple
  // Last component has no weight index unless function is extended. 
  for (std::vector<PdfBase*>::iterator p = comps.begin(); p != comps.end(); ++p) {
    components.push_back(*p); 
    assert(components.back()); 
  }

  getObservables(observables); 

  std::vector<unsigned long> pindices;

  std::cout << "init components " << components.size() << std::endl;
#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_BACKEND_OMP
  for (size_t w = 0; w < weights.size(); ++w) {
    assert(components[w]);
    pindices.push_back(components[w]->getFunctionIndex());
    pindices.push_back(components[w]->getParameterIndex());
    pindices.push_back(registerParameter(weights[w]));
  }
  assert(components.back());
  if (weights.size() < components.size()) {
    pindices.push_back(components.back()->getFunctionIndex());
    pindices.push_back(components.back()->getParameterIndex());
    extended = false;
  }
#else
  pindices.push_back(components.size());
  // reserved for later initialisation by sumOfNLL
  // this index is supposed to be actually a device side address
  // to the device vector containing precalculated values of
  // the components
  componentValuesAddressParamIndex = pindices.size();
  pindices.push_back(0);
  // reserved for later initialisation by sumOfNLL
  // meant to contain the address of the start of dev_event_array
  eventArrayAddressParamIndex = pindices.size();
  pindices.push_back(0);
  // reserved for later initilation by sumOfNLL
  // meant to contain the number of events to be calculated
  numEventsParamIndex = pindices.size();
  pindices.push_back(0);

  for (unsigned int w = 0; w < weights.size(); ++w) {
    assert(components[w]);
    pindices.push_back(registerParameter(weights[w])); 
  }
  assert(components.back()); 
  if (weights.size() < components.size()) {
    extended = false; 
  }
#endif

  if (extended) GET_FUNCTION_ADDR(ptr_to_AddPdfsExt);
  else GET_FUNCTION_ADDR(ptr_to_AddPdfs);

  initialise(pindices); 
} 


AddPdf::AddPdf (std::string n, Variable* frac1, PdfBase* func1, PdfBase* func2) 
  : GooPdf(0, n)
  , componentValues(0)
  , eventArrayAddressParamIndex(-1)
  , componentValuesAddressParamIndex(-1)
  , numEventsParamIndex(-1)
  , extended(false)
{
  // Special-case constructor for common case of adding two functions.
  components.push_back(func1);
  components.push_back(func2);
  getObservables(observables); 

  std::vector<unsigned long> pindices;
  pindices.push_back(func1->getFunctionIndex());
  pindices.push_back(func1->getParameterIndex());
  pindices.push_back(registerParameter(frac1)); 

  pindices.push_back(func2->getFunctionIndex());
  pindices.push_back(func2->getParameterIndex());
    
  GET_FUNCTION_ADDR(ptr_to_AddPdfs);

  initialise(pindices);
}

__host__ fptype AddPdf::normalise () const {
  //if (cpuDebug & 1) std::cout << "Normalising AddPdf " << getName() << std::endl;
  fptype ret = 0;
  fptype totalWeight = 0;

#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_BACKEND_OMP
  for (unsigned int i = 0; i < components.size()-1; ++i) {
    fptype weight = host_params[host_indices[parameters + 3*(i+1)]];
    totalWeight += weight;
    fptype curr = components[i]->normalise();
    ret += curr*weight;
  }
  fptype last = components.back()->normalise();
  if (extended) {
    fptype lastWeight = host_params[host_indices[parameters + 3*components.size()]];
    totalWeight += lastWeight;
    ret += last * lastWeight;
    ret /= totalWeight;
  }
  else {
    ret += (1 - totalWeight) * last;
  }
#else
  for (ptrdiff_t i = 0; i < components.size()-1; ++i) {
    fptype weight = host_params[host_indices[parameters + numEventsParamIndex + 1 + i]];
    totalWeight += weight;
    fptype curr = components[i]->normalise();
    ret += curr*weight;
  }
  fptype last = components.back()->normalise();
  if (extended) {
    fptype lastWeight = host_params[host_indices[parameters + numEventsParamIndex + 1 + components.size()]];
    totalWeight += lastWeight;
    ret += last * lastWeight;
    ret /= totalWeight;
  }
  else {
    ret += (1 - totalWeight) * last;
  }
#endif
  host_normalisation[parameters] = 1.0;
  if (getSpecialMask() & PdfBase::ForceCommonNorm) {
    // Want to normalise this as
    // (f1 A + (1-f1) B) / int (f1 A + (1-f1) B)
    // instead of default
    // (f1 A / int A) + ((1-f1) B / int B).

    for (unsigned int i = 0; i < components.size(); ++i) {
      host_normalisation[components[i]->getParameterIndex()] = (1.0 / ret);
    }
  }

  //if (cpuDebug & 1) std::cout << getName() << " integral returning " << ret << std::endl; 
  return ret; 
}

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
struct AddPdfEval {
  AddPdfEval(size_t xBound)
   : xBound(xBound) {

  }

  EXEC_TARGET
  void operator()(bulk_::agent<> &self,
                  thrust::device_ptr<fptype> y,
                  thrust::device_ptr<thrust::tuple<int, int> > fIdx,
                  thrust::constant_iterator<fptype*> events
                  ) {
    size_t component = self.index() / xBound;
    size_t offset = self.index() % xBound;
    thrust::tuple<int, int> functionTuple = fIdx.get()[component];
    int function = thrust::get<0>(functionTuple);
    int params = thrust::get<1>(functionTuple);
    fptype* eventAddress = *events + offset;
    y[self.index()] = callFunction(eventAddress, function, params);
    //y[self.index()] = 0;
  }

  size_t xBound;
};
#endif

__host__ double AddPdf::sumOfNll (int numVars) const {
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  preEvaluateComponents();
#endif

  static thrust::plus<double> cudaPlus;
  thrust::constant_iterator<int> eventSize(numVars);
  thrust::constant_iterator<fptype*> arrayAddress(dev_event_array);
  double dummy = 0;
  thrust::counting_iterator<int> eventIndex(0);
  double ret = thrust::transform_reduce(thrust::make_zip_iterator(thrust::make_tuple(eventIndex, arrayAddress, eventSize)),
                    thrust::make_zip_iterator(thrust::make_tuple(eventIndex + numEntries, arrayAddress, eventSize)),
                    *logger, dummy, cudaPlus);

  if (extended) {
    fptype expEvents = 0;
    //std::cout << "Weights:";
    for (unsigned int i = 0; i < components.size(); ++i) {
      expEvents += host_params[host_indices[parameters + 3*(i+1)]];
      //std::cout << " " << host_params[host_indices[parameters + 3*(i+1)]];
    }
    // Log-likelihood of numEvents with expectation of exp is (-exp + numEvents*ln(exp) - ln(numEvents!)).
    // The last is constant, so we drop it; and then multiply by minus one to get the negative log-likelihood.
    ret += (expEvents - numEvents*log(expEvents));
    //std::cout << " " << expEvents << " " << numEvents << " " << (expEvents - numEvents*log(expEvents)) << std::endl;
  }

  std::cout << "returning " << ret << std::endl;
  return ret;
}

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
void AddPdf::preEvaluateComponents() const {
  if (numEntries == 0) {
    return;
  }

  std::cout << "vector size is " << components.size() * numEntries << std::endl;

  if (componentValues) {
    delete componentValues;
  }

  thrust::constant_iterator<fptype*> arrayAddress(dev_event_array);
  componentValues = new thrust::device_vector<fptype>(components.size() * numEntries);
  thrust::device_vector<thrust::tuple<int, int> > functionAndParamIndices(components.size());
  thrust::host_vector<thrust::tuple<int, int> > functionAndParamIndices_host(components.size());

  for (unsigned int i = 0; i < components.size(); ++i) {
    PdfBase* pdf = components[i];
    functionAndParamIndices_host[i] = thrust::make_tuple(pdf->getFunctionIndex(),
                                                         pdf->getParameterIndex());
  }
  functionAndParamIndices = functionAndParamIndices_host;

  AddPdfEval eval(numEntries);
  bulk_::async(bulk_::par(components.size() * numEntries),
              eval,
              bulk_::root.this_exec,
              componentValues->data(),
              functionAndParamIndices.data(),
              arrayAddress).wait();

  thrust::host_vector<fptype> hval = *componentValues;

  for (int i = 0; i < 100; ++i) {
    std::cout << "val " << i << " : " << hval[i] << std::endl;
  }

  size_t* indices = host_indices + parameters + 1;
  indices[numEventsParamIndex] = numEntries;
  indices[eventArrayAddressParamIndex] = (size_t)&dev_event_array[0];
  indices[componentValuesAddressParamIndex] = (size_t)thrust::raw_pointer_cast(componentValues->data());

  std::cout << "compidx " << 0 << std::endl;
  std::cout << "evidx " << eventArrayAddressParamIndex << std::endl;
  std::cout << "validx " << componentValuesAddressParamIndex << std::endl;
  std::cout << "numidx " << numEventsParamIndex << std::endl;

  std::cout << std::hex << "host components " << indices[0] << std::endl;
  std::cout << std::hex << "host event addr " << (size_t)&dev_event_array[0] << std::endl;
  std::cout << std::hex << "host value addr " << (size_t)thrust::raw_pointer_cast(componentValues->data()) << std::endl;
  std::cout << std::dec << "host num events " << indices[numEventsParamIndex] << std::endl;

  MEMCPY_TO_SYMBOL(paramIndices, host_indices, totalParams*sizeof(unsigned long), 0, cudaMemcpyHostToDevice);
}
#endif

