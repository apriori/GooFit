#include "RooRealVar.h"
#include "RooDataSet.h"
#include "RooConstVar.h"
#include "RooCategory.h"
#include "RooArgSet.h"
#include "RooBDecay.h"
#include "RooFormulaVar.h"
#include "RooTruthModel.h"
#include "TApplication.h"
#include "TCanvas.h"
#include "RooPlot.h"
#include "RooDataHist.h"

//GooFit includes
#include "GooBDecayPdf.hh"
#include "FitManager.hh"

//ROOT Histogramm stuff
#include "TH1F.h"
#include <cstdio>

using namespace RooFit ;

int main()
{
    TApplication theApp("App", 0, 0);

    // C o n s t r u c t   p d f
    // -------------------------

    // Observable
    RooRealVar dt("dt","dt", 0,10) ;
    dt.setBins(40) ;

    // Parameters
    RooRealVar dm("dm","delta m(B0)",0.472) ;
    RooRealVar tau("tau","tau (B0)",1.547) ;
    RooRealVar w("w","flavour mistag rate",0.1) ;

    RooCategory tagFlav("tagFlav","Flavour of the tagged B0") ;
    tagFlav.defineType("B0",1) ;
    tagFlav.defineType("B0bar",-1) ;

    // Use delta function resolution model
    RooTruthModel tm("tm","truth model",dt) ;

    //////////////////////////////////////////////////////////////////////////////////
    // G e n e r i c   B   d e c a y  w i t h    u s e r   c o e f f i c i e n t s  //
    //////////////////////////////////////////////////////////////////////////////////

    // C o n s t r u c t   p d f
    // -------------------------

    // Model parameters
    RooRealVar DGbG("DGbG","DGamma/GammaAvg",0.5,-1,1);
    RooRealVar Adir("Adir","-[1-abs(l)**2]/[1+abs(l)**2]",0);
    RooRealVar Amix("Amix","2Im(l)/[1+abs(l)**2]",0.7);
    RooRealVar Adel("Adel","2Re(l)/[1+abs(l)**2]",0.7);

    // Derived input parameters for pdf
    RooFormulaVar DG("DG","Delta Gamma","@1/@0",RooArgList(tau,DGbG));

    // Construct coefficient functions for sin,cos,sinh modulations of decay distribution
    RooFormulaVar fsin("fsin","fsin","@0*@1*(1-2*@2)",RooArgList(Amix,tagFlav,w));
    RooFormulaVar fcos("fcos","fcos","@0*@1*(1-2*@2)",RooArgList(Adir,tagFlav,w));
    RooFormulaVar fsinh("fsinh","fsinh","@0",RooArgList(Adel));

    //GooFit wrapped variable sections, till proper
    //compatibility is established. These only include non-derived
    //variables and constants.

     //observable
    Variable goo_dt(dt.GetName(), dt.getMin(), dt.getMax());
    goo_dt.numbins = dt.getBins();

    //
    // calculate min/max for DG by hand, since there is no support
    // for RooFormulaVar

    fptype min = DGbG.getMin()/tau.getVal();
    fptype max = DGbG.getMax()/tau.getVal();
    fptype initial = DGbG.getVal()/tau.getVal();


    Variable goo_tau(tau.GetName(), tau.getVal());
    Variable goo_dm(dt.GetName(), dm.getVal());
    Variable goo_fcoshConst("cosh", 1.0);
    Variable goo_dg(DG.GetName(), initial, min, max);
    Variable goo_fsin(fsin.GetName(), fsin.getVal());
    Variable goo_fsinh(fsinh.GetName(), fsinh.getVal());
    Variable goo_fcos(fsin.GetName(), fcos.getVal());


    printf( "values: tau %.4f\n"
            "         dm %.4f\n"
            "      fcosh %.4f\n"
            "         dg %.4f, min %.4f, max %.4f\n"
            "       fsin %.4f\n"
            "      fsinh %.4f\n"
            "       fcos %.4f\n"
            , goo_tau.value
            , goo_dm.value
            , goo_fcoshConst.value
            , goo_dg.value, goo_dg.lowerlimit, goo_dg.upperlimit
            , goo_fsin.value
            , goo_fcos.value);
    fflush(stdout);


    // Construct generic B decay pdf using above user coefficients
    RooBDecay bcpg("bcpg","bcpg",dt,tau,DG,RooConst(1),fsinh,fcos,fsin,dm,tm, RooBDecay::SingleSided);



    // P l o t   -   I m ( l ) = 0 . 7 ,   R e ( l ) = 0 . 7   | l | = 1,   d G / G = 0 . 5
    // -------------------------------------------------------------------------------------

    // Generate some data
    RooDataSet* data = bcpg.generate(dt, 10000, kTRUE) ;

    bcpg.fitTo(*data);


    // GPU side RooBDecay (without any convolution = RooBDecay (**) RooTruthModel)
    GooBDecayInternal goo_bcpg("goo bdecay",
                      &goo_dt,
                      &goo_tau,
                      &goo_dg,
                      &goo_fcoshConst,
                      &goo_fsinh,
                      &goo_fcos,
                      &goo_fsin,
                      &goo_dm);

    std::vector<Variable*> vars;
    vars.push_back(&goo_dt);

    BinnedDataSet goo_data(&goo_dt);

    size_t entries = data->numEntries();

    for (size_t i = 0; i < entries; ++i) {
      const RooArgSet* args = data->get(i);
      const RooRealVar* dtArg = dynamic_cast<RooRealVar*>(args->find(dt.GetName()));

      goo_dt.value = dtArg->getVal();
      goo_data.addEvent();
    }

    //reset value to initial value
    goo_dt.value = 0;

    goo_bcpg.setData(&goo_data);

    printf("executing on gpu now\n");

    FitManager fitter(&goo_bcpg);
    fitter.fit();
    fitter.getMinuitValues();

    vector<fptype> values;
    goo_bcpg.evaluateAtPoints(&goo_dt, values);

    RooRealVar* dtClone = static_cast<RooRealVar*>(dt.Clone());
    dtClone->setVal(0.0);

    TH1D pdfHist("gpu hist", "", goo_dt.numbins, goo_dt.lowerlimit, goo_dt.upperlimit);

    double totalPdf = 0;
    for (size_t i = 0; i < values.size(); ++i) {
        totalPdf += values[i];
    }

    for (size_t i = 0; i < values.size(); ++i) {
      pdfHist.SetBinContent(i+1, values[i] / totalPdf * data->numEntries());
    }

    // Plot the generated data and both fits
    RooPlot* frame = dt.frame(Title("B decay distribution with CPV(Im(l)=0.7,Re(l)=0.7,|l|=1,dG/G=0.5) (B0/B0bar)")) ;
    RooDataHist gpuHist(pdfHist.GetName(), pdfHist.GetTitle(), RooArgSet(*dtClone), Import(pdfHist, kFALSE));

    //cpu fit in green
    data->plotOn(frame);
    bcpg.plotOn(frame, LineColor(kBlue), MarkerColor(kBlue), MarkerStyle(kBlue));
    //gpu fit in red
    gpuHist.plotOn(frame, LineColor(kRed), MarkerColor(kRed));

    TCanvas* c = new TCanvas("rf708_bphysics","rf708_bphysics",1200,800) ;
    c->cd(1) ; gPad->SetLeftMargin(0.15) ; frame->GetYaxis()->SetTitleOffset(1.6) ; frame->Draw() ;

    printf("numentries %i\n", data->numEntries());
    fflush(stdout);

    theApp.Run();
    return 0;
}
