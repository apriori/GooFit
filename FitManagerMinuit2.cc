#include "FitManagerMinuit2.hh"
#include <cstdlib>

PdfFunctionProxy::PdfFunctionProxy(PdfBase& pdf)
 : pdfRef(pdf)
 , dim(pdf.getParameters().size())
 , vars(pdf.getParameters()) {
  std::sort(vars.begin(), vars.end(), variableIndexCompare);
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

void PdfFunctionProxy::setParamMapArraySize(size_t size) {
  pars.resize(size, static_cast<fptype>(0.0));
}

double PdfFunctionProxy::DoEval(const double* x) const {
  size_t counter = 0;
  for (auto i = vars.begin(); i != vars.end(); ++i, counter++) {
    pars[(*i)->index] = x[counter];
  }

  pdfRef.copyParams(pars);
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
  //minimizer->SetPrecision(std::numeric_limits<fptype>::epsilon());
  minimizer->SetTolerance(1.0);
  minimizer->SetPrintLevel(1);

  std::sort(vars.begin(), vars.end(), variableIndexCompare);
}


bool FitManager::fit() {
  minimizer->Clear();

  size_t counter = 0;
  int maxIndexSize = 0;
  for (auto i = vars.begin(); i != vars.end(); ++i, counter++) {
    auto var = (*i);

    if (((*i)->lowerlimit == (*i)->upperlimit) || var->fixed) {
      minimizer->SetFixedVariable(counter, var->name, var->value);
    }
    else {
      minimizer->SetLimitedVariable(counter, var->name, var->value, var->error, var->lowerlimit, var->upperlimit);
    }

    if ((*i)->index > maxIndexSize) {
      maxIndexSize = (*i)->index;
    }
  }
  pdfProxy->setParamMapArraySize(maxIndexSize + 1);
  minimizer->SetMaxFunctionCalls(minimizer->NFree() * 500);
  minimizer->SetMaxIterations(minimizer->NFree() * 500);

  return minimizer->Minimize() && minimizer->Hesse();
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



