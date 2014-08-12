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
#include "Minuit2/Minuit2Minimizer.h"

class PdfFunctionProxy : public ROOT::Math::IBaseFunctionMultiDim {
public:
  PdfFunctionProxy(PdfBase &pdf);
  PdfFunctionProxy(PdfFunctionProxy &other);
  PdfFunctionProxy(const PdfFunctionProxy& other);
  virtual IBaseFunctionMultiDim* Clone() const;
  virtual ~PdfFunctionProxy() {}

  virtual unsigned int NDim() const { return dim; }

private:

  virtual double DoEval(const double* x) const;

private:

  PdfBase& pdfRef;
  unsigned int dim;
  std::vector<Variable*> vars;
};

class FitManager {
public:
  FitManager (PdfBase* dat, ROOT::Minuit2::EMinimizerType minmizerType = ROOT::Minuit2::kCombined, int strategy = 2);
  ROOT::Minuit2::Minuit2Minimizer* getMinimizer() { return minimizer; }


  ROOT::Minuit2::FunctionMinimum* fit (); 
  void getMinuitValues () const;
  virtual ~FitManager();

protected:
  PdfBase* pdfPointer;
  PdfFunctionProxy* pdfProxy;
  ROOT::Minuit2::Minuit2Minimizer* minimizer;
  std::vector<Variable*> vars;
  int numPars;
};

#endif
