disp('Initializing...')
%     global CURRENT_EXPERIMENT_NAME

% Data recording interfaces
%     name = inputdlg('Name this experiment, please','Experiment Name',1,{'PIPE'});
daqreset
restoredefaultpath
addpath(genpath('.'));
clearvars -GLOBAL
%addpath(genpath('hanlabexperimentfinal'))
s = serial('Com4');
flushinput(s);
clear s;
vr.vrSystem = VrSystemShort();
vr.vrSystem.start();        % enables experiment and trial state listeners
%     vr.vrSystem.savePath = 'C:\DATA';
fprintf('VrSystem initialized\n');

% Movement interface
vr.movementInterface = VrMovementInterfaceShort();
%     vr.movementFunction = @moveBucklin;
vr.movementInterface.start();

% Initialize RAW VELOCITY for recording direct optical sensor input
vr.vrSystem.rawVelocity = zeros(5,4);
% Begin data-recording systems
fprintf('Sending ExperimentStart notification...\n');
notify(vr.vrSystem,'ExperimentStart');
assignin('base','vr',vr)
% try
while true
    h = hat;
    vr = moveMike(vr);
    v = vrMsgMike(vr);
    xyLeft = vr.vrSystem.rawVelocity(1,1:2);
	xyRight = vr.vrSystem.rawVelocity(1,3:4);
    notify(vr.vrSystem,'FrameAcquired',v)
	fprintf(' Left: %d %d \tRight: %d %d\n',xyLeft(1),xyLeft(2),xyRight(1),xyRight(2))
    h2 = hat;
    dt = h2-h;
    pause(0.05-dt);
end
% catch
notify(vr.vrSystem,'ExperimentStop')
saveDataFile(vr.vrSystem)
saveDataSet(vr.vrSystem)
delete(vr.movementInterface)
% end