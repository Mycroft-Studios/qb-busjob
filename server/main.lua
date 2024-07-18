local GetPlayer = exports['qb-core']:GetCoreObject().Functions.GetPlayer
local cooldowns = {} -- Create a table to store the cooldowns.

function NearBus(src)
    local ped = GetPlayerPed(src) -- Get the player's ped.
    local coords = GetEntityCoords(ped) -- Get the player's coordinates.

    for i=1, #Config.NPCLocations do -- Loop through the bus stop locations.
        local v = Config.NPCLocations[i] -- Get the bus stop location.
        local dist = #(coords - v.xyz) -- Calculate the distance between the player and the bus stop.
        if dist < 20.0 then -- If the distance is less than 20.0.
            return true -- Return true.
        end
    end
end

function DropForExploit(src)
    DropPlayer(src, Lang:t('error.exploit')) -- Drop the player with an exploit error message.
    print(("Warning - Player [%s] tried to exploit the bus job."):format(src)) -- Print a warning message.
end

function Pay(src)
    if cooldowns[src] and cooldowns[src] > GetGameTimer() then -- If the player is on cooldown.
        return -- Return.
    end
    cooldowns[src] = GetGameTimer() + Config.Cooldown -- Set the cooldown time.
    local player = GetPlayer(src) -- Get the player object.
    if not player or player.PlayerData.job.name ~= 'bus' then -- If the player's job is not bus.
        DropForExploit(src) -- Drop the player with an exploit error message.
        return
    end

    if not NearBus(src) then -- If the player is not near the bus stop.
        DropForExploit(src) -- Drop the player with an exploit error message.
        return
    end

    local payment = Config.CalculatePayment() -- Calculate the payment amount.

    player.Functions.AddMoney('cash', payment, 'Bus job') -- Add the payment to the player's cash.
end

RegisterNetEvent('qb-busjob:server:NpcPay', function()
    local src = source
    Pay(src) -- Call the Pay method with the player's ID.
end)
