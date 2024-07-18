-------------------------✨ Performance ✨ ----------------------------
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
--------------------------------------------------------------------------

-- NPCHandler is a table that handles NPC-related functionality.
NPCHandler = {}
-- Set NPCHandler as the metatable for NPCHandler table.
NPCHandler.__index = NPCHandler

-- Initializes the NPCHandler object.
function NPCHandler:Init()
    self.active = false
    self.current = nil
    self.last = nil
    self.npc = nil
    self.blip = nil
    self.deliveryBlip = nil
    self.taken = false
    self.zone = nil
    self.inRange = false
end

--- Removes the delivery blip associated with the NPC handler.
function NPCHandler:RemoveDeliveryBlip()
    if self.deliveryBlip ~= nil then
        RemoveBlip(self.deliveryBlip)
    end
end

-- Sets the delivery blip for the NPC handler.
function NPCHandler:setDeliveryBlip()
    -- Remove any existing delivery blip.
    self:RemoveDeliveryBlip()

    -- Get the current bus route and corresponding coordinates.
    local route = BusHandler.route
    local coords = Config.NPCLocations[route]

    -- Add a blip at the specified coordinates.
    self.deliveryBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    -- Set the blip color to blue.
    SetBlipColour(self.deliveryBlip, 3)
    -- Enable blip route display.
    SetBlipRoute(self.deliveryBlip, true)
    -- Set the blip route color to blue.
    SetBlipRouteColour(self.deliveryBlip, 3)

    -- Update the last bus route.
    self.last = BusHandler.route
end

--- Removes the blip associated with the NPC.
function NPCHandler:removeBlip()
    if self.blip ~= nil then
        RemoveBlip(self.blip)
    end
end

-- Sets a blip for the NPC handler at the specified coordinates.
-- @param coords The coordinates where the blip should be set.
function NPCHandler:setBlip(coords)
    self.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipColour(self.blip, 3)
    SetBlipRoute(self.blip, true)
    SetBlipRouteColour(self.blip, 3)
end

-- Creates an NPC for the bus job.
function NPCHandler:Create()
    -- Check if the player is in a bus
    if not BusHandler:isBus() then
        return Client.object.Functions.Notify(Lang:t('error.not_in_bus'), 'error')
    end

    -- Check if the NPC is already active
    if self.active then
        return Client.object.Functions.Notify(Lang:t('error.already_driving_bus'), 'error')
    end

    -- Get the route and coordinates for the NPC
    local route = BusHandler.route
    local coords = Config.NPCLocations[route]

    -- Generate a random gender and skin for the NPC
    local Gender = math.random(1, #Config.NpcSkins)
    local PedSkin = math.random(1, #Config.NpcSkins[Gender])

    local model = Config.NpcSkins[Gender][PedSkin]
    Client.object.Functions.LoadModel(model)

    -- Create the NPC ped at the specified coordinates
    self.npc = CreatePed(3, model, coords.x, coords.y, coords.z - 0.98, coords.w, true, true)
    PlaceObjectOnGroundProperly(self.npc)
    FreezeEntityPosition(self.npc, true)
    SetEntityAsMissionEntity(self.npc, true, true) -- Set the NPC as a mission entity.

    -- Remove the previous blip and set a new blip at the NPC's location
    self:removeBlip()
    self:setBlip(coords)

    -- Notify the player to go to the bus stop
    Client.object.Functions.Notify(Lang:t('info.goto_busstop'), 'primary')

    -- Set the last route and activate the NPC
    self.last = route
    self.active = true

    -- Set the current interaction to "pickup" and create the interaction zone
    Client.currentInteraction = "pickup"
    self:CreateZone()
end

--- Creates a zone for the NPC handler.
function NPCHandler:CreateZone()
    -- Get the current bus route and corresponding coordinates.
    local route = BusHandler.route
    local coords = Config.NPCLocations[route]

    -- Create a zone at the specified coordinates.
    self.zone = CircleZone:Create(vector3(coords.x, coords.y, coords.z), 5, {
        name = "busjobdeliver",
        useZ = true,
        -- debugPoly=true
    })
    self:ZoneInteraction() -- Handle zone interaction.
end

function NPCHandler:LeaveBus()
    -- Get the bus vehicle.
    local vehicle = BusHandler:getBus()

    -- Task the NPC to leave the vehicle. 
    TaskLeaveVehicle(self.npc, vehicle, 0)

    SetVehicleEngineOn(vehicle, false, true, true) -- Turn off the vehicle engine.

    -- Wait until the NPC is in the vehicle
    while IsPedInVehicle(self.npc, vehicle, false) do
        Wait(0)
    end

    SetVehicleEngineOn(vehicle, true, true, false) -- Turn on the vehicle engine.

    SetEntityAsMissionEntity(self.npc, false, false) -- Set the NPC as a non-mission entity.

    -- tell the npc to go to the last bus stop
    local targetCoords = Config.NPCLocations[self.last]
    TaskGoStraightToCoord(self.npc, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)

    -- Notify the player that the NPC has been dropped off.
    Client.object.Functions.Notify(Lang:t('success.dropped_off'), 'success')
    self:RemoveDeliveryBlip() -- Remove the delivery blip.

    SetPedAsNoLongerNeeded(self.npc) -- Set the NPC as no longer needed.
    self.zone:destroy() -- Destroy the zone.
    self:Init() -- Reset the NPC handler.

    Wait(0) -- Wait a tick before continuing.

    -- Set the next stop for the bus
    BusHandler:nextStop()
    self:Create() -- Create a new NPC.

    -- Hide the text and destroy the zone.
    exports["qb-core"]:HideText()
end

function NPCHandler:ZoneInteraction()
    self.inRange = false -- Set inRange to false.

    self.zone:onPlayerInOut(function(isInside) -- Handle player interaction with the zone.
        if isInside then -- If the player is inside the zone.
            self.inRange = true -- Set inRange to true.
            exports["qb-core"]:DrawText(Lang:t('info.busstop_text'), 'rgb(220, 20, 60)') -- Draw text.
        else -- If the player is outside the zone.
            exports["qb-core"]:HideText() -- Hide the text.
            self.inRange = false -- Set inRange to false.
        end
    end)
end

--- Handles the logic for an NPC entering a bus.
function NPCHandler:EnterBus()
    -- Get the bus vehicle.
    local vehicle = BusHandler:getBus()
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
    ClearPedTasksImmediately(self.npc)
    FreezeEntityPosition(self.npc, false)

    -- Task the NPC to enter the bus at the free seat
    TaskEnterVehicle(self.npc, vehicle, -1, freeSeat, 1.0, 3)
    SetVehicleEngineOn(vehicle, false, true, true) -- Turn off the vehicle engine.

    -- Wait until the NPC is in the vehicle
    while not IsPedInVehicle(self.npc, vehicle, false) do
        Wait(0)
    end

    SetVehicleEngineOn(vehicle, true, true, false) -- Turn on the vehicle engine.

    -- Display a notification to the player
    Client.object.Functions.Notify(Lang:t('info.goto_busstop'), 'primary')

    -- Remove the blip from the NPC
    self:removeBlip()

    -- Destroy the zone
    self.zone:destroy()

    Wait(0) -- Wait a tick before continuing
    
    -- Set up the delivery for the bus
    BusHandler:DeliverySetup()

    -- Mark the NPC as taken
    self.taken = true

    -- Trigger the server event to pay the player
    TriggerServerEvent('qb-busjob:server:NpcPay')

    -- Hide the text
    exports["qb-core"]:HideText()
end
