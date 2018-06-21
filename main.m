function main(movement_com, camera_specs)
% restore all defaults and reset the NI DAQ board
disp('Initializing...')
daqreset
restoredefaultpath
addpath(genpath('.'));
clearvars -GLOBAL

if nargin < 1 || isempty(movement_com)
    movement_com = 'Com4';
end
if nargin < 2 || isempty(camera_specs)
   camera_specs = {'pulseTime',.005,...
     'activeHigh',true,...
     'portNumber',1,...
     'lineNumber',0};
end

% make sure to flush input from the desired port
s = serial(movement_com);
flushinput(s);
clear s;

experiment.camSystem = ImageAndMove();
experiment.camSystem.createSystemComponents(camera_specs{:});
experiment.camSystem.start();
fprintf('VrSystem initialized\n');

experiment.movementInterface = MovementInterface();
% Initialize RAW VELOCITY for recording direct optical sensor input
experiment.camSystem.rawVelocity = zeros(1,4);

global KEY_PRESSED % idea from https://www.mathworks.com/matlabcentral/answers/100980-how-do-i-write-a-loop-in-matlab-that-continues-until-the-user-presses-any-key
KEY_PRESSED =0;
set(gcf,'KeyPressFcn',@keypress);
experiment.movementInterface.start();


while ~KEY_PRESSED
    h = hat;
    experiment = moveStep(experiment);
    v = mvmt2msg(experiment);
    xyLeft = experiment.camSystem.rawVelocity(1,1:2);
    xyRight = experiment.camSystem.rawVelocity(1,3:4);
    notify(experiment.camSystem,'FrameAcquired',v)
    fprintf(' Left: %d %d \tRight: %d %d\n',xyLeft(1),xyLeft(2),xyRight(1),xyRight(2))
    h2 = hat;
    dt = h2-h;
    pause(0.05-dt);
end


notify(experiment.camSystem,'ExperimentStop')
saveDataFile(experiment.camSystem)
saveDataSet(experiment.camSystem)
delete(experiment.movementInterface)
clear

end

function keypress(obj,event)
    global KEY_PRESSED
    KEY_PRESSED = 1;
end
