#include "MapReducePdf.hh"

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
#include <thrust/system/cuda/detail/bulk.h>
using namespace thrust::system::cuda::detail;
struct ComponentsParallelEval {
  ComponentsParallelEval(size_t numEvents,
                         size_t numObs)
   : numEvents(numEvents)
   , numObs(numObs) {

  }

  EXEC_TARGET
  void operator()(bulk_::agent<> &self,
                  thrust::device_ptr<fptype> y,
                  size_t component,
                  size_t function,
                  size_t params,
                  thrust::constant_iterator<fptype*> events
                  ) {
    size_t offsetResult = self.index() + component * numEvents;
    fptype* eventAddress = *events + self.index() * numObs;
    y[offsetResult] = callFunction(eventAddress, function, params);
  }
  size_t numEvents;
  size_t numObs;
};
#endif

MapReducePdf::MapReducePdf(std::string n,
                           std::vector<PdfBase*> comps,
                           std::vector<size_t> extraIndices,
                           std::vector<fptype> extraDoubles,
                           std::vector<Variable*> extraParams)
 : GooPdf(0, n) {
  assert(comps.size() != 0);

  indices.push_back(comps.size());
  indices.push_back(extraIndices.size());
  indices.push_back(extraDoubles.size());
  indices.push_back(extraParams.size());
  // reserved for later initialisation by preEvaulateComponents
  // this index is supposed to be actually a device side address
  // to the device vector containing precalculated values of
  // the components
  componentValuesAddressParamIndex = indices.size();
  indices.push_back(0);
  // reserved for later initialisation by preEvaulateComponents
  // meant to contain the address of the start of dev_event_array
  eventArrayAddressParamIndex = indices.size();
  indices.push_back(0);
  // reserved for later initilation by preEvaulateComponents
  // meant to contain the number of events to be calculated.
  // this is needed for in-kernel pointer arithmetic
  numEventsParamIndex = indices.size();
  indices.push_back(0);

  for (size_t i = 0; i < comps.size(); ++i) {
    cudaStream_t stream;
    cudaStreamCreate(&stream);

    streams.push_back(stream);
    components.push_back(comps[i]);
    indices.push_back(comps[i]->getFunctionIndex());
    indices.push_back(comps[i]->getParameterIndex());
  }

  for (size_t i = 0; i < extraIndices.size(); ++i) {
    indices.push_back(extraIndices[i]);
  }

  for (size_t i = 0; i < extraDoubles.size(); ++i) {
    indices.push_back(extraDoubles[i]);
  }

  for (size_t i = 0; i < extraParams.size(); ++i) {
    indices.push_back(registerParameter(extraParams[i]));
  }
}

MapReducePdf::~MapReducePdf() {
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  for (size_t i = 0; i < components.size(); ++i) {
    cudaStreamDestroy(streams[i]);
  }
#endif
}

void MapReducePdf::delayedInitialize() {
  initialise(indices);
}

void MapReducePdf::onDataChanged(size_t numEvents) {
  this->numEvents = numEvents;
  std::cout << "ondata changed " << getName()  << std::endl;
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  componentValues = thrust::device_vector<fptype>(components.size() * numEvents);
  size_t* indices = host_indices + parameters + 1;
  indices[numEventsParamIndex] = numEvents;
  indices[eventArrayAddressParamIndex] = (size_t)dev_event_array;
  indices[componentValuesAddressParamIndex] = (size_t)thrust::raw_pointer_cast(componentValues.data());
  MEMCPY_TO_SYMBOL(paramIndices, host_indices, totalParams*sizeof(unsigned long), 0, cudaMemcpyHostToDevice);
#endif
}

void MapReducePdf::preEvaluateComponents(std::vector<bulk_::future<void> >& futures) const {
  //std::cout << "pre eval " << getName() << std::endl;
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  if (numEvents == 0) {
    return;
  }

  thrust::constant_iterator<fptype*> arrayAddress(dev_event_array);

  ComponentsParallelEval eval(numEvents, observables.size());
  for (size_t i = 0; i < components.size(); ++i) {
    PdfBase* pdf = components[i];

    futures.push_back(
      bulk_::async(bulk_::par(streams[i], numEvents),
                   eval,
                   bulk_::root.this_exec,
                   componentValues.data(),
                   i,
                   pdf->getFunctionIndex(),
                   pdf->getParameterIndex(),
                   arrayAddress));
  }
#endif
}
