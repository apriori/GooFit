#ifndef DALITZPLOT_PDF_HH
#define DALITZPLOT_PDF_HH

#include "GooPdf.hh" 
#include "DalitzPlotHelpers.hh" 
#include "devcomplex.hh"
#include <vector>

class SpecialResonanceIntegrator;
class SpecialResonanceCalculator; 
  
class DalitzPlotPdf : public GooPdf {
public:
  DalitzPlotPdf (std::string n, Variable* m12, Variable* m13, Variable* eventNumber, DecayInfo* decay, GooPdf* eff);
  virtual ~DalitzPlotPdf() {}
  // Note that 'efficiency' refers to anything which depends on (m12, m13) and multiplies the 
  // coherent sum. The caching method requires that it be done this way or the ProdPdf
  // normalisation will get *really* confused and give wrong answers. 

  __host__ virtual fptype normalise () const;
  __host__ void setDataSize (unsigned int dataSize, unsigned int evtSize = 3);
  __host__ std::vector<std::vector<fptype> > getFitFractions();
  __host__ void setForceIntegrals (bool f = true) {forceRedoIntegrals = f;}
  __host__ const DecayInfo* getDecayInfo() const { return decayInfo; };
  __host__ DecayInfo* getDecayInfo() { return decayInfo; };
  __host__ DEVICE_VECTOR<devcomplex<fptype> >* getCachedWaves() { return cachedWaves; }

protected:

private:
  DecayInfo* decayInfo; 
  Variable* _m12;
  Variable* _m13; 
  fptype* dalitzNormRange; 

  // Following variables are useful if masses and widths, involved in difficult BW calculation, 
  // change infrequently while amplitudes, only used in adding BW results together, change rapidly.
  DEVICE_VECTOR<devcomplex<fptype> >* cachedWaves; // Caches the BW values for each event.
  devcomplex<fptype>*** integrals; // Caches the integrals of the BW waves for each combination of resonances. 

  bool* redoIntegral;
  mutable bool forceRedoIntegrals; 
  fptype* cachedMasses; 
  fptype* cachedWidths;
  int totalEventSize; 
  int cacheToUse; 
  SpecialResonanceIntegrator*** integrators;
  SpecialResonanceCalculator** calculators; 
};

class SpecialResonanceIntegrator : public thrust::unary_function<thrust::tuple<int, fptype*>, devcomplex<fptype> > {
public:
  // Class used to calculate integrals of terms BW_i * BW_j^*. 
  SpecialResonanceIntegrator (int pIdx, unsigned int ri, unsigned int rj);
  EXEC_TARGET devcomplex<fptype> operator () (thrust::tuple<int, fptype*> t) const;
protected:
  EXEC_TARGET virtual devcomplex<fptype> devicefunction(fptype m12, fptype m13, int res_i, int res_j, fptype* p, unsigned long* indices) const;
  EXEC_TARGET virtual const char* whoami() const;
  unsigned int resonance_i;
  unsigned int resonance_j; 
  unsigned int parameters;
}; 

class SpecialResonanceCalculator : public thrust::unary_function<thrust::tuple<int, fptype*, int>, devcomplex<fptype> > {
public:
  // Used to create the cached BW values. 
  SpecialResonanceCalculator (int pIdx, unsigned int res_idx); 
  EXEC_TARGET devcomplex<fptype> operator () (thrust::tuple<int, fptype*, int> t) const;

private:

  unsigned int resonance_i;
  unsigned int parameters;
}; 

const int resonanceOffset_DP = 4; // Offset of the first resonance into the parameter index array
// Offset is number of parameters, constant index, number of resonances (not calculable
// from nP because we don't know what the efficiency might need), and cache index. Efficiency
// parameters are after the resonance information.
//
EXEC_TARGET inline int parIndexFromResIndex_DP (int resIndex)
{
  return resonanceOffset_DP + resIndex*resonanceSize;
}

#endif

