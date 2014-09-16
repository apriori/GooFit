#ifndef PDFGRAPHEVALUATOR_HH
#define PDFGRAPHEVALUATOR_HH

#include "GlobalCudaDefines.hh"

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
#include <thrust/system/cuda/detail/bulk.h>
using namespace thrust::system::cuda::detail;
#endif
#include <vector>

class PdfBase;
class PdfGraphEvaluator;

class NodeEvaluation {
public:
  NodeEvaluation() {}
  virtual ~NodeEvaluation() {}
  virtual void evaluate() = 0;
};

class PdfNodeState : public NodeEvaluation {
public:
  PdfNodeState(PdfGraphEvaluator* evaluator,
               PdfBase* pdf,
               PdfNodeState* parent);
  PdfBase* getPdf();
  void resetState();
  void recursiveReset();
  void addChildren(PdfBase* pdf);
  void addChildren(PdfNodeState* state);
  virtual void evaluate();

  virtual ~PdfNodeState();
  const std::vector<PdfNodeState*> getChildren() const { return children; }
  void notifyParentOfEvaluated();
  void setEvaluated(bool done) { isEvaluated = done; }

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
  SyncOperation(PdfGraphEvaluator* evaluator);
  virtual ~SyncOperation() {}
  virtual void evaluate();
private:
  PdfGraphEvaluator* evaluator;
};

class PdfGraphEvaluator {
public:
  PdfGraphEvaluator();
  virtual ~PdfGraphEvaluator();
  void constructFromTopLevelPdf(PdfBase* pdf);
  void evaluate();
  void syncAndFlush();

private:
  void analyzeAndFlatten();
  void constructFromPdf(PdfBase* pdf,
                        PdfNodeState* parent = NULL);
  void recursiveDelete();
  void checkAffectedSubGraph();
  PdfNodeState* rootNode;
  std::vector<NodeEvaluation*> flattenedGraph;
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  std::vector< std::pair<PdfNodeState*, std::vector<bulk_::future<void> > > > futurePool;
#endif
};

#endif // PDFGRAPHEVALUATOR_HH
