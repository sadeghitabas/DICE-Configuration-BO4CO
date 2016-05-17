% Authors: Pooyan Jamshidi (pooyan.jamshidi@gmail.com)
% The code is released under the FreeBSD License.
% Copyright (C) 2016 Pooyan Jamshidi, Imperial College London

% initilize the global variables
init();

% retrieve some settings
options=getmcruserdata('options');
domain=getmcruserdata('domain');
maxIter=getmcruserdata('exp_budget');
maxExp=getmcruserdata('maxExp');
nInit=getmcruserdata('initial_design');
save_folder=getmcruserdata('save_folder');
exp_name=getmcruserdata('exp_name');

expData = []; % init matrix saving experimental data

%% this is the analytical function we want to find it's minimum (a wrapper for the response function)
% domain represents the domain of the function

d = size(domain, 1); % dimension of the space

%% create the grid
%[xTest, xTestDiff, nTest, nTestPerDim] = makeGrid(xRange, nMinGridPoints);

%% initialize the prior
gps = covarianceKernelFactory(12, d);

%% initial samples from the Latin Hypercube design
% (this section should be genralized in a way to replace any DoE that gives initial design such as random, etc...)
maxIter=maxIter-nInit;
% this loop is only for replicating optimization loop to get a mean and CI for each optimization criteria
for exp=1:maxExp
    
    %obsX = lhsdesign(d, nInit)';
    obsX = lhsdesign4grid(d, nInit, domain);
    %obsX = unirnddesign4grid(d, nInit, domain);
    obsY = zeros(size(obsX, 1), 1);
    
    for k = 1:size(obsX, 1)
        obsY(k) = f(obsX(k, :));
    end
    
    %% Bayesian optimization loop (for locating minimizer)
    for k = 1:maxIter
        % every 10 sec check whether to stop or pause or continue running
        while 1
            switch getmcruserdata('mode')
                case 'running'
                    break
                case 'pause'
                    continue
                case 'stop'
                    exit
            end            
            pause(10);
        end
        % criterial to evaluate in order to find where to sample next
        [nextX, dummy1, xTest, m, s, z, ef,h,et] = boLCB(domain, obsX, obsY, gps);
        
        % evaluate at the suggested point
        nextY = f(nextX);
        
        % save the measurement pair and CIs
        obsX = [obsX; nextX];
        obsY = [obsY; nextY];
        
    end
    
    % saving the replication data
    expData=[expData obsX obsY];
end
%% update the config with what has been found
get_config();