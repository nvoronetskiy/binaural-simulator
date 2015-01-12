sim = simulator.SimulatorConvexRoom();
set(sim, ...
    'Renderer', @ssr_brs, ...
    'Sources', {simulator.source.Point()}, ...
    'Sinks', simulator.AudioSink(2) ...
    );

set(sim.Sources{1}, ...
    'Name', 'Cello', ...
    'IRDataset', simulator.DirectionalIR( ...
      'impulse_responses/qu_kemar_rooms/auditorium3/QU_KEMAR_Auditorium3_src3_xs+2.20_ys-1.94.sofa'), ...
    'AudioBuffer', simulator.buffer.FIFO(1) ...
    );

set(sim.Sources{1}.AudioBuffer, ...
    'File', 'stimuli/anechoic/instruments/anechoic_cello.wav' ...
    );

%% initialization
% note that all the parameters including objects' positions have to be
% defined BEFORE initialization in order to init properly
sim.set('Init',true);

%% static scene, dynamic head

% head should rotate about 170 degree to the right with 20 degrees per second
sim.Sinks.setDynamic('UnitFront', 'Velocity', 20);
sim.Sinks.set('UnitFront', [cosd(85); sind(85); 0]);

while ~sim.isFinished()
  sim.set('Refresh',true);  % refresh all objects
  sim.set('Process',true);
end

% save file
sim.Sinks.saveFile('out_brs.wav',sim.SampleRate);
%% clean up
sim.set('ShutDown',true);