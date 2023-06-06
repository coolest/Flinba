local FunctionBuilder = {}
FunctionBuilder.__index = FunctionBuilder;

function FunctionBuilder.new()
    local self = {
        _function   = function() end;
        _traceback  = "";
        _active     = false;
    }

    setmetatable(self, FunctionBuilder)

    return self
end

function FunctionBuilder:addFunction(f)
    assert(type(f) == "function", "Did not provide a function to connect");

    self._active    = true;
    self._function  = f

    return self
end

function FunctionBuilder:addTraceback(traceback)
    assert(type(traceback) == "string", "Traceback has to be a string");

    self._traceback = traceback;

    return self;
end

function FunctionBuilder:destroy()
    self._active = false;
end

function FunctionBuilder:call(...)
    if not self._active then
        return;
    end

    local ok, response = pcall(self._function, ...)

    if not ok then
        warn(self._traceback)
        warn(response)
        warn("Your function has been deleted and won't be called again.")

        self._active = false;
    end
end

return FunctionBuilder;