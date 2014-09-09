#ifndef MAPREDUCEADDPDF_HH
#define MAPREDUCEADDPDF_HH

#include "MapReducePdf.hh"

class MapReduceAddPdf : public MapReducePdf {
public:
  MapReduceAddPdf(std::string n,
                  std::vector<Variable*> weights,
                  std::vector<PdfBase*> comps);
  virtual ~MapReduceAddPdf() {}
  __host__ virtual fptype normalise () const;
  __host__ virtual bool hasAnalyticIntegral () const {return false;}

protected:
  __host__ virtual double sumOfNll (int numVars) const;
};

#endif // MAPREDUCEADDPDF_HH
