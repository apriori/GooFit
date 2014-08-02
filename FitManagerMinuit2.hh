#ifndef FITMANAGER_MINUIT2_HH
#define FITMANAGER_MINUIT2_HH

#include "Minuit2/FCNBase.h"
#include "Minuit2/FunctionMinimum.h"
#include "Minuit2/MnUserParameterState.h"
#include "Minuit2/MnPrint.h"
#include "Minuit2/MnMinimize.h"
#include "Minuit2/MnMinos.h"
#include "Minuit2/MnContours.h"
#include "Minuit2/MnPlot.h"
#include "Minuit2/MinosError.h"
#include "Minuit2/ContoursError.h"
class FitManager : public ROOT::Minuit2::FCNBase {
public:
  FitManager (PdfBase* dat) {pdfPointer = dat; lastresult = 0; }
  virtual double Up() const {return 1.0;}
  double operator () (const std::vector<double>& pars) const; 
  ROOT::Minuit2::FunctionMinimum* fit (); 
  void getMinuitValues () const;

protected:
  PdfBase* pdfPointer; 
  ROOT::Minuit2::FunctionMinimum* lastresult;
  ROOT::Minuit2::MnUserParameters* params;
  ROOT::Minuit2::MnMinimize* migrad;
  std::vector<Variable*> vars; 
  int numPars; 
};

#endif
