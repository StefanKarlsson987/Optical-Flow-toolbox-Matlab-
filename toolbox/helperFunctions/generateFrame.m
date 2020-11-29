% Copyright: Stefan  M. Karlsson, Josef Bigun 2014
function [imNew, GT_motionU,GT_motionV, supportImage,bEof] = generateFrame(vid, t,kindOfMovie,spdFactor,arrowKey,inSyntSettings,flowResIn)
persistent iix iiy k prevT rotAn P0 inertia synt rotAnprev PtXprev PtYprev flowRes edgeTilt macroDat;
global g;
if nargin<4
    spdFactor = [1,0];end
if nargin<5
    arrowKey = [0,0];end
bEof = 0;
%%%%%%%%%%%  FILE READING %%%%%%%%%%
if strcmp(kindOfMovie,'file')
    if isa(vid,'VideoReader')
        bEof = t == vid.NumberOfFrames;
         %in this case we have absolute time "t", use to bounce the video:
        t=varyT(round(t),vid.NumberOfFrames);
        imNew = single(rgb2gray(read(vid, t)));
    else %computer vision toolbox videoreader:
        imNew = 250*step(vid);
    end
GT_motionU = 0;
GT_motionV = 0;
supportImage = 0;

%%%%%%%%%%%  FILE READING %%%%%%%%%%
elseif strcmp(kindOfMovie,'folder') 
    if isempty(macroDat)
        macroDat = vid;
    end
    if macroDat.bEOF %if we reach the end of recording ...
        [imNew, ~, ~, macroDat] = getSavedFlow(1); %... then start over...
    else
        [imNew, ~, ~, macroDat] = getSavedFlow(); %otherwise continue to the next frame
    end
    GT_motionU = 0;
GT_motionV = 0;
supportImage = 0;


%%%%%%%%%%%  GENERATE SYNTHETIC %%%%%%%%%%
elseif strcmpi(kindOfMovie,'synthetic') 
    if isempty(iix) || nargin >6
        flowRes  = flowResIn;
        synt      = inSyntSettings;
        [iix,iiy] = meshgrid(linspace(-1,1,vid.Width),linspace(-1,1,vid.Height));
        iix       = single(iix); iiy= single(iiy);
        rotAnprev = 0;
        PtXprev   = 0;
        PtYprev   = 0;
        
        k = 0; %local time;
        prevT = t-1;
        rotAn = 0;
        P0       = [0,0];
        inertia  = [0,0];
        edgeTilt      = synt.edgeTilt;      %initial tilt of the background edge 
    end
        spd  = synt.spd;               %constant factor to speed of motion of the patterns generated
        cen1 = synt.cen1;              %centre offsets of circles
        cW   = synt.cW;                %radius of circles
        cFuz = synt.cFuz;              %fuzziness of the boundary
        cdet = synt.cdet;              %detail of the interior pattern(frequency of sinusoids)
        backWeight    = synt.backWeight;    %intensity of the global, background edge
        edgeTiltSpd   = synt.edgeTiltSpd;   %speed of rotation for background edge
        flickerWeight = synt.flickerWeight; %amount of flicker (in range [0,1])
        flickerFreq   = synt.flickerFreq;   %frequency of flicker (in range (0,Inf])
        noiseWeight   = synt.noiseWeight;   %amount of noise (in range [0,1])
        


        k = k    +(t-prevT)*spdFactor(1)*spd; %local time
        % arrowKey = arrowKey + spdFactor(1)*[sin(pi*(k+0.5)*2)/2  -cos(pi*(k+0.5))]/10;
        rotAn = rotAn+(t-prevT)*spdFactor(2)*spd; %rotation angle update
        prevT = t;
        arrowKeySpd = 0.0035;
        inertia = (inertia-0.0002*P0.*sign(inertia))*0.988 +...
                   arrowKey*arrowKeySpd - P0*0.001;
        totInertia = sqrt(sum(inertia.^2));
        maxInertia = 0.045;
    if totInertia > maxInertia
        inertia = maxInertia*inertia/totInertia;
    end

    P0 = P0 + inertia;
    PtX = 0.9*sin(pi*(k+0.5)*2)/2 + P0(1); %"figure eight" path in x and y, 
    PtY =-0.9*cos(pi*(k+0.5)  )   + P0(2); %as function of local time
%  fprintf([' ' num2str(t)])
    %rotation and translation, composite transform:
    iX = cos(rotAn)*(iix+PtX) + sin(rotAn)*(iiy+PtY);
    iY = sin(rotAn)*(iix+PtX) - cos(rotAn)*(iiy+PtY);
    % generate the textured disks:
        imNew =128*(                           2*sig(cW^2-(iX-cen1).^2-(iY-cen1).^2, cFuz*cW/50)+... disk blank          
                         (1+cos((sqrt(iX.^2+iY.^2))*cdet*24*pi  + 1.2)  ).*sig(cW^2-(iX-cen1).^2-(iY+cen1).^2, cFuz*cW/50)+... disk vert lines
                         (1+cos((iY+iX)*cdet*17*pi + 6/20)).*sig(cW^2-(iX+cen1).^2-(iY-cen1).^2, cFuz*cW/50)+... disk horiz lines
     (1+cos(iY*cdet*15*pi).*cos(iX*cdet*15*pi)).*sig(cW^2-(iX+cen1).^2-(iY+cen1).^2, cFuz*cW/50));  %disk checkerboard

if nargout> 1
    cf = cW + cFuz/110; %width of support region grows as fuzziness goes up

    supportImage = (cf^2>(iX-cen1).^2+(iY-cen1).^2)+(cf^2>(iX-cen1).^2+(iY+cen1).^2)+ ...
                   (cf^2>(iX+cen1).^2+(iY-cen1).^2)+(cf^2>(iX+cen1).^2+(iY+cen1).^2);
% 	tmpBin = ((cW/3)^2>(iX-cen1).^2+(iY-cen1).^2);%+((cW/3)^2>(iX-cen1).^2+(iY+cen1).^2)+ ...
%              ((cW/3)^2>(iX+cen1).^2+(iY-cen1).^2)+((cW/3)^2>(iX+cen1).^2+(iY+cen1).^2);
%     if strcmpi(g.method,'synthetic')
        GT_motionU = (vid.Width/4)*(imresizeNN(supportImage.*((cos(rotAnprev-rotAn)-1)*(iix+PtX)+  sin(rotAnprev-rotAn)*(iiy+PtY)-PtX+PtXprev) ,flowRes));
        GT_motionV = -(vid.Height/4)*(imresizeNN(supportImage.*(sin(rotAnprev-rotAn)    *(iix+PtX) - ((cos(rotAnprev-rotAn)-1)*(iiy+PtY))+PtY-PtYprev),flowRes));
%     else %syntheticFull
%         GT_motionU = (vid.Width/2)*tmpBin.*((cos(rotAnprev-rotAn)-1)*(iix+PtX)+  sin(rotAnprev-rotAn)*(iiy+PtY)-PtX+PtXprev);
%         GT_motionV = -(vid.Height/2)*tmpBin.*(sin(rotAnprev-rotAn)    *(iix+PtX) - ((cos(rotAnprev-rotAn)-1)*(iiy+PtY))+PtY-PtYprev);
%     end
end
 
rotAnprev = rotAn;
PtXprev   = PtX;
PtYprev   = PtY;

if flickerWeight > 0
    imNew = (flickerWeight*(cos(t*flickerFreq)+1)/2+(1-flickerWeight))*imNew;
end

if backWeight > 0
  imNew = (imNew + backWeight*(250-imNew).*sig(cos(edgeTilt)*iix+sin(edgeTilt)*iiy,1/100)); %apply the background, with custom tilt
  edgeTilt = edgeTilt + edgeTiltSpd;
% newIm = (newIm + backWeight*(250-newIm).*(iix>0)); %apply the background, fixed with hard boundary
end
if noiseWeight > 0
    imNew = (1-noiseWeight)*imNew + noiseWeight*((rand(size(iix),'single'))*255);
end


%%%%%%%%%%%  CAMERA INPUT %%%%%%%%%%
else %if strcmpi(kindOfMovie,'camera')  
    if vid.bUseCam==2 %videoinput lib:
%         vi_is_frame_new(vid.camIn, vid.camID-1);
        imNew  = vi_get_pixelsProper(vid.camIn, vid.camID-1,vid.Height,vid.Width);
    else %image aqcuisition toolbox:
%         newIm = single(flipdim(squeeze(getsnapshot(vid.camIn)),2));%/256;
%         imNew = single(flipdim(getsnapshot(vid.camIn),2));%/256;
%         g.bImaqRequiring = 1;
%         trigger(vid.camIn);
%         imNew = single(imresizeNN(fliplr(getdata(vid.camIn,1)), [vid.Height,vid.Width])) ;%/256;
        imNew = single(imresizeNN(fliplr(getsnapshot(vid.camIn)), [vid.Height,vid.Width])) ;%/256;
%         g.bImaqRequiring = 0;
%         flushdata(vid.camIn);

%         getdata(vid.camIn,1,'uint8')
        
    end
    GT_motionU = 0;
    GT_motionV = 0;
    supportImage = 0;
end
