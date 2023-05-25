local RunService = game:GetService("RunService")

local FunctionBuilder = require(script.functionBuilder)

local FlinbaBuilder = {}
FlinbaBuilder.__index = FlinbaBuilder

function FlinbaBuilder.new()
    local self          = {}

    self._state         = {
        force       = 5; 
        friction    = {value = 5; initial = 5};
        looseness   = 0.15;
    }
    self._onComplete    = {}
    self._onStep        = {} -- a function container that will be looped over and called every step
    self._conns         = {} -- for holding internal functions

    setmetatable(self, FlinbaBuilder)

    return self;
end

function FlinbaBuilder:addForce(force)
    assert(type(force) == "number", "Force is not a number");

    self._state.force = force;

    return self
end

function FlinbaBuilder:addFriction(friction)
    assert(type(friction) == "number", "Friction is not a number");

    self._state.friction = friction;

    return self
end

function FlinbaBuilder:addLooseness(looseness)
    assert(type(looseness) == "number", "Looseness is not a number");
    
    self._state.looseness = looseness;

    return self
end

function FlinbaBuilder:onStep(f)
    local func = FunctionBuilder.new()
        :addFunction(f)
        :addTraceback(debug.traceback(1))

    return table.insert(self._onStep, func)
end

function FlinbaBuilder:removeFromStep(i)
    assert(type(i) == "number", "You remove functions by passing in an index.")

    table.remove(self._onStep, i);
end

function FlinbaBuilder:onComplete(f)
    local func = FunctionBuilder.new()
        :addFunction(f)
        :addTraceback(debug.traceback(1))

    return table.insert(self._onComplete, func)
end

function FlinbaBuilder:removeFromComplete(i)
    assert(type(i) == "number", "You remove functions by passing in an index.")

    return table.remove(self._onComplete, i);
end

function FlinbaBuilder:destroy()
    for _, conn in ipairs(self._conns) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end

    table.clear(self._conns)
    table.clear(self._onComplete)
    table.clear(self._onStep)
end

function FlinbaBuilder:start()
    local isServer = RunService:IsServer()
    local event = isServer
        and RunService.Stepped
        or  RunService.RenderStepped

    table.insert(self._conns, event:Connect(function(dt)
        self._state.force -= (self._state.force/(1/self._state.friction.value)) * dt

        for _, funcBuilder in ipairs(self._onStep) do
            funcBuilder:call();
        end

        self._protectedCalls(self._onStep, self._state.force*dt);

        if math.abs(self._state.force) <= self._state.looseness then
            for _, funcBuilder in ipairs(self._onComplete) do
                funcBuilder:call();
            end

            self:destroy()
        end

        if self._state.kill then
            self._state.friction.value -= self._state.kill*dt
        end
    end))

    return self;
end

--[[
    For changing the _state during the Flinba is active

    NOTE:
        The add methods can be used to change _state while Flinba is active at any time (may or may not be bad design)
]]

function FlinbaBuilder:setKill(kill)
    assert(not kill or kill > 0, "Kill value has to be a positive non-zero number");

    self._state.kill = kill;

    if not kill then
        self._state.friction.value = self._state.friction.initial
    end

    return self;
end

function FlinbaBuilder:incrementForce(increment)
    assert(type(increment) == "number", "Increment is not a number");

    self._state.force += increment;

    return self;
end

FlinbaBuilder.setForce = FlinbaBuilder.addForce;

return FlinbaBuilder