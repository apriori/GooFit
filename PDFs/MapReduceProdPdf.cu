#include "MapReduceProdPdf.hh"

EXEC_TARGET fptype device_MapReduceProdPdf (fptype* evt, fptype* p, unsigned long* indices) {
  size_t components = indices[1];
  size_t valueStartAddress = indices[5];
  size_t eventStartAddress = indices[6];
  size_t numEvents = indices[7];
  size_t numObs = indices[indices[0]+1];
  size_t eventIndex = (size_t)(evt - (fptype*)eventStartAddress)/numObs;
  fptype* valueStart = reinterpret_cast<fptype*>(valueStartAddress);
  size_t pIndexStart = 8;

  fptype ret = 1;
  for (size_t i = 0; i < components; i++) {
    size_t inComponentValueIndex = i * numEvents + eventIndex;
    fptype curr = valueStart[inComponentValueIndex];

    printf("curr %f norm %f\n", curr, normalisationFactors[indices[pIndexStart + 2 * i + 1]]);

    ret *= normalisationFactors[indices[pIndexStart + 2 * i + 1]];
    ret *= curr;
  }
  return ret;
}

MEM_DEVICE device_function_ptr ptr_to_MapReduceProdPdf = device_MapReduceProdPdf;

MapReduceProdPdf::MapReduceProdPdf(std::string n,
                                   std::vector<PdfBase*> comps)
  : MapReducePdf(n, comps) {

  getObservables(observables); // Gathers from components

  PdfBase::obsCont observableCheck; // Use to check for overlap in observables

  for (std::vector<PdfBase*>::iterator p = comps.begin(); p != comps.end(); ++p) {
    if (varOverlaps) continue; // Only need to establish this once.
    PdfBase::obsCont currObses;
    (*p)->getObservables(currObses);
    for (PdfBase::obsIter o = currObses.begin(); o != currObses.end(); ++o) {
      if (find(observableCheck.begin(), observableCheck.end(), (*o)) == observableCheck.end()) continue;
      varOverlaps = true;
      break;
    }
    (*p)->getObservables(observableCheck);
  }

  if (varOverlaps) { // Check for components forcing separate normalisation
    for (std::vector<PdfBase*>::iterator p = comps.begin(); p != comps.end(); ++p) {
      if ((*p)->getSpecialMask() & PdfBase::ForceSeparateNorm) varOverlaps = false;
    }
  }
  GET_FUNCTION_ADDR(ptr_to_MapReduceProdPdf);
  delayedInitialize();
}

fptype MapReduceProdPdf::normalise() const {
  if (varOverlaps) {
    // Two or more components share an observable and cannot be separately
    // normalised, since \int A*B dx does not equal int A dx * int B dx.
    recursiveSetNormalisation(fptype(1.0));
    MEMCPY_TO_SYMBOL(normalisationFactors, host_normalisation, totalParams*sizeof(fptype), 0, cudaMemcpyHostToDevice);

    // Normalise numerically.
    //std::cout << "Numerical normalisation of " << getName() << " due to varOverlaps.\n";
    fptype ret = GooPdf::normalise();
    //if (cpuDebug & 1)
    //std::cout << "ProdPdf " << getName() << " has normalisation " << ret << " " << host_callnumber << std::endl;
    return ret;
  }

  // Normalise components individually
  for (std::vector<PdfBase*>::const_iterator c = components.begin(); c != components.end(); ++c) {
    (*c)->normalise();
  }
  host_normalisation[parameters] = 1;
  MEMCPY_TO_SYMBOL(normalisationFactors, host_normalisation, totalParams*sizeof(fptype), 0, cudaMemcpyHostToDevice);

  return 1.0;
}
