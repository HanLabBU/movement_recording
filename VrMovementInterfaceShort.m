classdef VrMovementInterfaceShort < hgsetget
    
    properties
        sensors = {'1','2'}
        mouse1
        mouse2
    end
    properties
        serialObj
        serialTag
        serialPort = 'COM4'
        serialBaudRate = 9600
		
    end
    
    properties (SetObservable)        
        state = 'ready'
    end
    
    methods
        function obj = VrMovementInterfaceShort(varargin)
            if nargin > 1
                for i = 1:2:length(varargin)
                    obj.(varargin(i))= obj.(varargin(i+1));
                end
            else
                obj.serialObj = serial(obj.serialPort);
                set(obj.serialObj,...
                    'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
                    'BaudRate',obj.serialBaudRate);
                    %'FlowControl',);
                obj.mouse1 = SensorMike('1');
                obj.mouse2 = SensorMike('2');
            end
        end                
        function msg = readSerialFcn(obj,~,~)
            try
                if strcmp(obj.state,'running')
                    msg = fscanf(obj.serialObj,'%s');
                else
                    flushinput(obj.serialObj);
                    return
                end
                msg = msg(:)';  % make character array horizontal
                msg = obj.parsedeltas(msg);%',d);
            catch me
                warning(me.message)
                disp(me.stack(1))
                disp(me.stack(2))
            end
        end        
        function start(obj)
            try 
                flushinput(obj.serialObj);
				fopen(obj.serialObj);
                disp('STARTING VrMovementInterface')
            catch err
                disp(err.message);
                disp(err.stack(1))
                disp(err.stack(2))
				instrhwinfo('serial') %KD
				delete(instrfindall); %KD
				obj.serialObj = serial(obj.serialPort);
                set(obj.serialObj,...
                    'BytesAvailableFcn',@(src,evnt)readSerialFcn(obj,src,evnt),...
                    'BaudRate',obj.serialBaudRate);
%                     'FlowControl','hardware');
				fopen(obj.serialObj);
            end
            obj.state = 'running';
        end        
        function stop(obj)
            try
                disp('stopping...')
                fclose(obj.serialObj);%todo: cleanup with instrument control toolbox tools
                disp('stopped!')
            catch err
                disp(err);
            end
        end        
        function msg = parsedeltas(obj,msg)
            if isempty(msg)
                msg = NaN;
                return
            end				
            sensornum = msg(1);
            if ~any(strcmp(sensornum,obj.sensors))
                msg = [];
                return
            end
            x_index = regexp(msg,'[x]*');
            y_index = regexp(msg,'[y]*');
            dx = str2double(msg(x_index+1:y_index-1));
            dy = str2double(msg(y_index+1:end));
            if isa(dx,'double') && isa(dy,'double')
                obj.(sprintf('mouse%s',sensornum)).dx = dx;
                obj.(sprintf('mouse%s',sensornum)).dy = dy;
            else
                error('bad sensor data!');
            end
        end
        function delete(obj)
            if ~isempty(obj.serialObj) && isvalid(obj.serialObj)
                fclose(obj.serialObj);
                delete(obj.serialObj);
            end
            instrreset
        end
    end
end
