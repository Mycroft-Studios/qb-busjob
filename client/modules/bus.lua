
------------------------------  Performance   ------------------------------
local TriggerEvent = TriggerEvent
local RemoveBlip = RemoveBlip
local AddBlipForCoord = AddBlipForCoord
local SetBlipColour = SetBlipColour
local SetBlipSprite = SetBlipSprite
local SetBlipDisplay = SetBlipDisplay
local SetBlipScale = SetBlipScale
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local GetVehiclePedIsIn = GetVehiclePedIsIn
local PlayerPedId = PlayerPedId
local GetEntityModel = GetEntityModel
local NetToVeh = NetToVeh
local SetVehicleNumberPlateText = SetVehicleNumberPlateText
local DeleteVehicle = DeleteVehicle
local TaskWarpPedIntoVehicle = TaskWarpPedIntoVehicle
local SetVehicleEngineOn = SetVehicleEngineOn
local SetTimeout = SetTimeout
---------------------------------------------------------------------------------

BusData = {} -- Table that holds the bus data.

--- Resets the bus data to its initial state.
function ResetBusData()
    BusData.active = false
    BusData.blip = nil
    BusData.max = #Config.NPCLocations
    BusData.route = 1
    BusData.nearStation = false

    CreateStation()
end

function UpdateDepotBlip()
    if PlayerData.job.name == "bus" then -- Check if the player's job is bus.
        local coords = Config.BusDepot -- Get the bus depot coordinates.
        BusData.blip = AddBlipForCoord(coords.x, coords.y, coords.z) -- Add a blip at the specified coordinates.

        -- Set the blip properties.
        SetBlipSprite(BusData.blip, 513)
        SetBlipDisplay(BusData.blip, 4)
        SetBlipScale(BusData.blip, 0.6)
        SetBlipAsShortRange(BusData.blip, true)
        SetBlipColour(BusData.blip, 49)

        -- Set the blip name.
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t('info.bus_depot'))
        EndTextCommandSetBlipName(BusData.blip)

    elseif BusData.blip ~= nil then -- Check if the blip exists.
        RemoveBlip(BusData.blip) -- Remove the blip.
        BusData.blip = nil -- Set the blip to nil.
    end
end

-- Retrieves the bus vehicle that the player is currently in.
--- @return integer vehicle entity of the bus.
function GetBus()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle
end

--- Checks if the current vehicle is a bus.
--- @return boolean: Returns true if the vehicle is a bus, false otherwise.
function IsBus()
    -- Get the current vehicle entity.
    local vehicle = GetBus()
    local model = GetEntityModel(vehicle)

    -- Check if the vehicle model is a bus or allowed vehicle.
    if model == `dynasty` then
        return true
    end

    if Config.AllowedVehicles[model] then
        return true
    end

    return false -- Return false if the vehicle is not a bus.
end

-- Updates the current route to the next stop.
function SetNextStop()
    if BusData.route <= (BusData.max - 1) then -- Check if the current route is less than the maximum number of routes.
        BusData.route += 1 -- Increment the route by 1.
    else
        BusData.route = 1 -- Set the route to the first stop if it exceeds the maximum number of routes.
    end
end

function SetupDropOff() -- Sets up the delivery process for the bus job.
    SetNextStop() -- Update the current route to the next stop.
    RemoveDeliveryBlip() -- Remove the delivery blip associated with the NPC.
    SetDeliveryBlip() -- Set the delivery blip for the NPC.


    NpcData.last = BusData.route -- Update the last bus route.
    CurrentInteraction = "dropoff" -- Set the current interaction to dropoff.
    CreateZone() -- Create the interaction zone for the NPC.
end

function CreateBus(model) -- Creates a bus vehicle for the player.
    -- Get the bus depot coordinates.
    local coords = Config.BusDepot

    -- Check if the player is already driving a bus.
    if BusData.active then
        -- Notify the player that they are already driving a bus.
        return QBCore.Functions.Notify(Lang:t('error.already_driving_bus'), 'error')
    end

    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId) -- Spawn the vehicle using the server callback.
        local veh = NetToVeh(netId) -- Get the vehicle entity from the network ID.
        
        SetVehicleNumberPlateText(veh, Lang:t('info.bus_plate') .. tostring(math.random(1000, 9999))) -- Set the vehicle number plate.
        exports['LegacyFuel']:SetFuel(veh, 100.0) -- Set the vehicle fuel level to 100%.

        exports['qb-menu']:closeMenu() -- Close the menu.

        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) -- Warp the player into the vehicle.
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh)) -- Set the vehicle owner using the vehicle plate.
        
        SetVehicleEngineOn(veh, true, true, false) -- Turn on the vehicle engine.
        
        -- Reset Station Interaction
        StationInteration(false)
        StationInteration(true)

        -- Set the bus route to the first stop.
        SetTimeout(500, function()
            CreateNpc()
        end)
    end, model, coords, true)
end

-- Garage function that handles the menu for selecting a bus vehicle
function GarageMenu()
    -- Create the vehicle menu
    local vehicleMenu = {
        {
            header = Lang:t('menu.bus_header'),
            isMenuHeader = true
        }
    }

    -- Iterate through the allowed vehicles and add them to the menu
    for model, label in pairs(Config.AllowedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            params = {
                isAction = true, -- Set the menu item as an action
                event = function() -- Set the event handler for the menu item
                    CreateBus(model)
                end,
            }
        }
    end

    -- Add the close option to the menu
    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang:t('menu.bus_close'),
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }

    -- Open the vehicle menu using the 'qb-menu' resource
    exports['qb-menu']:openMenu(vehicleMenu)
end

-- Stop function that handles theplayer quitting the bus job
function EndJob()
    if not NpcData.active or (NpcData.active and not NpcData.taken) then -- Check if the NPC is not active or taken.
        if IsBus() then -- Check if the player is in a bus.
            BusData.active = false -- Set the bus as inactive.
            local veh = GetBus() -- Get the bus vehicle.
            DeleteVehicle(veh) -- Delete the bus vehicle.

            RemoveNpcBlip() -- Remove the blip associated with the NPC.
            ResetNpcData() -- Reset the NPC.
            ResetBusData() -- Reset the bus data.

            exports["qb-core"]:HideText() -- Hide the text on the screen.
        end
    else
        QBCore.Functions.Notify(Lang:t('error.drop_off_passengers'), 'error') -- Notify the player to drop off the passengers.
    end
end

-- Handles the interaction between the player and the bus station.
function StationInteration(isPointInside)
    BusData.nearStation = isPointInside -- Set the nearStation flag based on the player's location.

    -- Check if the player's job is bus.
    if PlayerData.job.name ~= 'bus' then
        return -- Return if the player's job is not bus.
    end

    if isPointInside then -- Check if the player is inside the bus station.
        local inVeh = IsBus() -- Check if the player is in a bus vehicle.
        CurrentInteraction = inVeh and 'stop' or 'garage' -- Set the current interaction based on the player's actvity.

        -- Display the text based on the player's activity.
        exports['qb-core']:DrawText(Lang:t(inVeh and 'info.bus_stop_work' or 'info.busstop_text'), 'left')
    else -- If the player is outside the bus station.
        exports['qb-core']:HideText() -- Hide the text.

        if CurrentInteraction == 'garage' or CurrentInteraction == 'stop' then  -- Check if the current interaction is garage or stop.
            CurrentInteraction = nil -- Reset the current interaction.
        end
    end
end

-- Creates the bus station interaction zone.
function CreateStation()
  
    -- Create a circle zone for the bus station.
    local coords = Config.BusDepot
    local PolyZone = CircleZone:Create(coords.xyz, 5, {
        name = "busMain",
        useZ = true,
        debugPoly = false
    })

    -- Handle player interaction with the bus station.
    PolyZone:onPlayerInOut(function(isPointInside)
        StationInteration(isPointInside) -- Handle the station interaction.
    end)
end