#include "GooDecayPdf.hh"

EXEC_TARGET fptype device_GooDecay (fptype* evt, fptype* p, unsigned int* indices) {
  fptype t = evt[indices[2 + indices[0]]]; 
  fptype tau = p[indices[1]];

  fptype ret = EXP(-t/tau); 
  return ret; 
}

MEM_DEVICE device_function_ptr ptr_to_GooDecay = device_GooDecay; 

__host__ GooDecayPdf::GooDecayPdf (std::string n, Variable* _t, Variable* tau)
  : GooPdf(_t, n) 
{
  std::vector<unsigned int> pindices;
  pindices.push_back(registerParameter(tau));
  GET_FUNCTION_ADDR(ptr_to_GooDecay);
  initialise(pindices); 
}

__host__ fptype GooDecayPdf::integrate (fptype lo, fptype hi) const {
  fptype tau = host_params[host_indices[parameters + 1]]; 
  return -tau * (EXP(-hi/tau) - EXP(-lo/tau));
}

