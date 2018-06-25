classdef ImageMoveTrial < SubSystem
  
  

  properties % OBLIGATORY
	 experimentSyncObj
	 trialSyncObj
	 frameSyncObj
  end
  properties
 	 clockPulseObj
     trialPulseObj
     rawVelocity
     time
     maxFrameRate = 25;
  end
  properties (Hidden)
	 lastFrameAcquiredTime
  end
  
  events
	 ExperimentStart
	 ExperimentStop
	 FrameAcquired
  end
  
  
  
  methods
	 function obj = ImageMoveTrial(varargin)
		if nargin > 1
		  for k = 1:2:length(varargin)
			 obj.(varargin{k}) = varargin{k+1};
		  end
		end
		obj.defineDefaults()
		obj.checkProperties()
		obj.updateExperimentName()
	 end
	 function defineDefaults(obj)
		obj.defineDefaults@SubSystem;
	 end
	 function checkProperties(obj)
        obj.savedDataFiles = DataFile.empty(1,0);
		obj.currentDataFileSet = DataFile.empty(1,0);
		obj.checkProperties@SubSystem;
	 end
  end
    methods % Required by SubSystem
        function createSystemComponents(obj,clockSpecs, trialSpecs)
            if isempty(obj.frameSyncObj)
              obj.frameSyncObj = obj;
            end
            if isempty(obj.experimentSyncObj)
               obj.experimentSyncObj = obj; 
            end
            if isempty(obj.trialSyncObj)
               obj.trialSyncObj; 
            end
            if nargin < 2 || isempty(clockSpecs)
              obj.clockPulseObj = NiPulseOutput(...
                 'pulseTime',0.005,...
                 'activeHigh',true,...
                 'portNumber',1,...
                 'lineNumber',0);
              obj.clockPulseObj.setup();
            else
                obj.clockPulseObj = NiPulseOutput(clockSpecs{:});
                obj.clockPulseObj.setup();
            end

            if nargin < 3 || isempty(trialSpecs)
                obj.trialPulseObj = NiPulseOutput(...
                    'pulseTime',0.005,...
                    'activeHigh',true,...
                    'portNumber',1,...
                    'lineNumber',1);
                obj.trialPulseObj.setup();
            else
                obj.trialPulseObj = NiPulseOutput(trialSpecs{:});
                obj.trialPulseObj.setup();
            end
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
		obj.experimentStateListener.Enabled = true;
		obj.ready = true;
     end
	 function stop(obj)
        if ~isempty(obj.clockPulseObj)
            obj.clockPulseObj.stop();
        end
        if ~isempty(obj.trialPulseObj)
            obj.trialPulseObj.stop();
        end
        
		if obj.experimentRunning
		  obj.experimentRunning = false;
		  if ~isempty(obj.currentDataFile) ...
				&& isopen(obj.currentDataFile) ...
				&& ~issaved(obj.currentDataFile)
			 obj.saveDataFile;
			 obj.currentDataFile = DataFile.empty(1,0);
		  end
		  obj.saveDataSet();
		  obj.clearDataSet();
		  fprintf('Experiment Stopped\n');
		end
     end
	 function experimentStateChangeFcn(obj,~,evnt)
		fprintf('VrSystem: Received ExperimentStateChange event\n')
		switch evnt.EventName
		  case 'ExperimentStart'
			 if ~obj.experimentRunning
				obj.updateExperimentName();
                obj.start()
			 end
		  case 'ExperimentStop'
			 obj.stop();
		end
	 end
     
	 function frameAcquiredFcn(obj,~,evnt)
 		   if ~isempty(obj.lastFrameAcquiredTime)
			  maxFramePeriod = 1/obj.maxFrameRate;
              timeSinceLastFrameStart = toc(obj.lastFrameAcquiredTime);
              pause(maxFramePeriod - timeSinceLastFrameStart)
           end
		   
		   obj.lastFrameAcquiredTime = tic;
		   
		  obj.framesAcquired = obj.framesAcquired + 1;
		  if ~isempty(obj.clockPulseObj)
			 obj.clockPulseObj.sendPulse();
		  end
		  if isempty(obj.currentDataFile)
			 % called on first frame
			 obj.currentDataFile = DataFile(...
				'rootPath',obj.currentDataSetPath,...
				'experimentName',obj.currentExperimentName);%changed rootPath from sessionPath
		  end

		  info.Time = evnt.Time;
		  data = evnt.RawVelocity;
		  addFrame2File(obj.currentDataFile,data,info);
		 
     end
      
      function trialStateChangeFcn(obj,~,~)
          fprintf('Beginning new trial!\n');
          obj.trialPulseObj.sendPulse();
      end
      
      function set.trialSyncObj(obj,trial)
        obj.trialStateObj = trial;
        obj.trialStateListener = addlistener(obj.trialStateObj,...
            'NewTrial',@(src,evnt) trialStateChangeFcn(obj,src,evnt));
      end
      
	 function set.experimentSyncObj(obj,bhv)
		obj.experimentSyncObj = bhv;
		obj.experimentStateListener = addlistener(obj.experimentSyncObj,...
		  'ExperimentStart',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
		addlistener(obj.experimentSyncObj,...
		  'ExperimentStop',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
	 end
      
	 function set.frameSyncObj(obj,cam)
		obj.frameSyncObj = cam;
		% Define Listener
		obj.frameSyncListener = addlistener(obj.frameSyncObj,...
		  'FrameAcquired',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
	 end
      
      
  end
  
  methods
	 function delete(obj)
		try
		  obj.saveDataSet();
		  delete(obj.clockPulseObj);
		catch me
		  disp(me.message)
		end
	 end
  end
  
end
