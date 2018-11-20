function m = antijet(n)
% antijet colormap
% by Christian Himpe 2014
% released under BSD 2-Clause License ( opensource.org/licenses/BSD-2-Clause )

    if (nargin<1 || isempty(n))
        n = 256; 
    end
    L = linspace(0,1,n);

    R = -0.5*sin( L*(1.37*pi)+0.13*pi )+0.5;
    G = -0.4*cos( L*(1.5*pi) )+0.4;
    B =  0.3*sin( L*(2.11*pi) )+0.3;

    m = [R;G;B]';
