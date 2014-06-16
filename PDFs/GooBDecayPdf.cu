#include "GooBDecayPdf.hh"

#include "ConvolutionPdf.hh"

EXEC_TARGET fptype device_GooBDecay(fptype* evt, fptype* p, unsigned int* indices) {
  fptype t     = evt[indices[2 + indices[0]]]; 
  fptype tau  = p[indices[1]];
  fptype dgamma = p[indices[2]];
  fptype f0 = p[indices[3]];
  fptype f1 = p[indices[4]];
  fptype f2 = p[indices[5]];
  fptype f3 = p[indices[6]];
  fptype dm = p[indices[7]];

  fptype dgt = dgamma * t /2;
  fptype dmt = dm * t;
  fptype ft = FABS(t);
  
  return exp(-ft/tau) * (f0 * cosh(dgt) 
                        +f1 * sinh(dgt)
                        +f2 * cos(dmt)
                        +f3 * sin(dmt)
                        );
}

MEM_DEVICE device_function_ptr ptr_to_BDecay = device_GooBDecay;


GooBDecayInternal::GooBDecayInternal(
    std::string n,
    Variable* t, 
    Variable* tau, 
    Variable* dgamma,
    Variable* f0,
    Variable* f1,
    Variable* f2,
    Variable* f3,
    Variable* dm
    )
  : GooPdf(t, n)
{
    std::vector<unsigned int> pindices;
    pindices.push_back(registerParameter(tau));
    pindices.push_back(registerParameter(dgamma));
    pindices.push_back(registerParameter(f0));
    pindices.push_back(registerParameter(f1));
    pindices.push_back(registerParameter(f2));
    pindices.push_back(registerParameter(f3));
    pindices.push_back(registerParameter(dm));
    GET_FUNCTION_ADDR(ptr_to_BDecay);
    initialise(pindices); 
}

GooBDecay::GooBDecay(std::string n,
                     Variable* t, 
                     Variable* tau, 
                     Variable* dgamma,
                     Variable* f0,
                     Variable* f1,
                     Variable* f2,
                     Variable* f3,
                     Variable* dm,
                     GooPdf* resolution
                     )
    : ConvolutionPdf(n + "_conv_" + resolution->getName(),
                     t, 
                     new GooBDecayInternal(n + "_unconv", t, tau, dgamma, f0, f1, f2, f3, dm),
                     resolution)
{
 
}



