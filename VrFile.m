classdef VrFile < DataFile
		

		
		
				
		properties (SetObservable, GetObservable, AbortSet)% Header Data
				worldNumber				
				trialNumber
        end
		
		methods % Constructor
				function obj = VrFile(varargin)
						obj = obj@DataFile(varargin{:});
				end
		end
		methods (Hidden) % Initialization
				function defineDefaults(obj)
						obj.defineDefaults@DataFile;
						obj.default.experimentName = 'none';
						obj.default.headerFileName =  ['VrHeader_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fhf'];
						obj.default.dataFileName = ['VrData_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fdf'];
						obj.default.infoFileName = ['VrFrameInfo_',datestr(obj.default.startTime,'yyyy_mm_dd_HHMMSS'),...
								sprintf('_N%i',obj.instanceNumber),'.fif'];
				end
				function checkProperties(obj)
						% Add any property containing a variable length string to paddedProps
						obj.paddedProps = {...
								'experimentName'};
						obj.checkProperties@DataFile;
				end
		end
		methods % Functions for Saving
				function checkFrameInfo(obj,info)
						obj.checkFrameInfo@DataFile(info);						
				end
		end		
		methods % Cleanup and State-Check
				function delete(obj)
						obj.delete@DataFile;
				end
				function obj = saveobj(obj)
						obj = saveobj@DataFile(obj);
				end
		end
		methods (Static)
				function obj = loadobj(obj)
						obj = obj.loadobj@DataFile;
				end
		end
		
		
		
		
		
		
		
end







