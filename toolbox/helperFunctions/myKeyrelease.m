
%%%%CALLBACK FUNCTION FOR KEYBOARD RELEASE %%%%%
function myKeyrelease(~,evnt)
    global g;
    switch evnt.Key,
      case 'uparrow'
          g.arrowKey(2) = 0;          
      case 'downarrow'
          g.arrowKey(2) = 0;
      case 'rightarrow'
          g.arrowKey(1) = 0;
	  case 'leftarrow'
          g.arrowKey(1) = 0;
    end
    

      