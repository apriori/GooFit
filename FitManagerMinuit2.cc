#include "FitManagerMinuit2.hh"
#include <cstdlib>


PdfFunctionProxy::PdfFunctionProxy(PdfBase& pdf)
 : pdfRef(pdf)
 , dim(pdf.getParameters().size())
 , vars(pdf.getParameters()) {
}

PdfFunctionProxy::PdfFunctionProxy(PdfFunctionProxy &other)
 : pdfRef(other.pdfRef)
 , dim(other.dim)
 , vars(other.vars) {

}

PdfFunctionProxy::PdfFunctionProxy(const PdfFunctionProxy& other)
 : pdfRef(other.pdfRef)
 , dim(other.dim)
 , vars(other.vars) {

}

ROOT::Math::IBaseFunctionMultiDim* PdfFunctionProxy::Clone() const {
  return new PdfFunctionProxy(*this);
}

double PdfFunctionProxy::DoEval(const double* x) const {
  vector<double> gooPars; // Translates from Minuit indexing to GooFit indexing
  auto vars = pdfRef.getParameters();
  gooPars.resize(dim);
  for (auto i = vars.begin(); i != vars.end(); ++i) {
    gooPars[(*i)->index] = x[(*i)->index];
  }

  pdfRef.copyParams(gooPars);
  double nll = pdfRef.calculateNLL();
  host_callnumber++;

  return nll;
}

FitManager::FitManager(PdfBase *dat, ROOT::Minuit2::EMinimizerType minmizerType, int strategy)
  : pdfPointer(dat)
  , pdfProxy(new PdfFunctionProxy(*dat))
  , minimizer(new ROOT::Minuit2::Minuit2Minimizer(minmizerType))
  , vars(pdfPointer->getParameters()) {
  minimizer->SetFunction(*pdfProxy);
  minimizer->SetDefaultOptions();
  minimizer->SetStrategy(strategy);
  minimizer->SetPrecision(std::numeric_limits<fptype>::epsilon());
  minimizer->SetTolerance(1.0);
  minimizer->SetPrintLevel(1);

  std::sort(vars.begin(), vars.end(), variableIndexCompare);
}


ROOT::Minuit2::FunctionMinimum* FitManager::fit () {
  minimizer->Clear();
  minimizer->SetMaxFunctionCalls(minimizer->NFree() * 500);
  minimizer->SetMaxIterations(minimizer->NFree() * 500);

  for (auto i = vars.begin(); i != vars.end(); ++i) {
    auto var = (*i);

    if (((*i)->lowerlimit == (*i)->upperlimit) || var->fixed) {
      minimizer->SetFixedVariable(var->index, var->name, var->value);
    }
    else {
      minimizer->SetLimitedVariable(var->index, var->name, var->value, var->error, var->lowerlimit, var->upperlimit);
    }
  }

  if (minimizer->Minimize()) {
    return NULL;
  }


  return NULL;
}


void FitManager::getMinuitValues () const {
  auto minimizeParams = minimizer->State().Parameters();

  for (auto i = vars.begin(); i != vars.end(); ++i) {
      Variable* var = (*i);
      var->value = minimizeParams.Value(var->name);
      var->error = minimizeParams.Error(var->name);
    }
}

FitManager::~FitManager() {
  delete minimizer;
  delete pdfProxy;
}



