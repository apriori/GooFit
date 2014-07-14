#ifndef GOOBDECAY_PDF_HH
#define GOOBDECAY_PDF_HH

#include "GooPdf.hh"
//#include "ConvolutionPdf.hh"

class GooBDecayInternal : public GooPdf {
public:
    GooBDecayInternal (std::string n,
                       Variable* dt,
                       Variable* tag,
                       Variable* parS,
                       Variable* parC,
                       Variable* parOmega,
                       Variable* tau,
                       Variable* dgamma,
                       Variable* f0,
                       Variable* f1,
                       Variable* dm
                       );
    virtual fptype integrate (fptype lo, fptype hi) const;
    virtual ~GooBDecayInternal() {}
    __host__ virtual bool hasAnalyticIntegral () const { return true; }
};

/*
class GooBDecay : public ConvolutionPdf {
public:
    GooBDecay (std::string n,
               Variable* dt,
               Variable* tag,
               Variable* tau,
               Variable* dgamma,
               Variable* f0,
               Variable* f1,
               Variable* f2,
               Variable* f3,
               Variable* dm,
               GooPdf* resolution
               );
    virtual ~GooBDecay() {}

private:
};
*/

#endif
