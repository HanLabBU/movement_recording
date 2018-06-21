classdef mvmt2msg < event.EventData
    
    properties
        RawVelocity
        Time
    end
    
    methods
        function eventData = mvmt2msg(experiment)            
            eventData.RawVelocity = experiment.camSystem.rawVelocity;
            eventData.Time = experiment.camSystem.time;
        end
    end
    
end