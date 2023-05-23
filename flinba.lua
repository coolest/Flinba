local RunService = game:GetService("RunService")

local Flinba = {}
Flinba.__index = Flinba
--[[
    For creating a new Fling Based Animation
]]
function Flinba.new(force, friction, looseness)
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

    assert(type(force)      == "number", "Force is not a number");
    assert(type(friction)   == "number", "Friction is not a number");
    assert(type(looseness)  == "number", "Looseness is not a number");

    assert(type(friction)   > 0, "Friction has to be a positive non-zero number");
    assert(type(force)      > 0, "Force has to be a positive non-zero number");
    -- looseness can be negative (a bit odd but possible)

    local self = {}
    setmetatable(self, Flinba)

    self.state = {
        force       = force;
        friction    = friction;

        -- assumes you will use the alpha to determine the values (always starts at 0 and always ends at 1)
        alpha       = 0;
    };

    -- Event used to update the value
    local isServer = RunService:IsServer()
    self._onStep = isServer
        and RunService.Stepped
        or  RunService.RenderStepped

    -- Connections that will be cleaned up when destroyed
    self._garbage = {};
    
    -- Functions are stored here then called if the Flinba ever finishes
    self._onComplete = {};
    
    return self;
end
--[[

]]
function Flinba:onStep(f)
    assert(type(f) == "function", "Did not provide a function to connect");

    return table.insert(self._garbage, self._onStep:Connect(f));
end
--[[
    For stopping a Fling Based Animation before it is completed
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
--[[
    This method may have its drawbacks but it is more easier to implement
]]
function Flinba:onComplete(f)
    assert(type(f) == "function", "Did not provide a function");

    table.insert(self._onComplete, {f, debug.traceback()}) -- might be excessive
end
--[[
    Starts the alpha transition from 0 to 1
]]
function Flinba:start()
    table.insert(self._garbage, self._onStep:Connect(function(dt)
        self.state.alpha += self.state.force                                        * dt
        self.state.force -= math.max(self.state.force/self.state.friction, 0.01)    * dt

        if self.state.alpha >= 1-self.state.looseness then
            local catch = {}
            for _, f in ipairs(self._onComplete) do
                local ok, err = pcall(f[1])
                if not ok then
                    table.insert(catch, {err, f[2]})
                end
            end

            self:destroy()

            if #catch > 0 then
                local flattened = {}
                for _, info in ipairs(catch) do
                    table.insert(table.concat(info, "\n"))
                end

                error(table.concat(flattened, "\n"))
            end
        end
    end))
end

return Flinba