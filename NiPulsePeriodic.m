classdef NiPulsePeriodic < hgsetget
   
    properties
        niDevice
        startTime
        currTime
        currFrame
        pulseStartFrame
        pulseEndFrame
        pulseLength
        OnorOff
        SwitchTime % indicates the time elapsed since the last switch of on/off
    end
    
    methods
        function obj = NiPulsePeriodic(varargin)
            if nargin
                obj.niDevice = NiPulseOutput(varargin{:});
            else % come back to this
                obj.niDevice = NiPulseOutput();
            end
            obj.niDevice.setup();
            addlistener(obj.niDevice,'FrameAcquired',@(src,evnt) loopEvnt(obj,src,evnt));
            obj.startTime = hat;
            obj.currTime = hat;
            obj.currFrame = 0;
        end
        
        % this function should update the pulse, turning it either on or
        % off, based on the time that has past in the experiment
        function loopEvnt(obj,~,~)
            obj.currFrame = obj.currFrame + 1;
            obj.currTime = hat;
            
        end
        %this nested function should allow the user to decide how often and
        %for how long the led on the NIDAQ board will pulse
        function pulseFrequency(obj, pulseInterval, pulseLength)
            while hat > obj.startTime
                passedTime = hat - obj.startTime
                if passedTime == pulseInterval
                    obj.SwitchTime = 0;
                    pulseTime(obj, pulseLength)
                    
                    
                    %set switchTime to 0 and start counting...this is going
                    %to have to be changed
                    %also saw on Mathworks.com about the "return" function,
                    %that will likely be used based on the way I am trying
                    %to set this up so far
            
                end
            end
            
            function pulseTime(obj, pulseLength)
                obj.OnorOff = obj.nidevice.outputSingleScan;
                %obj.SwitchTime = 
                switch obj.OnorOff
                    case 1
                        while obj.SwitchTime <= pulseLength %while the time since it was switched on is less than the pulseLength have the LED on
                        obj.nidevice.outputSingleScan = 1;
                        end
                        if obj.SwitchTime > pulseLength %once the time since it was switched on is greater than the pulseLength, turn the LED off and reset SwitchTime
                        obj.OnorOff = 0;
                        obj.nidevice.outputSingleScan = 0;
                        obj.SwitchTime = 0; 
                        end 
                    case 0
                        
                end
            end
        end
    end
end