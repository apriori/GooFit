#ifndef ADD_PDF_HH
#define ADD_PDF_HH

#include "GooPdf.hh" 

class AddPdf : public GooPdf {
public:

  AddPdf (std::string n, std::vector<Variable*> weights, std::vector<PdfBase*> comps); 
  AddPdf (std::string n, Variable* frac1, PdfBase* func1, PdfBase* func2); 
  virtual ~AddPdf();
  __host__ virtual fptype normalise () const;
  __host__ virtual bool hasAnalyticIntegral () const {return false;}
  __host__ std::vector<Variable*> getWeights() const { return weights; }

protected:
  __host__ virtual double sumOfNll (int numVars) const;
  __host__ virtual void preEvaluateComponents(bool force = false) const;

private:
  void initParallelEvalRequirements();

  mutable thrust::device_vector<fptype>* componentValues;
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  std::vector<cudaStream_t> streams;
#endif
  int eventArrayAddressParamIndex;
  int componentValuesAddressParamIndex;
  int numEventsParamIndex;

  std::vector<Variable*> weights;
  bool extended; 
};

#endif
