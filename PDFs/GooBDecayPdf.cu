#include "GooBDecayPdf.hh"

//#include "ConvolutionPdf.hh"
#include <cstdio>

EXEC_TARGET fptype device_GooBDecay(fptype* evt, fptype* p, unsigned int* indices) {
  fptype t        = evt[indices[2 + indices[0]]];
  fptype tag      = evt[indices[2 + indices[0] + 1]];
  fptype parS     = p[indices[1]];
  fptype parC     = p[indices[2]];
  fptype parOmega = p[indices[3]];
  fptype tau      = p[indices[4]];
  fptype dgamma   = p[indices[5]];
  fptype f0       = p[indices[6]];
  fptype f1       = p[indices[7]];
  fptype dm       = p[indices[8]];

  fptype dgt = dgamma * t /2;
  fptype dmt = dm * t;
  fptype coeffBase = tag * (1. - 2. * parOmega);
  fptype f2 = -coeffBase * parC;
  fptype f3 = coeffBase * parS;
  fptype ft = FABS(t);

  fptype cosh_ = COSH(dgt);
  fptype sinh_ = SINH(dgt);
  fptype cos_ = COS(dmt);
  fptype sin_ = SIN(dmt);

  return exp(-ft/tau) * (f0 * cosh_
                        +f1 * sinh_
                        +f2 * cos_
                        +f3 * sin_
                        );
}

MEM_DEVICE device_function_ptr ptr_to_BDecay = device_GooBDecay;


GooBDecayInternal::GooBDecayInternal(std::string n,
    Variable* dt,
    Variable* tag,
    Variable *parS,
    Variable *parC,
    Variable *parOmega,
    Variable* tau,
    Variable* dgamma,
    Variable* f0,
    Variable* f1,
    Variable* dm
    )
  : GooPdf(dt, n) {
    tag->fixed = true;
    registerObservable(tag);

    std::vector<unsigned int> pindices;
    pindices.push_back(registerParameter(parS));
    pindices.push_back(registerParameter(parC));
    pindices.push_back(registerParameter(parOmega));
    pindices.push_back(registerParameter(tau));
    pindices.push_back(registerParameter(dgamma));
    pindices.push_back(registerParameter(f0));
    pindices.push_back(registerParameter(f1));
    pindices.push_back(registerParameter(dm));
    GET_FUNCTION_ADDR(ptr_to_BDecay);
    initialise(pindices);
}

__host__ fptype bdecayNorm(fptype t,
                           fptype tag,
                           fptype parS,
                           fptype parC,
                           fptype parOmega,
                           fptype tau,
                           fptype f0,
                           fptype f1,
                           fptype dm) {
  fptype dmt = dm * t;
  fptype coeffBase = tag * (1. - 2. * parOmega);
  fptype f2 = -coeffBase * parC;
  fptype f3 = coeffBase * parS;

  fptype inv_coeff = (-tau)/(1 + dmt*dmt * tau * tau);
  fptype expPart = exp(-t/tau);
  fptype cosdmt = cos(dmt);
  fptype sindmt = sin(dmt);
  fptype dmttau = dmt * tau;

  fptype expIntCoeff = -tau;
  fptype sinIntCoeff = f3 * inv_coeff * (sindmt + dmttau * cosdmt);
  fptype cosIntCoeff = f2 * inv_coeff * (cosdmt - dmttau * sindmt);
  return expPart * (expIntCoeff + sinIntCoeff + cosIntCoeff);
}

fptype GooBDecayInternal::integrate(fptype lo, fptype hi) const {
  lo = std::max(lo, (fptype)0.0);
  unsigned int* indices = host_indices + parameters;
  fptype hiInt = bdecayNorm(hi,
                    1,
                    host_params[indices[1]],
                    host_params[indices[2]],
                    host_params[indices[3]],
                    host_params[indices[4]],
                    host_params[indices[6]],
                    host_params[indices[7]],
                    host_params[indices[8]]
                    );
  fptype loInt = bdecayNorm(lo,
                    1,
                    host_params[indices[1]],
                    host_params[indices[2]],
                    host_params[indices[3]],
                    host_params[indices[4]],
                    host_params[indices[6]],
                    host_params[indices[7]],
                    host_params[indices[8]]
                    );
  fptype hiInt2 = bdecayNorm(hi,
                    -1,
                     host_params[indices[1]],
                     host_params[indices[2]],
                     host_params[indices[3]],
                     host_params[indices[4]],
                     host_params[indices[6]],
                     host_params[indices[7]],
                     host_params[indices[8]]
                    );
  fptype loInt2 = bdecayNorm(lo,
                    -1,
                   host_params[indices[1]],
                   host_params[indices[2]],
                   host_params[indices[3]],
                   host_params[indices[4]],
                   host_params[indices[6]],
                   host_params[indices[7]],
                   host_params[indices[8]]
                    );
  //return hiInt2 + hiInt - loInt - loInt2;
  fptype ttau = host_params[indices[4]];
  return 2*-ttau * (exp(-hi/ttau) - exp(-lo/ttau));
  //return hiInt - loInt;
}

/*
GooBDecay::GooBDecay(std::string n,
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
                     )
    : ConvolutionPdf(n + "_conv_" + resolution->getName(),
                     dt,
                     new GooBDecayInternal(n + "_unconv", dt, tag, tau, dgamma, f0, f1, f2, f3, dm),
                     resolution)
{
 
}
*/




