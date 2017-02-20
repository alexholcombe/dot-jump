function result = DTDJ_pdf_Mixture_Single(x,p,mu_x,kappa_x,mu_t,sigma_t)

    global xDomain;
    global xDomainPhi;
    global tDomain;
    global theseErrorIndices;
    
    [p mu_x kappa_x mu_t sigma_t];
    
    p
    
    normComponent = normpdf(tDomain,mu_t,sigma_t)
    vmComponent = (1/(2*pi*besseli(0,kappa_x))).*exp(kappa_x*cos(xDomainPhi-mu_x))
    
    % Normalise both
    normComponent = normComponent/sum(normComponent);
    vmComponent = vmComponent/sum(vmComponent);
    
    % Combine and normalise
    fullPDF = vmComponent'*normComponent;
    fullPDF = fullPDF/sum(fullPDF(:));
    
    nonGuessLikelihood = prod(p*sum(fullPDF(theseErrorIndices(x,:)),2))
    guessLikelihood = prod((1-p)*(1/length(xDomain)))
    
    successResult = p*sum(fullPDF(theseErrorIndices(x,:)),2);
    failResult = (1-p)*(1/length(xDomain));
    
    result = successResult + failResult;

end