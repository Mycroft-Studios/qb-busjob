Server = {}
Server.__index = Server
Server.object = exports['qb-core']:GetCoreObject()

function Server:NearBus(src)
    local ped = GetPlayerPed(src) -- Get the player's ped.
    local coords = GetEntityCoords(ped) -- Get the player's coordinates.

    for _, v in pairs(Config.NPCLocations) do -- Loop through the bus stop locations.
        local dist = #(coords - v.xyz) -- Calculate the distance between the player and the bus stop.
        if dist < 20.0 then -- If the distance is less than 20.0.
            return true -- Return true.
        end
    end
end

function Server:DropForExploit(src)
    DropPlayer(src, Lang:t('error.exploit')) -- Drop the player with an exploit error message.
    print(("Warning - Player [%s] tried to exploit the bus job."):format(src)) -- Print a warning message.
end

function Server:Pay(src)
    local player = Server.object.Functions.GetPlayer(src) -- Get the player object.
    if not player or player.PlayerData.job.name ~= 'bus' then -- If the player's job is not bus.
        self:DropForExploit(src) -- Drop the player with an exploit error message.
        return
    end

    if not self:NearBus(src) then -- If the player is not near the bus stop.
        self:DropForExploit(src) -- Drop the player with an exploit error message.
        return
    end

    local payment = Config.CalculatePayment() -- Calculate the payment amount.

    player.Functions.AddMoney('cash', payment, 'Bus job') -- Add the payment to the player's cash.
end

RegisterNetEvent('qb-busjob:server:NpcPay', function()
    local src = source
    Server:Pay(src) -- Call the Pay method with the player's ID.
end)
