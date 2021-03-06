function [Rest, t, k, parm] = SSA2P(y,x,prim,D,G,parm)
% Sequential Simulation of Areal-to-Point Kriging
tik.global = tic;
%% * *INPUT CEHCKING*
% This section of the code generates a valid parm structure based on the
% inputted parm. If some parm value haven't been input, this section will
% fill automatically with defautl value. This may not allowed be the best.

% Input Variable
[X, Y] = meshgrid(x, y);
nx=numel(x); ny=numel(y); nd=numel(D);

% Paramter settings
if ~isfield(parm, 'seed_path'),     parm.seed_path      = 'shuffle'; end
if ~isfield(parm, 'seed_U'),        parm.seed_U         = 'shuffle'; end
if ~isfield(parm, 'seed_search'),   parm.seed_U         = 'shuffle'; end
if ~isfield(parm, 'saveit'),        parm.saveit         = 0; end % bolean, save or not the result of simulation
if ~isfield(parm, 'name'),          parm.name           = ''; end % name use for saving file
if ~isfield(parm, 'n_real'),        parm.n_real         = 1; end

% Kriging parameter
parm.k.covar = kriginginitiaite(parm.k.covar);
if ~isfield(parm, 'k') || ~isfield(parm.k, 'method'),   parm.k.method = 'sbss'; end
if ~isfield(parm, 'k') || ~isfield(parm.k, 'lookup'),   parm.k.lookup = false; end
if ~isfield(parm, 'k') || ~isfield(parm.k, 'nb'),       parm.k.nb = 30; end

if ~isfield(parm, 'k') || ~isfield(parm.k, 'wradius')
    parm.k.wradius  = 3;
end
k = parm.k;

% Path
if ~isfield(parm, 'path'),          parm.path            = 'linear'; end
if ~isfield(parm, 'path_random'),   parm.path_random     = 1; end
if ~isfield(parm, 'mg'),            parm.mg              = 1; end

if ~isfield(parm, 'cstk_s') % cstk_s is the scale at which cst is switch on
    if ~isfield(parm, 'cstk'),      parm.cstk           = 1; end % constant path and kriging weight activated or not
    if parm.cstk
        parm.cstk_s = 0; % will never use cstk
    else
        parm.cstk_s = Inf; % will always use cstk
    end
end


%% 1. Creation of the grid an path


%% 2. Define Path
tik.path = tic;
Path = nan(ny,nx);
rng(parm.seed_path);
if parm.mg
   sx = 1:ceil(log(nx+1)/log(2));
   sy = 1:ceil(log(ny+1)/log(2));
   sn = max([numel(sy), numel(sx)]);
   nb = nan(sn,1);
   start = zeros(sn+1,1);
   dx = nan(sn,1); dy = nan(sn,1);
   path = nan(nx*ny,1);
   for i_scale = 1:sn
       dx(i_scale) = 2^(sn-sx(min(i_scale,end)));
       dy(i_scale) = 2^(sn-sy(min(i_scale,end)));
       [Y_s,X_s] = ndgrid(1:dy(i_scale):ny,1:dx(i_scale):nx); % matrix coordinate
       id = find(isnan(Path(:)) & ismember([Y(:) X(:)], [Y_s(:) X_s(:)], 'rows'));
       nb(i_scale) = numel(id);
       start(i_scale+1) = start(i_scale)+nb(i_scale);
       path( start(i_scale)+(1:nb(i_scale)) ) = id(randperm(nb(i_scale)));
       Path(path( start(i_scale)+(1:nb(i_scale)) )) = start(i_scale)+(1:nb(i_scale));
   end
else
   id=find(isnan(Path));
   path = id(randperm(numel(id)));
   Path(path) = 1:numel(id);
   dx=1; dy=1; nb = numel(id); start=[0 nb]; sn=1;
end

t.path = toc(tik.path);


%% 3. Initialization Spiral Search

% Initialize spiral search stuff which don't change
x = ceil( min(k.covar(1).range(1)*k.wradius, nx));
y = ceil( min(k.covar(1).range(2)*k.wradius, ny));
[ss_Y, ss_X] = ndgrid(-y:y, -x:x);% grid{i_scale} of searching windows
ss_dist = sqrt( (ss_X/k.covar(1).range(1)).^2 + (ss_Y/k.covar(1).range(2)).^2); % find distence
ss_id_1 = find(ss_dist <= k.wradius); % filter node behind radius.
rng(parm.seed_search);
ss_id_1 = ss_id_1(randperm(numel(ss_id_1)));
[~, ss_id_2] = sort(ss_dist(ss_id_1)); % sort according distence.
ss_X_s=ss_X(ss_id_1(ss_id_2)); % sort the axis
ss_Y_s=ss_Y(ss_id_1(ss_id_2));
ss_n=numel(ss_X_s); %number of possible neigh


if parm.mg
    ss_scale=sn*ones(size(ss_X));
    for i_scale = sn-1:-1:1
        x_s = [-fliplr(dx(i_scale):dx(i_scale):x(end)) 0 dx(i_scale):dx(i_scale):x(end)]+(x+1);
        y_s = [-fliplr(dy(i_scale):dy(i_scale):y(end)) 0 dy(i_scale):dy(i_scale):y(end)]+(y+1);
        ss_scale(y_s,x_s)=i_scale;
    end
    ss_scale_s = ss_scale(ss_id_1(ss_id_2));
else
    ss_scale_s = sn*ones(size(ss_id_2));
end

%% 3. Initialization Covariance Lookup Table
if k.lookup
    ss_Ca0 = zeros(ss_n,1);
    ss_Caa = zeros(ss_n);
    for i=1:numel(k.covar)
        a0_h = sqrt(sum(([ss_Y_s(:) ss_X_s(:)]*k.covar(i).cx).^2,2));
        ab_h = squareform(pdist([ss_Y_s ss_X_s]*k.covar(i).cx));
        
        ss_Ca0 = ss_Ca0 + kron(k.covar(i).g(a0_h), k.covar(i).c0);
        ss_Caa = ss_Caa + kron(k.covar(i).g(ab_h), k.covar(i).c0);
    end
end
% Transform ss.Caa sparse?


%% Secondary variable



%% 3. Simulation
tik.weight = tic;
NEIGH_P = nan(nx*ny,k.nb);
NEIGH_S = nan(nx*ny,k.nb);
LAMBDA_P = nan(nx*ny,k.nb);
LAMBDA_S = nan(nx*ny,k.nb);
S = nan(nx*ny,1);

k_nb = k.nb;
k_covar_c0 = sum([k.covar.c0]);
XY_i=[Y(path) X(path)];

for i_scale = 1:sn
    ss_id = find(ss_scale_s<=i_scale);
    ss_XY_s = [ss_Y_s(ss_id) ss_X_s(ss_id)];
    if k.lookup
        ss_Ca0_s = ss_Ca0(ss_id);
        ss_Caa_s = ss_Caa(ss_id,ss_id);
    end
    
    for i_pt = start(i_scale)+(1:nb(i_scale))

        % Prim Neigh
        n=0;
        neigh=nan(k_nb,1);
        NEIGH_1 = nan(k.nb,1);
        NEIGH_2 = nan(k.nb,1);
        for nn = 2:size(ss_XY_s,1) % 1 is the point itself... therefore unknown
            ijt = XY_i(i_pt,:) + ss_XY_s(nn,:);
            if ijt(1)>0 && ijt(2)>0 && ijt(1)<=ny && ijt(2)<=nx
                if Path(ijt(1),ijt(2)) < i_pt % check if it,jt exist
                    n=n+1;
                    neigh(n) = nn;
                    NEIGH_1(n) = ijt(1);
                    NEIGH_2(n) = ijt(2);
                    if n >= k_nb
                        break;
                    end
                end
            end
        end
        
        if n==0
            S(i_pt) = k_covar_c0;
            Ca0 = [];
            Caa = [];
        else
            % Prim
            NEIGH_P(i_pt,:) = NEIGH_1 + (NEIGH_2-1)* ny;
            if k.lookup
                Ca0 = ss_Ca0_s(neigh(1:n));
                Caa = ss_Caa_s(neigh(1:n), neigh(1:n));
            else
                d = pdist([0 0; ss_XY_s(neigh(1:n),:)]*k.covar.cx);
                C = k.covar.g(d);
                if n==1
                    Ca0 = C;
                    Caa = 1;
                else
                    Ca0 = C(1:n)';
                    % Equivalent to : squareform(C(n+1:end));
                    Caa = diag(ones(n,1))*0.5;
                    Caa(tril(true(n),-1)) = C(n+1:end);
                    Caa = Caa + Caa';
                end
            end
        end
        
        
        
        % Sec
        G_id_s = G(:,path(i_pt))>0; %all sec contributing to sim pt
        G_id_s(any(G(:,NEIGH_P(i_pt,1:n))>0,2))=true;
        n_s = sum(G_id_s);
        G_id_z = any(G(G_id_s,:)>0,1)'; %all prim contributing to sec
        G_id_z(NEIGH_P(i_pt,1:n)) = true;
        % n_z = sum(G_id_z);
        
        z = [Y(G_id_z) X(G_id_z)];
        hz=squareform(pdist(z*k.covar.cx));
        Cz = kron(k.covar.g(hz),k.covar.c0);
        
        Czd = Cz * G(G_id_s, G_id_z)';
        Cd = G(G_id_s, G_id_z) * Czd;
        
        % C0d = kron(k.covar.g(0), k.covar.c0) * G(G_id_s,path(i_pt))';
        C0d = Czd(z(:,1)==Y(path(i_pt)) & z(:,2)==X(path(i_pt)),:)';

        % Cad = Caa * G(G_id_s,NEIGH_P(i_pt,1:n))';
        Cad=nan(n,n_s);
        for i=1:n
            Cad(i,:) = Czd(z(:,1)==NEIGH_1(i) & z(:,2)==NEIGH_2(i),:)';
        end
        
        NEIGH_S(i_pt,1:n_s) = find(G_id_s);


        l = [ Cd Cad' ; Cad Caa ] \ [ C0d ; Ca0 ];
        % l = [ Cd Czd(NEIGH_P(i_pt,1:n))' ; Czd(NEIGH_P(i_pt,1:n)) Caa ] \ [ C0d ; Ca0 ];
        LAMBDA_S(i_pt,1:n_s) = l(1:n_s);
        LAMBDA_P(i_pt,1:n) = l(n_s+1:end);
        S(i_pt) = k_covar_c0 - l'*[ C0d ; Ca0 ];
    end
    disp(['scale: ' num2str(i_scale) '/' num2str(sn)])
end
t.weight = toc(tik.weight);


if parm.saveit
    filename=['result-SGS/SIM-', parm.name ,'_', datestr(now,'yyyy-mm-dd_HH-MM-SS'), '.mat'];
    mkdir('result-SGS/')
    save(filename, 'parm', 'nx','ny','start','nb', 'path', 'sn', 'k','NEIGH','S','LAMBDA')
end

%% Realization loop

tik.real = tic;
Rest = nan(ny,nx,parm.n_real);
parm_seed_U = parm.seed_U;

for i_real=1:parm.n_real
    Res=nan(ny,nx);
    rng(parm_seed_U);
    U=randn(ny,nx);
    for i_scale = 1:sn
        for i_pt = start(i_scale)+(1:nb(i_scale))
            n = ~isnan(NEIGH_P(i_pt,:));
            n_s = ~isnan(NEIGH_S(i_pt,:));
            Res(path(i_pt)) = LAMBDA_P(i_pt,n)*Res(NEIGH_P(i_pt,n))' + LAMBDA_S(i_pt,n_s)*D(NEIGH_S(i_pt,n_s))' + U(i_pt)*S(i_pt);

%             figure(1); clf;
%             subplot(1,2,1); hold on;
%             imagesc(Res); 
%             % plot(XY_i(NEIGH_P(i_pt,n),2), XY_i(NEIGH_P(i_pt,n),1),'xk')
%             caxis([-3 3]); axis equal tight
%             
%             subplot(1,2,2);
%             imagesc(D); caxis([-3 3]); axis equal tight
%             if (Res(path(i_pt))>3)
%                 keyboard
%             end
        end
    end
    
    Rest(:,:,i_real) = Res;
end

if parm.saveit
    filename=['result-SGS/SIM-', parm.name ,'_', datestr(now,'yyyy-mm-dd_HH-MM-SS'), '.mat'];
    mkdir('result-SGS/')
    save(filename, 'parm','nx','ny', 'Rest', 't', 'k','U')
end

t.real = toc(tik.real);
t.global = toc(tik.global);
end
