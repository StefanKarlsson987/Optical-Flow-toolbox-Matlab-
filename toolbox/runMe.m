% Copyright: Stefan  M. Karlsson, Josef Bigun 2015
clear in;
% This script sets up the call to the function 'vidProcessing'. 

%% argument 'movieType'
% The source of video to process. 
 in.movieType = 'synthetic';    % generate synthetic video. 
% in.movieType = 'lipVid.avi'; % assumes a file 'LipVid.avi' in current folder. 
                               % Variable framerate videos not supported
% in.movieType = 'GroundTruthData';  % A folder containing video previously saved with 
                               % the toolbox
% in.movieType =  'camera';     % assumes a camera available in the system. 
                               % if many cameras connected, use "in.camID" to choose 

%% argument 'method'     
%  optical flow or visualization method  %%%

% optical flow methods are referenced by function handles. For your own
% optical flow algorithm, implement it as a function and set a handle to
% it like this:

% in.method =  @FlowLK;      %Lucas and Kanade 
in.method =  @Flow1;       %Locally regularized and vectorized method
% in.method =  @FlowHS;      %Horn and Schunk, variational (global regularization)
% in.method =  'synthetic';  %Ground truth optical flow (synthetic sequence only)

%%% Options for 'method' that gives no flow:
% in.method = 'gradient';  %Displays the gradient values
% in.method = 'edge';      %Displays 2D edge detection by gradients
% in.method = 'nothing';   %generate only the video    

% the number of iterations performed for iterative algorithms
in.MaxIterations = 10;


%% Argument bRecordFlow
in.bRecordFlow = 1; %record the video (and flow if available)
%define a directory for saving (if no folder given, toolbox creates a new folder as "savedOutputX")
% in.pathToSave  = 'GroundTruthData'; 

% in.startingTime  = 50;
if in.bRecordFlow %if recording, put time limitation:
   in.endingTime  = 700;
end
% in.endingTime  = 'eof';
% in.endingTime = Inf;


%% Arguments vidRes and flowRes
% resolution of video and flow field [Height Width]:
in.vidRes  = [128 128];   %video resolution, does not affect file-input(avi or saved-folder)
in.flowRes = [24 24];     %flow resolution

%% argument 'tIntegration'  
% the amount of temporal integration. tIntegration should be in the 
% range [0,1). If tIntegration = 0, then no integration in time occurs. 
% in.tIntegration = 0.2;

% in.bDisplayGT  = 1; %display groundtruth flow, if available


%% Argument syntSettings 
%Use "in.syntSettings" to specify the contents of synthetic video.
%in.syntSettings.backWeight = 0.7;     %background edge
%in.syntSettings.edgeTiltSpd=-2*pi/10000; %speed of rotation of background edge
% in.syntSettings.noiseWeight = 0.2;    %signal to noise weight (in range [0,1])

% target framerate that video is to be rendered/processed:
in.targetFramerate = 20;
% indicate auto-play of recorded data from the session(happens after session is over):
in.bAutoPlayWithPlayer = 1;

%% DO THE CALL TO THE TOOLBOX(initiate the session):
pathToSave = vidProcessing(in);
% Either wait until in.endingTime is reached, or shutdown rendering
% window to stop the processing.

%%% you can view recorded data at any time in the future by:
% FancyFlowPlayer(pathToSave);

% NOTE 0.1: more examples of how to use the "in" structure to define
% arguments are found in remarks in "vidProcessing.m"

% NOTE 1: vidProcessing make use of the global workspace through a single
% global variable "g". 

% NOTE 2: with high res optical flow, there may be some quantization errors
% when saving. Flow is saved in 8 bit(for u and v each) preciscion only when 
% high res. Play around with the parameter:
% in.rm = 5; 
% rm is the upper bound of how high the output flow may be (for high res
% flow only). If you increase it, you loose quantization preciscion, but
% that may be preferrable from having your data be corrupted by truncation



