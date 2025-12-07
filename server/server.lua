local function getVehicleEntry(index)
    return Config.Vehicles[index]
end

RegisterNetEvent('vtx_rental:attemptRent', function(index)
    local src = source
    local entry = getVehicleEntry(index)
    if not entry then
        TriggerClientEvent('vtx_rental:rentDenied', src, 'Invalid selection')
        return
    end

    local price = tonumber(entry.price) or 0
    if price < 0 then price = 0 end

    if price == 0 then
        TriggerClientEvent('vtx_rental:rentApproved', src, index)
        return
    end

    local currency = Config.Payment and Config.Payment.item or 'money'

    local count = exports.ox_inventory:Search(src, 'count', currency) or 0
    if count < price then
        TriggerClientEvent('vtx_rental:rentDenied', src, 'Not enough money')
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, currency, price)
    if not removed then
        TriggerClientEvent('vtx_rental:rentDenied', src, 'Payment error')
        return
    end

    TriggerClientEvent('vtx_rental:rentApproved', src, index)
end)
