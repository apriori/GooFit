#include "MapReduceAddPdf.hh"

EXEC_TARGET fptype device_MapReduceAddPdfs (fptype* evt, fptype* p, unsigned long* indices) {
  size_t valueStartAddress = indices[1];
  size_t eventStartAddress = indices[2];
  size_t numEvents = indices[3];
  size_t numObs = indices[indices[0]+1];
  size_t eventIndex = (size_t)(evt - (fptype*)eventStartAddress)/numObs;
  size_t pIndexStart = 4;
  fptype* valueStart = reinterpret_cast<fptype*>(valueStartAddress);
  fptype ret = 0;
  fptype totalWeight = 0.0;
  size_t inComponentValueIndex = eventIndex;
  fptype curr = valueStart[inComponentValueIndex];
  fptype weight = p[indices[pIndexStart + 1]];

  ret += weight * curr * normalisationFactors[indices[pIndexStart]];
  inComponentValueIndex += numEvents;
  curr = valueStart[inComponentValueIndex];
  ret += (1 - totalWeight) * curr * normalisationFactors[indices[pIndexStart + 2]];
  return ret;
}

EXEC_TARGET fptype device_MapReduceAddPdfsExt (fptype* evt, fptype* p, size_t* indices) {
  size_t components = indices[1];
  size_t valueStartAddress = indices[5];
  size_t eventStartAddress = indices[6];
  size_t numEvents = indices[7];
  size_t numObs = indices[indices[0]+1];
  size_t eventIndex = (size_t)(evt - (fptype*)eventStartAddress)/numObs;
  size_t pIndexStart = 8;
  size_t weightStart = pIndexStart + components * 2;
  fptype* valueStart = reinterpret_cast<fptype*>(valueStartAddress);

  fptype ret = 0;
  fptype totalWeight = 0;
  for (size_t i = 0; i < components; i++) {
    size_t inComponentValueIndex = i * numEvents + eventIndex;
    fptype curr = valueStart[inComponentValueIndex];
    fptype weight = p[indices[weightStart + i]];

    //printf("curr %f weight %f norm %f\n", curr, weight, normalisationFactors[indices[pIndexStart + 2 * i + 1]]);

    ret += weight * curr * normalisationFactors[indices[pIndexStart + 2 * i + 1]];
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

MEM_DEVICE device_function_ptr ptr_to_MapReduceAddPdfs = device_MapReduceAddPdfs;
MEM_DEVICE device_function_ptr ptr_to_MapReduceAddPdfsExt = device_MapReduceAddPdfsExt;

MapReduceAddPdf::MapReduceAddPdf (std::string n, std::vector<Variable*> weights, std::vector<PdfBase*> comps)
  : MapReducePdf(n,
                 comps,
                 std::vector<size_t>(),
                 std::vector<fptype>(),
                 weights) {

  assert((weights.size() == comps.size()) || (weights.size() + 1 == comps.size()));
  getObservables(observables);
  GET_FUNCTION_ADDR(ptr_to_MapReduceAddPdfsExt);
  delayedInitialize();
}

__host__ fptype MapReduceAddPdf::normalise() const {
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
  size_t weightStartIndex = parameters + numEventsParamIndex + 1 + 2 * components.size();
  for (ptrdiff_t i = 0; i < components.size()-1; ++i) {
    fptype weight = host_params[host_indices[weightStartIndex + i]];
    totalWeight += weight;
    fptype curr = components[i]->normalise();
    ret += curr*weight;
  }
  fptype last = components.back()->normalise();
  if (true) {
    fptype lastWeight = host_params[host_indices[weightStartIndex + components.size() -1]];
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

  if (cpuDebug & 1) std::cout << getName() << " integral returning " << ret << std::endl;
  return ret;
}

__host__ double MapReduceAddPdf::sumOfNll(int numVars) const {
  recursivePreEvaluateComponents();

  static thrust::plus<double> cudaPlus;
  thrust::constant_iterator<int> eventSize(numVars);
  thrust::constant_iterator<fptype*> arrayAddress(dev_event_array);
  double dummy = 0;
  thrust::counting_iterator<int> eventIndex(0);
  double ret = thrust::transform_reduce(thrust::make_zip_iterator(thrust::make_tuple(eventIndex, arrayAddress, eventSize)),
                    thrust::make_zip_iterator(thrust::make_tuple(eventIndex + numEntries, arrayAddress, eventSize)),
                    *logger, dummy, cudaPlus);

  if (true) {
    fptype expEvents = 0;
    for (size_t i = 0; i < components.size(); ++i) {
#if THRUST_DEVICE_SYSTEM==THRUST_DEVICE_BACKEND_OMP
      expEvents += host_params[host_indices[parameters + 3*(i+1)]];
#else
      size_t weightStartIndex = parameters + numEventsParamIndex + 1 + 2 * components.size();
      expEvents += host_params[host_indices[weightStartIndex + i]];
#endif
    }
    // Log-likelihood of numEvents with expectation of exp is (-exp + numEvents*ln(exp) - ln(numEvents!)).
    // The last is constant, so we drop it; and then multiply by minus one to get the negative log-likelihood.
    ret += (expEvents - numEvents*log(expEvents));
    //std::cout << " " << expEvents << " " << numEvents << " " << (expEvents - numEvents*log(expEvents)) << std::endl;
  }

  //std::cout << "returning " << ret << std::endl;
  exit(1);
  return ret;
}
