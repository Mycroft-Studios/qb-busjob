-------------------------   Performance   ----------------------------
local RemoveBlip = RemoveBlip
local AddBlipForCoord = AddBlipForCoord
local SetBlipColour = SetBlipColour
local SetBlipRoute = SetBlipRoute
local SetBlipRouteColour = SetBlipRouteColour
local CreatePed = CreatePed
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local FreezeEntityPosition = FreezeEntityPosition
local TaskLeaveVehicle = TaskLeaveVehicle
local IsPedInVehicle = IsPedInVehicle
local SetVehicleEngineOn = SetVehicleEngineOn
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local TaskGoStraightToCoord = TaskGoStraightToCoord
local SetPedAsNoLongerNeeded = SetPedAsNoLongerNeeded
local TaskEnterVehicle = TaskEnterVehicle
local ClearPedTasksImmediately = ClearPedTasksImmediately
local GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers
local IsVehicleSeatFree = IsVehicleSeatFree
local TriggerServerEvent    = TriggerServerEvent
------------------------------------------------------------------------

NpcData = {} -- Table that holds the NPC data.

-- Resets the NPC data to its initial state.
function ResetNpcData()
    NpcData.active = false
    NpcData.current = nil
    NpcData.last = nil
    NpcData.npc = nil
    NpcData.blip = nil
    NpcData.deliveryBlip = nil
    NpcData.taken = false
    NpcData.zone = nil
    NpcData.inRange = false
end


-- Removes the delivery blip from the map.
function RemoveDeliveryBlip()
    if NpcData.deliveryBlip ~= nil then
        RemoveBlip(NpcData.deliveryBlip)
    end
end

-- sets the delivery blip for the NPC
function SetDeliveryBlip()
    -- Remove any existing delivery blip.
    RemoveDeliveryBlip()

    -- Get the current bus route and corresponding coordinates.
    local route = BusData.route
    local coords = Config.NPCLocations[route]

    -- Add a blip at the specified coordinates.
    NpcData.deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    -- Set the blip color to blue.
    SetBlipColour(NpcData.deliveryBlip, 3)
    -- Enable blip route display.
    SetBlipRoute(NpcData.deliveryBlip, true)
    -- Set the blip route color to blue.
    SetBlipRouteColour(NpcData.deliveryBlip, 3)

    -- Update the last bus route.
    NpcData.last = BusData.route
end

--- Removes the blip associated with the NPC.
function RemoveNpcBlip()
    if NpcData.blip ~= nil then
        RemoveBlip(NpcData.blip)
    end
end

-- Sets a blip for the NPC at the specified coordinates.
-- @param coords The coordinates where the blip should be set.
function SetNpcBlip(coords)
    NpcData.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipColour(NpcData.blip, 3)
    SetBlipRoute(NpcData.blip, true)
    SetBlipRouteColour(NpcData.blip, 3)
end

-- Creates an NPC for the bus job.
function CreateNpc()
    -- Check if the player is in a bus
    if not IsBus() then
        return QBCore.Functions.Notify(Lang:t('error.not_in_bus'), 'error')
    end

    -- Check if the NPC is already active
    if NpcData.active then
        return QBCore.Functions.Notify(Lang:t('error.already_driving_bus'), 'error')
    end

    -- Get the route and coordinates for the NPC
    local route = BusData.route
    local coords = Config.NPCLocations[route]

    -- Generate a random gender and skin for the NPC
    local Gender = math.random(1, #Config.NpcSkins)
    local PedSkin = math.random(1, #Config.NpcSkins[Gender])

    local model = Config.NpcSkins[Gender][PedSkin]
    QBCore.Functions.LoadModel(model)

    -- Create the NPC ped at the specified coordinates
    NpcData.npc = CreatePed(3, model, coords.x, coords.y, coords.z - 0.98, coords.w, true, true)
    PlaceObjectOnGroundProperly(NpcData.npc)
    FreezeEntityPosition(NpcData.npc, true)
    SetEntityAsMissionEntity(NpcData.npc, true, true) -- Set the NPC as a mission entity.

    -- Remove the previous blip and set a new blip at the NPC's location
    RemoveNpcBlip()
    SetNpcBlip(coords)

    -- Notify the player to go to the bus stop
    QBCore.Functions.Notify(Lang:t('info.goto_busstop'), 'primary')

    -- Set the last route and activate the NPC
    NpcData.last = route
    NpcData.active = true

    -- Set the current interaction to "pickup" and create the interaction zone
    CurrentInteraction = "pickup"
    CreateZone()
end

--- Creates a zone for the NPC at the specified coordinates.
function CreateZone()
    -- Get the current bus route and corresponding coordinates.
    local route = BusData.route
    local coords = Config.NPCLocations[route]

    -- Create a zone at the specified coordinates.
    NpcData.zone = CircleZone:Create(vector3(coords.x, coords.y, coords.z), 5, {
        name = "busjobdeliver",
        useZ = true,
        -- debugPoly=true
    })
    ZoneInteraction() -- Handle zone interaction.
end

function LeaveBus()
    -- Get the bus vehicle.
    local vehicle = GetBus()

    -- Task the NPC to leave the vehicle. 
    TaskLeaveVehicle(NpcData.npc, vehicle, 0)

    SetVehicleEngineOn(vehicle, false, true, true) -- Turn off the vehicle engine.

    -- Wait until the NPC is in the vehicle
    while IsPedInVehicle(NpcData.npc, vehicle, false) do
        Wait(0)
    end

    SetVehicleEngineOn(vehicle, true, true, false) -- Turn on the vehicle engine.

    SetEntityAsMissionEntity(NpcData.npc, false, false) -- Set the NPC as a non-mission entity.

    -- tell the npc to go to the last bus stop
    local targetCoords = Config.NPCLocations[NpcData.last]
    TaskGoStraightToCoord(NpcData.npc, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)

    -- Notify the player that the NPC has been dropped off.
    QBCore.Functions.Notify(Lang:t('success.dropped_off'), 'success')
    RemoveDeliveryBlip() -- Remove the delivery blip.

    SetPedAsNoLongerNeeded(NpcData.npc) -- Set the NPC as no longer needed.
    NpcData.zone:destroy() -- Destroy the zone.
    ResetNpcData() -- Reset the NPC data.

    Wait(0) -- Wait a tick before continuing.

    -- Set the next stop for the bus
    SetNextStop()
    CreateNpc() -- Create a new NPC.

    -- Hide the text and destroy the zone.
    exports["qb-core"]:HideText()
end

function ZoneInteraction()
    NpcData.inRange = false -- Set inRange to false.

    NpcData.zone:onPlayerInOut(function(isInside) -- Handle player interaction with the zone.
        if isInside then -- If the player is inside the zone.
            NpcData.inRange = true -- Set inRange to true.
            exports["qb-core"]:DrawText(Lang:t('info.busstop_text'), 'rgb(220, 20, 60)') -- Draw text.
        else -- If the player is outside the zone.
            exports["qb-core"]:HideText() -- Hide the text.
            NpcData.inRange = false -- Set inRange to false.
        end
    end)
end

--- Handles the logic for an NPC entering a bus.
function EnterBus()
    -- Get the bus vehicle.
    local vehicle = GetBus()
    -- Get the maximum number of passengers for the vehicle.
    local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

    -- Find a free seat in the bus
    for i = maxSeats - 1,0, -1  do
        if IsVehicleSeatFree(vehicle, i) then
            freeSeat = i
            break
        end
    end

    -- If no free seat is found, exit the function
    if not freeSeat then
        return
    end

    -- Clear the NPC's tasks and unfreeze their position
    ClearPedTasksImmediately(NpcData.npc)
    FreezeEntityPosition(NpcData.npc, false)

    -- Task the NPC to enter the bus at the free seat
    TaskEnterVehicle(NpcData.npc, vehicle, -1, freeSeat, 1.0, 3)
    SetVehicleEngineOn(vehicle, false, true, true) -- Turn off the vehicle engine.

    -- Wait until the NPC is in the vehicle
    while not IsPedInVehicle(NpcData.npc, vehicle, false) do
        Wait(0)
    end

    SetVehicleEngineOn(vehicle, true, true, false) -- Turn on the vehicle engine.

    -- Display a notification to the player
    QBCore.Functions.Notify(Lang:t('info.goto_busstop'), 'primary')

    -- Remove the blip from the NPC
    RemoveNpcBlip()

    -- Destroy the zone
    NpcData.zone:destroy()

    Wait(0) -- Wait a tick before continuing
    
    -- Set up the delivery for the bus
    SetupDropOff()

    -- Mark the NPC as taken
    NpcData.taken = true

    -- Trigger the server event to pay the player
    TriggerServerEvent('qb-busjob:server:NpcPay')

    -- Hide the text
    exports["qb-core"]:HideText()
end
