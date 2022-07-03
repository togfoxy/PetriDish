ecsUpdate = {}

local function calcRadius(entity)
    -- NOTE: assumes entity has a growth rate and age and maximum radius
    local result = entity.grows.growthRate * entity.age.value
    if result > entity.grows.maxRadius then result = entity.grows.maxRadius end
    if result < 3 then result = 3 end
    assert(result > 0)
    return result
end

local function killEntity(entity)
    -- unit test
    local ecsOrigsize = #ECS_ENTITIES
    local physicsOrigsize = #PHYSICS_ENTITIES
    --

    -- destroy the body then remove empty body from the array
    for i = 1, #PHYSICS_ENTITIES do
        if PHYSICS_ENTITIES[i].fixture:getUserData() == entity.uid.value then     --!
            PHYSICS_ENTITIES[i].body:destroy()
            table.remove(PHYSICS_ENTITIES, i)
            break
        end
    end

    -- remove the entity from the arrary
    for i = 1, #ECS_ENTITIES do
        if ECS_ENTITIES[i] == entity then
            table.remove(ECS_ENTITIES, i)
            break
        end
    end

    -- destroy the entity
    entity:destroy()

    -- unit test
    assert(#ECS_ENTITIES < ecsOrigsize)
    assert(#PHYSICS_ENTITIES < physicsOrigsize)
end

function ecsUpdate.init()

    systemAge = concord.system({
        pool = {"age"}
    })
    function systemAge:update(dt)
        for _, entity in ipairs(self.pool) do
            entity.age.value = entity.age.value + dt
            if entity.age.value > entity.age.maxAge then
                killEntity(entity)
            end
        end
    end
    ECSWORLD:addSystems(systemAge)

    systemPosition = concord.system({
        pool = {"position"}
    })
    function systemPosition:update(dt)
        for _, entity in ipairs(self.pool) do
            -- update the radius if there is age and grows
            if entity:has("grows") and entity:has("age") then
                entity.position.radius = calcRadius(entity)
                -- update the mass on the physics object
                local uid = entity.uid.value
                physEntity = fun.getBody(uid)
                physEntity.body:setMass(RADIUSMASSRATIO * entity.position.radius)
            end
        end
    end
    ECSWORLD:addSystems(systemPosition)
end

return ecsUpdate
