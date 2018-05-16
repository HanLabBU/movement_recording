classdef vrMsgMike < event.EventData
    
    properties
        Xpos
        Ypos
        Zpos
        ViewAngle        
        Dt
        ForwardVelocity
        RotationalVelocity
        iterations
        World
        Velocity
        RawVelocity
        Time
    end
    
    methods
        function eventData = vrMsgMike(vr)            
            eventData.RawVelocity = vr.vrSystem.rawVelocity;
            eventData.Time = hat;
        end
    end
    
end

% NOTE:
% RawVelocity is a 5x4 matrix where each of the 5 rows is taken from each sequential step used to
% calculate the 1x4 "vr.velocity" vector used by Virmen to move through the virtual world.
% Columns are [dx dy dz domega] in vr.velocity, but represent different values, e.g. the raw [dx,dy]
% values from each sensor are in the first row. For what each value corresponds to refer to
% moveBucklin.m
