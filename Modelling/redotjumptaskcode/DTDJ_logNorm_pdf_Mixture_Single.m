function result = DTDJ_pdf_Mixture_Single_global(x,p,mu_x,kappa_x,mu_t,sigma_t)

    global xDomain;
    global xDomainPhi;
    global tDomain;
    global theseErrorIndices;
    
%    [p,mu_x,kappa_x,mu_t,sigma_t]
    
    
    sigma_t = log(sigma_t);
    mu_t = log(mu_t);
    
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
    normComponent = normComponent/normFactor;
    vmComponent = vmComponent/vmFactor;
    
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