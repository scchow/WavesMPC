%%% driftMoveRobot.m 
%%% Daniel Fernández
%%% May 2015
%%% moves the non-actuated robot.  Takes initial position and all relevant
%%% DE parameters and passes them through DEs called x2dot and z2dot.  Gets
%%% new state and updates all errors and plotdata.


function [ robot ] = driftMoveRobot( t, robot, spectra, count )

dt = t(2) - t(1);
x = robot.state.px; z = robot.state.pz; 

pErrorX = robot.errors.pErrorX;
pErrorZ = robot.errors.pErrorZ;

rho = spectra.rho;

mDry = robot.mDry;                  %robot dry mass
mAdx = robot.mAdx;                  %robot added mass in x
mAdz = robot.mAdz;                  %robot added mass in z
Ax = robot.width * robot.height;    %incident area in x
Az = robot.length * robot.width;    %incident area in z

[ robot.particles ] = getRobotParticles( t, x, z, spectra, robot.particles, count );
vx = robot.particles.vx(count); ax = robot.particles.ax(count);
vz = robot.particles.vz(count); az = robot.particles.az(count);

[ Cd ] = getCd( vx, vz, Ax, Az );


x2dot = @(tx,x1dot) ...
    (mAdx*ax + rho*Ax*Cd/2 * abs(x1dot-vx) * (x1dot-vx)) / -(mDry+mAdx)/2;

z2dot = @(tz,z1dot) ...
    (mAdz*az + rho*Az*Cd/2 * abs(z1dot-vz) * (z1dot-vz)) / -(mDry+mAdz)/2;

[ tx, yx ] = ode45( x2dot, [0 dt], robot.state.vx );
[ tz, yz ] = ode45( z2dot, [0 dt], robot.state.vz );


robot.state.ax = x2dot( tx(end), yx(end) );
robot.state.az = z2dot( tz(end), yz(end) );
robot.state.vx = yx(end)-0.001; 
robot.state.vz = yz(end);
robot.state.px = odeDisplacement( robot.state.px, yx, tx );
robot.state.pz = odeDisplacement( robot.state.pz, yz, tz );

Y = [ robot.state.px, robot.state.pz, robot.state.vx, robot.state.vz, ...
    robot.state.ax, robot.state.az ]; 
[ robot.robotPlots ] = updatePlotHistory( Y, robot.robotPlots, count, 1 );

[ robot ] = updateErrors( robot, count, pErrorX, pErrorZ );

tempPx = robot.particlePlots.px(count) + robot.particles.vx(count) * dt;
tempPz = robot.particlePlots.pz(count) + robot.particles.vz(count) * dt;
tempVx = robot.particles.vx(count+1);
tempVz = robot.particles.vz(count+1);
tempAx = robot.particles.ax(count+1);
tempAz = robot.particles.az(count+1);

U = [ tempPx, tempPz, tempVx, tempVz, tempAx, tempAz ];
[ robot.particlePlots ] = updatePlotHistory( U, robot.particlePlots, count, 1 );



return

end