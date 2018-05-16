function vr = moveMike(vr)

% NEW +++++  READING FROM DX (DIVIDED BY TIME)
% READ X,Y FROM SENSOR INTERFACES
if ~isfield(vr,'movementInterface')
	vr.movementInterface = VrMovementInterface;
	vr.movementInterface.start();
end


leftX = vr.movementInterface.mouse1.dx;
leftY = vr.movementInterface.mouse1.dy;
rightX = vr.movementInterface.mouse2.dx;
rightY = vr.movementInterface.mouse2.dy;
vr.vrSystem.rawVelocity(1,:) = [leftX, leftY, rightX, rightY];
vr.movementInterface.mouse1.dx = 0;
vr.movementInterface.mouse1.dy = 0;
vr.movementInterface.mouse2.dx = 0;
vr.movementInterface.mouse2.dy = 0;
