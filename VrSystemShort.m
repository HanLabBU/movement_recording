classdef VrSystemShort < SubSystem
  
  
  
  properties % SETTINGS
	 maxFrameRate = 25
	 showRawMotion = true
	 showFramePeriod = false
  end
  properties % OBLIGATORY
	 experimentSyncObj
	 trialSyncObj
	 frameSyncObj
  end
  properties
	 autoSyncTrialTime
	 autoSyncTimerObj
	 distanceFromTarget
	 rewardPulseObj
	 startPulseObj
	 clockPulseObj
	 clkCounterName = 'ctr1'
	 clockRate = 25;
	 rewardCondition ='false';
	 punishPulseObj
	 eligible
  end
  properties (Hidden)
	 lastError
	 lastFrameAcquiredTime
  end
  
  events
	 ExperimentStart
	 ExperimentStop
	 NewTrial
	 NewStimulus
	 FrameAcquired
  end
  
  
  
  methods
	 function obj = VrSystemShort(varargin)
		if nargin > 1
		  for k = 1:2:length(varargin)
			 obj.(varargin{k}) = varargin{k+1};
		  end
		end
		obj.defineDefaults()
		obj.checkProperties()
		obj.updateExperimentName()
		obj.createSystemComponents()
	 end
	 function defineDefaults(obj)
		obj.defineDefaults@SubSystem;
		obj.default.autoSyncTrialTime = 60;
		obj.default.autoSaveFrequency = 1;
	 end
	 function checkProperties(obj)
		obj.checkProperties@SubSystem;
	 end
  end
  methods % Requiired by SubSystem
	 function createSystemComponents(obj)
		if isempty(obj.experimentSyncObj) || ~isvalid(obj.experimentSyncObj)
		  obj.experimentSyncObj = obj;
		end
		if isempty(obj.trialSyncObj) || ~isvalid(obj.trialSyncObj)
		  if logical(obj.autoSyncTrialTime)
			 % A
			 obj.autoSyncTimerObj = timer(...
				'ExecutionMode','fixedRate',...
				'BusyMode','queue',...
				'Period',obj.autoSyncTrialTime,...
				'StartFcn',@(src,evnt)autoSyncTimerFcn(obj,src,evnt),...
				'TimerFcn',@(src,evnt)autoSyncTimerFcn(obj,src,evnt));
		  end
		  obj.trialSyncObj = obj;
		end
		if isempty(obj.frameSyncObj)
		  obj.frameSyncObj = obj;
		end
		% SETUP OUTPUTS USING NI-DAQ SESSION INTERFACE
% 		if eval(obj.rewardCondition)
% 		  % REWARD-PULSE
% 		  obj.rewardPulseObj = NiPulseOutput(...
%              'type','analog',...
% 			 'pulseTime',3,...
% 			 'activeHigh',true,...
% 			 'aoNumber',1,...
%              'pulseVal',5);
%           obj.rewardPulseObj.setup();

		  obj.clockPulseObj = NiPulseOutput(...
			 'pulseTime',.005,...
			 'activeHigh',true,...
			 'portNumber',1,...
			 'lineNumber',0);
		  obj.clockPulseObj.setup();
       
		obj.frameSyncListener.Enabled = false;
	 end
	 function start(obj)
		obj.updateExperimentName()
		fprintf('STARTING VRSYSTEM:\n\tSession-Path: %s\n',...
		  obj.sessionPath);
		if ~isdir(obj.sessionPath)
		  mkdir(obj.sessionPath)
		end
		if isempty(obj.frameSyncListener)
		  warning('VrSystem:start:NoFrameSyncListener',...
			 'The Behavior-Control sysem is not connected to a camera, and will not record data every frame');
		else
		  obj.frameSyncListener.Enabled = true;
		end
% 		obj.trialStateListener.Enabled = true;
% 		obj.experimentStateListener.Enabled = true;
		obj.ready = true;
		fprintf('VrSystem ready... waiting for ExperimentStart event\n');
	 end
	 function trigger(obj)
		if ~isready(obj)
		  obj.start();
		end
        if ~isempty(obj.clockPulseObj)
            obj.clockPulseObj.startBackground();
        end
		obj.trialStateListener.Enabled = true;
		fprintf('Experiment Started\n');
		obj.experimentRunning = true;
		if ~isempty(obj.currentDataFileSet)
		  obj.currentDataFileSet = VrFile.empty(1,0);
		  obj.nDataFiles = 0;
		end
		if logical(obj.autoSyncTrialTime) && ~isempty(obj.autoSyncTimerObj)
		  start(obj.autoSyncTimerObj);
		  disp('autoSyncTimer started')
		end
		obj.startPulseObj.sendPulse();
	 end
	 function stop(obj)
        if ~isempty(obj.clockPulseObj)
            obj.clockPulseObj.stop();
        end
		if ~isempty(obj.frameSyncListener)
		  obj.frameSyncListener.Enabled = false;
		end
		obj.trialStateListener.Enabled = false;
		obj.experimentStateListener.Enabled = false;
		if obj.experimentRunning
		  obj.experimentRunning = false;
		  if ~isempty(obj.currentDataFile) ...
				&& isopen(obj.currentDataFile) ...
				&& ~issaved(obj.currentDataFile)
			 obj.saveDataFile;
			 obj.currentDataFile = VrFile.empty(1,0);
		  end
		  obj.saveDataSet();
		  obj.clearDataSet();
		  if logical(obj.autoSyncTrialTime) && ~isempty(obj.autoSyncTimerObj)
			 obj.autoSyncTimerObj.stop();
		  end
		  fprintf('Experiment Stopped\n');
		end
     end

	 function frameAcquiredFcn(obj,~,evnt)
		try
		   % NEW
		   if ~isempty(obj.lastFrameAcquiredTime)
			  timeSinceLastFrameStart = toc(obj.lastFrameAcquiredTime);
			  maxFramePeriod = 1/obj.maxFrameRate;
			  while timeSinceLastFrameStart < maxFramePeriod
				 timeSinceLastFrameStart = toc(obj.lastFrameAcquiredTime);
				 pause(min(.01, maxFramePeriod - timeSinceLastFrameStart))
			  end
		   end
		   
		   try
			  framePeriod = toc(obj.lastFrameAcquiredTime);
		   catch
			  framePeriod = inf;
		   end
		   
		   obj.lastFrameAcquiredTime = tic;
		   
		   
		  obj.framesAcquired = obj.framesAcquired + 1;
		  if ~isempty(obj.clockPulseObj)
			 obj.clockPulseObj.sendPulse()
		  end
		  if isempty(obj.currentDataFile)
			 % called on first frame
			 obj.currentDataFile = VrFile(...
				'rootPath',obj.currentDataSetPath,...
				'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
		  end

		  info.Time = evnt.Time;
		  data = evnt.RawVelocity;
		  addFrame2File(obj.currentDataFile,data,info);
		  
		  end
		  
		  if obj.showFramePeriod
			 fprintf(' \t FrameRate: %f\n', 1/framePeriod)
		  end
		  
     end
  end
  methods
      
      function trialStateChangeFcn(obj)
      end
      function experimentStateChangeFcn(obj)
      end
  end
  
  methods
	 function delete(obj)
		try
		  obj.saveDataSet();
		  delete(obj.clockPulseObj);
		  delete(obj.startPulseObj);
% 		  delete(obj.rewardPulseObj);
		catch me
		  disp(me.message)
		end
	 end
  end
  
end
