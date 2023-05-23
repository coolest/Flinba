# Flinba
FLINg Based Animation

The goal of this is to introduce a very rudimentary base level framework for fling based animations.
Fling based animations are [talk about them fr]

```lua
local pathToFliba = "42"
local flinba = require(pathToFliba).flinba

local force = 5;
local friction = 5;
local looseness = 1/1000;
local label = "optional label for profiling the internal stepped function"

local anim = flinba.new(force, friction, looseness, label)

-- subscribe to force applications
anim:onStep(function(force)
  object.CFrame = object.CFrame + CFrame.Angles(0, force/15, 0) -- edit the objects value based off of the force given
end)

anim:onComplete(function()
  print("wow im done")
end)

anim:start() -- start the anim

for i = 1, 10 do
  anim:setForce(anim:getForce() + 5) -- can set force during the anim (based off of player input or other factors)
  task.wait(0.5)
end

--[[
  do some computation or very complicated conditionals
 ]]
 
 if calculateVeryComplicatedConditionals() then
  anim:destroy() -- stops the fliba animation and disconnects everything, etc. 
 end
```
