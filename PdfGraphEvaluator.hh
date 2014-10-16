#ifndef PDFGRAPHEVALUATOR_HH
#define PDFGRAPHEVALUATOR_HH

#include "GlobalCudaDefines.hh"
#include "PdfBase.hh"

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
#include <thrust/system/cuda/detail/bulk.h>
using namespace thrust::system::cuda::detail;
#endif
#include <vector>

class PdfBase;
class PdfGraphEvaluator;

class NodeEvaluation {
public:
  __host__ NodeEvaluation() {}
  __host__ virtual ~NodeEvaluation() {}
  __host__ virtual void evaluate() = 0;
  __host__ virtual std::string getDescription() const = 0;
};

class PdfNodeState : public NodeEvaluation {
public:
  __host__ PdfNodeState(PdfGraphEvaluator* evaluator,
               PdfBase* pdf,
               PdfNodeState* parent);
  __host__ PdfBase* getPdf();
  __host__ void resetState();
  __host__ void recursiveReset();
  __host__ void addChildren(PdfBase* pdf);
  __host__ void addChildren(PdfNodeState* state);
  __host__ virtual void evaluate();

  __host__ virtual ~PdfNodeState();
  __host__ const std::vector<PdfNodeState*> getChildren() const { return children; }
  __host__ void notifyParentOfEvaluated();
  __host__ void setEvaluated(bool done) { isEvaluated = done; }
  __host__ virtual std::string getDescription() const { return "PdfEvaluation: " + pdf->getName(); }
  __host__ bool hasChildren() const { return !children.empty(); }

private:
  PdfGraphEvaluator* evaluator;
  PdfBase* pdf;
  bool isEvaluated;
  bool isRecursiveEvaluated;
  int evaluatedComponents;
  PdfNodeState* parent;
  std::vector<PdfNodeState*> children;
};


class SyncOperation : public NodeEvaluation {
public:
  __host__ SyncOperation(PdfGraphEvaluator* evaluator);
  __host__ virtual ~SyncOperation() {}
  __host__ virtual void evaluate();
  __host__ virtual std::string getDescription() const { return "Sync"; }
private:
  PdfGraphEvaluator* evaluator;
};

class PdfGraphEvaluator {
public:
  __host__ PdfGraphEvaluator();
  __host__ virtual ~PdfGraphEvaluator();
  __host__ void constructFromTopLevelPdf(PdfBase* pdf);
  __host__ void evaluate();
  __host__ void syncAndFlush();

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  void addFutures(const std::pair<PdfNodeState*, std::vector<bulk_::future<void> > >& pair) {
    futurePool.push_back(pair);
  }
#endif

private:
  __host__ void analyzeAndFlatten();
  __host__ void constructFromPdf(PdfBase* pdf,
                        PdfNodeState* parent = NULL);
  __host__ void recursiveDelete();
  __host__ void checkAffectedSubGraph();
  bool hasComponentGraph;
  PdfNodeState* rootNode;
  std::vector<NodeEvaluation*> flattenedGraph;
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP

  std::vector< std::pair<PdfNodeState*, std::vector<bulk_::future<void> > > > futurePool;
#endif
};

#endif // PDFGRAPHEVALUATOR_HH
