function [filename, grid_gen, K_true, phi_true, sigma_true, K, sigma, Sigma, gen] = data_generation(gen)
% DATA_GENERATION is basically creating all the data required for a simulation.
% INPUT:
% GRID
%   * xmax:         length of the grid_gen of x [unit]
%   * ymax:         length of the grid_gen of y [unit]
%   * sx:          scale level. number of cell is 2^gen.scale.x(i)+1
%   * sy:          scale level. number of cell is 2^gen.scale.y(i)+1
% STRUCTURE
%   * method:       method of generation: 'fromRho', ''
%   * samp:         Method of sampling of K and g | 1: borehole, 2:random. For fromK or from Rho only
%   * samp_n:       Number of well or number of point
%   * covar:
%       * modele    covariance structure
%       * c
%   * mu            parameter of the first field.
%   * std
% RHO R2
%   * Rho.grid_gen.nx           = 300;
%   * Rho.grid_gen.ny           = 60; % log-spaced grid_gen.
%   * Rho.elec.spacing      = 2; % in grid_gen spacing unit.
%   * Rho.elec.config_max   = 6000; % number of configuration of electrode maximal
%   * Rho.method          = 'R2';
% OTHER
%   * plotit              = false;      % display graphic or not (you can still display later with |script_plot.m|)
%   * saveit              = true;       % save the generated file or not, this will be turn off if mehod Paolo or filename are selected
%   * name                = 'Small_range';
%   * seed                = 123456;
% OUTPUT:
%       - K_true:      	Hydraulic conductivity true field, matrix (grid_gen.nx x grid_gen.ny) (data or generated)
%       - rho_true:      	Electrical conductivity true field, matrix (grid_gen.nx x grid_gen.ny)  (data or from K_true)
%       - K:          	Hydraulic conductivity at some point, structure: location (K.x, K.y) of data (K.d) (sampled from K_true)
%       - g:          	Electrical conductivity at some point, structure: location (g.x, g.y) of data (g.d) (sampled from rho_true)
%       - G:          	Electrical conductivity measured grid_gen, matrix (G.nx x G.ny) of data (G.d) (ERT inverse)
%
% Author: Raphael Nussbaumer

%% * *INPUT CEHCKING*
assert(isfield(gen, 'xmax'))
assert(isfield(gen, 'ymax'))
assert(isfield(gen, 'nx'))
assert(isfield(gen, 'ny'))
if ~isfield(gen, 'method'); gen.method = 'Random'; end
if ~isfield(gen, 'samp'); gen.samp = 2; end
if ~isfield(gen, 'samp_n'); gen.samp_n = 1/100 * (2^gen.sx+1)*(2^gen.sy+1); end
if ~isfield(gen, 'mu'); gen.mu = 0; end
if ~isfield(gen, 'std'); gen.std = 1; end
% Other
if ~isfield(gen, 'plotit'); gen.plotit = 0; end
if ~isfield(gen, 'saveit'); gen.saveit = 1; end
if ~isfield(gen, 'name'); gen.name = ''; end
if ~isfield(gen, 'seed'); gen.seed = 'default'; end
if ~isfield(gen, 'plot'); gen.plot = true; end
tic

rng(gen.seed)

%% * 2. *construction of the grid_gen*

cell2vertex         = @(x) [x(1)-(x(2)-x(1))/2  x(1:end-1)+diff(x)/2  x(end)+(x(end)-x(end-1))/2];
vertex2cell         = @(x) x(1:end-1) + diff(x)/2; 

grid_gen.nx     = gen.nx;
grid_gen.ny     = gen.ny;
grid_gen.nxy    = grid_gen.nx*grid_gen.ny; % total number of cells

grid_gen.dx=gen.xmax/(grid_gen.nx);
grid_gen.dy=gen.ymax/(grid_gen.ny);

grid_gen.x_n    = linspace(0, gen.xmax, grid_gen.nx+1);
grid_gen.y_n    = linspace(0, gen.ymax, grid_gen.ny+1);

grid_gen.x= vertex2cell(grid_gen.x_n);% coordinate of cells center
grid_gen.y= vertex2cell(grid_gen.y_n);
grid_gen.xy=1:grid_gen.nxy;

[grid_gen.X, grid_gen.Y] = meshgrid(grid_gen.x,grid_gen.y); % matrix coordinate

%% * 2. *handle function for generating a fiel and all phsical relationship*

f_Heinz         = @(phi,a,b)    10.^(a *phi - b); % log_10(K) = 6.66 \phi - 4.97 + noise (Heinz et al., 2003)
f_Heinz_inv     = @(K)      (log10(K)+4.97)/ 6.66 ; % log_10(K) = 6.66 \phi - 4.97  + noise (Heinz et al., 2003)
f_Archie        = @(phi)    43*real(phi.^1.4);  % \sigma = \sigma_W \phi ^m  + noise (Archie, 1942) where sigma_W can go up to .075, 1.2<m<1.6
f_Archie_inv    = @(sigma)  (sigma/43).^(1/1.4) ;  % \sigma = \sigma_W \phi ^m  + noise (Archie, 1942)

f_Kozeny        = @(phi,d)  d^2/180*phi^3/(1-phi)^2;
f_Kozeny        = @(K,d)    roots([-d^2/180/K 1 -2 1]);
f_KC            = @(phi,d10) 9810/0.001002 * phi.^3./(1-phi).^2 .* d10^2/180; % Kozeny-Carman @20�C


%% * 3. *Generate field*
switch gen.method
    case 'Normal-Random'
        
        sigma_true  =  gen.mu + gen.std*fftma_perso(gen.covar, grid_gen);
        
        phi_true    = f_Archie_inv(sigma_true);
        K_true      = f_Heinz(phi_true,6.66,4.97);
        rho_true    = 1000./sigma_true;
        
    case 'Log-Random'
        sigma_true  =  10.^(gen.mu + gen.std*fftma_perso(gen.covar, grid_gen));
        
        phi_true    = f_Archie_inv(sigma_true);
        K_true      = f_Heinz(phi_true,6.66,4.97);
        rho_true    = 1000./sigma_true;
        
    case 'fromPhi'
        phi_true    = gen.mu + gen.std*fftma_perso(gen.covar, grid_gen);
        
        assert(all(phi_true(:)>0),'All phi_true are not greater than 0')
        % K_true      = f_Heinz(phi_true,6.66,4.97);
        %         K_true_2      = f_Heinz(phi_true,7,4.5);
        %         mask = fftma_perso(gen.covar, grid_gen);
        %         K_true =K_true_1;
        %         K_true(mask<0) = K_true_2(mask<0);
        sigma_true  = f_Archie(phi_true); % archie gives conductivity, I want resisitivitiy
        rho_true    = 1000./sigma_true;
        
    case 'fromLogPhi'
        phi_true    = exp(gen.mu + gen.std*fftma_perso(gen.covar, grid_gen));
        
        assert(all(phi_true(:)>0),'All phi_true are not greater than 0')
        % K_true      = f_Heinz(phi_true,6.66,4.97);
        %       K_true_2      = f_Heinz(phi_true,7,4.5);
        %       mask = fftma_perso(gen.covar, grid_gen);
        %       K_true =K_true_1;
        %       K_true(mask<0) = K_true_2(mask<0);
        sigma_true  = f_Archie(phi_true); % archie gives conductivity, I want resisitivitiy
        rho_true    = 1000./sigma_true;
        
    otherwise
        error('method not define.')
end

%% Sampling
sigma = sampling_pt(grid_gen,sigma_true,gen.samp,gen.samp_n);
% K    = sampling_pt(grid_gen,K_true,gen.samp,gen.samp_n);

% Plot
if gen.plotit
    sigma_true_t = (log(sigma_true) - mean(log(sigma_true(:)))) ./ std(log(sigma_true(:)));
    sigma_dt = (log(sigma.d) - mean(log(sigma_true(:)))) ./ std(log(sigma_true(:)));
    
    
    figure(1);clf; subplot(2,1,1); hold on;axis equal; title('Electrical Conductivity [mS/m]');xlabel('x [m]'); ylabel('y [m]')
    imagesc(grid_gen.x,grid_gen.y,sigma_true_t);colorbar;  scatter(sigma.x,sigma.y,sigma.d); legend({'Sampled location'})
    subplot(2,1,2); hold on; title('Histogram'); xlabel('Electrical Conductivity [mS/m]'); set(gca,'Ydir','reverse')
    ksdensity(sigma_true_t(:)); ksdensity(sigma_dt(:)); legend({'True','Sampled'})
    
    [gamma_x, gamma_y] = variogram_gridded_perso(sigma_true_t);
    figure(2); clf; subplot(2,1,1); hold on; title('Horizontal (x) Variogram')
    plot(grid_gen.x(1:end/2),gamma_x(1:end/2)./std(sigma_true_t(:))^2);
    % plot([gen.covar.modele(1,2) gen.covar.modele(1,2)],[0 1])
    plot(grid_gen.x(1:end/2),1-gen.covar.g(grid_gen.x(1:end/2)/gen.covar.range(2)),'linewidth',2)
    subplot(2,1,2); hold on; title('Vertical (y) Variogram')
    plot(grid_gen.y(1:end/2),gamma_y(1:end/2)./std(sigma_true_t(:))^2);
    % plot([gen.covar.modele(1,3) gen.covar.modele(1,3)],[0 1])
    plot(grid_gen.y(1:end/2),1-gen.covar.g(grid_gen.y(1:end/2)/gen.covar.range(1)),'linewidth',2)
    
    keyboard;close all; % try different initial data if wanted
end

%%
filepath       = 'data_gen/IO-file/';
mkdir(filepath);
delete([filepath '*']);

% Forward Grid
f                   = gen.f;
x_plus              = logspace(log10(grid_gen.x_n(end)-grid_gen.x_n(end-1)), log10(10*(grid_gen.x_n(end)-grid_gen.x_n(1))), f.n_plus);
% x_plus            = (x(2)-x(1)).* 1.3.^(1:n_plus);
y_plus              = logspace(log10(grid_gen.y_n(end)-grid_gen.y_n(end-1)), log10(10*(grid_gen.x_n(end)-grid_gen.x_n(1))), f.n_plus);
f.grid.x_n          = sort([grid_gen.x_n(1)-x_plus grid_gen.x_n grid_gen.x_n(end)+x_plus]); 
f.grid.y_n          = sort([grid_gen.y_n grid_gen.y_n(end)+y_plus]);
f.grid.x            = vertex2cell(f.grid.x_n); 
f.grid.y            = vertex2cell(f.grid.y_n); 
f.grid.inside       = false( numel(f.grid.y), numel(f.grid.x));
f.grid.inside( 1:end-f.n_plus, f.n_plus+1:end-f.n_plus) = true;

% Electrod config
elec                = gen.elec;
% [~,min_spacing]     = min(abs(grid_gen.x-elec.spacing));
% elec.spacing        = grid_gen.x(min_spacing);
elec.spacing        = round(elec.spacing/grid_gen.dx)*grid_gen.dx; % in meter
f.elec_spacing      = elec.spacing/grid_gen.dx; % in grid.x spacing.
f.elec_id           = f.n_plus+f.elec_spacing*(elec.bufzone)+1 : f.elec_spacing : numel(f.grid.x_n)-f.n_plus-elec.bufzone*f.elec_spacing;
elec.x              = f.grid.x_n(f.elec_id);
elec.n              = numel(elec.x);

% elec.config_max   = 3000;
elec.method         = 'dipole-dipole';
elec.depth_max      = ceil(elec.n*grid_gen.y(end)/grid_gen.x(end));
elec.selection      = 5; %1: k-mean, 2:iterative removal of the closest neighboohood 3:iterative removal of the averaged closest point 4:voronoi 5:random
elec                = config_elec(elec); % create the data configuration.

% Inverse Grid
i = gen.i;
tmp_des = 1:f.elec_spacing;
tmp_des = tmp_des(rem(f.elec_spacing,tmp_des)==0);
[~,tmp_id] = min( abs( tmp_des.*(elec.n+2*elec.bufzone-1) - i.grid.nx ) );
i.elec_spacing      = tmp_des(tmp_id);
i.grid.x_n          = grid_gen.x_n(1:f.elec_spacing/i.elec_spacing:end);
% 1. linear
% i.grid.y_n          = grid_gen.y_n(1:floor((grid_gen.ny-1)/(i.grid.ny-1)):end);
% 2. log? power?
% fun = @(a,r,n,s) a*(1-r^n)/(1-r) - s;
% fun2 = @(r) fun(2*diff(grid_gen.y_n(1:2)),r,gen.i.grid.ny,grid_gen.y_n(end)-grid_gen.y_n(1));
% r = fsolve(fun2,1.1);
% y_n_dy = diff(grid_gen.y_n(1:2))*r.^(0:gen.i.grid.ny);
% i.grid.y_n          = grid_gen.y_n(1)+cumsum([0 y_n_dy]);
% 3.log
% i.grid.y_n          = logspace(log10(grid_gen.y_n(1)+5),log10(grid_gen.y_n(end)+5),grid_gen.ny+1)-5; % cell center
% 4. r^2 y = a*ind^2 + b*ind + c;
tmp_x               = [1 1 ; i.grid.ny^2 i.grid.ny ] \ [grid_gen.dy;grid_gen.y_n(end)];
i.grid.y_n          = tmp_x(1)*(0:i.grid.ny).^2 + tmp_x(2)*(0:i.grid.ny);
x_plus              = logspace(log10(i.grid.x_n(end)-i.grid.x_n(end-1)), log10(10*(i.grid.x_n(end)-i.grid.x_n(1))), i.n_plus);
y_plus              = logspace(log10(i.grid.y_n(end)-i.grid.y_n(end-1)), log10(10*(i.grid.x_n(end)-i.grid.x_n(1))), i.n_plus);
i.grid.x_n          = sort([i.grid.x_n(1)-x_plus i.grid.x_n i.grid.x_n(end)+x_plus]); 
i.grid.y_n          = sort([i.grid.y_n i.grid.y_n(end)+y_plus]);
i.grid.x            = vertex2cell(i.grid.x_n); 
i.grid.y            = vertex2cell(i.grid.y_n);
i.elec_id           = find(sum(bsxfun(@eq,i.grid.x_n',elec.x),2))';
i.grid.inside       = false( numel(i.grid.y), numel(i.grid.x));
i.grid.inside( 1:end-i.n_plus, i.n_plus+1:end-i.n_plus) = true;

% Forward
f.header            = 'Forward';  % title of up to 80 characters
f.job_type          = 0;
f.filepath          = filepath;
f.readonly          = 0;
f.alpha_aniso       = gen.covar.range0(2)/gen.covar.range0(1);

% Rho value
% f                  = griddedInterpolant({grid.y,grid.x},rho_true,'nearest','nearest');
f.rho               = mean(rho_true(:))*ones( numel(f.grid.y), numel(f.grid.x));
f.rho(f.grid.inside)= rho_true; % f({grid_Rho.y,grid_Rho.x});
% f.filename        = 'gtrue.dat';
f.rho_min           = min(rho_true(:));
f.rho_avg           = mean(rho_true(:));
f.rho_max           = max(rho_true(:))*2;
f                   = Matlat2R2(f,elec); % write file and run forward modeling

% Add some error to the observation
i.a_wgt = 0;%0.01;
i.b_wgt = 0.02;%0.02;
% var(R) = (a_wgt*a_wgt) + (b_wgt*b_wgt) * (R*R)
f.output.resistancewitherror = i.a_wgt.*randn(numel(f.output.resistance),1) + (1+i.b_wgt*randn(numel(f.output.resistance),1)).*f.output.resistance;
%f.output.resistancewitherror(f.output.resistancewitherror>0) = -f.output.resistancewitherror(f.output.resistancewitherror>0);
%f.output.resistancewitherror(f.output.resistancewitherror<-10) = -10;

fid = fopen([f.filepath 'R2_forward.dat'],'r');
A = textscan(fid,'%f %f %f %f %f %f %f');fclose(fid);
A{end-1}(2:end) = f.output.resistancewitherror;
fid=fopen([f.filepath 'R2_forward.dat'],'w');
A2=[A{:}];
fprintf(fid,'%d\n',A2(1,1));
for u=2:size(A2,1)
    fprintf(fid,'%d %d %d %d %d %.10e %.5f\n',A2(u,:));
end
fclose(fid);


if 0==1
    figure(4); clf; hold on;
    [X,Y] = meshgrid(f.grid.x_n,f.grid.y_n);
    mesh(X,Y,0*X,'EdgeColor','b','facecolor','none')
    [X,Y] = meshgrid(i.grid.x_n,i.grid.y_n);
    mesh(X,Y,0*X,'EdgeColor','r','facecolor','none')
    [X,Y] = meshgrid(f.grid.x,f.grid.y);
    scatter(X(:),Y(:),'b')
    [X,Y] = meshgrid(i.grid.x,i.grid.y);
    scatter(X(:),Y(:),'r')
    plot(elec.x,f.grid.y_n(1),'xk')
    view(2); axis tight; set(gca,'Ydir','reverse');
end


% Inverse
i.header            = 'Inverse';  % title of up to 80 characters
i.job_type          = 1;
i.inverse_type      = 1; 
i.filepath          = filepath;
i.readonly          = 0;
i.alpha_aniso       = f.alpha_aniso;
i.tolerance         = 1;
i.rho_avg           = f.rho_avg;
i                   = Matlat2R2(i,elec);

%% Ouput Sigma
Sigma.d             = 1000./flipud(i.output.res);

if i.res_matrix ==  1 && any(~isnan(i.output.sen(:)))
    Sigma.sen       = 1000./flipud(i.output.sen);
elseif i.res_matrix ==  2 && any(~isnan(i.output.rad(:)))
    Sigma.rad       = flipud(i.output.rad);
elseif i.res_matrix ==  3 && any(~isnan(i.output.Res(:)))
    Sigma.res=i.output.Res;
%     Sigma.res(~i.output.inside,:)=[]; Sigma.res(:,~i.output.inside(:))=[];
%     Sigma.res_out=i.output.Res;
%     Sigma.res_out(~i.output.inside,:)=[]; Sigma.res_out(:,i.output.inside(:))=[];
%     Sigma.res_out = sum(Sigma.res_out,2);
end
rmpath data_gen/R2
Sigma.x = i.grid.x;
Sigma.y = i.grid.y;
[Sigma.X,Sigma.Y] = meshgrid(Sigma.x, Sigma.y);

gen.i           = i;
gen.f           = f;
gen.elec        = elec;

%% * 4.*SAVING*

if gen.saveit
    filename = ['data_gen/GEN-', gen.name ,'_', datestr(now,'yyyy-mm-dd_HH-MM'), '.mat'];
    save(filename, 'phi_true', 'sigma_true', 'Sigma','grid_gen', 'gen','-v7.3') %'sigma',
end

fprintf('  ->  finish in %g sec\n', toc)
end