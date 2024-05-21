function [h0,stats] = MBoxtest(X,alpha,options)
% Multivariate Statistical Testing for the Homogeneity of Covariance Matrices by the Box's M.
%
%   Syntax: 
%       stats = MBoxtest(X,alpha,'Name',value,...)
%
%     Inputs:
%          X - data matrix (Size of matrix must be n-by-(1+p); sample=column 1, variables=column 2:p).
%      alpha - significance level (default = 0.05).
%   
%     Options:
%       'ConditioningLevel' (1,1) double = 1e-8; % Adds conditioning noise with specified level to the data, to ensure positive definite covariance.
%       'Verbose' (1,1) logical = true; % Set false to suppress Command Window print statements.
%
%     Output:
%       h0 - 1 if we covariance matrices are not significantly different at
%               the specified alpha level. 0 otherwise.
%       stats
%          MBox - the Box's M statistic.
%          Chi-sqr. or F - the approximation statistic test.
%          df's - degrees' of freedom of the approximation statistic test.
%          P - observed significance level.
%
%    If the groups sample-size is at least 20 (sufficiently large), Box's M test
%    takes a Chi-square approximation; otherwise it takes an F approximation.
%
%    Example: For a two groups (g = 2) with three independent variables (p = 3), we
%             are interested to test the homogeneity of covariances matrices with a
%             significance level = 0.05. The two groups have the same sample-size
%             n1 = n2 = 5.
%                                       Group
%                      ---------------------------------------
%                            1                        2
%                      ---------------------------------------
%                       x1   x2   x3             x1   x2   x3
%                      ---------------------------------------
%                       23   45   15             277  230   63
%                       40   85   18             153   80   29
%                      215  307   60             306  440  105
%                      110  110   50             252  350  175
%                       65  105   24             143  205   42
%                      ---------------------------------------
%
%             Total data matrix must be:
%          X=[1 23 45 15;1 40 85 18;1 215 307 60;1 110 110 50;1 65 105 24;
%          2 277 230 63;2 153 80 29;2 306 440 105;2 252 350 175;2 143 205 42];
%
%             Calling on Matlab the function:
%                MBoxtest(X,0.05)
%
%             Answer is:
%
%  ------------------------------------------------------------
%       MBox         F           df1          df2          P
%  ------------------------------------------------------------
%     27.1622     2.6293          6           463       0.0162
%  ------------------------------------------------------------
%  Covariance matrices are significantly different.
%
%  Created by A. Trujillo-Ortiz and R. Hernandez-Walls
%             Facultad de Ciencias Marinas
%             Universidad Autonoma de Baja California
%             Apdo. Postal 453
%             Ensenada, Baja California
%             Mexico.
%             atrujo@uabc.mx
%             And the special collaboration of the post-graduate students of the 2002:2
%             Multivariate Statistics Course: Karel Castro-Morales, Alejandro Espinoza-Tenorio,
%             Andrea Guia-Ramirez, Raquel Muniz-Salazar, Jose Luis Sanchez-Osorio and
%             Roberto Carmona-Pina.
%  November 2002.
%
% Modifications by M. Murphy
%   2024-05-20: Remove `eval` statements. Add modern argument parsing.
%
%  To cite this file, this would be an appropriate format:
%  Trujillo-Ortiz, A., R. Hernandez-Walls, K. Castro-Morales, A. Espinoza-Tenorio, A. Guia-Ramirez
%    and R. Carmona-Pina. (2002). MBoxtest: Multivariate Statistical Testing for the Homogeneity of
%    Covariance Matrices by the Box's M. A MATLAB file. [WWW document]. URL http://www.mathworks.com/
%    matlabcentral/fileexchange/loadFile.do?objectId=2733&objectType=FILE
%
%  References:
%
%  Stevens, J. (1992), Applied Multivariate Statistics for Social Sciences. 2nd. ed.
%              New-Jersey:Lawrance Erlbaum Associates Publishers. pp. 260-269.

arguments
    X (:,:) double
    alpha (1,1) double {mustBeInRange(alpha,0,1)} = 0.05
    options.RandomSeed (1,1) {mustBeInteger} = 1234; % Ensures the same result when conditioning noise is added.
    options.ConditioningLevel (1,1) double = 1e-6; % Noise level should be lower than expected signals by a few orders of magnitude. Prevents negative determinant on pooled covariance matrix. Set this value to 0 if you want no conditioning noise added.
    options.PlotScatter (1,1) logical = true;
    options.ScatterEigenThreshold (1,1) {mustBeInRange(options.ScatterEigenThreshold,0,100)} = 75;
    options.Verbose (1,1) logical = true;
end
RandStream('threefry4x64_20','Seed',options.RandomSeed);

G = findgroups(X(:,1));
[N,c] = size(X);
p = c - 1;
X = X(:,2:c) + randn(N,c-1)*options.ConditioningLevel;
g = max(G); %Number of groups.

n = nan(1,g);
Xg = cell(1,g);
if options.PlotScatter
    fig = figure('Name', 'MBoxTest Scatter Plot','Color','w');
    ax = axes(fig,'NextPlot','add','FontName','Tahoma');
end
band=2;
for k = 1:g
    Xg{k}=X(G==k,2:end);
    n(k)=size(Xg{k},1);
    if options.PlotScatter
        [~,score,~,~,explained] = pca(Xg{k});
        if k == 1
            cs = cumsum(explained);
            eig1 = find(cs > options.ScatterEigenThreshold,1,'first');
            eig2 = eig1+1;

        end
        scatter(ax,score(:,eig1),score(:,eig2), ...
            'filled','MarkerEdgeColor','none','MarkerFaceAlpha',0.35,...
            'DisplayName',sprintf('Group-%d',k));
    end
    if n(k)>=20
        band=1;
    end
end
if options.PlotScatter
    legend(ax,'Location','eastoutside');
    xlabel(ax,sprintf("Eig-%d Projection",eig1),'FontName','Tahoma','Color','k');
    ylabel(ax,sprintf("Eig-%d Projection",eig2),'FontName','Tahoma',"Color",'k');
end

%Partition of the group covariance matrices.
S = cell(g,1);
for k=1:g
    % S{k} = cov(Xg{k});
    S{k} = (Xg{k}' * Xg{k}) ./ (n(k) - 1);
    % S{k} = Xg{k}' * Xg{k};
    % test = cov(Xg{k});
    % fprintf(1,'Frobenius norm Group-%d = %7.2f\n',k,norm(S{k},"fro")-norm(test,"fro"));
end 
S = cat(3,S{:});

deno=N-g;
% Sp = cov(X(:,2:end));
Sp = sum(pagemtimes(S,reshape(n-1,1,1,g)),3)./deno;

% Compute determinants
Sk_det = nan(1,g);
for k=1:g
    Sk_det(k) = det(S(:,:,k));
    if Sk_det < 0
        warning("Determinant of covariance for group %d is less than zero!", k);
    end
end
Sp_det = det(Sp);
if Sp_det < 0
    warning("Negative determinant (%11.1f) of pooled covariance.",det(Sp));
end

% % % Compute un-adjusted test statistic % % %
% M = (N - g)*log|S| - ∑(n_k - 1) * log|S_k|
MBox=deno*log(Sp_det) - sum(log(Sk_det).*(n-1));  %Box's M statistic.

sum_a=sum(1./(n(1:g)-1));
sum_b=sum(1./((n(1:g)-1).^2));
C=(((2*p^2)+(3*p)-1)/(6*(p+1)*(g-1)))*(sum_a-(1/deno));  %Computing of correction factor.
if band==1
    X2=MBox*(1-C);  %Chi-square approximation.
    v=(p*(p+1)*(g-1))/2;  %Degrees of freedom.
    P=1-chi2cdf(X2,v);  %Significance value associated to the observed Chi-square statistic.
    if options.Verbose
        disp(' ');
        fprintf('------------------------------------------------\n');
        disp('     MBox     Chi-sqr.         df          P')
        fprintf('------------------------------------------------\n');
        fprintf('%10.4f%11.4f%12.i%13.4f\n',MBox,X2,v,P);
        fprintf('------------------------------------------------\n');
        if P >= alpha
            disp('Covariance matrices are not significantly different.');
        else
            disp('Covariance matrices are significantly different.');
        end
    end
    stats = struct('MBox', MBox, 'X2', X2, 'df', v, 'p',  P);
    h0 = P >= alpha;
else
    %To obtain the F approximation we first define Co, which combined to the before C value
    %are used to estimate the denominator degrees of freedom (v2); resulting two possible cases.
    Co=(((p-1)*(p+2))/(6*(g-1)))*(sum_b-(1/(deno^2)));
    if Co-(C^2)>= 0
    	v1=(p*(p+1)*(g-1))/2;  %Numerator degrees of freedom.
        v21=fix((v1+2)/(Co-(C^2)));  %Denominator degrees of freedom.
        F1=MBox*((1-C-(v1/v21))/v1);  %F approximation.
        P1=1-fcdf(F1,v1,v21);  %Significance value associated to the observed F statistic.
        if options.Verbose
            disp(' ');
            fprintf('------------------------------------------------------------\n');
            disp('     MBox         F           df1          df2          P')
            fprintf('------------------------------------------------------------\n');
            fprintf('%10.4f%11.4f%11.i%14.i%13.4f\n',MBox,F1,v1,v21,P1);
            fprintf('------------------------------------------------------------\n');
            if P1 >= alpha
                disp('Covariance matrices are not significantly different.');
            else
                disp('Covariance matrices are significantly different.');
            end
        end
        stats = struct('MBox', MBox, 'F', F1, 'df1', v1, 'df2',v21, 'p',  P1);
        h0 = P1 >= alpha;
    else
        v1=(p*(p+1)*(g-1))/2;  %Numerator degrees of freedom.
        v22=fix((v1+2)/((C^2)-Co));  %Denominator degrees of freedom.
        b=v22/(1-C-(2/v22));
        F2=(v22*MBox)/(v1*(b-MBox));  %F approximation.
        P2=1-fcdf(F2,v1,v22);  %Significance value associated to the observed F statistic.
        if options.Verbose
            disp(' ');
            fprintf('------------------------------------------------------------\n');
            disp('     MBox         F           df1          df2          P')
            fprintf('------------------------------------------------------------\n');
            fprintf('%10.4f%11.4f%11.i%14.i%13.4f\n',MBox,F2,v1,v22,P2);
            fprintf('------------------------------------------------------------\n');
    
            if P2 >= alpha
                disp('Covariance matrices are not significantly different.');
            else
                disp('Covariance matrices are significantly different.');
            end
        end
        stats = struct('MBox', MBox, 'F', F2, 'df1', v1, 'df2',v22, 'p',  P2);
        h0 = P2 >= alpha;
    end
end
if options.PlotScatter
    if h0
        title(ax,sprintf("Same Covariance (p \\geq \\alpha=%0.4f)",alpha),'Color','b','FontName','Tahoma');
    else
        title(ax,sprintf("Different Covariance (p < \\alpha=%0.4f)",alpha),'FontName','Tahoma','Color','r');
    end
    subtitle(ax,sprintf('Min: %5.1f%% Variance Excluded',options.ScatterEigenThreshold),'FontName',"Tahoma",'Color',[0.65 0.65 0.65]);
end

end
