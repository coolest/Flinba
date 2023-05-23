local Info = {}

function Info.timeAtEnd(force, friction, looseness)
    return ((1/friction) * (looseness - force) - (1/friction))/(-force)
end

return Info