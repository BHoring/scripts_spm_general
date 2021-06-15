% A somewhat intrusive function to "link" two SPM results open in different MATLAB instances. 
% Using sections, you can hook this up to your callbacks. Every coordinate change now writes 
% the new coordinates to a text file go between. To recall the coordinates from another SPM,
% apply the same callback, and either call SPMCorresponder('read'), or - as intended - use 
% this little SPM UI hack.
%
% Two CUSTOM EDITS in spm_mip_ui.m are required for this to work. Unless you know what you're 
% doing, don't.
%
% FIRST CUSTOM EDIT is in the section %-Create UIContextMenu for marker jumping, where you add this somewhere:
% uimenu(h,'Separator','on','Label','goto nearest corresponding voxel',... % CUSTOM
%     'CallBack',['spm_mip_ui(''Jump'',',...
%     'get(get(gcbo,''Parent''),''UserData''),''nrcorresp'');'],...
%     'Interruptible','off','BusyAction','Cancel','Enable',str);       

% SECOND CUSTOM EDIT is in the section case 'jump', where you add this somewhere as new loc case:
% case 'nrcorresp' % CUSTOM EDIT
%     str       = 'nearest corresponding voxel';
%     xyz = SPMCorresponder('read');
%     i = 1;
%     d         = sqrt(sum((oxyz-xyz).^2));
% 
% Version: 1.1
% Author: Björn Horing, bjoern.horing@gmail.com
% Date: 2021-06-15
%
% Version notes
% 1.1
% - function description, comments for Git; removed localized defaults

function varargout = SPMCorresponder(action)

    if ~nargin
        action = 'write';
    end

    hostName = char(getHostName(java.net.InetAddress.getLocalHost));
    switch hostName
        case 'yourPC'
            projectDir = 'yourProjectDirectory';

        otherwise
            error('Host %s not recognized.',hostName);
    end

    global st;
    if isempty(st)
        error('Please open sections first to instantiate callbacks!'); % You can make this as intrusive as you wish...
    end

    st.registry.hReg.UserData.CorrespFile = [projectDir filesep 'SPMCorresp.txt'];    
    
    switch lower(action)
        case 'write'
            st.callback = @WriteMe;
            WriteMe;
            
        case 'read'
            varargout{1} = ReadMe;
        
        otherwise
            fprintf('Case %s not recognized. Skipping SPMCorresponder (your loss!)...\n',action);
          
    end
    
    
function xyz = ReadMe

    global st;    
    
    fH = fopen(st.registry.hReg.UserData.CorrespFile,'r');   
    xyz = fscanf(fH,'%f'); % how this is complementary to WriteMe is BeyondMe
    fclose(fH);
    
        
function WriteMe

    global st;    

    fH = fopen(st.registry.hReg.UserData.CorrespFile,'w+');
    fprintf(fH,'%0.1f\n%0.1f\n%0.1f',st.centre);        
    fclose(fH);
   