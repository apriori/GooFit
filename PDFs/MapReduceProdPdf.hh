#ifndef MAPREDUCEPRODPDF_HH
#define MAPREDUCEPRODPDF_HH

#include "MapReducePdf.hh"

class MapReduceProdPdf : public MapReducePdf {
public:
  MapReduceProdPdf(std::string n,
                   std::vector<PdfBase*> comps);
  virtual ~MapReduceProdPdf() {}
  __host__ virtual fptype normalise () const;
  __host__ virtual bool hasAnalyticIntegral () const {return false;}

private:
  bool varOverlaps; // True if any components share an observable.
};

#endif // MAPREDUCEPRODPDF_HH
