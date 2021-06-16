% To get a grasp on the distributions of parametric modulators entering second level analyses,
% this function compiles pmods from the respective first level. 
%
% [T,TRes] = GetPModDistributions(anaPath_L2)
% anaPath_L2    - path to second level SPM, expects the first levels to be available at SPM.xY.P.
%
% out
% T             - table with all desired parameters (e.g. min, max, mean, std)
% TRes          - table with the mean of all desired parameters
%
% [T,TRes] = GetPModDistributions(baseDir,anaName,allSbs) % may require some fiddling in GetL1Synthesize subfunction 
%                                                    according to project folder structure
% baseDir       - path to root folder of first level results (i.e. one above subject folder)
% anaName       - name of your analysis in subject folder
% allSbs        - list of all subjects to be looped 
%
% out
% T             - table with all desired parameters (e.g. min, max, mean, std)
% TRes          - table with the mean of all desired parameters
%
% Version: 1.1
% Author: Björn Horing, bjoern.horing@gmail.com
% Date: 2021-06-16
%
% Version notes
% 1.1
% - function description, comments for Git; removed localized defaults

function [T,TRes] = GetPModDistributions(varargin)

    % some hardcoded stuff, don't want to overburden the varargin here...
    NR = 1; % index of the regressor of interest
    NP = 'all'; % index of the pmods of interest, or 'all'
    sbRE = '(?<=[\\\/]sub)\d{3}(?=[\\\/])'; % regular expression to identify subjects; if left empty, will use consecutive number for subject id entry
    
    if nargin==1
        anaPath_L1 = GetL1FromL2(varargin{1}); % top-down
    elseif nargin==3
        anaPath_L1 = GetL1Synthesize(varargin{1},varargin{2},varargin{3}); % bottom-up
    end

    T = table(NaN,NaN,{''});
    T.Properties.VariableNames = {'NSb','SbId','Path'}; % some default vars so we know who we're talking about
    
    warning('off'); % suppress partial row warning
    for a = 1:numel(anaPath_L1) % loop first level SPMs
        anaPath = [anaPath_L1{a} filesep 'SPM.mat'];
        
        clear SPM; % can't hurt
        
        fprintf('Processing %s... ',anaPath);
        load(anaPath); % load new SPM
        
        T.NSb(a) = a;
        if ~isempty(sbRE)
            T.SbId(a) = str2double(cell2mat(regexp(anaPath,sbRE,'MATCH'))); % get proper ID if possible
        end
        T.Path{a} = anaPath;
        
        if isnumeric(NP) % which pmod subselection do you want?
            pRange = NP;
        elseif strcmp(NP,'all') % ... or should I just get all there are?
            pRange = 1:numel(SPM.Sess.U(NR).P);
        end
        
        for p = pRange
            cP = SPM.Sess.U(1).P(p); % current pmod
            cN = regexprep(cP.name,{'\-','\+','\*'},{'minus','plus','X'}); % obtain valid column name
            T.(['min_' cN])(a)   = min(cP.P);
            T.(['max_' cN])(a)   = max(cP.P);
            T.(['m_' cN])(a)     = mean(cP.P);
            T.(['sd_' cN])(a)    = std(cP.P);
            % ... 
        end
        
        fprintf('done.\n');
    end
    warning('on');   
    
    TRes = table(T.Properties.VariableNames(4:end)',mean(T{:,4:end})');
    TRes.Properties.VariableNames = {'ParameterName','Mean'};

    
function anaPath_L1 = GetL1FromL2(anaPath_L2) % obtain L1 paths top-down through L2 analysis (lazy!)

    anaPath_L1 = {};

    if isempty(regexp(anaPath_L2,'SPM\.mat$','ONCE'))
        load([anaPath_L2 filesep 'SPM.mat']);
    else
        load(anaPath_L2);
    end
    
    anaPath_L1 = unique(cellfun(@fileparts,SPM.xY.P,'UniformOutput',false));
    
    
function anaPath_L1 = GetL1Synthesize(baseDir,anaName,allSbs) % obtain L1 paths bottom-up by synthesizing them from your folder systematics
    anaPath_L1 = {};

    for s = 1:numel(allSbs)
        anaPath_L1{s,1} = sprintf('%s%ssub03d%s%s',baseDir,filesep,allSbs(s),filesep,anaName);    
    end
