#ifndef GOODECAY_PDF_HH
#define GOODECAY_PDF_HH

#include "GooPdf.hh" 

class GooDecayPdf : public GooPdf {
public:
  GooDecayPdf (std::string n, Variable* _t, Variable* tau); 
  virtual ~GooDecayPdf() {}
  __host__ fptype integrate (fptype lo, fptype hi) const; 
  __host__ virtual bool hasAnalyticIntegral () const { return true; } 


private:

};

#endif
