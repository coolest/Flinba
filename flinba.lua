local RunService = game:GetService("RunService")

local profileCounter = 0;

local Flinba = {}
Flinba.__index = Flinba
--[[
    For creating a new Fling Based Animation

    NOTE:
        You are creating a "force" where a "friction" like phenomon slows the force down, eventually to 0.
        YOU ARE NOT tweening a value from a -> b. 
        You **should be** subscribing to force changes and apply some mutation to an object or property based on the force each step.
]]
function Flinba.new(force, friction, looseness, label)
    -- default values
    if not force then
        force = 5
    end
    if not friction then
        friction = 5;
    end
    if not looseness then
        looseness = 0.15;
    end

    assert(type(force)                  == "number", "Force is not a number");
    assert(type(friction)               == "number", "Friction is not a number");
    assert(type(looseness)              == "number", "Looseness is not a number");
    assert(label == nil or type(label)  == "string", "Label must be a string, if exists");

    local self = {}
    setmetatable(self, Flinba)

    self.state = {
        force       = force;
        looseness   = looseness;
        friction    = {value = friction, initial = friction};
    };

    -- for profiling
    self._label = label or tostring(profileCounter)
    profileCounter+=1;

    -- Connections that will be cleaned up when destroyed
    self._garbage = {};
    
    -- Functions are stored here then called if the Flinba ever finishes
    self._onComplete = {};
    
    -- Functions that are called during internal onStep
    self._onStep = {}

    return self;
end
--[[
    "top level" function for objects to protected called a bunch of functions then have the error (if existant)
    formatted nicely

    intention is for internal use so there are no assertions; obviously this function is exposed so usage could happen

    NOTE:
        functions :: array[ {"function", "string"} ]
            where the "function" is the function to be called and should be of type "function" (this is not checked)
            where the "string" is a traceback to what string put this function in the table to be called 
]]
function Flinba._protectedCalls(functions, ...)
    if #functions == 0 then
        return
    end
    
    local catch = {}
    for _, f in ipairs(functions) do
        local ok, err = pcall(f[1], ...)
        if not ok then
            table.insert(catch, {err, f[2]})
        end
    end

    if #catch > 0 then
        local flattened = {}
        for _, info in ipairs(catch) do
            table.insert(table.concat(info, "\n"))
        end

        warn(table.concat(flattened, "\n"))
    end
end
--[[

]]
function Flinba:onStep(f)
    assert(type(f) == "function", "Did not provide a function to connect");

    return table.insert(self._onStep, {f, debug.traceback()})
end
--[[
    This method may have its drawbacks but it is more easier to implement
]]
function Flinba:onComplete(f)
    assert(type(f) == "function", "Did not provide a function");

    table.insert(self._onComplete, {f, debug.traceback()}) -- might be excessive
end
--[[
    For mutating force (i.e. some event happened that increases the force)
]]
function Flinba:getForce()
    return self.state.force;
end
function Flinba:setForce(force) -- to increment force do something like flinba:setForce(flinba:getForce() + 1)
    assert(type(force) == "number", "Force is not a number");

    self.state.force = force;
end
function Flinba:isActive()
    return #self._garbage > 0
end
--[[
    
]]
function Flinba:start()
    -- Event used to update the value
    local isServer = RunService:IsServer()
    local event = isServer
        and RunService.Stepped
        or  RunService.RenderStepped

    table.insert(self._garbage, event:Connect(function(dt)
        debug.profilebegin("FLINBA-" .. self._label .. "-STEPPED-"..(isServer and "SERVER" or "CLIENT"))

        self.state.force -= (self.state.force/(1/self.state.friction.value)) * dt

        self._protectedCalls(self._onStep, self.state.force*dt);

        if math.abs(self.state.force) <= self.state.looseness then
            self._protectedCalls(self._onComplete)
            self:destroy()
        end

        if self.state.kill then
            self.state.friction.value *= (1+self.state.kill*dt)
        end

        debug.profileend()
    end))
end
--[[
    
]]
function Flinba:destroy()
    for _, conn in ipairs(self._garbage) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end

    table.clear(self._garbage)
    table.clear(self._onComplete)
end

function Flinba:setKill(kill)
    assert(not kill or kill > 0, "Kill value has to be a positive non-zero number");

    self.state.kill = kill;

    if not kill then
        self.state.friction.value = self.state.friction.initial
    end
end

return Flinba