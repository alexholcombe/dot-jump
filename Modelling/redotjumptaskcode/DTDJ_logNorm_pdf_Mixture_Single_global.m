function [result normComponent normalisedNormComponent vmComponent fullPDF successResult failResult] = DTDJ_pdf_Mixture_Single_global(x,params)

    global xDomain;
    global xDomainPhi;
    global tDomain;
    global theseErrorIndices;

    p = params(1);
    mu_x = params(2);
    kappa_x = params(3);
    mu_t = log(params(4));
    sigma_t = log(params(5));
    
    normComponent = lognpdf(tDomain,mu_t,sigma_t);
    vmComponent = (1/(2*pi*besseli(0,kappa_x))).*exp(kappa_x*cos(xDomainPhi-mu_x));
    
    normFactor = sum(normComponent);
    vmFactor = sum(vmComponent);
    if normFactor == 0
        normFactor = 10^-9;
    end
    if vmFactor == 0
        vmFactor = 10^-9;
    end

    % Normalise both
    normalisedNormComponent = normComponent/normFactor;
    normalisedVMComponent = vmComponent/vmFactor;
    
    % Combine and normalise
    fullPDF = vmComponent'*normComponent;
    fullPDFFactor = sum(fullPDF(:));
    if fullPDFFactor == 0
        fullPDFFactor = 10^-9;
    end 

    fullPDF = fullPDF/fullPDFFactor;
    
    successResult = p*sum(fullPDF(theseErrorIndices(x,:)),2);
    failResult = (1-p)*(1/length(xDomain));
    
    result = successResult + failResult;

end