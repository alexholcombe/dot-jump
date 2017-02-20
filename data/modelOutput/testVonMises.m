function result = vm(x, mu_x, kappa_x)
    mu_x
    kappa_x

    global xDomain;
    global xDomainPhi;
    
    vmComponent = (1/(2*pi*besseli(0,kappa_x))).*exp(kappa_x*cos(xDomainPhi-mu_x));
   
    result = vmComponent
end