% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [in,vid]= ParseAndSetupScript(in)

% Parsing
% arguments are:
% MOVIETYPE - indicates source of video
% METHOD - indicates kind of analysis/visualization
% bFineScale,
% tIntegration, 
% camID, 
% vidRes,
% spdFactor, 
% lagTime, 
% bRecordFlow. 

%% movieType - indicates source of video
if ~isfield(in,'movieType'), in.movieType  = 'synthetic';  end

%% method - indicates kind of analysis/visualization
% error checking:
if isfield(in,'userDefMethod'), error('"userDefMethod" is for internal use only, cannot be set manually. Use the field "method", which can be set to a function handle'); end
if ~isfield(in,'method'), in.method = 'nothing'; end
if strcmp (in.method,'user'), error('dont specify method as "user". instead, set "method" to a function handle'); end
if strcmpi(in.method,'synthetic') || strcmpi(in.method,'syntheticFull')
    if ~strcmpi(in.movieType,'synthetic')
        warning('Groundtruth flow is only available for movietype = "synthetic"');
        in.method = 'nothing';
    end
end
%dummy handle, will only ever be used in functionName2string conversion
in.userDefMethod = @GroundTruthFlow; 
% the user may send a function handle as method...
if isa(in.method,'function_handle')
    %... then put "userDefMethod" to the handle
    in.userDefMethod = in.method;
    in.method = 'user';
end
in.method = lower(in.method);
if ~any(strcmp(in.method, ...
        {'user','gradient','edge','nothing','synthetic','syntheticfull'}))
    error(['method: ' in.method ' unrecognized option' ]);
end


%% tIntegration -  indicates amount of temporal integration
if ~isfield(in,'tIntegration'), in.tIntegration = 0; end
if (in.tIntegration >=1) || (in.tIntegration < 0)
    error('tIntegration must be in the interval [0,1)');
end
%% MaxIterations - amount of iterations for iterative solvers
if ~isfield(in,'MaxIterations'), in.MaxIterations = 25; end
if (in.MaxIterations >=1000) || (in.MaxIterations < 1)
    error('MaxIterations must be in the interval [1,1000]');
end

%% camID -  indicates ID of camera (if many connected, choose one)
if ~isfield(in,'camID'), in.camID = 1; end

%% syntSettings - settings for synthetic sequence generation
if ~isfield(in,'syntSettings'),            in.syntSettings= []; end
% syntSettings.spdFactor - spdFactor(1) speed along 8-shape, spdFactor(2) rotational
if ~isfield(in.syntSettings,'spdFactor'),  in.syntSettings.spdFactor = [0, 0.5]; end
if length(in.syntSettings.spdFactor) == 1
    in.syntSettings.spdFactor = [in.syntSettings.spdFactor, 0]; %if speed of rotation was not given, set zero
end
% syntSettings.spd - overall tuning of speed of animation
if ~isfield(in.syntSettings,'spd'),        in.syntSettings.spd=1/150; end
% syntSettings.cen1 - centre offsets of circles
if ~isfield(in.syntSettings,'cen1'),       in.syntSettings.cen1=0.4; end
% syntSettings.cW - radius of circles
if ~isfield(in.syntSettings,'cW'),         in.syntSettings.cW=0.3; end
% syntSettings.cFuz - fuzziness of the boundary
if ~isfield(in.syntSettings,'cFuz'),       in.syntSettings.cFuz=1.4; end
% syntSettings.cdet -detail of the interior pattern(frequency of sinusoids)
if ~isfield(in.syntSettings,'cdet'),       in.syntSettings.cdet=0.7; end
% syntSettings.backWeight -intensity of the global, background edge
if ~isfield(in.syntSettings,'backWeight'), in.syntSettings.backWeight=0; end
% syntSettings.edgeTilt - initial tilt angle for background edge
if ~isfield(in.syntSettings,'edgeTilt'),   in.syntSettings.edgeTilt=0; end
% syntSettings.edgeTiltSpd - speed of rotation for background edge
if ~isfield(in.syntSettings,'edgeTiltSpd'),in.syntSettings.edgeTiltSpd=0; end
% flickerWeight - amount of flicker (in range [0,1])
if ~isfield(in.syntSettings,'flickerWeight'), in.syntSettings.flickerWeight=0; end
% flickerFreq - frequency of flicker (in range (0,Inf])
if ~isfield(in.syntSettings,'flickerFreq'), in.syntSettings.flickerFreq=0.3; end
% noiseWeight - amount of noise (in range [0,1])
if ~isfield(in.syntSettings,'noiseWeight'), in.syntSettings.noiseWeight=0; end



%% lagTime - initial artificial lag time. make the renderings slower
if ~isfield(in,'lagTime'),in.lagTime = 0;end
in.lagTime = abs(in.lagTime(1)); %should be single positive

%% bRecordFlow - boolean to indicate saving the generated flow field
if ~isfield(in,'bRecordFlow'),in.bRecordFlow = 0;end
%%% bRecordFlow is only valid when flow is present(some 'methods' do not
%%% produce flow)
% if in.bRecordFlow && (sum(strcmpi(in.method,{'edge','gradient','nothing'})))
%     warning(['bRecordFlow is set but this is not supported for method: "' in.method '". Recording is disabled']);
%     in.bRecordFlow = 0;
% end

%%pathToSave - folder to save to. If set to '', automatic folder created if saving:
if (~isfield(in,'pathToSave')) || (in.bRecordFlow == 0) 
    in.pathToSave = '';
end
%%bAutoPlayWithPlayer - indicate whether to automatically play saved data
%%upon finishing the session
if (~isfield(in,'bAutoPlayWithPlayer'))
    in.bAutoPlayWithPlayer = 0;
end

%% rm - magnitude tuner for avoiding errors when saving flow
% We assume the magnitude of the flow never exceeds "in.rm"
% "rm" is only for storing the flow. It makes sure we can represent
% the flow using uint8 preciscion. This only has effect for when:
% in.bRecordFlow =1 AND in.method is a "flow method" (such as @FlowLK)
if ~isfield(in,'rm'),in.rm = 1;end
in.rm = single(in.rm); %just want it in single precision

%% sc - scale vectors for plotting:
% has no effect, except for the visualization
if ~isfield(in,'sc'),in.sc = 8; end

%% targetFramerate - frame rate for visualization only
if ~isfield(in,'targetFramerate'),
	in.targetFramerate = 25; 
end

%% vidRes - size of the video (for synthetic and camera input only)
%can be a vector as [width height]
if ~isfield(in,'vidRes'), in.vidRes = 128; end
if length(in.vidRes) == 1
    in.vidRes = [in.vidRes in.vidRes]; 
end

    

if ~isfield(in,'endingTime'), in.endingTime = Inf; end
if ~isnumeric(in.endingTime) %assume a string is given
    if ~strcmp(in.endingTime,'eof')
        error(['unrecognized string for in.endingTime: "' in.endingTime '". Only "eof" is allowed as string input for argument in.endingTime.' ]);
    end
end
if ~isfield(in,'startingTime'), in.startingTime = 1; end
if in.startingTime < 1,in.startingTime = 1; end

if ~isfield(in,'bDisplayGT'), in.bDisplayGT = 0; end
if in.bDisplayGT
    if ~strcmpi(in.movieType,'synthetic')
        warning('Cannot display ground truth flow, unless in.movietype = "synthetic",  Setting bDisplayGT = FALSE');
        in.bDisplayGT = 0;
    end
    if strcmpi(in.method,'synthetic') || strcmpi(in.method,'syntheticfull')
        warning('bDisplayGT argument was set to TRUE, even though the method was "synthetic". With synthetic method, you get the groundtruth ONLY. Setting bDisplayGT = FALSE');
        in.bDisplayGT = 0;
    end
end

if ~isfield(in,'gamma'), in.gamma = 1; end
if ~isnumeric(in.gamma) || in.gamma < 0 
    error('invalid setting "in.gamma"');
end

%% setup globals
global g;
g.bQuittingRequested = 0;
% g.bImaqRequiring = 0;
g.bUpdateText = 0;
g.kindOfMovie  = in.movieType; 
g.bAutoPlayWithPlayer = in.bAutoPlayWithPlayer;
if ~strcmpi(g.kindOfMovie,'synthetic') && ~strcmpi(g.kindOfMovie,'camera')
    if exist(in.movieType,'file') == 2
    	g.kindOfMovie  = 'file';
    elseif exist(in.movieType,'dir') == 7
        g.kindOfMovie  = 'folder';
        if strcmp(in.movieType,in.pathToSave) %if we save to same folder we are reading from
            error(['Indicated save position (folder: ' in.pathToSave ') is the same as the source of video input. Writing to the same location as you are reading from is not allowed.' ])
        end
    else
       error(['provided in.movieType: ' in.movieType ' invalid. No such file or folder']);
    end
else %if its not recorded data as video input, make sure in.endingTime is not "eof"
    if strcmp(in.endingTime,'eof')
        warning('in.endingTime is set to "eof", but movie input is not recorded data. Ignoring');
        in.endingTime = Inf;
    end
end

g.arrowKey  = [0,0];%will be controlled by keyboard
g.spdFactor = in.syntSettings.spdFactor; %will be controlled by keyboard
g.lagTime   = in.lagTime;%will be controlled by keyboard
g.bPause    = 0;%will be controlled by keyboard
g.method    = in.method;
g.gamma     = in.gamma;%will be controlled by keyboard
g.edgeUpper = 255;

%% Setup video:
[vid,in.vidRes(2),in.vidRes(1),nofFrames] =  myVidSetup(g.kindOfMovie,in.movieType,in.vidRes(2),in.vidRes(1),in.camID,in.startingTime,in.targetFramerate);
if strcmp(in.endingTime,'eof')
    in.endingTime = nofFrames;
end

%% Setup Timer:
g.timer1=timer('TimerFcn', @onFrameUpdate, 'StopFcn', @cleanUpScript, ... 
	'ErrorFcn', @onTimerError,...
    'Period',    round(1000/in.targetFramerate)/1000, ...
    'StartDelay',round(1000/in.targetFramerate)/1000, ...
    'ExecutionMode','fixedRate','BusyMode','drop','ObjectVisibility','off');

%% flowRes - the resolution of the optical flow. This affects the non-full
% versions (such as method='HS' but not method = 'HSFull')
if ~isfield(in,'flowRes'), in.flowRes = in.vidRes; end
if length(in.flowRes) == 1  
    in.flowRes = [in.flowRes in.flowRes];
end
if strcmpi(in.method,'syntheticFull')
    in.flowRes = in.vidRes;
end
if any(in.flowRes > in.vidRes)
    warning('resolution of the flow (in.flowRes) is larger than the video resolution. Setting flowRes to maximum');
    in.flowRes = in.vidRes;
end

if(in.flowRes(1)<1) %if less than 1, relative to video size
    in.flowRes = round(fliplr(in.vidRes).*in.flowRes); 
end

