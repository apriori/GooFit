#ifndef MIXING_TIME_RESOLUTION_HH
#define MIXING_TIME_RESOLUTION_HH
#include "GlobalCudaDefines.hh" 
#include "GooPdf.hh" 

typedef fptype (*device_resfunction_ptr) (fptype, fptype, fptype, fptype, fptype, fptype, fptype, fptype, fptype, fptype*, unsigned long*);

class MixingTimeResolution {
public: 
  MixingTimeResolution (); 
  virtual ~MixingTimeResolution ();

  void initIndex (void* dev_fcn_ptr = host_fcn_ptr);

  virtual fptype normalisation (fptype di1, fptype di2, fptype di3, fptype di4, fptype tau, fptype xmixing, fptype ymixing) const = 0;
  virtual void createParameters (std::vector<unsigned long>& pindices, PdfBase* dis) = 0;
  int getDeviceFunction () const {return resFunctionIdx;} 

private:
  int resFunctionIdx; 
};

#endif 
