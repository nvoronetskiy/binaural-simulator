classdef (Abstract) SimulatorInterface < xml.MetaObject
  %SIMULATORINTERFACE is the base class for all configurations for the simulator

  properties
    % blocksize for binaural renderer
    % @type integer
    BlockSize;
    % sample rate of audio input signals in Hz
    % @type integer
    SampleRate;
    % threads used for computing ear signals
    % @type integer
    % @default 1
    NumberOfThreads = 1;
    % rendering mex-function
    % @type function_handle
    % @default @ssr_binaural
    Renderer = @ssr_binaural;
    % HRIR-dataset
    % @type DirectionalIR
    HRIRDataset;

    % maximum delay in seconds caused by distance and finite sound velocity
    % @type double
    MaximumDelay = 0.0;
    % pre-delay in seconds to handle non-causality
    % @type double
    PreDelay = 0.0;
    % maximum length of simulation in seconds
    % @type double
    % @default inf
    %
    % Setting this to inf, says that the simulation stops if all sources
    % are empty (WHICH MAY NEVER HAPPEN!)
    LengthOfSimulation = inf;

    % array of sources
    % @type AudioSource[]
    Sources
    % array of sinks
    % @type AudioSink[]
    Sinks = simulator.AudioSink.empty;
    % array of walls
    % @type Wall[]
    Walls = simulator.Wall.empty;

    % assumed room type for image source model
    % @type char[]
    % @default shoebox
    ReverberationRoomType = 'shoebox';
    % order of image source model (number of subsequent reflections)
    % @type integer
    % @default 0
    ReverberationMaxOrder = 0;

    % object for eventhandler (for dynamic scenes)
    % @type simulator.dynamic.SceneEventHandler
    EventHandler;
  end

  %% Constructor
  methods
    function obj = SimulatorInterface()
      obj.addXMLAttribute('BlockSize', 'double');
      obj.addXMLAttribute('SampleRate', 'double');
      obj.addXMLAttribute('NumberOfThreads', 'double');
      obj.addXMLAttribute('MaximumDelay', 'double');
      obj.addXMLAttribute('PreDelay', 'double');
      obj.addXMLAttribute('LengthOfSimulation', 'double');
      obj.addXMLAttribute('ReverberationMaxOrder', 'double');
      obj.addXMLAttribute('Renderer', 'function_handle');
      obj.addXMLAttribute('HRIRDataset',  ...
        'simulator.DirectionalIR', ...
        'HRIRs', ...
        @(x) simulator.DirectionalIR(xml.dbGetFile(x)));

      obj.addXMLElement('Sinks', ...
        'simulator.AudioSink', ...
        'sink', ...
        @(x)simulator.AudioSink(2));
      obj.addXMLElement('EventHandler', ...
        'simulator.dynamic.SceneEventHandler', ...
        'dynamic', ...
        @(x) simulator.dynamic.SceneEventHandler(obj));
      % sources and walls do not occur here because they have to be handled
      % in a different way. See configureXMLSpecific.
    end
  end

  %% XML
  methods (Access=protected)
    function configureXMLSpecific(obj, xmlnode)
      % function configureXMLSpecific(obj, xmlnode)
      % See also: xml.MetaObject.configureXMLSpecific

      % special handling of source objects
      sourceList = xmlnode.getElementsByTagName('source');
      sourceNum = sourceList.getLength;

      kdx = 1;
      for idx=1:sourceNum
        source = sourceList.item(idx-1);
        attr = (char(source.getAttribute('Type')));
        switch attr
          case 'point'
            obj.Sources{kdx} = simulator.source.Point();
          case 'ism'
            if strcmp(obj.ReverberationRoomType, 'shoebox')
              obj.Sources{kdx} = simulator.source.ISMShoeBox(obj);
            elseif strcmp(obj.ReverberationModel, 'convex')
              obj.Sources{kdx} = simulator.source.ISMConvex(obj);
            end
          case 'plane'
            obj.Sources{kdx} = simulator.source.Plane();
          case 'pwd'
            obj.Sources{kdx} = simulator.source.PWDGroup();
          case 'direct'
            obj.Sources{kdx} = simulator.source.Binaural;
          otherwise
            warning('source type not yet implemented for xml parsing');
            continue;
        end
        obj.Sources{kdx}.XML(source);
        kdx = kdx + 1;
      end

      % special handling of wall objects
      wallList = xmlnode.getElementsByTagName('wall');
      wallNum = wallList.getLength;
      kdx = 1;
      for idx=1:wallNum
        wall = wallList.item(idx-1);

        % create new wall object and do the xml-parsing for the wall
        wallObj = simulator.Wall();
        wallObj.XML(wall);

        % try to get the room informations
        roomtype = (char(wall.getAttribute('Room')));

        % try to get the room height
        roomheight = str2num(wall.getAttribute('RoomHeight'));

        % distinguish the number of walls which will be generated
        switch roomtype
          case ''
            range = kdx;
            obj.Walls(kdx) = wallObj;
          case '2D'
            range = kdx+3;
            obj.Walls(kdx:range) = ...
              wallObj.createUniformPrism(roomheight, roomtype);
            delete(wallObj);
          case '3D'
            range = kdx+5;
            obj.Walls(kdx:range) = ...
              wallObj.createUniformPrism(roomheight, roomtype);
          otherwise
            error('room type not yet supported for xml parsing');
        end

        kdx = range + 1;
      end
    end
  end

  %% some functionalities for controlling the Simulator
  % this properties can be used to invoke some of the abstract functions

  properties
    % flag indicates if the simulator is initialited
    % @type logical
    % @default false
    Init = false;
  end
  properties (Dependent, GetAccess=private)
    % set to true to process one frame of ear signals
    % @type logical
    %
    % See also: process
    Process;
    % set to true to refresh scene geometry
    % @type logical
    %
    % See also: refresh
    Refresh;
    % set to true to clear history of simulator
    % @type logical
    %
    % See also: reinit
    ReInit;
    % set to true to clear convolver memory (obsolete)
    % @type logical
    %
    % This functionality will be fully replaced by ReInit in the term
    %
    % See also: clearmemory ReInit
    ClearMemory;
    % set to true to shut down the simulator
    % @type logical
    %
    % See also: shutdown
    ShutDown;
  end

  methods (Abstract)
    init(obj);
    refresh(obj);
    process(obj);
    reinit(obj);
    clearmemory(obj);
    shutdown(obj);
    isFinished(obj);
  end
  % special setter and getter for this
  methods
    function set.Init(obj, Init)
      isargclass('logical', Init);
      if (Init)
        obj.init();
      end
      obj.Init = Init;
    end
    function set.Refresh(obj, Refresh)
      isargclass('logical', Refresh);
      if (Refresh)
        obj.refresh();
      end
    end
    function set.Process(obj, Process)
      isargclass('logical', Process);
      if (Process)
        obj.process();
      end
    end
    function set.ReInit(obj, ReInit)
      isargclass('logical', ReInit);
      if (ReInit)
        obj.reinit();
      end
    end
    function set.ClearMemory(obj, ClearMemory)
      isargclass('logical', ClearMemory);
      if (ClearMemory)
        obj.clearmemory();
      end
    end
    function set.ShutDown(obj, ShutDown)
      isargclass('logical', ShutDown);
      if (ShutDown)
        obj.shutdown();
        obj.Init = false;
      end
    end
  end

  %% setter, getter
  methods
    function set.BlockSize(obj, BlockSize)
      isargpositivescalar(BlockSize);  % check if positive scalar
      isargnonzeroscalar(BlockSize);  % check if non-zero scalar
      obj.errorIfInitialized;
      obj.BlockSize = BlockSize;
    end
    function set.NumberOfThreads(obj, NumberOfThreads)
      isargpositivescalar(NumberOfThreads);  % check if positive scalar
      isargnonzeroscalar(NumberOfThreads);  % check if non-zero scalar
      obj.errorIfInitialized;
      obj.NumberOfThreads = NumberOfThreads;
    end
    function set.Renderer(obj, Renderer)
      if ~isa(Renderer, 'function_handle')  % check if function_handle
        error('Renderer is not a function handle');
      end
      if all(exist(func2str(Renderer)) ~= [2, 3])
        error('*.m/*.mex file for Renderer function not found');
      end
      obj.errorIfInitialized;
      obj.Renderer = Renderer;
    end
    function set.HRIRDataset(obj, HRIRDataset)
      isargclass('simulator.DirectionalIR',HRIRDataset);  % check class
      if numel(HRIRDataset) ~= 1
        error('only one HRIRDataset is allowed');
      end
      obj.errorIfInitialized;
      obj.HRIRDataset = HRIRDataset;
    end
    function set.MaximumDelay(obj, MaximumDelay)
      isargpositivescalar(MaximumDelay);
      obj.errorIfInitialized;
      obj.MaximumDelay = MaximumDelay;
    end
    function set.LengthOfSimulation(obj, LengthOfSimulation)
      isargpositivescalar(LengthOfSimulation);
      obj.LengthOfSimulation = LengthOfSimulation;
    end
    function set.Sinks(obj, Sinks)
      isargclass('simulator.AudioSink',Sinks);  % check class
      if numel(Sinks) ~= 1
        error('only one sink is allowed');
      end
      if Sinks.NumberOfInputs ~= 2
        error('Sink does not have two channels');
      end
      obj.errorIfInitialized;
      obj.Sinks = Sinks;
    end
    function set.Sources(obj, Sources)
      isargclass('cell', Sources);
      isargclass('simulator.source.Base', Sources{:});
      obj.errorIfInitialized;
      obj.Sources = Sources;
    end
    function set.Walls(obj, Walls)
      isargclass('simulator.Wall',Walls);  % check class
      isargvector(Walls);  % check if vector
      obj.errorIfInitialized;
      obj.Walls = Walls;
    end
    function set.ReverberationRoomType(obj, v)
      isargchar(v);  % check if string
      if ~any(strcmp(v, 'shoebox', 'convex'))
        error('"%s" is not a supported room type', v);
      end
      obj.ReverberationRoomType = v;
    end
    function set.ReverberationMaxOrder(obj, ReverberationMaxOrder)
      isargpositivescalar(ReverberationMaxOrder);  % check if positive scalar
      obj.ReverberationMaxOrder = ReverberationMaxOrder;
    end
    function set.EventHandler(obj, EventHandler)
      isargclass('simulator.dynamic.SceneEventHandler',EventHandler);  % check class
      if numel(EventHandler) ~= 1
        error('only one eventhandler is allowed');
      end
      obj.errorIfInitialized;
      obj.EventHandler = EventHandler;
    end
  end

  %% Misc
  methods (Access = private)
    function errorIfInitialized(obj)
      if obj.Init
        error('Cannot change property while Simulator is initialized');
      end
    end
  end
end
