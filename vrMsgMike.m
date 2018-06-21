classdef vrMsgMike < event.EventData
    
    properties
        RawVelocity
        Time
    end
    
    methods
        function eventData = vrMsgMike(vr)            
            eventData.RawVelocity = vr.camSystem.rawVelocity;
            eventData.Time = vr.camSystem.time;
        end
    end
    
end