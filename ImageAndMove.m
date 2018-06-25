classdef ImageAndMove < SubSystem
  
  

  properties % OBLIGATORY
	 experimentSyncObj
	 trialSyncObj
	 frameSyncObj
  end
  properties
 	 clockPulseObj
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
	 function obj = ImageAndMove(varargin)
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
        obj.savedDataFiles = VrFile.empty(1,0);
		obj.currentDataFileSet = VrFile.empty(1,0);
		obj.checkProperties@SubSystem;
	 end
  end
    methods % Required by SubSystem
	
        function createSystemComponents(obj,varargin)
        if isempty(obj.frameSyncObj)
          obj.frameSyncObj = obj;
        end
        if nargin < 2
          obj.clockPulseObj = NiPulseOutput(...
             'pulseTime',.005,...
             'activeHigh',true,...
             'portNumber',1,...
             'lineNumber',0);
          obj.clockPulseObj.setup();
        else
            obj.clockPulseObj = NiPulseOutput(varargin{:});
            obj.clockPulseObj.setup();
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
		if ~isempty(obj.frameSyncListener)
		  obj.frameSyncListener.Enabled = false;
		end
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
      
      function trialStateChangeFcn(obj)
      end
      
	 function set.experimentSyncObj(obj,bhv)
		if ~isempty(obj.experimentStateListener)
		  obj.experimentStateListener.Enabled = false;
		end
		obj.experimentSyncObj = bhv;
		obj.experimentStateListener = addlistener(obj.experimentSyncObj,...
		  'ExperimentStart',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
		addlistener(obj.experimentSyncObj,...
		  'ExperimentStop',@(src,evnt)experimentStateChangeFcn(obj,src,evnt));
		obj.experimentStateListener.Enabled = true;
	 end
      
	 function set.frameSyncObj(obj,cam)
		if ~isempty(obj.frameSyncListener)
		  obj.frameSyncListener.Enabled = false;
		end
		obj.frameSyncObj = cam;
		% Define Listener
		obj.frameSyncListener = addlistener(obj.frameSyncObj,...
		  'FrameAcquired',@(src,evnt)frameAcquiredFcn(obj,src,evnt));
		obj.frameSyncListener.Enabled = false;
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

