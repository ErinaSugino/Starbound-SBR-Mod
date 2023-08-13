require "/scripts/spawnPoint.lua" -- Needed for findSpaceInRect function

Sexbound.TransformUtil = {}

function Sexbound.TransformUtil.findNearestUnoccupiedTile(rectSize)
    local position = entity.position()
    local bounds = mcontroller.boundBox()

    position[2] = position[2] + bounds[2]

    position = vec2.floor(position)

    -- If position at the entity's feet is not occupied then return it.
    if not world.tileIsOccupied(position, true) then
        return position
    end

    -- else
    local nearbyPosition = findSpaceInRect(rect.withCenter(position, rectSize), bounds)

    if nearbyPosition then
        nearbyPosition[2] = nearbyPosition[2] + bounds[2]

        nearbyPosition = vec2.floor(nearbyPosition)

        if not world.tileIsOccupied(nearbyPosition, true) then
            return nearbyPosition
        end
    end

    return false
end
