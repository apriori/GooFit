#include "FitManagerMinuit2.hh"

ROOT::Minuit2::FunctionMinimum* FitManager::fit () {
  host_callnumber = 0; 
  params = new ROOT::Minuit2::MnUserParameters();
  vars.clear();
  pdfPointer->getParameters(vars); 

  numPars = vars.size();
  int maxIndex = 0;
  for (std::vector<Variable*>::iterator i = vars.begin(); i != vars.end(); ++i) {
    if ((*i)->isCategoryConstant) continue;
    if ((*i)->lowerlimit == (*i)->upperlimit) params->Add((*i)->name, (*i)->value, (*i)->error); 
    else params->Add((*i)->name, (*i)->value, (*i)->error, (*i)->lowerlimit, (*i)->upperlimit); 
    if ((*i)->fixed) params->Fix(params->Index((*i)->name)); 

    if (maxIndex < (*i)->getIndex()) maxIndex = (*i)->getIndex();
  }

  numPars = maxIndex+1; 
  migrad = new ROOT::Minuit2::MnMigrad(*this, *params); 
  ROOT::Minuit2::FunctionMinimum* ret = new ROOT::Minuit2::FunctionMinimum((*migrad)());

  if (lastresult != 0) {
      delete lastresult;
  }
  lastresult = ret;

  return ret; 
}

double FitManager::operator () (const vector<double>& pars) const {
  vector<double> gooPars; // Translates from Minuit indexing to GooFit indexing
  gooPars.resize(numPars); 
  int counter = 0; 
  for (std::vector<Variable*>::const_iterator i = vars.begin(); i != vars.end(); ++i) {
    gooPars[(*i)->index] = pars[counter++]; 
  }

  pdfPointer->copyParams(gooPars); 
  double nll = pdfPointer->calculateNLL();
  host_callnumber++; 

#ifdef PRINTCALLS
  double edm = migrad->State().Edm(); 
  cout.precision(8); 
  cout << "State at call " 
	    << host_callnumber << " : "
	    << nll << " "
	    << edm << " Pars: ";
  std::vector<Variable*> vars;
  pdfPointer->getParameters(vars); 
  for (std::vector<Variable*>::iterator i = vars.begin(); i != vars.end(); ++i) {
    if (0 > (*i)->getIndex()) continue;
    if ((*i)->fixed) continue;
    cout << "(" << (*i)->name << " " << pars[(*i)->getIndex()] << ") "; // migrad->Value((*i)->getIndex()) << ") ";
  }

  cout << endl; 
#endif 

  return nll; 
}

void FitManager::getMinuitValues () const {
  const ROOT::Minuit2::MnUserParameters& params = lastresult->UserParameters();

  for (std::vector<Variable*>::const_iterator i = vars.begin(); i != vars.end(); ++i) {
      Variable* var = (*i);
      var->value = params.Value(var->name);
      var->error = params.Error(var->name);
  }
}

