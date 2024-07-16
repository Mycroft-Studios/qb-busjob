
----------------✨ Performance ✨ -------------------
local AddEventHandler = AddEventHandler
local RegisterNetEvent = RegisterNetEvent
local TriggerEvent = TriggerEvent
local RegisterCommand = RegisterCommand
local RegisterKeyMapping = RegisterKeyMapping
local GetCurrentResourceName = GetCurrentResourceName
-------------------------------------------------------

-- Variables
-- Client class definition
Client = {}
Client.__index = Client

-- Get the core object from qb-core resource
Client.object = exports['qb-core']:GetCoreObject()

-- Get the player data using the core object's Functions.GetPlayerData() method
Client.PlayerData = Client.object.Functions.GetPlayerData()

-- Initialize the current interaction as nil
Client.currentInteraction = nil

-- This event handler is triggered when a resource starts
AddEventHandler('onResourceStart', function(resourceName)
    -- handles script restarts
    if GetCurrentResourceName() == resourceName then
        BusHandler:Init() -- Initialize the BusHandler
        NPCHandler:Init() -- Initialize the NPCHandler
        BusHandler:updateBlip() -- Update the blip for the BusHandler
    end
end)

-- Triggered when the player is loaded into the game.
-- Retrieves the player's data and updates the bus blip on the map.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Client.PlayerData = Client.object.Functions.GetPlayerData()
    BusHandler:updateBlip()
end)

-- Triggered when the player is unloaded from the game.
-- Resets the player's data.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Client.PlayerData = {}
end)

-- Triggered when the player's job is updated.
-- Updates the player's job information and updates the bus blip on the map.
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    Client.PlayerData.job = JobInfo
    BusHandler:updateBlip()
end)

RegisterCommand("busInteraction", function()
    if Client.PlayerData.job.name == "bus" then
        -- Handles the interaction between the player and the bus stop.
        -- If the player is in range of the NPC, it checks the current interaction type and performs the corresponding action.
        if NPCHandler.inRange then
            if Client.currentInteraction == "pickup" then
                NPCHandler:EnterBus() -- Player enters the bus.
            elseif Client.currentInteraction == "dropoff" then
                NPCHandler:LeaveBus() -- Player leaves the bus.
            end
        end
        -- Handles the interaction with the bus station.
        -- If the player is near the bus station, it checks the current interaction and performs the corresponding action.
        if BusHandler.nearStation then
            if Client.currentInteraction == "garage" then
                BusHandler:Garage() -- Calls the Garage function of the BusHandler class.
            elseif Client.currentInteraction == "stop" then
                BusHandler:Stop() -- Calls the Stop function of the BusHandler class.
            end
        end
    end
end, false)

-- Registers a key mapping for the "busInteraction" action
RegisterKeyMapping("busInteraction", "Bus Interaction", "keyboard", "e")

-- Triggers an event to remove suggestions for the "/busInteraction" command in the chat
TriggerEvent('chat:removeSuggestions', '/busInteraction')
