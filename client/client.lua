local npcPed

local function loadModel(model)
    local hash = (type(model) == 'string') and joaat(model) or model
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

local function ensureNPC()
    if DoesEntityExist(npcPed) then return npcPed end
    local hash = loadModel(Config.NPC.model)
    if not hash then return nil end

    local coords = Config.NPC.coords
    npcPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, Config.NPC.heading or 0.0, false, true)

    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)

    -- Interaction setup
    local mode = (Config.Interaction and Config.Interaction.mode) or 'ox_target'
    if mode == 'ox_target' and exports.ox_target then
        exports.ox_target:addLocalEntity(npcPed, {
            {
                label = Config.Target.label or 'Rent a Vehicle',
                icon = Config.Target.icon or 'fa-solid fa-car',
                distance = Config.Target.distance or 2.0,
                onSelect = function()
                    TriggerEvent('vtx_rental:openMenu')
                end
            }
        })
    elseif mode == 'qb-target' and resourceRunning('qb-target') then
        exports['qb-target']:AddTargetEntity(npcPed, {
            options = {
                {
                    label = Config.Target.label or 'Rent a Vehicle',
                    icon = Config.Target.icon or 'fa-solid fa-car',
                    action = function()
                        TriggerEvent('vtx_rental:openMenu')
                    end
                }
            },
            distance = Config.Target.distance or 2.0
        })
    elseif mode == 'textui' then
        local key = (Config.Interaction and Config.Interaction.key) or 38 -- E
        CreateThread(function()
            local shown = false
            local prompt = ('[E] %s'):format(Config.Target.label or 'Rent a Vehicle')
            local uiPos = (Config.TextUI and Config.TextUI.position) or 'right-center'
            local pos = Config.NPC.coords
            local distMax = (Config.Target.distance or 2.0) + 0.5
            while DoesEntityExist(npcPed) do
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local dist = #(coords - vector3(pos.x, pos.y, pos.z))
                if dist <= distMax then
                    if not shown then
                        shown = true
                        lib.showTextUI(prompt, {
                            position = uiPos,
                            icon = 'car',
                            style = {
                                borderRadius = 6,
                                backgroundColor = '#111214',
                                color = '#FFFFFF'
                            }
                        })
                    end
                    if IsControlJustPressed(0, key) then
                        TriggerEvent('vtx_rental:openMenu')
                    end
                else
                    if shown then
                        shown = false
                        lib.hideTextUI()
                    end
                end
                Wait(0)
            end
            if shown then lib.hideTextUI() end
        end)
    end

    SetModelAsNoLongerNeeded(hash)
    return npcPed
end

local function vehicleFromIndex(idx)
    return Config.Vehicles[idx]
end

local function resourceRunning(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function tryGiveKeys(veh)
    local plate = GetVehicleNumberPlateText(veh)
    -- qb-vehiclekeys
    if resourceRunning('qb-vehiclekeys') and exports['qb-vehiclekeys'] and exports['qb-vehiclekeys'].AddKeys then
        pcall(function() exports['qb-vehiclekeys']:AddKeys(plate) end)
    end
    -- qs-vehiclekeys
    if resourceRunning('qs-vehiclekeys') then
        pcall(function() exports['qs-vehiclekeys']:GiveKeys(plate, 'rental', true) end)
    end
    -- cd_garage (AddKey expects plate)
    if resourceRunning('cd_garage') then
        pcall(function() TriggerEvent('cd_garage:AddKey', plate) end)
    end
    -- wasabi_carlock
    if resourceRunning('wasabi_carlock') then
        pcall(function() exports['wasabi_carlock']:GiveTemporaryKeys(veh) end)
    end
    -- renewed-vehiclekeys
    if resourceRunning('Renewed-Vehiclekeys') then
        pcall(function() exports['Renewed-Vehiclekeys']:addKey(veh) end)
    end
    -- ox_vehiclelock
    if resourceRunning('ox_vehiclelock') then
        pcall(function() exports['ox_vehiclelock']:giveKeys(veh) end)
    end
    -- fallback to user-defined hook
    if Config.GiveKeys then
        pcall(Config.GiveKeys, veh)
    end
end

local function spawnVehicle(entry)
    local spawnInfo = entry.spawn
    local hash = loadModel(entry.model)
    if not hash then
        lib.notify({ type = 'error', description = 'Invalid vehicle model: ' .. tostring(entry.model) })
        return
    end

    local x, y, z = spawnInfo.coords.x, spawnInfo.coords.y, spawnInfo.coords.z
    local heading = spawnInfo.heading or 0.0

    local veh = CreateVehicle(hash, x, y, z, heading, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetEntityHeading(veh, heading)
    SetVehicleOnGroundProperly(veh)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)
    -- enforce heading again post-warp and reset camera to forward
    SetEntityHeading(veh, heading)
    Wait(0)
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)

    local prefix = (Config.PlatePrefix or 'RENT'):sub(1, 4)
    SetVehicleNumberPlateText(veh, ("%s%03d"):format(prefix, math.random(0, 999)))

    -- mark as rental for other systems via statebag
    local ent = Entity(veh)
    if ent and ent.state then
        ent.state:set('vtx_rental', true, true)
    end

    -- unlock and power on
    SetVehicleDoorsLocked(veh, 1)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)

    -- universal keys handoff
    tryGiveKeys(veh)

    SetModelAsNoLongerNeeded(hash)
end

RegisterNetEvent('vtx_rental:openMenu', function()
    local options = {}
    for i, v in ipairs(Config.Vehicles) do
        options[#options+1] = {
            title = v.label,
            icon = 'car',
            description = ('$%s'):format(v.price),
            onSelect = function()
                TriggerServerEvent('vtx_rental:attemptRent', i)
            end
        }
    end

    lib.registerContext({
        id = 'vtx_rental_menu',
        title = Config.Menu.title or 'Vehicle Rentals',
        options = options
    })
    lib.showContext('vtx_rental_menu')
end)

RegisterNetEvent('vtx_rental:rentApproved', function(idx)
    local entry = vehicleFromIndex(idx)
    if not entry then return end

    -- Teleport player to spawn coords first, then spawn vehicle and warp in
    local ped = PlayerPedId()
    local coords = entry.spawn.coords
    local heading = entry.spawn.heading or 0.0
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    SetEntityHeading(ped, heading)

    spawnVehicle(entry)
    lib.notify({
        title = 'Vehicle Rental',
        description = 'Vehicle rented successfully!',
        type = 'success',
        duration = 1800
    })
end)

RegisterNetEvent('vtx_rental:rentDenied', function(reason)
    local description
    if reason == 'Not enough money' then
        description = 'Failed to rent vehicle. Check if you have enough money.'
    else
        description = reason or 'Failed to rent vehicle.'
    end
    lib.notify({
        title = 'Vehicle Rental',
        description = description,
        type = 'error',
        duration = 1800
    })
end)

CreateThread(function()
    Wait(500)
    ensureNPC()
end)

-- export: IsRental(veh)
function IsRental(veh)
    if not veh or veh == 0 then return false end
    local ent = Entity(veh)
    if ent and ent.state and ent.state.vtx_rental then return true end
    local prefix = (Config.PlatePrefix or 'RENT'):sub(1, 4)
    local plate = (GetVehicleNumberPlateText(veh) or '')
    return plate:sub(1, #prefix) == prefix
end
