#ifndef MAPREDUCEPDF_HH
#define MAPREDUCEPDF_HH

#include "GooPdf.hh"

// This Pdf is in fact only a container around components
// which can be completely independantly evaluated.
// It will just evaluate the provided components in parallel
// for all events, so a reduction can take the intermediate
// results and combine them in an arbitrary way

class MapReducePdf : public GooPdf {
public:
  MapReducePdf(std::string n,
               std::vector<PdfBase*> comps,
               std::vector<size_t> extraIndices = std::vector<size_t>(),
               std::vector<fptype> extraDoubles = std::vector<fptype>(),
               std::vector<Variable*> extraParams = std::vector<Variable*>());
  virtual ~MapReducePdf();
  __host__ virtual fptype normalise () const = 0;
  __host__ virtual bool hasAnalyticIntegral () const { return false; }

private:
  std::vector<size_t> indices;

protected:
  __host__ void delayedInitialize();
  __host__ virtual void onDataChanged(size_t numEvents);
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
   __host__ virtual void preEvaluateComponents(std::vector<bulk_::future<void> >& futures) const;
#endif

  void initParallelEvalRequirements();
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  mutable thrust::device_vector<fptype> componentValues;
  std::vector<cudaStream_t> streams;
#endif
  int eventArrayAddressParamIndex;
  int componentValuesAddressParamIndex;
  int numEventsParamIndex;
};

#endif // MAPREDUCEPDF_HH
