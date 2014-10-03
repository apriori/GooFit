#include "PdfGraphEvaluator.hh"

#include "PdfBase.hh"
#include <queue>

__host__ PdfGraphEvaluator::PdfGraphEvaluator()
  : hasComponentGraph(false)
  , rootNode(NULL) {
}

__host__ PdfGraphEvaluator::~PdfGraphEvaluator() {

}


__host__ PdfNodeState::PdfNodeState(PdfGraphEvaluator* evaluator,
                           PdfBase* pdf,
                           PdfNodeState* parent)
  : evaluator(evaluator)
  , pdf(pdf)
  , isEvaluated(false)
  , isRecursiveEvaluated(false)
  , evaluatedComponents(0)
  , parent(parent) {
}

__host__ void PdfNodeState::resetState() {
  setEvaluated(false);
}

__host__ void PdfNodeState::recursiveReset() {
  setEvaluated(false);
  for (size_t i = 0;i < children.size(); ++i) {
    children[i]->recursiveReset();
  }
}

__host__ void PdfNodeState::addChildren(PdfBase* pdf) {
  children.push_back(new PdfNodeState(evaluator, pdf, this));
}

__host__ void PdfNodeState::addChildren(PdfNodeState* state) {
  children.push_back(state);
}

__host__ void PdfNodeState::evaluate() {
  //std::cout << "EVAL " << pdf->getName() << std::endl;

  if (isEvaluated) {
    return;
  }

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  std::pair<PdfNodeState*, std::vector<bulk_::future<void> > > pair;
  pair.first = this;
  pdf->preEvaluateComponents(pair.second);
#endif
}

__host__ PdfNodeState::~PdfNodeState() {

}

__host__ void PdfNodeState::notifyParentOfEvaluated() {
  setEvaluated(true);
}

__host__ void PdfGraphEvaluator::constructFromTopLevelPdf(PdfBase* pdf) {
  if (pdf->getComponents().size() > 0) {
    constructFromPdf(pdf);
    analyzeAndFlatten();
    hasComponentGraph = true;
  }
}

__host__ void PdfGraphEvaluator::constructFromPdf(PdfBase* pdf,
                                                  PdfNodeState* parent) {
  PdfNodeState* newParent = new PdfNodeState(this, pdf, parent);

  if (parent == NULL) {
    rootNode = newParent;
  }

  std::vector<PdfBase*> comps = pdf->getComponents();
  for (size_t i = 0;i < comps.size(); ++i) {
    constructFromPdf(comps[i], newParent);
  }

  if (parent != NULL) {
    parent->addChildren(newParent);
  }
}

__host__ void PdfGraphEvaluator::evaluate() {
  if (hasComponentGraph) {
    checkAffectedSubGraph();

    std::vector<NodeEvaluation*>::reverse_iterator it = flattenedGraph.rbegin();
    for ( ; it != flattenedGraph.rend(); it++) {
      (*it)->evaluate();
    }
  }
}

__host__ void PdfGraphEvaluator::syncAndFlush() {
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  for (size_t i = 0; i < futurePool.size(); ++i) {

    std::pair<PdfNodeState*, std::vector<bulk_::future<void> > >& element = futurePool[i];

    PdfNodeState* pdfState = element.first;
    for (size_t j = 0; j < element.second.size(); ++j) {
      element.second[j].wait();
      pdfState->notifyParentOfEvaluated();
    }
    pdfState->setEvaluated(true);
  }
  futurePool.clear();
#endif
}

__host__ void PdfGraphEvaluator::analyzeAndFlatten() {
  std::queue<std::pair<int, PdfNodeState*> > nodes;
  nodes.push(std::pair<int, PdfNodeState*>(0, rootNode));

  std::vector<PdfNodeState*> visitedNodes;

  int currentDepth = 0;

  flattenedGraph.push_back(rootNode);
  flattenedGraph.push_back(new SyncOperation(this));

  while (!nodes.empty()) {
    std::pair<int, PdfNodeState*> nodeTuple = nodes.front();
    int newDepth = nodeTuple.first;
    PdfNodeState* node = nodeTuple.second;
    nodes.pop();

    if (std::find(visitedNodes.begin(), visitedNodes.end(), node) != visitedNodes.end()) {
      std::cout << "skipping " << node->getDescription() << std::endl;
      continue;
    }

    if (currentDepth != newDepth) {
      flattenedGraph.push_back(new SyncOperation(this));
    }

    visitedNodes.push_back(node);

    if (std::find(flattenedGraph.begin(), flattenedGraph.end(), node) == flattenedGraph.end()) {
      flattenedGraph.push_back(node);
    }

    std::vector<PdfNodeState*> children = node->getChildren();

    if (children.size() > 0) {
      for (size_t i = 0; i < children.size(); ++i) {
        PdfNodeState* child = children[i];
        nodes.push(std::pair<int, PdfNodeState*>(newDepth + 1, child));
        flattenedGraph.push_back(child);
      }
    }
    currentDepth = newDepth;
  }

  std::vector<NodeEvaluation*>::reverse_iterator it = flattenedGraph.rbegin();

  std::cout << "flattened graph is: " << std::endl;
  for (; it != flattenedGraph.rend(); ++it) {
    std::cout << (*it)->getDescription() << std::endl;
  }
}

__host__ void PdfGraphEvaluator::checkAffectedSubGraph() {
  if (rootNode != NULL) {
    rootNode->recursiveReset();
  }
}


__host__ SyncOperation::SyncOperation(PdfGraphEvaluator* evaluator)
 : evaluator(evaluator) {

}

__host__ void SyncOperation::evaluate() {
  //std::cout << "SYNC " << std::endl;
  evaluator->syncAndFlush();
}
