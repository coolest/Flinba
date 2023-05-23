# Flinba
FLINg Based Animation

The goal of this is to introduce a very rudimentary base level framework for fling based animations.
Fling based animations are [talk about them fr]

```lua
local pathToFliba = "42"
local flinba = require(pathToFliba).flinba

local force = 1;
local friction = 5;
local looseness = 0.15;
local label = "optional label for profiling the internal stepped function"

local anim = flinba.new(force, friction, looseness, label)

anim:onStep(function(alpha)
  object.property = initialValue * (1-alpha) + goalFinal * alpha
end)

anim:onComplete(function()
  print("wow im done")
end)

--[[
  do some computation or very complicated conditionals
 ]]
 
 if calculateVeryComplicatedConditionals() then
  anim:destroy() -- stops the fliba animation and disconnects everything, etc. 
   -- does not revert to initial value
 end
```
