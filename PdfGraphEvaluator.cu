#include "PdfGraphEvaluator.hh"

#include "PdfBase.hh"
#include <queue>

__host__ PdfGraphEvaluator::PdfGraphEvaluator()
  : hasComponentGraph(false)
  , rootNode(NULL) {
}

__host__ PdfGraphEvaluator::~PdfGraphEvaluator() {
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  for (size_t i = 0; i < futurePool.size(); ++i) {
    std::pair<PdfNodeState*, std::vector<bulk_::future<void> >* >& element = futurePool[i];
    delete element.second;
  }
#endif
}


__host__ PdfNodeState::PdfNodeState(PdfGraphEvaluator* evaluator,
                           PdfBase* pdf,
                           PdfNodeState* parent)
  : evaluator(evaluator)
  , pdf(pdf)
  , isEvaluated(false)
  , isRecursiveEvaluated(false)
  , evaluatedComponents(0)
  , parent(parent)
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  , futureVectorPtr(0)
#endif
{



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
  if (isEvaluated) {
    return;
  }

#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  pdf->preEvaluateComponents(*futureVectorPtr);
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

    std::pair<PdfNodeState*, std::vector<bulk_::future<void> >* >& element = futurePool[i];

    PdfNodeState* pdfState = element.first;

    for (size_t j = 0; j < element.second->size(); ++j) {
      if ((*element.second)[j].valid()) {
        (*element.second)[j].wait();
        //pdfState->notifyParentOfEvaluated();
      }
    }
    element.second->clear();
  }
#endif
}

__host__ void PdfGraphEvaluator::analyzeAndFlatten() {
  std::queue<std::pair<int, PdfNodeState*> > nodes;
  nodes.push(std::pair<int, PdfNodeState*>(0, rootNode));

  int currentDepth = 0;

  flattenedGraph.push_back(new SyncOperation(this));
  flattenedGraph.push_back(rootNode);
  flattenedGraph.push_back(new SyncOperation(this));

  std::vector<PdfNodeState*> states;
  states.push_back(rootNode);

  while (!nodes.empty()) {
    std::pair<int, PdfNodeState*> nodeTuple = nodes.front();
    int newDepth = nodeTuple.first;
    PdfNodeState* node = nodeTuple.second;
    nodes.pop();

    std::cout << "visiting " << node->getPdf()->getName() << std::endl;
    if (currentDepth != newDepth && !nodes.empty() && node->hasChildren()) {
      flattenedGraph.push_back(new SyncOperation(this));
    }

    if (std::find(flattenedGraph.begin(), flattenedGraph.end(), node) == flattenedGraph.end() &&
        node->hasChildren()) {
      flattenedGraph.push_back(node);
      states.push_back(node);
    }

    std::vector<PdfNodeState*> children = node->getChildren();

    if (children.size() > 0) {
      for (size_t i = 0; i < children.size(); ++i) {
        PdfNodeState* child = children[i];
        if (child->hasChildren()) {
          nodes.push(std::pair<int, PdfNodeState*>(newDepth + 1, child));
          flattenedGraph.push_back(child);
          states.push_back(child);
        }
      }
    }
    currentDepth = newDepth;
  }

  std::vector<NodeEvaluation*>::reverse_iterator it = flattenedGraph.rbegin();

  std::cout << "flattened graph is: " << std::endl;
  for (; it != flattenedGraph.rend(); ++it) {
    std::cout << (*it)->getDescription() << std::endl;
  }

  std::vector<PdfNodeState*>::reverse_iterator statesRit = states.rbegin();
#if THRUST_DEVICE_SYSTEM!=THRUST_DEVICE_BACKEND_OMP
  for (; statesRit != states.rend(); ++statesRit) {
    std::vector<bulk_::future<void> > * vect = new std::vector<bulk_::future<void> >();
    (*statesRit)->setFutureVectorPointer(vect);
    futurePool.push_back(std::pair<PdfNodeState*, std::vector<bulk_::future<void> >* >(*statesRit, vect));
  }
#endif
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
  evaluator->syncAndFlush();
}
