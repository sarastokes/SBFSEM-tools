%Code subject: Finding Bezier segment control points based on smoothness
%                                  assertion for a set of arbitrary  n-d points
%Programmer: Aaron Wetzler, aaronwetzler@gmail.com
%Date:12/12/2009

%This work is entirely derived from the work of Oleg V Polikarpotchkin
%I have simply ported it from his .NET code on codeProject and applied Matlabs  
%matrix features to enable it to be multi-dimensional. A known bug in the
%original codeproject.com  code  was resolved by Peter Lee. 
%The original post along with the messages can be found here:
%http://www.codeproject.com/KB/graphics/BezierSpline.aspx?msg=3301993#xx3301993xx
%There is very little error checking in the code I provide so if you wish
%to reuse it make sure to add error checking.
%WARNING- The assumptions used do not guarantee relative local smoothness. There can be loops
%or nearly jagged edges. If the points are well selected however these artifacts are highly
%unlikely.

%[P1,  P2]=gcp(P0)
%The function expects an [n X  m] array as input where each of the n
%rows represents a point and each of its m columns are the components of
%the point. The matrix P0 to a large extent represents the control points 
%on a set of cubic order Bezier segments.
%The Bezier cubic is:
%B(t)=(1-t)^3*P0+3(1-t)^2*t*P1+3(1-t)*t^2*P2+t^3*P3
%
%P1 and P2 will be the derived control points for each segment
%
%The following conditions are used to derive P1 and P2:
%1 - P1(i+1)+P2(i)=2P0(i+1)
%2 - P1(i)+2P1(i+1)= P2(i+1)+2P2(i)
%3 - 2P1(1)-P2(1)=P0(1)
%4 - 2P2(n)-P1(n)=P3(n)=P0(n+1)
%
%These are derived from the the initial assertions that 
%B(i,1)`=B(i+1,0)`
%B(i,1)``=B(i+1,0)``
%B(1,0)``=B(n,1)``=0;
%
%In order to find P1 and P2 we first eliminate P2 from the conditions that
%we derive from the problem. We then can place the unknown P1 coefficients
%in a matrix with a calculable solution vector comprised of combinations of
%pairs of the input set of points P0. When we do so we see that we receive
%a tridiagonal matrix symetrical about the main diagonal. 
%Finally we solve the system of equations using an algorithm for solving
%tridiagonal matrices. 

function  [P1,  P2]=findControlPoints(P0)

numSegments = size(P0,1)-1;%Get the number of points and let numSegments b the number of segments i.e. number of points- 1
dim=size(P0,2);%Get the number of dimensions being used. Can be n-dimensional. Only really need up to 3 dimensions

%We want to find P1 and P2 and we start by making them all zeros
P1 = zeros(numSegments,dim); 
P2 = zeros(numSegments,dim);

%Simple error check
if (numSegments < 1)
    disp('Input vector must contain at least 2 points'); return
end

 %Special case: Bezier curve should be a straight line.
if (numSegments == 1)
    P1(1,:) = (2.0 * P0(1,:) + P0(2,:)) / 3.0;  %3P1 = 2P0 + P3
    P2(1,:) = 2.0 *P1(1,:) - P0(1,:);               % P2 = 2P1  P0
    return
end

%Set solution values
solutionVector=zeros(numSegments,dim);
solutionVector(2:numSegments-1,:)=4.0*P0(2:numSegments-1,:)+2.0*P0(3:numSegments,:);

%Set start and end values of solution vector
solutionVector(1,:) = P0(1,:) + 2 * P0(2,:);
solutionVector(numSegments,:)= (8.0 * P0(numSegments,:) + P0(numSegments+1,:)) / 2.0;

% Solve for P1
P1=solveForP1(solutionVector);

%Solve for P2
 P2(1:numSegments-1,:)=2*P0(2:numSegments,:)-P1(2:numSegments,:);
 P2(numSegments,:)=(P0 (numSegments+1,:) + P1(numSegments,:)) /2.0 ;
     
 %Return with P1 and P2 having been determined
return


%This function solves the known tridiagonal matrix with the precalculated
%solution vector for the problem at hand.
function P1=solveForP1(solutionVector)

n = size(solutionVector,1); %find the number of equations
dim=size(solutionVector,2); %and the number of dimensions were working in
P1 = zeros(n,dim); %initialize the result
tmp = P1;%give us a temp variable of the same size

b =ones(1,dim)* 2.0;%The algorithm is initialized with P1(1) coefficient
P1(1,:)= solutionVector(1,:) ./ b;

%no we work our way through our tridiagonal matrix 
for i = 2:n 
    tmp(i,:)= 1 ./ b;
    if (i<n)
        b(:)=4.0-tmp(i,:);
    else
        b(:)=3.5-tmp(i,:);
    end

    P1(i,:) = (solutionVector(i,:) - P1(i - 1,:))./ b;
end

%Here we work our way back resubstituting the intermediate solutions
for i = 2:n
    P1(n - i+1,:) =P1(n-i+1,:)- tmp(n - i+2,:) .* P1(n - i+2,:); % Backsubstitution.
end

%Return having found the solved matrix output
return 