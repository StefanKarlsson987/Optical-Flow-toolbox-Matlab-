
%%%%CALLBACK FUNCTION FOR KEYBOARD PRESS %%%%%
function myKeypress(~,evnt)
    global g;
    g.bUpdateText = 1;
    switch evnt.Key,
   	  case 'r'
          g.gamma = g.gamma + 0.05;
      case 'f'
          g.gamma = max(0,g.gamma - 0.05);
      case 'q'
          g.lagTime = g.lagTime + 0.02;
      case 'a'
          g.lagTime = max(0,g.lagTime - 0.02);
      case 'w'
          g.spdFactor(1) = g.spdFactor(1) + 0.5;
      case 's'
          g.spdFactor(1) = max(0,g.spdFactor(1) - 0.5);
      case {'e', 'pagedown'}
          g.spdFactor(2) = g.spdFactor(2) + 0.5;
      case {'d','pageup'}
          g.spdFactor(2) = g.spdFactor(2) - 0.5;
      case 'uparrow'
          g.arrowKey(2) = 1; 
          g.bUpdateText = 0;
      case 'downarrow'
          g.arrowKey(2) = -1;
          g.bUpdateText = 0;
      case 'rightarrow'
          g.arrowKey(1) = -1;
          g.bUpdateText = 0;
	  case 'leftarrow'
          g.arrowKey(1) = 1;
          g.bUpdateText = 0;
	  case {'p','space'}
          %only handle this event if "onFrameUpdate" finished handling
          %previous pause event. g.Pause will be set AND the timer will be
          %stopped when handling the pause event is done.
        if ~(g.bPause && strcmpi(g.timer1.Running,'on'))
           g.bPause = ~g.bPause;
           g.bUpdateText = 1;
            if ~g.bPause && strcmpi(g.timer1.Running,'off')
                start(g.timer1);
            end
        end          
      otherwise
          g.bUpdateText = 0;
%             disp(['Currently no binding for: ' evnt.Key]);
    end
    
end

    
    
    
    
    
    
    
    
    
    