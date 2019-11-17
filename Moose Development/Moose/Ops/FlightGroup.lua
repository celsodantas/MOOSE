--- **Ops** - (R2.5) - AI Flight Group for Ops.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Monitor fuel and ammo status.
--    * Sophisticated task queueing system.
--    * Many additional events for each element and the whole group.
--
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.FlightGroup
-- @image OPS_FlightGroup.png


--- FLIGHTGROUP class.
-- @type FLIGHTGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @field #string groupname Name of flight group.
-- @field Wrapper.Group#GROUP group Flight group object.
-- @field #string type Aircraft type of flight group.
-- @field #table elements Table of elements, i.e. units of the group.
-- @field #table waypoints Table of waypoints.
-- @field #table waypoints0 Table of initial waypoints.
-- @field #table coordinates Table of waypoint coordinates.
-- @field #table taskqueue Queue of tasks.
-- @field #number taskcounter Running number of task ids.
-- @field #number taskcurrent ID of current task. If 0, there is no current task assigned.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @field Wrapper.Airbase#AIRBASE homebase The home base of the flight group.
-- @field Wrapper.Airbase#AIRBASE destination The destination base of the flight group.
-- @field #string actype Type name of the aircraft.
-- @field #number speedmax Max speed in km/h.
-- @field #number range Range of the aircraft in km.
-- @field #number ceiling Max altitude the aircraft can fly at in meters.
-- @field #boolean ai If true, flight is purely AI. If false, flight contains at least one human player.
-- @field #boolean fuellow Fuel low switch.
-- @field #number fuellowthresh Low fuel threshold in percent.
-- @field #boolean fuellowrtb RTB on low fuel switch.
-- @field #boolean fuelcritical Fuel critical switch.
-- @field #number fuelcriticalthresh Critical fuel threshold in percent.
-- @field #boolean fuelcriticalrtb RTB on critical fuel switch. 
-- @field Ops.Squadron#SQUADRON squadron The squadron the flight group belongs to.
-- @field Ops.FlightControl#FLIGHTCONTROL flightcontrol The flightcontrol handling this group.
-- @field Core.UserFlag#USERFLAG flaghold Flag for holding.
-- @field #number Tholding Abs. mission time stamp when the group reached the holding point.
-- @field #number Tparking Abs. mission time stamp when the group was spawned uncontrolled and is parking.
-- @extends Core.Fsm#FSM

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\FLIGHTGROUP_Main.jpg)
--
-- # The FLIGHTGROUP Concept
--
--
--
-- @field #FLIGHTGROUP
FLIGHTGROUP = {
  ClassName          = "FLIGHTGROUP",
  Debug              =   nil,
  sid                =   nil,
  groupname          =   nil,
  group              =   nil,
  grouptemplate      =   nil,
  type               =   nil,
  waypoints          =   nil,
  waypoints0         =   nil,
  coordinates        =    {},
  elements           =    {},
  taskqueue          =    {},
  taskcounter        =   nil,
  taskcurrent        =   nil,
  detectedunits      =    {},
  homebase           =   nil,
  destination        =   nil,
  actype             =   nil,
  speedmax           =   nil,
  range              =   nil,
  ceiling            =   nil,
  fuellow            = false,
  fuellowthresh      =   nil,
  fuellowrtb         =   nil,
  fuelcritical       =   nil,  
  fuelcriticalthresh =   nil,
  fuelcriticalrtb    = false,
  squadron           =   nil,
  flightcontrol      =   nil,
  flaghold           =   nil,
  Tholding           =   nil,
  Tparking           =   nil,
}


--- Status of flight group element.
-- @type FLIGHTGROUP.ElementStatus
-- @field #string INUTERO Element was not spawned yet or its status is unknown so far.
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string TAKEOFF Element took of after takeoff event.
-- @field #string AIRBORNE Element is airborne. Either after takeoff or after air start.
-- @field #string LANDING Element is landing.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
FLIGHTGROUP.ElementStatus={
  INUTERO="inutero",
  SPAWNED="spawned",
  PARKING="parking",
  TAXIING="taxiing",
  TAKEOFF="takeoff",
  AIRBORNE="airborne",
  LANDING="landing",
  LANDED="landed",
  ARRIVED="arrived",
  DEAD="dead",
}


--- Flight group element.
-- @type FLIGHTGROUP.Element
-- @field #string name Name of the element, i.e. the unit/client.
-- @field Wrapper.Unit#UNIT unit Element unit object.
-- @field Wrapper.Group#GROUP group Group object of the element.
-- @field #string modex Tail number.
-- @field #string skill Skill level.
-- @field #boolean ai If true, element is AI.
-- @field Wrapper.Client#CLIENT client The client if element is occupied by a human player.
-- @field #table pylons Table of pylons.
-- @field #number fuelmass Mass of fuel in kg.
-- @field #number category Aircraft category.
-- @field #string categoryname Aircraft category name.
-- @field #string callsign Call sign, e.g. "Uzi 1-1".
-- @field #string status Status, i.e. born, parking, taxiing. See @{#FLIGHTGROUP.ElementStatus}.
-- @field #number damage Damage of element in percent.
-- @field Wrapper.Airbase#AIRBASE.ParkingSpot parking The parking spot table the element is parking on.


--- Flight group tasks.
-- @type FLIGHTGROUP.Mission
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.
-- @param #string BAI Battlefield Air Interdiction task.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike task.
-- @param #string AWACS AWACS task.
-- @param #string TANKER Tanker task.
FLIGHTGROUP.Mission={
  INTERCEPT="Intercept",
  CAP="CAP",
  BAI="BAI",
  SEAD="SEAD",
  STRIKE="Strike",
  CAS="CAS",
  AWACS="AWACS",
  TANKER="Tanker",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskStatus
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string ACCOMPLISHED Task is accomplished.
-- @field #string WAYPOINT Task is executed at a waypoint.
FLIGHTGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  ACCOMPLISHED="accomplished",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskType
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
FLIGHTGROUP.TaskType={
  SCHEDULED="scheduled",
  WAYPOINT="waypoint",
}


--- Flight group tasks.
-- @type FLIGHTGROUP.Task
-- @field #string type Type of task: either SCHEDULED or WAYPOINT.
-- @field #number id Task ID. Running number to get the task.
-- @field #number prio Priority.
-- @field #number time Abs. mission time when to execute the task.
-- @field #table dcstask DCS task structure.
-- @field #string description Brief text which describes the task.
-- @field #string status Task status.
-- @field #number duration Duration before task is cancelled in seconds. Default never.
-- @field #number timestamp Abs. mission time, when task was started.
-- @field #number waypoint Waypoint index if task is a waypoint task.


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.1.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.
-- TODO: Add EPLRS, TACAN.
-- TODO: Get ammo.
-- TODO: Get pylons.
-- TODO: Fuel threshhold ==> RTB.
-- TODO: ROE, Afterburner restrict.
-- TODO: Respawn? With correct loadout, fuelstate.
-- TODO: Waypoints, read, add, insert, detour.
-- TODO: Damage?
-- TODO: shot events?
-- TODO: Marks to add waypoints/tasks on-the-fly.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTGROUP object and start the FSM.
-- @param #FLIGHTGROUP self
-- @param #string groupname Name of the group.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(groupname)

  -- First check if we already have a flight group for this group.
  local fg=_DATABASE:GetFlightGroup(groupname)
  if fg then
    fg:I(fg.sid..string.format("WARNING: Flight group %s already exists in data base!", groupname))
    return fg
  end

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTGROUP

  --self.group=AIGroup
  self.groupname=tostring(groupname)

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()
  
  -- Defaults
  self:SetFuelLowThreshold()
  self:SetFuelCriticalThreshold()


  -- Add FSM transitions.
  --                 From State  -->   Event      -->      To State
  self:AddTransition("Stopped",       "Start",             "Running")     -- Start FSM.

  self:AddTransition("*",             "FlightStatus",      "*")           -- FLIGHTGROUP status update.
  self:AddTransition("*",             "QueueUpdate",       "*")           -- Update task queue.
  
  
  self:AddTransition("*",             "DetectedUnit",      "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitNew",   "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitKnown", "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitLost",  "*")           -- Group lost a detected target.

  self:AddTransition("*",             "RTB",               "Returning")   -- Group is returning to base.
  self:AddTransition("*",             "Orbit",             "Orbiting")    -- Group is holding position.
  self:AddTransition("*",             "Hold",              "Holding")     -- Group is holding position.

  self:AddTransition("*",             "PassingWaypoint",   "*")           -- Group passed a waypoint.
  
  self:AddTransition("*",             "FuelLow",           "*")          -- Fuel state of group is low. Default ~25%.
  self:AddTransition("*",             "FuelCritical",      "*")          -- Fuel state of group is critical. Default ~10%.
  
  self:AddTransition("*",             "OutOfAmmo",         "*")          -- Group is completely out of ammo.
  self:AddTransition("*",             "OutOfGuns",         "*")          -- Group is out of gun shells.
  self:AddTransition("*",             "OutOfRockets",      "*")          -- Group is out of rockets.
  self:AddTransition("*",             "OutOfBombs",        "*")          -- Group is out of bombs.
  self:AddTransition("*",             "OutOfMissiles",     "*")          -- Group is out of missiles.

  self:AddTransition("*",             "TaskExecute",      "*")           -- Group will execute a task.
  self:AddTransition("*",             "TaskDone",         "*")           -- Group finished a task.
  self:AddTransition("*",             "TaskCancel",       "*")           -- Cancel current task.
  self:AddTransition("*",             "TaskPause",        "*")           -- Pause current task.

  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementParking",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementTakeoff",   "*")           -- An element took off.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element is airborne.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element crashed, ejected, or pilot dead.

  self:AddTransition("*",             "ElementOutOfAmmo", "*")           -- An element is completely out of ammo.

  self:AddTransition("*",             "FlightSpawned",    "Spawned")     -- The whole flight group was spawned.
  self:AddTransition("*",             "FlightParking",    "Parking")     -- The whole flight group is parking.
  self:AddTransition("*",             "FlightTaxiing",    "Taxiing")     -- The whole flight group is taxiing.
  self:AddTransition("*",             "FlightTakeoff",    "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightAirborne",   "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightLanding",    "Landing")     -- The whole flight group is landing.
  self:AddTransition("*",             "FlightLanded",     "Landed")      -- The whole flight group has landed.
  self:AddTransition("*",             "FlightArrived",    "Arrived")     -- The whole flight group has arrived.
  self:AddTransition("*",             "FlightDead",       "Dead")        -- The whole flight group is dead.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] Start
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] __Start
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FLIGHTGROUP and all its event handlers.
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLIGHTGROUP and all its event handlers.
  -- @function [parent=#FLIGHTGROUP] __Stop
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#FLIGHTGROUP] FlightStatus
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#FLIGHTGROUP] __FlightStatus
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end


  -- Init task counter.
  self.taskcurrent=0
  self.taskcounter=0

  -- Holding flag.  
  self.flaghold=USERFLAG:New(string.format("%s_FlagHold", self.groupname))
  self.flaghold:Set(0)
  
  -- Add to data base.
  _DATABASE:AddFlightGroup(self)

  -- Autostart.
  --self:__Start(0.1)
  self:Start()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a *scheduled* task.
-- @param #FLIGHTGROUP self
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #table task DCS task table stucture.
-- @param #number prio Priority of the task.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddTask(description, task, prio, clock, duration)

  -- Increase coutner.
  self.taskcounter=self.taskcounter+1

  -- Set time.
  local time=timer.getAbsTime()+5
  if clock then
    if type(clock)=="string" then
      time=UTILS.ClockToSeconds(clock)
    elseif type(clock)=="number" then
      time=timer.getAbsTime()+clock
    end
  end

  -- Task data structure.
  local newtask={} --#FLIGHTGROUP.Task
  newtask.description=description
  newtask.status=FLIGHTGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.prio=prio or 50
  newtask.time=time
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.waypoint=-1
  newtask.type=FLIGHTGROUP.TaskType.SCHEDULED
  
  -- Info.
  self:I(self.sid..string.format("Adding task %s scheduled at %s", newtask.description, UTILS.SecondsToClock(time, true)))

  -- Debug info.
  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)

  return self
end

--- Add a *waypoint* task.
-- @param #FLIGHTGROUP self
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #table task DCS task table stucture.
-- @param #number waypointindex Number of waypoint. Counting starts at one! 
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddTaskWaypoint(description, task, waypointindex, prio, duration)

  -- Increase coutner.
  self.taskcounter=self.taskcounter+1

  -- Task data structure.
  local newtask={} --#FLIGHTGROUP.Task
  newtask.description=description
  newtask.status=FLIGHTGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.prio=prio or 50
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.time=0
  newtask.waypoint=waypointindex
  newtask.type=FLIGHTGROUP.TaskType.WAYPOINT

  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)
  
  if self.group and self.group:IsAlive() then
    self:_UpdateRoute()
  end

  return self
end

--- Set squadron the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @param Ops.Squadron#SQUADRON squadron The squadron object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetSquadron(squadron)
  self:I(self.sid..string.format("Add flight to SQUADRON %s", squadron.squadronname))
  self.squadron=squadron
  return self
end

--- Get squadron the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @return Ops.Squadron#SQUADRON The squadron object.
function FLIGHTGROUP:GetSquadron()
  return self.squadron
end

--- Set the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @param Ops.FlightControl#FLIGHTCONTROL flightcontrol The FLIGHTCONTROL object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFlightControl(flightcontrol)
  self:I(self.sid..string.format("Setting FLIGHTCONTROL to airbase %s", flightcontrol.airbasename))
  self.flightcontrol=flightcontrol
  return self
end

--- Get the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @return Ops.FlightControl#FLIGHTCONTROL The FLIGHTCONTROL object.
function FLIGHTGROUP:GetFlightControl()
  return self.flightcontrol
end

--- Set low fuel threshold. Triggers event "FuelLow" and calls event function "OnAfterFuelLow".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 25 %.
-- @param #boolean rtb If true, RTB on fuel low event.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelLowThreshold(threshold, rtb)
  self.fuellow=false
  self.fuellowthresh=threshold or 25
  self.fuellowrtb=rtb
  return self
end

--- Set fuel critical threshold. Triggers event "FuelCritical" and event function "OnAfterFuelCritical".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 10 %.
-- @param #boolean rtb If true, RTB on fuel critical event.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelCriticalThreshold(threshold, rtb)
  self.fuelcritical=false
  self.fuelcriticalthresh=threshold or 10
  self.fuelcriticalrtb=rtb
  return self
end

--- Get set of decteded units.
-- @param #FLIGHTGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function FLIGHTGROUP:GetDetectedUnits()
  return self.detectedunits
end

--- Get MOOSE group object.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Group#GROUP Moose group object.
function FLIGHTGROUP:GetGroup()
  return self.group
end

--- Get flight group name.
-- @param #FLIGHTGROUP self
-- @return #string Group name.
function FLIGHTGROUP:GetName()
  return self.group:GetName()
end

--- Get waypoint.
-- @param #FLIGHTGROUP self
-- @param #number indx Waypoint index.
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypoint(indx)
  return self.waypoints[indx]
end

--- Get final waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointFinal()
  return self.waypoints[#self.waypoints]
end

--- Get next waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointNext()
  local n=math.min(self.currentwp+1, #self.waypoints)
  return self.waypoints[n]
end

--- Get current waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointCurrent()
  return self.waypoints[self.currentwp]
end

--- Check if flight is in state spawned.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsSpawned()
  return self:Is("Spawned")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsParking()
  return self:Is("Parking")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsTaxiing()
  return self:Is("Taxiing")
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsAirborne()
  return self:Is("Airborne")
end

--- Check if flight is landing.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsLanded()
  return self:Is("Landing")
end

--- Check if flight has landed and is now taxiing to its parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsLanded()
  return self:Is("Landed")
end

--- Check if flight has arrived at its destination parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsArrived()
  return self:Is("Arrived")
end

--- Check if flight is holding and waiting for landing clearance.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is holding.
function FLIGHTGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if flight is dead.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsDead()
  return self:Is("Dead")
end

--- Check if flight low on fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is low on fuel.
function FLIGHTGROUP:IsFuelLow()
  return self.fuellow
end

--- Check if flight critical on fuel
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is critical on fuel.
function FLIGHTGROUP:IsFuelCritical()
  return self.fuelcritical
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group v%s", FLIGHTGROUP.version)
  self:I(self.sid..text)
  
  -- Check if the group is already alive and if so, add its elements.
  local group=GROUP:FindByName(self.groupname)
  
  if group and group:IsAlive() then
  
    -- Set group object.
    self.group=group
    
    -- Get units of group.
    local units=group:GetUnits()

    -- Debug info.    
    self:I(self.sid..string.format("FF Found alive group %s at start with %d units", group:GetName(), #units))
    
    
    -- Add elemets.
    for _,unit in pairs(units) do
      local element=self:AddElementByName(unit:GetName())
    end
    
    -- Trigger spawned event for all elements.
    for _,element in pairs(self.elements) do
      self:ElementSpawned(element)    
    end
    
  end    
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self.OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self.OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self.OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self.OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self.OnEventEngineShutdown)
  self:HandleEvent(EVENTS.PilotDead,      self.OnEventPilotDead)
  self:HandleEvent(EVENTS.Ejection,       self.OnEventEjection)
  self:HandleEvent(EVENTS.Crash,          self.OnEventCrash)
  self:HandleEvent(EVENTS.RemoveUnit,     self.OnEventRemoveUnit)

  -- Start the status monitoring.
  self:__FlightStatus(-1)
end

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckDetectedUnits()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d. FC=%s. Destination=%s",
  fsmstate, #self.elements, #self.elements, self.taskcurrent, #self.taskqueue, self.currentwp or 0, self.waypoints and #self.waypoints or 0, 
  self.detectedunits:Count(), self.flightcontrol and self.flightcontrol.airbasename or "none", self.destination and self.destination:GetName() or "unknown")
  self:I(self.sid..text)

  -- Element status.
  text="Elements:"
  local fuelmin=999999
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    local name=element.name
    local status=element.status
    local unit=element.unit
    local fuel=unit:GetFuel() or 0
    local life=unit:GetLifeRelative() or 0
    
    if fuel*100<fuelmin then
      fuelmin=fuel*100
    end

    -- Check if element is not dead and we missed an event.
    if life<0 and element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      self:ElementDead(element)
    end
    
    -- Get ammo.
    local nammo=0
    local nshells=0
    local nrockets=0
    local nbombs=0
    local nmissiles=0
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      nammo, nshells, nrockets, nbombs, nmissiles=self:GetAmmoElement(element)
    end

    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f, shells=%d, rockets=%d, bombs=%d, missiles=%d", i, name, status, fuel*100, life*100, nshells, nrockets, nbombs, nmissiles)
  end
  if #self.elements==0 then
    text=text.." none!"
  end
  self:I(self.sid..text)
  
  -- Low fuel?
  if fuelmin<self.fuellowthresh and not self.fuellow then
    self:FuelLow()
  end
  
  -- Critical fuel?
  if fuelmin<self.fuelcriticalthresh and not self.fuelcritical then
    self:FuelCritical()
  end  

  -- Task queue.
  text=string.format("Tasks #%d", #self.taskqueue)
  for i,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    local name=task.description
    local taskid=task.dcstask.id or "unknown"
    local status=task.status
    local clock=UTILS.SecondsToClock(task.time)
    local eta=task.time-timer.getAbsTime()
    local started=UTILS.SecondsToClock(task.timestamp or 0)
    local duration=-1
    if task.duration then
      duration=task.duration
      if task.timestamp then
        duration=task.duration-(timer.getAbsTime()-task.timestamp)
      else
        duration=task.duration
      end
    end
    -- Output text for element.
    text=text..string.format("\n[%d] %s: %s: status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, taskid, name, status, clock, eta, started, duration)
  end
  self:I(self.sid..text)


  -- Next check in ~30 seconds.
  self:__FlightStatus(-30)
end

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterQueueUpdate(From, Event, To)

  -- Check no current task.
  if self.taskcurrent<=0 then

    -- Get task from queue.
    local task=self:GetTask()

    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end
    
  else
  
    -- Get current task.
    local task=self:GetTaskCurrent()
    
    -- Check if task has a defined duration.
    if task and task.duration and task.timestamp then
          
      -- Check if max task duration is over.
      local cancel=timer.getAbsTime()>task.timestamp+task.duration
      
      --self:E(string.format("FF timestap=%d , duration=%d, time=%d, stamp+duration=%s < time = %s", task.timestamp, task.duration, timer.getAbsTime(), task.timestamp+task.duration, tostring(cancel)))
      
      -- Cancel task if task is running longer than duration.
      if cancel then
        self:TaskCancel()
      end
    end

  end

  -- Update queue every ~5 sec.
  self:__QueueUpdate(-5)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function, handling the birth of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Set group.
    self.group=self.group or EventData.IniGroup
    
    -- Set homebase if not already set.
    if EventData.Place then
      self.homebase=self.homebase or EventData.Place
    end
        
    -- Get element.
    local element=self:GetElementByName(unitname)

    -- Create element spawned event if not already present.
    if not self:_IsElement(unitname) then
      element=self:AddElementByName(unitname)
    end
      
    -- Set element to spawned state.
    self:T(self.sid..string.format("EVENT: Element %s born ==> spawned", element.name))            
    self:ElementSpawned(element)    
    
  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineStartup(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      if self:IsAirborne() or self:IsHolding() then
        -- TODO: what?
      else
        self:T(self.sid..string.format("EVENT: Element %s started engines ==> taxiing (if AI)", element.name))
        -- TODO: could be that this element is part of a human flight group.
        -- Problem: when player starts hot, the AI does too and starts to taxi immidiately :(
        --          when player starts cold, ?
        if self.ai then
          self:ElementTaxiing(element)
        end
      end
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventTakeOff(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.sid..string.format("EVENT: Element %s took off ==> airborne", element.name))
      self:ElementTakeoff(element, EventData.Place)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventLanding(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    local airbase=EventData.Place

    local airbasename="unknown"
    if airbase then
      airbasename=tostring(airbase:GetName())
    end

    if element then
      self:T3(self.sid..string.format("EVENT: Element %s landed at %s ==> landed", element.name, airbasename))
      self:ElementLanded(element, airbase)      
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineShutdown(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
    
      if element.unit and element.unit:IsAlive() then
    
        local coord=unit:GetCoordinate()
        
        local airbase=coord:GetClosestAirbase()
        
        local _,_,dist,parking=coord:GetClosestParkingSpot(airbase)
        
        if dist and dist<10 and unit:InAir()==false then
          self:ElementArrived(element, airbase, parking)
          self:T3(self.sid..string.format("EVENT: Element %s shut down engines ==> arrived", element.name))
        else
          self:T3(self.sid..string.format("EVENT: Element %s shut down engines (in air) ==> dead", element.name))
          self:ElementDead(element)
        end
        
      else
      
        self:T(self.sid..string.format("EVENT: Element %s shut down engines but is NOT alive ==> waiting for crash event (==> dead)", element.name))

      end
      
    else
    end

  end

end


--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.sid..string.format("EVENT: Element %s crashed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.sid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementSpawned(From, Event, To, Element)
  self:I(self.sid..string.format("Element spawned %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.SPAWNED)

  if Element.unit:InAir() then
    self:ElementAirborne(Element)
  else
      
    -- Get parking spot.
    local spot, dist=self:GetParkingSpot(Element)
    
    if dist<10 then
    
      Element.parking=spot
  
      self:ElementParking(Element)
    else
      self:E(self.sid..string.format("Element spawned not in air but not on any parking spot."))
    end
  end
end

--- On after "ElementParking" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementParking(From, Event, To, Element)
  self:I(self.sid..string.format("Element parking %s at spot %s.", Element.name, tostring(Element.parking.TerminalID)))
  
  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.PARKING)
end

--- On after "ElementTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementTaxiing(From, Event, To, Element)
  self:T2(self.sid..string.format("Element taxiing %s.", Element.name))
  
  -- Not parking any more.
  Element.parking=nil

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAXIING)
end

--- On after "ElementTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementTakeoff(From, Event, To, Element, airbase)
  self:T(self.sid..string.format("Element takeoff %s at %s airbase.", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAKEOFF, airbase)
  
  -- Trigger element airborne event.
  self:__ElementAirborne(10, Element)
end

--- On after "ElementAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementAirborne(From, Event, To, Element)
  self:T2(self.sid..string.format("Element airborne %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.AIRBORNE)
end

--- On after "ElementLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementLanded(From, Event, To, Element, airbase)
  self:T2(self.sid..string.format("Element landed %s at %s airbase", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.LANDED, airbase)
end

--- On after "ElementArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementArrived(From, Event, To, Element)
  self:T2(self.sid..string.format("Element arrived %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ARRIVED)
end

--- On after "ElementDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDead(From, Event, To, Element)
  self:T2(self.sid..string.format("Element dead %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.DEAD)
end


--- On after "FlightSpawned" event. Sets the template, initializes the waypoints.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightSpawned(From, Event, To)
  self:I(string.format("FF Flight group %s spawned!", tostring(self.groupname)))

  -- Get template of group.
  self.template=self.group:GetTemplate()
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
  local unit=self.group:GetUnit(1)
  
  self.descriptors=unit:GetDesc()
  
  self.actype=unit:GetTypeName()
  
  self.ceiling=self.descriptors.Hmax
  
  self.ai=not self:_IsHuman(self.group)
  
  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    element.ai=not self:_IsHumanUnit(element.unit)
  end

  -- Init waypoints.
  if not self.waypoints then
    self:InitWaypoints()
  end
  
  if not self.ai then
    if self.flightcontrol then
      --self.flightcontrol:_CreatePlayerMenu(self)
    end
  end  
    
end

--- On after "FlightParking" event. Add flight to flightcontrol of airbase.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightParking(From, Event, To)
  self:I(self.sid..string.format("Flight is parking %s.", self.groupname))

  local airbase=self.group:GetCoordinate():GetClosestAirbase()
  
  local airbasename=airbase:GetName() or "unknown"
  
  -- Parking time stamp.
  self.Tparking=timer.getAbsTime()

  local flightcontrol=_DATABASE:GetFlightControl(airbasename)
  
  if flightcontrol then
    self:SetFlightControl(flightcontrol)
  
    if self.flightcontrol then
    
      -- Add flight to parking queue, waiting for takeoff cleance.
      self.flightcontrol:_AddFlightToParkingQueue(self)
      
    end
  end  
end


--- On after "FlightTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightTaxiing(From, Event, To)
  self:T(self.sid..string.format("Flight is taxiing %s.", self.groupname))
  
  -- Parking over.
  self.Tparking=nil

  -- TODO: need a better check for the airbase.
  local airbase=self.group:GetCoordinate():GetClosestAirbase(nil, self.group:GetCoalition())

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    -- Add flight to takeoff queue.
    self.flightcontrol:_AddFlightToTakeoffQueue(self)
    
    -- Remove flight from parking queue.
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qparking, self, "parking")
  end

end

--- On after "FlightTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightTakeoff(From, Event, To, airbase)
  self:T(self.sid..string.format("Flight takeoff %s at %s.", self.groupname, airbase and airbase:GetName() or "unknown airbase"))

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qtakeoff, self, "takeoff")
  end
  
  -- Trigger airborne event.
  self:__FlightAirborne(1, airbase)
  
end

--- On after "FlightAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightAirborne(From, Event, To, airbase)
  self:T(self.sid..string.format("Flight airborne %s at %s.", self.groupname,airbase and airbase:GetName() or "unknown airbase"))

  -- Remove flight from FC takeoff queue.
  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    --self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qtakeoff, self, "takeoff")
  end
  
  -- Update queue.
  self:__QueueUpdate(-1)
  
end

--- On after "FlightLanding" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightLanding(From, Event, To)
  self:T(self.sid..string.format("Flight landing %s", self.groupname))

  self:_SetElementStatusAll(FLIGHTGROUP.ElementStatus.LANDING)
  
end

--- On after "FlightLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightLanded(From, Event, To, airbase)
  self:T(self.sid..string.format("Flight landed %s at %s.", self.groupname, airbase and airbase:GetName() or "unknown airbase"))

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qlanding, self, "landing")
  end
end

--- On after "FlightArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightArrived(From, Event, To)
  self:T(self.sid..string.format("Flight arrived %s", self.groupname))
end

--- On after "FlightDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightDead(From, Event, To)
  self:T(self.sid..string.format("Flight dead %s", self.groupname))

  -- Delete waypoints so they are re-initialized at the next spawn.
  self.waypoints=nil
end


--- On after "PassingWaypoint" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number passed.
-- @param #number N Final waypoint number.
function FLIGHTGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  local text=string.format("Flight %s passed waypoint %d/%d", self.groupname, n, N)
  self:I(self.sid..text)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
end

--- On after "FuelLow" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelLow(From, Event, To)

  -- Debug message.
  local text=string.format("Low fuel for flight group %s", self.groupname)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  -- Set switch to true.
  self.fuellow=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destination or self.homebase
  
  if airbase and self.fuellowrtb then
    self:RTB(airbase)
  end
end

--- On after "FuelCritical" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelCritical(From, Event, To)

  -- Debug message.
  local text=string.format("Critical fuel for flight group %s", self.groupname)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  -- Set switch to true.
  self.fuelcritical=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destination or self.homebase
  
  if airbase and self.fuelcriticalrtb then
    self:RTB(airbase)
  end
end


--- On after "RTB" event. Send flightgroup back to base.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The base to return to.
function FLIGHTGROUP:onafterRTB(From, Event, To, airbase)

  -- Debug message.
  local text=string.format("Flight group returning to airbase %s.", airbase:GetName())
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  self:RouteRTB(airbase)
end

--- On after "Orbit" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coord Coordinate where to orbit.
-- @param #number Altitude Altitude in meters.
-- @param #number Speed Speed in km/h.
function FLIGHTGROUP:onafterOrbit(From, Event, To, Coord, Altitude, Speed)

  -- Debug message.
  local text=string.format("Flight group set to orbit at altitude %d m and speed %.1f km/h", Altitude, Speed)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  --TODO: set ROE passive. introduce roe event/state/variable.
  
  local TaskOrbit=self.group:TaskOrbit(Coord, Altitude, UTILS.KmphToMps(Speed))

  self.group:SetTask(TaskOrbit)
end

--- On before "Hold" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for travelling from current position to holding point in knots.
-- @param #number SpeedHold Holding speed in knots.
function FLIGHTGROUP:onbeforeHold(From, Event, To, airbase, SpeedTo, SpeedHold)

  if airbase==nil then
    self:E("FF airbase is nil!")
    return false
  end

  if airbase and airbase:GetCoalition()~=self.group:GetCoalition() then
    self:E("FF wrong coalition!")
    return false
  end
  
  return true
end

--- On after "Hold" event. Order flight to hold at an airbase and wait for signal to land.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for travelling from current position to holding point in knots. Default 350 kts.
-- @param #number SpeedHold Holding speed in knots. Default 250 kts.
-- @param #number SpeedLand Landing speed in knots. Default 170 kts.
function FLIGHTGROUP:onafterHold(From, Event, To, airbase, SpeedTo, SpeedHold, SpeedLand)
  
  -- Defaults:
  SpeedTo=SpeedTo or 350
  SpeedHold=SpeedHold or 250
  local SpeedLand=170

  -- Debug message.
  local text=string.format("Flight group set to hold at airbase %s", airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
 
  
  -- Holding points.
  local p0=airbase:GetZone():GetRandomCoordinate():SetAltitude(UTILS.FeetToMeters(6000))
  local p1=nil
  local wpap=nil
  
  -- Do we have a flight control?
  local fc=_DATABASE:GetFlightControl(airbase:GetName())
  if fc then
    -- Get holding point from flight control.
    local HoldingPoint=fc:_GetHoldingpoint(self)
    p0=HoldingPoint.pos0
    p1=HoldingPoint.pos1
    
    -- Debug marks.
    if self.Debug then
      p0:MarkToAll("Holding point P0")
      p1:MarkToAll("Holding point P1")
    end
    
    -- Set flightcontrol for this flight.
    self:SetFlightControl(fc)
  end
  
  self.group:ClearTasks()
  
  self.flaghold:Set(333)
  
  -- Task fuction when reached holding point.
  local TaskArrived=self.group:TaskFunction("FLIGHTGROUP._ReachedHolding", self)

  -- Orbit until flaghold=1 (=true)
  local TaskOrbit=self.group:TaskOrbit(p0, nil, UTILS.KnotsToMps(SpeedHold), p1)
  local TaskStop=self.group:TaskCondition(nil, self.flaghold.UserFlagName, 1)  
  local TaskControlled=self.group:TaskControlled(TaskOrbit, TaskStop)
  
  -- Waypoints.
  local wp={}
  wp[#wp+1]=self.group:GetCoordinate():WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {}, "Current Pos")
  wp[#wp+1]=                        p0:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {TaskArrived, TaskControlled}, "Holding Point")
  
 
  -- Respawn?
  local respawn=false
  
  if respawn then
  
    -- Get group template.
    local Template=self.group:GetTemplate()
  
    -- Set route points.
    Template.route.points=wp
    
    MESSAGE:New("Respawning group"):ToAll()

    --Respawn the group.
    self.group=self.group:Respawn(Template, true)
    
  end  
  
  -- Route the group.
  self.group:Route(wp, 1)
  
end

--- On after TaskExecute event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskExecute(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task %s ID=%d execute.", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  -- Cancel current task if there is any.
  if self.taskcurrent>0 then
    self:TaskCancel()
  end

  -- Set current task.
  self.taskcurrent=Task.id
  
  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=FLIGHTGROUP.TaskStatus.EXECUTING

  -- If task is scheduled (not waypoint) set task.
  if Task.type==FLIGHTGROUP.TaskType.SCHEDULED then

    -- Clear all tasks.
    self.group:ClearTasks()
  
    -- Task done.
    local TaskDone=self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task)
    
    local DCStasks={}
    if Task.dcstask.id=='ComboTask' then
      -- Loop over all combo tasks.
      for TaskID, Task in ipairs( Task.dcstask.params.tasks ) do
        table.insert(DCStasks, Task)
      end    
    else
      table.insert(DCStasks, Task.dcstask)
    end
    table.insert(DCStasks, TaskDone)
  
    -- Combo task.
    local TaskCombo=self.group:TaskCombo(DCStasks)
    
    env.info("FF executing Taskcombo:")
    self:I({task=TaskCombo})
  
    -- Set task for group.
    self.group:SetTask(TaskCombo)
    
  end
  
end


--- On after TaskPause event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskPause(From, Event, To, Task)

  if self.taskcurrent>0 then

    -- Clear all tasks.
    self.group:ClearTasks()

    -- Task status executing.
    Task.status=1 --FLIGHTGROUP.TaskStatus.PAUSED

  end

end

--- On after "TaskCancel" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskCancel(From, Event, To)
  
  -- Get current task.
  local task=self:GetTaskCurrent()
  
  if task then
    local text=string.format("Task %s ID=%d cancelled.", task.description, task.id)
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)    
    self:I(self.sid..text)
    -- Clear tasks.
    self.group:ClearTasks()
    self:TaskDone(task)  
  else
    local text=string.format("WARNING: No current task to cancel!")
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:I(self.sid..text)      
  end
end


--- On after TaskDone event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  -- No current task.
  self.taskcurrent=0
  
  -- Task status done.
  Task.status=FLIGHTGROUP.TaskStatus.ACCOMPLISHED
  
  -- Update route.
  self:_UpdateRoute()
  
end


--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
-- @parma #string assignment The (optional) assignment for the asset.
function FLIGHTGROUP:onafterDetectedUnit(From, Event, To, Unit)
  self:I(self.sid..string.format("Detected unit %s.", Unit:GetName()))
  self.detectedunits:AddUnit(Unit)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get next task in queue. Task needs to be in state SCHEDULED and time must have passed.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:GetTask()

  if #self.taskqueue==0 then
    return nil
  else

    -- Sort results table wrt times they have already been engaged.
    local function _sort(a, b)
      local taskA=a --#FLIGHTGROUP.Task
      local taskB=b --#FLIGHTGROUP.Task
      return (taskA.time<taskB.time) or (taskA.time==taskB.time and taskA.prio<taskB.prio)
    end

    table.sort(self.taskqueue, _sort)

    local time=timer.getAbsTime()

    -- Look for first task that is not accomplished.
    for _,_task in pairs(self.taskqueue) do
      local task=_task --#FLIGHTGROUP.Task
      if task.type==FLIGHTGROUP.TaskType.SCHEDULED and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and time>=task.time then
        return task
      end
    end

  end

  return nil
end


--- Get the unfinished waypoint tasks
-- @param #FLIGHTGROUP self
-- @param #number n Waypoint index. Counting starts at one.
-- @return #table Table of tasks. Table could also be empty {}.
function FLIGHTGROUP:GetTasksWaypoint(n)

  if #self.taskqueue==0 then
    return {}
  else

    -- Sort results table wrt times they have already been engaged.
    local function _sort(a, b)
      local taskA=a --#FLIGHTGROUP.Task
      local taskB=b --#FLIGHTGROUP.Task
      return (taskA.time<taskB.time) or (taskA.time==taskB.time and taskA.prio<taskB.prio)
    end

    table.sort(self.taskqueue, _sort)


    -- Tasks table.    
    local tasks={}

    -- Look for first task that is not accomplished.
    for _,_task in pairs(self.taskqueue) do
      local task=_task --#FLIGHTGROUP.Task
      if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and task.waypoint==n then
        table.insert(tasks, task)
      end
    end

    return tasks
  end

  return nil
end


--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskExecute(group, flightgroup, task)

  -- Debug message.
  local text=string.format("Task Execute %s", task.description)
  flightgroup:T2(flightgroup.sid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskExecute(task)
  end
end

--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskDone(group, flightgroup, task)

  -- Debug message.
  local text=string.format("Task Done %s", task.description)
  flightgroup:T2(flightgroup.sid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskDone(task)
  end
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #FLIGHTGROUP flightgroup Flightgroup object.
--@param #number i Waypoint number that has been reached.
function FLIGHTGROUP._PassingWaypoint(group, flightgroup, i)

  local final=#flightgroup.waypoints or 1

  -- Debug message.
  local text=string.format("Group %s passing waypoint %d of %d.", group:GetName(), i, final)

  -- Debug smoke and marker.
  if flightgroup.Debug then
    local pos=group:GetCoordinate()
    --pos:SmokeRed()
    --local MarkerID=pos:MarkToAll(string.format("Group %s reached waypoint %d", group:GetName(), i))
  end

  -- Debug message.
  flightgroup:T3(flightgroup.sid..text)

  -- Set current waypoint.
  flightgroup.currentwp=i

  -- Passing Waypoint event.
  flightgroup:PassingWaypoint(i, final)

  -- If final waypoint reached, do route all over again.
  if i==final and final>1 then
    --TODO: final waypoint reached! what next?
  end
end

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ReachedHolding(group, flightgroup)
  flightgroup:T(flightgroup.sid..string.format("Group %s reached holding point", group:GetName()))
  
  if flightgroup.Debug then
    group:GetCoordinate():MarkToAll("Holding Point Reached")
  end
  
  flightgroup.flaghold:Set(666)
  
  -- Add flight to waiting/holding queue.
  if flightgroup.flightcontrol then
    flightgroup.flightcontrol:_AddFlightToHoldingQueue(flightgroup)
  end
end

--- Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param Wrapper.Group#GROUP group The Moose group object.
-- @param #FLIGHTGROUP flightgroup The flight group object.
-- @param Wrapper.Airbase#AIRBASE destination Destination airbase
function FLIGHTGROUP._DestinationOverhead(group, flightgroup, destination)

  -- Tell the flight to hold.
  -- WARNING: This needs to be delayed or we get a CTD!
  flightgroup:__Hold(1, destination)

end


--- Route flight group back to base.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE RTBAirbase
-- @param #number Speed Speed in km/h.
-- @param #number Altitude Altitude in meters.
-- @param #table TaskOverhead Task to execute when reaching overhead waypoint.
function FLIGHTGROUP:RouteRTB(RTBAirbase, Speed, Altitude, TaskOverhead)

  -- If speed is not given take 80% of max speed.
  Speed=Speed or self.speedmax*0.8

  -- Curent (from) waypoint.
  local coord=self.group:GetCoordinate()

  if Altitude then
    coord:SetAltitude(Altitude)
  end

  -- Current coordinate.
  local PointFrom=coord:WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Overhead pass.
  local PointOverhead=RTBAirbase:GetCoordinate():SetAltitude(Altitude or coord.y):WaypointAirTurningPoint(nil, Speed, TaskOverhead, "Overhead Pass")

  -- Landing waypoint.
  local PointLanding=RTBAirbase:GetCoordinate():SetAltitude(20):WaypointAirLanding(Speed, RTBAirbase, {}, "Landing")

  -- Waypoint table.
  local Points={PointFrom, PointOverhead, PointLanding}

  -- Get group template.
  local Template=self.group:GetTemplate()

  -- Set route points.
  Template.route.points=Points

  -- Respawn the group.
  --self.group=self.group:Respawn(Template, true)
  
  local TaskRTB=self.group:TaskRoute(Points)
  
  --[[
  self.taskcounter=self.taskcounter+1
  
  local task={} --#FLIGHTGROUP.Task
  task.dcstask=TaskRTB
  task.description="RTB"
  task.id=self.taskcounter
  task.type=FLIGHTGROUP.TaskType.SCHEDULED
  task.prio=0
  task.time=timer.getAbsTime()
  ]]
  
  self:AddTask("RTB", TaskRTB, 0)
  
  self:TaskCancel()

  -- Route the group or this will not work.
  --self.group:Route(Points, 1)

end


--- Route flight group to orbit.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE CoordOrbit Orbit coordinate.
-- @param #number Speed Speed in km/h. Default 60% of max group speed.
-- @param #number Altitude Altitude in meters. Default 10,000 ft.
-- @param Core.Point#COORDINATE CoordRaceTrack (Optional) Race track coordinate.
function FLIGHTGROUP:RouteOrbit(CoordOrbit, Speed, Altitude, CoordRaceTrack)

  -- If speed is not given take 80% of max speed.
  Speed=Speed or self.group:GetSpeedMax()*0.6

  -- Altitude.
  local altitude=Altitude or UTILS.FeetToMeters(10000)

  -- Waypoints.
  local wp={}

  -- Current coordinate.
  wp[1]=self.group:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Orbit
  wp[2]=CoordOrbit:SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Orbit")


  local TaskOrbit=self.group:TaskOrbit(CoordOrbit, altitude, Speed, CoordRaceTrack)
  local TaskRoute=self.group:TaskRoute(wp)

  --local TaskCondi=self.group:TaskCondition(time,userFlag,userFlagValue,condition,duration,lastWayPoint)

  local TaskCombo=self.group:TaskControlled(TaskRoute, TaskOrbit)

  self.group:SetTask(TaskCombo, 1)

  -- Route the group or this will not work.
  --self.group:Route(wp, 1)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an element to the flight group.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element or nil.
function FLIGHTGROUP:AddElementByName(unitname)

  local unit=UNIT:FindByName(unitname)

  if unit then

    local element={} --#FLIGHTGROUP.Element

    element.name=unitname
    element.unit=unit
    element.status=FLIGHTGROUP.ElementStatus.INUTERO
    element.group=unit:GetGroup()
    
    element.modex=element.unit:GetTemplate().onboard_num
    element.skill=element.unit:GetTemplate().skill
    element.pylons=element.unit:GetTemplatePylons()
    element.fuelmass=element.unit:GetTemplatePayload().fuel
    element.category=element.unit:GetCategory()
    element.categoryname=element.unit:GetCategoryName()
    element.callsign=element.unit:GetCallsign()
    
    if element.skill=="Client" or element.skill=="Player" then
      element.ai=false
      element.client=CLIENT:FindByName(unitname)
    else
      element.ai=true
    end
    
    local text=string.format("Adding element %s: status=%s, skill=%s, modex=%s, fuelmass=%.1f, category=%d, categoryname=%s, callsign=%s, ai=%s",
    element.name, element.status, element.skill, element.modex, element.fuelmass, element.category, element.categoryname, element.callsign, tostring(element.ai))
    self:I(self.sid..text)

    -- Add element to table.
    table.insert(self.elements, element)

    return element
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element.
function FLIGHTGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return element
    end

  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetHomebaseFromWaypoints()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp and wp.action and wp.action==COORDINATE.WaypointAction.FromParkingArea or wp.action==COORDINATE.WaypointAction.FromParkingAreaHot or wp.action==COORDINATE.WaypointAction.FromRunway  then
      
      -- Get airbase ID depending on airbase category.
      local airbaseID=wp.airdromeId or wp.helipadId
      
      local airbase=AIRBASE:FindByID(airbaseID)
      
      return airbase    
    end
    
    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.
    
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetDestinationFromWaypoints()

  local wp=self:GetWaypointFinal()
  
  if wp then
    
    if wp and wp.action and wp.action==COORDINATE.WaypointAction.Landing then
      
      -- Get airbase ID depending on airbase category.
      local airbaseID=wp.airdromeId or wp.helipadId
      
      local airbase=AIRBASE:FindByID(airbaseID)
      
      return airbase    
    end
    
    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.
    
  end

  return nil
end


--- Check if task description is unique.
-- @param #FLIGHTGROUP self
-- @param #string description Task destription
-- @return #boolean If true, no other task has the same description.
function FLIGHTGROUP:CheckTaskDescriptionUnique(description)

  -- Loop over tasks in queue
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.description==description then
      return false
    end    
  end
  
  return true
end

--- Get the currently executed task if there is any.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP.Task Current task or nil.
function FLIGHTGROUP:GetTaskCurrent()
  return self:GetTaskByID(self.taskcurrent, FLIGHTGROUP.TaskStatus.EXECUTING)
end

--- Get task by its id.
-- @param #FLIGHTGROUP self
-- @param #number id Task id.
-- @param #string status (Optional) Only return tasks with this status, e.g. FLIGHTGROUP.TaskStatus.SCHEDULED.
-- @return #FLIGHTGROUP.Task The task or nil.
function FLIGHTGROUP:GetTaskByID(id, status)

  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task

    if task.id==id then
      if status==nil or status==task.status then
        return task
      end
    end

  end

  return nil
end


--- Get next waypoint of the flight group.
-- @param #FLIGHTGROUP self
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
-- @return #number Number of waypoint.
function FLIGHTGROUP:GetNextWaypoint()

  -- Next waypoint.
  local Nextwp=nil
  if self.currentwp==#self.waypoints then
    Nextwp=1
  else
    Nextwp=self.currentwp+1
  end

  -- Debug output
  local text=string.format("Current WP=%d/%d, next WP=%d", self.currentwp, #self.waypoints, Nextwp)
  self:T2(self.lid..text)

  -- Next waypoint.
  local nextwp=self.waypoints[Nextwp] --Core.Point#COORDINATE

  return nextwp,Nextwp
end

--- Get next waypoint coordinates.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint table.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function FLIGHTGROUP:GetWaypointCoordinate(wp)
  -- TODO: move this to COORDINATE class.
  return COORDINATE:New(wp.x, wp.alt, wp.y)
end

--- Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param #FLIGHTGROUP self
-- @param #number n Number of next waypoint. Default self.currentwp+1.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateRoute(n)

  -- TODO: what happens if currentwp=#waypoints
  n=n or self.currentwp+1
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks()

  local wp={}
  
  -- Set current waypoint or we get problem that the _PassingWaypoint function is triggered too early, i.e. right now and not when passing the next WP.
  -- TODO: This, however, leads to the flight to go right over this point when it is on an airport ==> Need to test Waypoint takeoff 
  local current=self.group:GetCoordinate():WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, 350, true, nil, {}, "Current")
  table.insert(wp, current)

  -- Set "remaining" waypoits.
  for i=n, #self.waypoints do
    local w=self.waypoints[i]
    if self.Debug then
      --self:GetWaypointCoordinate(w):MarkToAll(string.format("UpdateRoute Waypoint %d", i))
    end
    table.insert(wp, w)
  end
  
  -- Get destination airbase from waypoints.
  self.homebase=self:GetHomebaseFromWaypoints() or self.homebase
  
  -- Get destination airbase from waypoints.
  self.destination=self:GetDestinationFromWaypoints() or self.destination
  
  if self.destination and #wp>0 and _DATABASE:GetFlightControl(self.destination:GetName()) then
  
    -- Task to hold.
    local TaskOverhead=self.group:TaskFunction("FLIGHTGROUP._DestinationOverhead", self, self.destination)
    
    
    local coordoverhead=self.destination:GetZone():GetRandomCoordinate():SetAltitude(UTILS.FeetToMeters(6000))
  
    -- Add overhead waypoint.
    local wpoverhead=coordoverhead:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, 500, false, nil, {TaskOverhead}, "Destination Overhead")
    self:I(self.sid..string.format("Adding overhead waypoint as #%d", #wp))
    
    
    table.insert(wp, #wp, wpoverhead)
  end
  
  
  -- Debug info.
  self:I(self.sid..string.format("Updating route for WP>=%d (%d/%d) homebase=%s destination=%s", n, #wp, #self.waypoints, self.homebase and self.homebase:GetName() or "unknown", self.destination and self.destination:GetName() or "unknown"))
  
  if #wp>0 then

    -- Route group to all defined waypoints remaining.
    self.group:Route(wp, 1)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    -- Get destination or home airbase.
    local airbase=self.destination or self.homebase
    
    if self:IsAirborne() then
    
      -- TODO: check if no more scheduled tasks.
      
      if airbase then
          -- Route flight to destination/home.
          self:RTB(airbase)        
      else
        -- Let flight orbit.
        --self:Orbit(self.group:GetCoordinate(), UTILS.FeetToMeters(20000), self.group:GetSpeedMax()*0.4)
      end
      
    end
    
  end
  
  return self
end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateWaypointTasks()

  for i,wp in pairs(self.waypoints) do
    
    if i>self.currentwp or #self.waypoints==1 then
    
      self:T(self.sid..string.format("Updating waypoint task for waypoint %d/%d. Last waypoint passed %d.", i, #self.waypoints, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("FLIGHTGROUP._PassingWaypoint", self, i)
      
      table.insert(taskswp, TaskPassingWaypoint)
      
      -- Get taks
      local tasks=self:GetTasksWaypoint(i)
      
      if #tasks>0 then
        for _,task in pairs(tasks) do
          local Task=task --#FLIGHTGROUP.Task
          
          -- Add task execute.
          table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskExecute", self, Task))
  
          -- Add task itself.
          table.insert(taskswp, Task.dcstask)
          
          -- Add task done.
          table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task))
        end
      end
          
      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)
          
      -- Debug info.
      self:T3({wptask=taskswp})
      
    end
  end

end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @param #table waypoints Table of waypoints. Default is from group template.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:InitWaypoints(waypoints)

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=waypoints or self.waypoints0
  
  self:I(self.sid..string.format("Initializing %d waypoints", #self.waypoints))

  -- Init array.
  self.coordinates={}

  -- Set waypoint table.
  for i,point in ipairs(self.waypoints or {}) do

    -- Coordinate of the waypoint
    local coord=COORDINATE:New(point.x, point.alt, point.y)

    -- Set velocity of the coordinate.
    coord:SetVelocity(point.speed)

    -- Add to table.
    table.insert(self.coordinates, coord)

    -- Debug info.
    if self.Debug then
      --coord:MarkToAll(string.format("Flight %s waypoint %d, Speed=%.1f knots", self.groupname, i, UTILS.MpsToKnots(point.speed)))
    end

  end

  -- Set current waypoint. Counting starts a one.
  self.currentwp=1
  
  -- Update route.
  if #self.waypoints>0 then
    self:_UpdateRoute(1)
  end

  return self
end

--- Add a waypoint to the flight plan.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #number speed Speed in knots. Default 350 kts.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddWaypointAir(coordinate, wpnumber, speed)

  -- Waypoint number.
  wpnumber=wpnumber or #self.waypoints+1
  
  -- Speed in knots.
  speed=speed or 350

  -- Speed at waypoint.
  local speedkmh=UTILS.KnotsToKmph(speed)

  -- Create air waypoint.
  local wp=coordinate:WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, speedkmh, true, nil, {}, string.format("Added Waypoint #%d", wpnumber))
  
  -- Add to table.
  table.insert(self.waypoints, wpnumber, wp)
  
  -- Debug info.
  self:I(self.sid..string.format("Adding AIR waypoint #%d, speed=%.1f knots. Last waypoint passed was #%s. Total waypoints #%d", wpnumber, speed, self.currentwp, #self.waypoints))
  
  -- Shift all waypoint tasks after the inserted waypoint.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and task.waypoint>=wpnumber then
      task.waypoint=task.waypoint+1
    end
  end  
  
  self:_UpdateRoute()
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function FLIGHTGROUP:_IsElement(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return true
    end

  end

  return false
end

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
function FLIGHTGROUP:_AllSameStatus(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.status==FLIGHTGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end

  end

  return true
end

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string status Status to check.
-- @return #boolean If true, all elements have a similar status.
function FLIGHTGROUP:_AllSimilarStatus(status)

  -- Check if all are dead.
  if status==FLIGHTGROUP.ElementStatus.DEAD then
    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
        -- At least one is still alive.
        return false
      end
    end
    return true
  end

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    
    self:T(self.sid..string.format("Status=%s, element %s status=%s", status, element.name, element.status))

    -- Dead units dont count ==> We wont return false for those.
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
    
      ----------
      -- ALIVE
      ----------

      if status==FLIGHTGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Check that others are not still IN UTERO
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.INUTERO  then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not stil SPAWNED
        if element.status~=status or
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not stil SPAWNED or PARKING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.TAKEOFF then

        -- Element TAKEOFF: Check that the other are not stil SPAWNED, PARKING or TAXIING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING) then
          self:T(self.sid..string.format("Status=%s, element %s status=%s ==> returning FALSE", status, element.name, element.status))
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not stil SPAWNED, PARKING, TAXIING or TAKEOFF
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING or 
          element.status==FLIGHTGROUP.ElementStatus.TAKEOFF) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not stil AIRBORNE or LANDING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not stil AIRBORNE, LANDING, or LANDED (taxiing).
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING  or
          element.status==FLIGHTGROUP.ElementStatus.LANDED)  then
          return false
        end

      end
      
    else
      -- Element is dead. We don't care unless all are dead.
    end --DEAD

  end

  self:T(self.sid..string.format("All similar status %s ==> returning TRUE", status))
  
  return true
end

--- Check if all elements of the flight group have the same status or are dead.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element.
-- @param #string newstatus New status of element
-- @param Wrapper.Airbase#AIRBASE airbase Airbase if applicable.
function FLIGHTGROUP:_UpdateStatus(element, newstatus, airbase)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus

  if newstatus==FLIGHTGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightSpawned()
    end

    --[[
    if element.unit:InAir() then
      self:ElementAirborne(element)
    else
      self:ElementParking(element)
    end
    ]]

  elseif newstatus==FLIGHTGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightParking()
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightTaxiing()
    end
    
  elseif newstatus==FLIGHTGROUP.ElementStatus.TAKEOFF then
    ---
    -- TAKEOFF
    ---

    if self:_AllSimilarStatus(newstatus) then
      -- Trigger takeoff event. Also triggers airborne event.
      self:FlightTakeoff(airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsTaxiing() then
        self:FlightAirborne()
      elseif self:IsParking() then
        --self:FlightTaxiing()
        self:FlightAirborne()
      elseif self:IsSpawned() then
        --self:FlightParking()
        --self:FlightTaxiing()
        self:FlightAirborne()
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightLanded(airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:FlightArrived()
      elseif self:IsAirborne() then
        self:FlightLanded()
        self:FlightArrived()
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightDead()
    end

  end
end

--- Set status for all elements (except dead ones).
-- @param #FLIGHTGROUP self
-- @param #string status Element status.
function FLIGHTGROUP:_SetElementStatusAll(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      element.status=status
    end
  end

end

--- Check detected units.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckDetectedUnits()

  if self.group and not self:IsDead() then

    -- Get detected DCS units.
    local detectedtargets=self.group:GetDetectedTargets()

    local detected={}
    for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
      local DetectedObject=Detection.object -- DCS#Object

      if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then
        local unit=UNIT:Find(DetectedObject)
        
        if unit and unit:IsAlive() then
          -- Name of detected unit
          local unitname=unit:GetName()

          -- Add unit to detected table of this run.        
          table.insert(detected, unit)
          
          -- Trigger detected unit event.
          self:DetectedUnit(unit)
          
          if self.detectedunits:FindUnit(unitname) then
            -- Unit is already in the detected unit set ==> Trigger "DetectedUnitKnown" event.
            self:DetectedUnitKnown(unit)
          else
            -- Unit is was not detected ==> Trigger "DetectedUnitNew" event.
            self:DetectedUnitNew(unit)
          end
          
        end
      end
    end

    -- Loop over units in detected set.
    for _,_unit in pairs(self.detectedunits:GetSet()) do
      local unit=_unit --Wrapper.Unit#UNIT

      -- Loop over detected units
      local gotit=false
      for _,_du in pairs(detected) do
        local du=_du --Wrapper.Unit#UNIT
        if unit:GetName()==du:GetName() then
          gotit=true
        end
      end

      if not gotit then
        self:DetectedUnitLost(unit)
      end

    end

  end


end

--- Get onboard number.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of the unit.
-- @return #string Modex.
function FLIGHTGROUP:_GetOnboardNumber(unitname)

  local group=UNIT:FindByName(unitname):GetGroup()

  -- Units of template group.
  local units=group:GetTemplate().units

  -- Get numbers.
  local numbers={}
  for _,unit in pairs(units) do

    if unitname==unit.name then
      return tostring(unit.onboard_num)
    end

  end

  return nil
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element The element.
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #number Total amount of ammo the whole group has left.
-- @return #number Number of shells left.
-- @return #number Number of rockets left.
-- @return #number Number of bombs left.
-- @return #number Number of missiles left.
function FLIGHTGROUP:GetAmmoElement(element, display)

  -- Default is display false.
  if display==nil then
    display=false
  end

  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  local nbombs=0

  local unit=element.unit


  -- Output.
  local text=string.format("FLIGHTGROUP group %s - unit %s:\n", self.groupname, unit:GetName())

  -- Get ammo table.
  local ammotable=unit:GetAmmo()

  if ammotable then

    local weapons=#ammotable

    -- Display ammo table
    if display then
      self:E(FLIGHTGROUP.id..string.format("Number of weapons %d.", weapons))
      self:E({ammotable=ammotable})
      self:E(FLIGHTGROUP.id.."Ammotable:")
      for id,bla in pairs(ammotable) do
        self:E({id=id, ammo=bla})
      end
    end

    -- Loop over all weapons.
    for w=1,weapons do

      -- Number of current weapon.
      local Nammo=ammotable[w]["count"]

      -- Type name of current weapon.
      local Tammo=ammotable[w]["desc"]["typeName"]

      local _weaponString = UTILS.Split(Tammo,"%.")
      local _weaponName   = _weaponString[#_weaponString]

      -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
      local Category=ammotable[w].desc.category

      -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
      local MissileCategory=nil
      if Category==Weapon.Category.MISSILE then
        MissileCategory=ammotable[w].desc.missileCategory
      end

      -- We are specifically looking for shells or rockets here.
      if Category==Weapon.Category.SHELL then

        -- Add up all shells.
        nshells=nshells+Nammo

        -- Debug info.
        text=text..string.format("- %d shells of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.ROCKET then

        -- Add up all rockets.
        nrockets=nrockets+Nammo

        -- Debug info.
        text=text..string.format("- %d rockets of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.BOMB then

        -- Add up all rockets.
        nbombs=nbombs+Nammo

        -- Debug info.
        text=text..string.format("- %d bombs of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.MISSILE then

        -- Add up all cruise missiles (category 5)
        if MissileCategory==Weapon.MissileCategory.AAM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.BM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.OTHER then
          nmissiles=nmissiles+Nammo
        end

        -- Debug info.
        text=text..string.format("- %d %s missiles of type %s\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName)

      else

        -- Debug info.
        text=text..string.format("- %d unknown ammo of type %s (category=%d, missile category=%s)\n", Nammo, Tammo, Category, tostring(MissileCategory))

      end

    end
  end

  -- Debug text and send message.
  if display then
    self:I(self.sid..text)
  else
    self:T3(self.sid..text)
  end
  MESSAGE:New(text, 10):ToAllIf(display)

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles+nbombs

  return nammo, nshells, nrockets, nbombs, nmissiles
end


--- Returns a name of a missile category.
-- @param #FLIGHTGROUP self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function FLIGHTGROUP:_MissileCategoryName(categorynumber)
  local cat="unknown"
  if categorynumber==Weapon.MissileCategory.AAM then
    cat="air-to-air"
  elseif categorynumber==Weapon.MissileCategory.SAM then
    cat="surface-to-air"
  elseif categorynumber==Weapon.MissileCategory.BM then
    cat="ballistic"
  elseif categorynumber==Weapon.MissileCategory.ANTI_SHIP then
    cat="anti-ship"
  elseif categorynumber==Weapon.MissileCategory.CRUISE then
    cat="cruise"
  elseif categorynumber==Weapon.MissileCategory.OTHER then
    cat="other"
  end
  return cat
end

--- Checks if a human player sits in the unit.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #boolean If true, human player inside the unit.
function FLIGHTGROUP:_IsHumanUnit(unit)
  
  -- Get player unit or nil if no player unit.
  local playerunit=self:_GetPlayerUnitAndName(unit:GetName())
  
  if playerunit then
    return true
  else
    return false
  end
end

--- Checks if a group has a human player.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function FLIGHTGROUP:_IsHuman(group)

  -- Get all units of the group.
  local units=group:GetUnits()
  
  -- Loop over all units.
  for _,_unit in pairs(units) do
    -- Check if unit is human.
    local human=self:_IsHumanUnit(_unit)
    if human then
      return true
    end
  end

  return false
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FLIGHTGROUP self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FLIGHTGROUP:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

--- Returns the coalition side.
-- @param #FLIGHTGROUP self
-- @return #number Coalition side number.
function FLIGHTGROUP:GetCoalition()
  return self.group:GetCoalition()
end

--- Returns the coalition side.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element of the flight group.
-- @return Wrapper.Airbase#AIRBASE.ParkingSpot
-- @return #number Distance to spot in meters.
function FLIGHTGROUP:GetParkingSpot(element)

  local coord=element.unit:GetCoordinate()

  local ab=coord:GetClosestAirbase(nil, self:GetCoalition())
  
  local _,_,dist,spot=coord:GetClosestParkingSpot(ab)

  return spot, dist
end

--- Get holding time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetHoldingTime()
  if self.Tholding then
    return timer.getAbsTime()-self.Tholding
  end
  
  return -1
end

--- Get parking time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetParkingTime()
  if self.Tparking then
    return timer.getAbsTime()-self.Tparking
  end
  
  return -1
end

--- Get number of elements alive.
-- @param #FLIGHTGROUP self
-- @param #string status (Optional) Only count number, which are in a special status.
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetNelements(status)

  local n=0
  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        if status==nil or element.status==status then
          n=n+1
        end
      end
    end
  end

  
  return n
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------