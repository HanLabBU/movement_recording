function main(movement_com, camera_specs, frame_rate) % ttl_controls)
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
if nargin < 3 || isempty(frame_rate)
   frame_rate = 0.04; %Hz
end

% make sure to flush input from the desired port
s = serial(movement_com);
flushinput(s);
clear s;

% initialize escape routine
global KEY_PRESSED % idea from https://www.mathworks.com/matlabcentral/answers/100980-how-do-i-write-a-loop-in-matlab-that-continues-until-the-user-presses-any-key
KEY_PRESSED = 0;
set(gcf,'KeyPressFcn',@keypress);

%Initialize Camera
experiment.camSystem = ImageAndMove();
experiment.camSystem.createSystemComponents(camera_specs{:});
if ~isempty(ttl_controls)
    for n=1:numel(ttl_controls)
        experiment.(sprintf('ttl%d',n)) = NiPulseOutput(ttl_controls{n}{:});
        experiment.(sprintf('ttl%d',n)).setup();
    end
end
experiment.camSystem.start();
fprintf('Camera System initialized\n');

% Initialize Movement
experiment.movementInterface = MovementInterface(movement_com);
experiment.camSystem.rawVelocity = zeros(1,4);
experiment.movementInterface.start();

orig_time = hat;
while ~KEY_PRESSED
    h = hat;
    experiment = moveStep(experiment);
    v = mvmt2msg(experiment);
    xyLeft = experiment.camSystem.rawVelocity(1,1:2);
    xyRight = experiment.camSystem.rawVelocity(1,3:4);
    notify(experiment.camSystem,'FrameAcquired',v)
    % for n=1:numel(ttl_controls)
    %   notify(experiment.(sprintf('ttl%d',n)),'FrameAcquired');
    % end
    fprintf(' Left: %d %d \tRight: %d %d\n',xyLeft(1),xyLeft(2),xyRight(1),xyRight(2))
    h2 = hat;
    dt = h2-h;
    pause(frame_rate-dt);
end


notify(experiment.camSystem,'ExperimentStop')
saveDataFile(experiment.camSystem)
saveDataSet(experiment.camSystem)
delete(experiment.movementInterface)
clear

end

function keypress(~,~)
    global KEY_PRESSED
    KEY_PRESSED = 1;
end
