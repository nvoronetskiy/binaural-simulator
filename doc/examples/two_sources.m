sim = simulator.SimulatorConvexRoom();
set(sim, ...
    'HRIRDataset', simulator.DirectionalIR( ...
        'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'), ...
    'Sources', {simulator.source.Point(), simulator.source.Point()}, ...
    'Sinks',   simulator.AudioSink(2) ...
    );
set(sim.Sources{1}, ...
    'Name', 'Cello', ...
    'Position', [1; 2; 0], ...
    'AudioBuffer', simulator.buffer.FIFO(1) ...
    );
set(sim.Sources{1}.AudioBuffer, ...
    'File', 'stimuli/anechoic/instruments/anechoic_cello.wav' ...
    );
set(sim.Sources{2}, ...
    'Name', 'Castanets', ...
    'Position', [0; 0; 0], ...
    'AudioBuffer', simulator.buffer.FIFO(1) ...
    );
set(sim.Sources{2}.AudioBuffer, ...
    'File', 'stimuli/anechoic/instruments/anechoic_castanets.wav' ...
    );
set(sim.Sinks, ...
    'Name', 'Head', ...
    'UnitFront', [1; 0; 0], ...
    'Position', [0; 0; 0] ...
    );
sim.set('Init',true);
while ~sim.isFinished()
    sim.set('Refresh',true);  % refresh all objects
    sim.set('Process',true);
end
data = sim.Sinks.getData();
sim.Sinks.saveFile('out_two_sources.wav',sim.SampleRate);
sim.set('ShutDown',true);
