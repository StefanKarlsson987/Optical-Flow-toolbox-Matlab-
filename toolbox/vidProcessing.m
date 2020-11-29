% Authors: Stefan M. Karlsson, Josef Bigun 2014

function pathToSave = vidProcessing(in)
% Opens a figure and display the video together with whatever else
% information/visualization we request.
% Once finished viewing the results of the video processing,
% close the window to return back from the function. 
% vidProcessing();        - displays interactive synthesized video
% vidProcessing(in);      - contains various setting in the structure "in"

% "in" may contain the members described in the script "runMe.m".

%in addition to the uses in "runMe.m":

%%% Argument "lagTime"
%initial artificial lag time. make the renderings slower with higher values
% is set dynamically with keyboard interface during execution.
%in.lagTime = 0; 
                            
%%% Argument "camID"
% in.camID     = 1;        %(default 1) for "camera" select which camera
% NOTE: some systems have virtual cameras installed. Try to choose different
% values for camID, and see if you get better performance. 

%%% Argument "syntSettings"
% settings for the synthetic sequence
% in.syntSettings.spdFactor = [0, 0.5]; %initial motion %spdFactor(1): along 8-shape, 
                                                        %spdFactor(2): rotational
% in.syntSettings.spd        = 1/150;  %constant factor of speed of motion
% in.syntSettings.cen1       = 0.4;    %centre offsets of disks generated
% in.syntSettings.cW         = 0.3;    %radius of disks
% in.syntSettings.cFuz       = 1.5;    %fuzziness of the boundary of disks
% in.syntSettings.cdet       = 0.7;    %detail level of the interior pattern

% in.syntSettings.backWeight = 0;      %Strength of background edge pattern
% in.syntSettings.edgeTilt   = 0;      %initial tilt of background edge
% in.syntSettings.edgeTiltSpd= 0;      %speed of rotation of background edge 

% in.syntSettings.flickerWeight= 0;    %amount of flicker of the disks (in range [0,1])
% in.syntSettings.flickerFreq  = 0.3;  %frequency of flicker (in range (0,Inf])
% in.syntSettings.noiseWeight  = 0;    %signal-to-noise weight (in range [0,1])

%%%%%%%%% argument "flowRes"
%%% indicates resolution of the flow field can be either scalar(percentage of video 
%%% resolution), or 2D vector (absolute resolution). Examples:
% in.flowRes  = 0.15; 
% in.flowRes  = [25 40]; 

%%% Argument "sc"
%scale optical flow with this constant, for visualization only:
% in.sc = 8;  %(default)

%%% OUTPUT: pathToSave 
% full path to where saved data is stored

% ensure access to functions and scripts in the folder "helperFunctions"
addpath('helperFunctions');
if nargin > 0
    if nargin > 1 || ~isstruct(in)
        error('invalid input to VidProcessing. Only 1 (or zero) arguments accepted: a struct with relevant fields. See example in RunMe.m');
    end
elseif nargin == 0
    in = struct;
end
global g; %contains shared information, ugly solution, but fastest compared 
          %to sane solutions such as based on Matlab classes
          
% "Though this be madness, yet there is method in't" 
% I really wish I did not have to use the global workspace like this. 
% I tried using a nice class to embed vidProcessing, and found the
% performance went down. This performance drop is specific to Matlab classes
% (I was using Matlab 2011). After deciding that I would use the
%  global workspace this way, at least i want to do it as controlled as
% I can. There is only one variable on the global workspace, called "g". 
% I further do some checking that it really "belongs" to vidProcessing
% before starting the program. But dont be fooled by these pre-cautions:
% The use of the global workspace is still a dangerous, ugly solution.
% read more about this issue here:
% http://stackoverflow.com/questions/1693429/is-matlab-oop-slow-or-am-i-doing-something-wrong
persistent bKillGlob
if isempty(bKillGlob)
    bKillGlob = false;
end
if ~isempty(g) %if a previous 'g' exists...
    % ... check if it does not corresponds to the toolbox, 
    if ~isfield(g,'bQuittingRequested') || ~isfield(g,'kindOfMovie')
        %if it does not, then I dont dare to delete it, better exit
        error('There is a global variable "g" that was no created by me (is it important?). Please type "clear global g" before you run me again.');
    end
    %check to see that the previous run, has exited properly:
    if ~g.bQuittingRequested
        if ~bKillGlob
            bKillGlob = true;
            warning('A previous session has not finished correctly. Data from that session is available in global variable g. Run me again, and I will kill this data');
            pathToSave = [];
            return;
        end
    end
    %then i clear it and reinitialize it in the global workspace:
    g = [];
%     global g;
end

[g.in, g.vid] = ParseAndSetupScript(in); %script for parsing input and setup environment
% index variable for time:
g.t=g.in.startingTime;

%from this point on, we handle the video by the object 'vid'. This is how
%we get the first frame:
    [g.imPrev,g.U,g.V,g.in.supIm] = generateFrame(g.vid, g.t,g.kindOfMovie,g.spdFactor,g.arrowKey,g.in.syntSettings,g.in.flowRes);
     g.imNew = g.imPrev;
%     g.imNew       = generateFrame(g.vid, g.t,g.in.bFineScale,g.kindOfMovie,g.spdFactor,g.arrowKey);
%if we display groundtruth flow, initialize generateFrame with right
%resolution flow (can't happen for input other than synthetic:)
if g.in.bDisplayGT
    assert(g.vid.bUseCam == 0);
   g.U_GT = g.U;
   g.V_GT = g.V;
else
    g.U_GT =0;g.V_GT =0;
end
% different methods, different functions, get the first output:
switch g.in.method
    case 'nothing'
        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew);
    case 'gradient'
        [dx, dy, dt] = grad3D(g.imNew,g.imPrev);
        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew,dx,dy,dt);
    case 'edge'
        g.edgeIm = zeros(size(g.imNew),'single');
        g.edgeIm = DoEdgeStrength(g.in, g.imNew, g.imPrev,g.gamma,g.edgeIm);
        checkEdgeOutput(g.edgeIm); %sanity check of DoEdgeStrength function
        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew,g.edgeIm);
    case 'syntheticfull'
        g.U = zeros(size(g.imNew));        g.V = zeros(size(g.imNew));
        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew,g.U,g.V);
    case 'synthetic'
        g.U = ones(g.in.flowRes,'single'); g.V = ones(g.in.flowRes,'single');
        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew,g.U,g.V);        
    otherwise
        [g.U, g.V] = g.in.userDefMethod(g.in,g.imNew,g.imPrev);
        checkFlowOutput(g.U, g.V);%sanity check on flow
        if ~all(g.in.flowRes == size(g.U))
            warning(['specified flow resolution (flowRes): ' num2str(g.in.flowRes) ' does not match the output of function "' func2str(g.in.userDefMethod) '", Changing flow resolution to match']);
            g.in.flowRes = size(g.U);
            [~, g.U_GT,g.V_GT,g.in.supIm] = generateFrame(g.vid, g.t,g.kindOfMovie,g.spdFactor,g.arrowKey,g.in.syntSettings,g.in.flowRes);
        end

        [g.myHandles,g.pathToSave] = setupGraphicsScript(g.in,g.imNew,g.U,g.V);        
end

%set flowRes to size of output flow.
% g.in.flowRes = size(g.U);

% if g.vid.bUseCam == 1
%      start(g.vid.camIn);
%      pause(0.05);
% else
%     error('getting there, only implemented camera through matlab toolbox');
% end

in = g.in;
myHandles = g.myHandles;
    %Do first perform analysis and update graphics:
    switch in.method
        case 'gradient'
            [dx, dy, dt] = grad3D(g.imNew,g.imPrev);
            updateGraphicsScript(in,myHandles,g.imNew,dx,dy,dt);
        case 'edge'
            g.edgeIm = DoEdgeStrength(g.in, g.imNew, g.imPrev,g.gamma,g.edgeIm);
            updateGraphicsScript(in,myHandles,g.imNew,g.edgeIm);
        case 'nothing'
            updateGraphicsScript(in,myHandles,g.imNew); 
        case 'user'
            [g.U, g.V] = in.userDefMethod(in,g.imNew,g.imPrev,g.U, g.V);
            updateGraphicsScript(in,myHandles,g.imNew,g.U,g.V,g.U_GT,g.V_GT);
    end
drawnow %expose
start(g.timer1);
pathToSave = g.pathToSave;

