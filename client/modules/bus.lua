
-------------------------------✨ Performance ✨ ------------------------------
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

-- The BusHandler class handles the functionality related to the bus job.
-- It provides methods for managing bus-related tasks and data.
BusHandler = {} -- Create a table to store the BusHandler class.
BusHandler.__index = BusHandler -- Set the BusHandler table as the metatable for the BusHandler class.

-- Initializes the BusHandler object
function BusHandler:Init()
    self.active = false
    self.blip = nil
    self.max = #Config.NPCLocations
    self.route = 1
    self.nearStation = false

    self:CreateStation()
end

function BusHandler:updateBlip()
    if Client.PlayerData.job.name == "bus" then -- Check if the player's job is bus.
        local coords = Config.BusDepot -- Get the bus depot coordinates.
        self.blip = AddBlipForCoord(coords.x, coords.y, coords.z) -- Add a blip at the specified coordinates.

        -- Set the blip properties.
        SetBlipSprite(self.blip, 513)
        SetBlipDisplay(self.blip, 4)
        SetBlipScale(self.blip, 0.6)
        SetBlipAsShortRange(self.blip, true)
        SetBlipColour(self.blip, 49)

        -- Set the blip name.
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t('info.bus_depot'))
        EndTextCommandSetBlipName(self.blip)

    elseif self.blip ~= nil then -- Check if the blip exists.
        RemoveBlip(self.blip) -- Remove the blip.
        self.blip = nil -- Set the blip to nil.
    end
end

-- Retrieves the bus vehicle that the player is currently in.
--- @return integer vehicle entity of the bus.
function BusHandler:getBus()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle
end

--- Checks if the current vehicle is a bus.
--- @return boolean: Returns true if the vehicle is a bus, false otherwise.
function BusHandler:isBus()
    -- Get the current vehicle entity.
    local vehicle = self:getBus()
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
function BusHandler:nextStop()
    if self.route <= (self.max - 1) then -- Check if the current route is less than the maximum number of routes.
        self.route += 1 -- Increment the route by 1.
    else
        self.route = 1 -- Set the route to the first stop if it exceeds the maximum number of routes.
    end
end

function BusHandler:DeliverySetup() -- Sets up the delivery process for the bus job.
    self:nextStop() -- Update the current route to the next stop.
    NPCHandler:RemoveDeliveryBlip() -- Remove the delivery blip associated with the NPC handler.
    NPCHandler:setDeliveryBlip() -- Set the delivery blip for the NPC handler.


    NPCHandler.last = self.route -- Update the last bus route.
    Client.currentInteraction = "dropoff" -- Set the current interaction to dropoff.
    NPCHandler:CreateZone() -- Create the interaction zone for the NPC handler.
end

function BusHandler:Create(model) -- Creates a bus vehicle for the player.
    -- Get the bus depot coordinates.
    local coords = Config.BusDepot

    -- Check if the player is already driving a bus.
    if self.active then
        -- Notify the player that they are already driving a bus.
        return Client.object.Functions.Notify(Lang:t('error.already_driving_bus'), 'error')
    end

    Client.object.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId) -- Spawn the vehicle using the server callback.
        local veh = NetToVeh(netId) -- Get the vehicle entity from the network ID.
        
        SetVehicleNumberPlateText(veh, Lang:t('info.bus_plate') .. tostring(math.random(1000, 9999))) -- Set the vehicle number plate.
        exports['LegacyFuel']:SetFuel(veh, 100.0) -- Set the vehicle fuel level to 100%.

        exports['qb-menu']:closeMenu() -- Close the menu.

        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) -- Warp the player into the vehicle.
        TriggerEvent("vehiclekeys:client:SetOwner", Client.object.Functions.GetPlate(veh)) -- Set the vehicle owner using the vehicle plate.
        
        SetVehicleEngineOn(veh, true, true, false) -- Turn on the vehicle engine.
        
        -- Reset Station Interaction
        BusHandler:StationInteration(false)
        BusHandler:StationInteration(true)

        -- Set the bus route to the first stop.
        SetTimeout(500, function()
            NPCHandler:Create()
        end)
    end, model, coords, true)
end

-- Garage function that handles the menu for selecting a bus vehicle
function BusHandler:Garage()
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
                    BusHandler:Create(model)
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
function BusHandler:Stop()
    if not NPCHandler.active or (NPCHandler.active and not NPCHandler.taken) then -- Check if the NPC is not active or taken.
        if self:isBus() then -- Check if the player is in a bus.
            self.active = false -- Set the bus as inactive.
            DeleteVehicle(self:getBus()) -- Delete the bus vehicle.

            NPCHandler:removeBlip() -- Remove the blip associated with the NPC handler.
            NPCHandler:Init() -- Reset the NPC handler.
            BusHandler:Init() -- Reset the BusHandler.

            exports["qb-core"]:HideText() -- Hide the text on the screen.
        end
    else 
        Client.object.Functions.Notify(Lang:t('error.drop_off_passengers'), 'error') -- Notify the player to drop off the passengers.
    end
end

-- Handles the interaction between the player and the bus station.
function BusHandler:StationInteration(isPointInside)
    local inVeh = self:isBus() -- Check if the player is in a bus.
    self.nearStation = isPointInside -- Set the nearStation flag based on the player's location.
    
    if Client.PlayerData.job.name == "bus" then -- Check if the player's job is bus.
        if isPointInside then -- If the player is inside the station.
            if not inVeh then -- If the player is not in a bus.
                exports["qb-core"]:DrawText(Lang:t('info.busstop_text'), 'left') -- Draw the text on the screen.

                Client.currentInteraction = "garage" -- Set the current interaction to garage.
            else -- If the player is in a bus.
                exports["qb-core"]:DrawText(Lang:t('info.bus_stop_work'), 'left') -- Draw the text on the screen.

                Client.currentInteraction = "stop" -- Set the current interaction to stop.
            end
        else
            exports["qb-core"]:HideText() -- Hide the text on the screen.

            if Client.currentInteraction == "garage" or Client.currentInteraction == "stop" then -- If the current interaction is garage or stop.
                Client.currentInteraction = nil -- Set the current interaction to nil.
            end
        end
    end
end

-- Creates the bus station interaction zone.
function BusHandler:CreateStation()
  
    -- Create a circle zone for the bus station.
    local coords = Config.BusDepot
    local PolyZone = CircleZone:Create(coords.xyz, 5, {
        name = "busMain",
        useZ = true,
        debugPoly = false
    })

    -- Handle player interaction with the bus station.
    PolyZone:onPlayerInOut(function(isPointInside)
        BusHandler:StationInteration(isPointInside) -- Handle the station interaction.
    end)
end