------------------  Performance  ----------------------
local RegisterNetEvent = RegisterNetEvent
local TriggerEvent = TriggerEvent
local RegisterCommand = RegisterCommand
local RegisterKeyMapping = RegisterKeyMapping
-------------------------------------------------------

-- Variables
-- Client class definition
-- Get the core object from qb-core resource
QBCore = exports['qb-core']:GetCoreObject()

-- Get the player data using the core object's Functions.GetPlayerData() method
PlayerData = QBCore.Functions.GetPlayerData()

-- Initialize the current interaction as nil
CurrentInteraction = nil

-- Initialize the bus data
CreateThread(function ()
    ResetBusData()    -- Reset the bus data
    ResetNpcData()    -- Initialize the NPCHandler
    UpdateDepotBlip() -- Update the depot blip
end)

-- Triggered when the player is loaded into the game.
-- Retrieves the player's data and updates the bus blip on the map.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    UpdateDepotBlip() -- Update the depot blip
end)

-- Triggered when the player is unloaded from the game.
-- Resets the player's data.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- Triggered when the player's job is updated.
-- Updates the player's job information and updates the bus blip on the map.
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    UpdateDepotBlip() -- Update the depot blip
end)

RegisterCommand("busInteraction", function()
    if PlayerData.job.name == "bus" then
        -- Handles the interaction between the player and the bus stop.
        -- If the player is in range of the NPC, it checks the current interaction type and performs the corresponding action.
        if NpcData.inRange then
            if CurrentInteraction == "pickup" then
                EnterBus() -- Player enters the bus.
            elseif CurrentInteraction == "dropoff" then
                LeaveBus() -- Player leaves the bus.
            end
        end
        -- Handles the interaction with the bus station.
        -- If the player is near the bus station, it checks the current interaction and performs the corresponding action.
        if BusData.nearStation then
            if CurrentInteraction == "garage" then
                GarageMenu() -- Opens the garage menu.
            elseif CurrentInteraction == "stop" then
                EndJob()     -- Ends the bus job.
            end
        end
    end
end, false)

-- Registers a key mapping for the "busInteraction" action
RegisterKeyMapping("busInteraction", "Bus Interaction", "keyboard", "e")

-- Triggers an event to remove suggestions for the "/busInteraction" command in the chat
TriggerEvent('chat:removeSuggestions', '/busInteraction')
