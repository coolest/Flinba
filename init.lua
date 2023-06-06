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
        bounds      = {min = -math.huge, max = math.huge};
    };
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

    self._state.friction = {value = friction, initial = friction};

    return self
end

function FlinbaBuilder:addLooseness(looseness)
    assert(type(looseness) == "number", "Looseness is not a number");
    
    self._state.looseness = looseness;

    return self
end

function FlinbaBuilder:addBounds(min, max)
    assert(type(min) == "number", "Min value is not a number");
    assert(type(max) == "number", "Max value is not a number");

    self._state.bounds = {min = min, max = max};

    return self;
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

    self._onComplete[i]:destroy()
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
        self._state.force = math.clamp(
            self._state.force - (self._state.force/(1/self._state.friction.value)) * dt,
            self._state.bounds.min,
            self._state.bounds.max
        );

        for _, funcBuilder in ipairs(self._onStep) do
            funcBuilder:call(self._state.force);
        end

        if math.abs(self._state.force) <= self._state.looseness then
            for _, funcBuilder in ipairs(self._onComplete) do
                funcBuilder:call();
            end

            self:destroy()
        end

        if self._state.kill then
            self._state.friction.value += self._state.kill*dt
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

--[[

]]

function FlinbaBuilder:getForce()       return self._state.force;       end;
function FlinbaBuilder:getFriction()    return self._state.friction;    end;
function FlinbaBuilder:getLooseness()   return self._state.looseness;   end;
function FlinbaBuilder:getBounds()      return self._state.bounds;      end;

function FlinbaBuilder:isActive()       return #self._conns > 0         end;

return FlinbaBuilder