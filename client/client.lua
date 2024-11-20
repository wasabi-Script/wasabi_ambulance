-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
ESX = exports["es_extended"]:getSharedObject()
isDead, disableKeys, inMenu, stretcher, stretcherMoving, isBusy = nil, nil, nil, nil, nil, nil
local playerLoaded, injury
plyRequests = {}

CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(1000)
    end
    ESX.PlayerData.job = ESX.GetPlayerData().job
    exports.qtarget:AddTargetModel({`xm_prop_x17_bag_med_01a`}, {
        options = {
            {
                event = 'wasabi_ambulance:pickupBag',
                icon = 'fas fa-hand-paper',
                label = Strings.pickup_bag_target,
            },
            {
                event = 'wasabi_ambulance:interactBag',
                icon = 'fas fa-briefcase',
                label = Strings.interact_bag_target,
            },

        },
        job = 'all',
        distance = 1.5
    })
    exports.qtarget:Player({
        options = {
            {
                event = 'wasabi_ambulance:diagnosePatient',
                icon = 'fas fa-stethoscope',
                label = Strings.diagnose_patient,
                job = 'ambulance',
            },
            {
                event = 'wasabi_ambulance:reviveTarget',
                icon = 'fas fa-medkit',
                label = Strings.revive_patient,
                job = 'ambulance',
            },
            {
                event = 'wasabi_ambulance:healTarget',
                icon = 'fas fa-bandage',
                label = Strings.heal_patient,
                job = 'ambulance',
            },
            {
                event = 'wasabi_ambulance:useSedative',
                icon = 'fas fa-syringe',
                label = Strings.sedate_patient,
                job = 'ambulance',
            }
        },
        distance = 2.5,
    })
end)

AddEventHandler("onClientMapStart", function()
	exports.spawnmanager:spawnPlayer()
	Wait(5000)
	exports.spawnmanager:setAutoSpawn(false)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    local ped = cache.ped
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
	ESX.PlayerData = xPlayer
	playerLoaded = true
    if Config.AntiCombatLog.enabled then
        ESX.TriggerServerCallback('wasabi_ambulance:checkDeath', function(dead)
            if dead then
                Wait(2000) -- For slow clients we will wait 2 seconds~ for the ped to be spawned
                SetEntityHealth(PlayerPedId(), 0)
                if Config.AntiCombatLog.notification.enabled then
                    TriggerEvent('wasabi_ambulance:notify', Config.AntiCombatLog.notification.title, Config.AntiCombatLog.desc, 'error', 'skull-crossbones')
                end
            end
        end)
    end
    if ESX.PlayerData.job.name == 'ambulance' then
        TriggerServerEvent('wasabi_ambulance:requestSync')
    end
end)

RegisterNetEvent('wasabi_ambulance:notify', function(title, desc, style, icon)
    if icon then
        lib.notify({
            title = title,
            description = desc,
            duration = 3500,
            icon = icon,
            type = style
        })
    else
        lib.notify({
            title = title,
            description = desc,
            duration = 3500,
            type = style
        })
    end
end)

RegisterNetEvent('esx:setJob', function(job)
	ESX.PlayerData.job = job
    if job.name == 'ambulance' then
        TriggerServerEvent('wasabi_ambulance:requestSync')
    end
end)

CreateThread(function()
	while true do
		local sleep = 1500
		if isDead or disableKeys then
            sleep = 0
			DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Camera Pan(Mouse)
			EnableControlAction(0, 2, true) -- Camera Tilt(Mouse)
            EnableControlAction(0, 38, true) -- E Key
			EnableControlAction(0, 46, true) -- E Key
            EnableControlAction(0, 47, true) -- G Key
			EnableControlAction(0, 245, true) -- T Key
		end
        Wait(sleep)
	end
end)

AddEventHandler('esx:onPlayerSpawn', function()
    isDead = false
    local ped = cache.ped
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetPlayerHealthRechargeLimit(PlayerId(), 0.0)
    if firstSpawn then
        firstSpawn = false
        while not playerLoaded do
            Wait(1000)
        end
        lib.requestAnimDict('get_up@directional@movement@from_knees@action', 100)
        TaskPlayAnim(ped, 'get_up@directional@movement@from_knees@action', 'getup_r_0', 8.0, -8.0, -1, 0, 0, 0, 0, 0)
    else
        AnimpostfxStopAll()
        lib.requestAnimDict('get_up@directional@movement@from_knees@action', 100)
        TaskPlayAnim(ped, 'get_up@directional@movement@from_knees@action', 'getup_r_0', 8.0, -8.0, -1, 0, 0, 0, 0, 0)
    end
    TriggerServerEvent('wasabi_ambulance:setDeathStatus', false)
    RemoveAnimDict('get_up@directional@movement@from_knees@action')
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    injury = nil
    ESX.UI.Menu.CloseAll()
    if Config.MythicHospital then
        TriggerEvent('mythic_hospital:client:RemoveBleed')
        TriggerEvent('mythic_hospital:client:ResetLimbs')
    end
    for k,v in pairs(DeathReasons) do
        for i=1, #v do
            if data.deathCause == v[i] then
                injury = tostring(k) -- Not sure maybe will return string anyway
                break
            end
        end
    end
    TriggerServerEvent('wasabi_ambulance:injurySync', injury)
    OnPlayerDeath()
end)

-- I am monster thread
CreateThread(function()
    while ESX.PlayerData.job == nil do
        Wait(1000) -- Necessary for some of the loops that use job check in these threads within threads.
    end
    for k,v in pairs(Config.Locations) do
        if v.Blip.Enabled then
            CreateBlip(v.Blip.Coords, v.Blip.Sprite, v.Blip.Color, v.Blip.String, v.Blip.Scale, false)
        end
        if v.BossMenu.Enabled then
            exports.qtarget:AddBoxZone(k.."_medboss", v.BossMenu.Target.coords, v.BossMenu.Target.width, v.BossMenu.Target.length, {
                name=k.."_medboss",
                heading=v.BossMenu.Target.heading,
                debugPoly=false,
                minZ=v.BossMenu.Target.minZ,
                maxZ=v.BossMenu.Target.maxZ
            }, {
                options = {
                    {
                        event = 'wasabi_ambulance:openBossMenu',
                        icon = 'fa-solid fa-suitcase-medical',
                        label = v.BossMenu.Target.label
                    }
                },
                job = 'ambulance',
                distance = 2.0
            })
        end
        if v.CheckIn.Enabled then
            CreateThread(function()
                local ped, pedSpawned
                local textUI
                while true do
                    local sleep = 1500
                    local playerPed = cache.ped
                    local coords = GetEntityCoords(playerPed)
                    local dist = #(coords - v.CheckIn.Coords)
                    if dist <= 30 and not pedSpawned then
                        lib.requestAnimDict('mini@strip_club@idles@bouncer@base', 100)
                        lib.requestModel(v.CheckIn.Ped, 100)
                        ped = CreatePed(28, v.CheckIn.Ped, v.CheckIn.Coords.x, v.CheckIn.Coords.y, v.CheckIn.Coords.z, v.CheckIn.Heading, false, false)
                        FreezeEntityPosition(ped, true)
                        SetEntityInvincible(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        TaskPlayAnim(ped, 'mini@strip_club@idles@bouncer@base', 'base', 8.0, 0.0, -1, 1, 0, 0, 0, 0)
                        pedSpawned = true
                    elseif dist < 5 and pedSpawned then
                        if not textUI then
                            lib.showTextUI(v.CheckIn.Label)
                            textUI = true
                        end
                        sleep = 0
                        if IsControlJustReleased(0, 38) then
                            textUI = nil
                            lib.hideTextUI()
                            ESX.TriggerServerCallback('wasabi_ambulance:tryRevive', function(cb)
                                if cb == 'success' then
                                    TriggerEvent('wasabi_ambulance:notify', Strings.checkin_hospital, Strings.checkin_hospital_desc, 'success')
                                elseif cb == 'max' then
                                    TriggerEvent('wasabi_ambulance:notify', Strings.max_ems, Strings.max_ems_desc, 'error')
                                else
                                    TriggerEvent('wasabi_ambulance:notify', Strings.not_enough_funds, Strings.not_enough_funds_desc, 'error')
                                end
                            end, v.CheckIn.Cost, v.CheckIn.MaxOnDuty, v.CheckIn.PayAccount)
                        end
                    elseif dist > 4 and textUI then
                        lib.hideTextUI()
                        textUI = nil
                    elseif dist >= 31 and pedSpawned then
                        local model = GetEntityModel(ped)
                        SetModelAsNoLongerNeeded(model)
                        DeletePed(ped)
                        SetPedAsNoLongerNeeded(ped)
                        RemoveAnimDict('mini@strip_club@idles@bouncer@base')
                        pedSpawned = nil
                    end
                    Wait(sleep)
                end
            end)
        end
        if v.Cloakroom.Enabled then
            CreateThread(function()
                local textUI
                while true do
                    local sleep = 1500
                    if ESX.PlayerData.job.name == 'ambulance' then
                        local ped = cache.ped
                        local coords = GetEntityCoords(ped)
                        local dist = #(coords - v.Cloakroom.Coords)
                        if dist <= v.Cloakroom.Range then
                            if not textUI then
                                lib.showTextUI(v.Cloakroom.Label)
                                textUI = true
                            end
                            sleep = 0
                            if IsControlJustReleased(0, 38) then
                                openOutfits(k)
                            end
                        else
                            if textUI then
                                lib.hideTextUI()
                                textUI = nil
                            end
                        end
                    end
                    Wait(sleep)
                end
            end)
        end
        if v.MedicalSupplies.Enabled then
            exports.qtarget:AddBoxZone(k.."_medsup", v.MedicalSupplies.Coords, 1.0, 1.0, {
                name=k.."_medsup",
                heading=v.MedicalSupplies.Heading,
                debugPoly=false,
                minZ=v.MedicalSupplies.Coords.z-1.5,
                maxZ=v.MedicalSupplies.Coords.z+1.5
            }, {
                options = {
                    {
                        event = 'wasabi_ambulance:medicalSuppliesMenu',
                        icon = 'fa-solid fa-suitcase-medical',
                        label = Strings.request_supplies_target,
                        hospital = k
                    }
                },
                job = 'ambulance',
                distance = 1.5
            })
            CreateThread(function() 
                local ped, pedSpawned
                while true do
                    local sleep = 1500
                    local playerPed = cache.ped
                    local coords = GetEntityCoords(playerPed)
                    local dist = #(coords - v.MedicalSupplies.Coords)
                    if dist <= 30 and not pedSpawned then
                        lib.requestAnimDict('mini@strip_club@idles@bouncer@base', 100)
                        lib.requestModel(v.MedicalSupplies.Ped, 100)
                        ped = CreatePed(28, v.MedicalSupplies.Ped, v.MedicalSupplies.Coords.x, v.MedicalSupplies.Coords.y, v.MedicalSupplies.Coords.z, v.MedicalSupplies.Heading, false, false)
                        FreezeEntityPosition(ped, true)
                        SetEntityInvincible(ped, true)
                        SetBlockingOfNonTemporaryEvents(ped, true)
                        TaskPlayAnim(ped, 'mini@strip_club@idles@bouncer@base', 'base', 8.0, 0.0, -1, 1, 0, 0, 0, 0)
                        pedSpawned = true
                    elseif dist >= 31 and pedSpawned then
                        local model = GetEntityModel(ped)
                        SetModelAsNoLongerNeeded(model)
                        DeletePed(ped)
                        SetPedAsNoLongerNeeded(ped)
                        RemoveAnimDict('mini@strip_club@idles@bouncer@base')
                        pedSpawned = false
                    end
                    Wait(sleep)
                end
            end)
        end
        if v.Vehicles.Enabled then
            CreateThread(function()
                local zone = v.Vehicles.Zone
                local textUI
                while true do
                    local sleep = 1500
                    if ESX.PlayerData.job.name == 'ambulance' then
                        local playerPed = cache.ped
                        local coords = GetEntityCoords(playerPed)
                        local dist = #(coords - zone.coords)
                        local dist2 = #(coords - v.Vehicles.Spawn.air.coords)
                        if dist < zone.range + 1 and not inMenu and not IsPedInAnyVehicle(playerPed, false) then
                            sleep = 0
                            if not textUI then
                                lib.showTextUI(zone.label)
                                textUI = true
                            end
                            if IsControlJustReleased(0, 38) then
                                textUI = nil
                                lib.hideTextUI()
                                openVehicleMenu(k)
                                sleep = 1500
                            end
                        elseif dist < zone.range + 1 and not inMenu and IsPedInAnyVehicle(playerPed, false) then
                            sleep = 0
                            if not textUI then
                                textUI = true
                                lib.showTextUI(zone.return_label)
                            end
                            if IsControlJustReleased(0, 38) then
                                textUI = nil
                                lib.hideTextUI()
                                if DoesEntityExist(cache.vehicle) then
                                    DoScreenFadeOut(800)
                                    while not IsScreenFadedOut() do Wait(100) end
                                    SetEntityAsMissionEntity(cache.vehicle)
                                    DeleteVehicle(cache.vehicle)
                                    DoScreenFadeIn(800)
                                end
                            end
                        elseif dist2 < 10 and IsPedInAnyVehicle(playerPed, false) then
                            sleep = 0
                            if not textUI then
                                textUI = true
                                lib.showTextUI(zone.return_label)
                            end
                            if IsControlJustReleased(0, 38) then
                                textUI = nil
                                lib.hideTextUI()
                                if DoesEntityExist(cache.vehicle) then
                                    DoScreenFadeOut(800)
                                    while not IsScreenFadedOut() do Wait(100) end
                                    SetEntityAsMissionEntity(cache.vehicle)
                                    DeleteVehicle(cache.vehicle)
                                    SetEntityCoordsNoOffset(playerPed, zone.coords.x, zone.coords.y, zone.coords.z, false, false, false, true)
                                    DoScreenFadeIn(800)
                                end
                            end
                        else
                            if textUI then
                                textUI = nil
                                lib.hideTextUI()
                            end
                        end
                    end
                    Wait(sleep)
                end
            end)
        end
    end
end)

RegisterNetEvent('wasabi_ambulance:syncRequests')
AddEventHandler('wasabi_ambulance:syncRequests', function(_plyRequests, quiet)
    if ESX.PlayerData.job.name == 'ambulance' then
        plyRequests = _plyRequests
        if not quiet then
            TriggerEvent('wasabi_ambulance:notify', Strings.assistance_title, Strings.assistance_desc, 'error', 'suitcase-medical')
        end
    end
end)

-- esx_ambulancejob compatibility
RegisterNetEvent('esx_ambulancejob:revive')
AddEventHandler('esx_ambulancejob:revive', function()
    TriggerEvent("wasabi_ambulance:revive")
end)

RegisterNetEvent('wasabi_ambulance:revivePlayer', function()
    if LocalPlayer.state.dead then
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local injury = LocalPlayer.state.injury
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(50)
        end
        TriggerServerEvent('wasabi_ambulance:setDeathStatus', false)
        isDead = false
        NetworkResurrectLocalPlayer(coords, heading, true, false)
        ClearPedBloodDamage(ped)
        if Config.MythicHospital then
            TriggerEvent('mythic_hospital:client:RemoveBleed')
            TriggerEvent('mythic_hospital:client:ResetLimbs')
        end
        FreezeEntityPosition(ped, false)
        DoScreenFadeIn(800)
        AnimpostfxStopAll()
        TriggerServerEvent('esx:onPlayerSpawn')
        TriggerEvent('esx:onPlayerSpawn')
        ClearPedTasks(ped)
        if not injury then
            SetEntityHealth(ped, 200)
        else
            ApplyDamageToPed(ped, Config.ReviveHealth[injury])
        end
    end 
end)

RegisterNetEvent('wasabi_ambulance:revive',function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    TriggerServerEvent('wasabi_ambulance:setDeathStatus', false)
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Wait(50)
    end
    NetworkResurrectLocalPlayer(coords, heading, true, false)
    ClearPedBloodDamage(ped)
    isDead = false
    if Config.MythicHospital then
        TriggerEvent('mythic_hospital:client:RemoveBleed')
        TriggerEvent('mythic_hospital:client:ResetLimbs')
    end
    DoScreenFadeIn(800)
    AnimpostfxStopAll()
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
end)

RegisterNetEvent('wasabi_ambulance:heal', function(full, quiet)
    local ped = cache.ped
    local maxHealth = 200
    if not full then
        local health = GetEntityHealth(ped)
        local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
        SetEntityHealth(ped, newHealth)
    else
        SetEntityHealth(ped, maxHealth)
    end
    if not quiet then
        TriggerEvent('wasabi_ambulance:notify', Strings.player_successful_heal, Strings.player_healed_desc, 'success')
    end
end)

RegisterNetEvent('wasabi_ambulance:sedate', function()
    local ped = cache.ped
    TriggerEvent('wasabi_ambulance:notify', Strings.assistance_title, Strings.assistance_desc, 'success', 'syringe')
    ClearPedTasks(ped)
    lib.requestAnimDict('mini@cpr@char_b@cpr_def', 100)
    disableKeys = true
    TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, 8.0, -1, 33, 0, 0, 0, 0)
    FreezeEntityPosition(ped, true)
    Wait(Config.EMSItems.sedate.duration)
    FreezeEntityPosition(ped, false)
    disableKeys = false
    ClearPedTasks(ped)
    RemoveAnimDict('mini@cpr@char_b@cpr_def')
end)

RegisterNetEvent('wasabi_ambulance:intoVehicle', function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    if IsPedInAnyVehicle(ped) then
        coords = GetOffsetFromEntityInWorldCoords(ped, -2.0, 1.0, 0.0)
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    else
        if IsAnyVehicleNearPoint(coords, 6.0) then
            local vehicle = GetClosestVehicle(coords, 6.0, 0, 71)
            if DoesEntityExist(vehicle) then
                local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)
                for i=maxSeats - 1, 0, -1 do
                    if IsVehicleSeatFree(vehicle, i) then
                        freeSeat = i
                        break
                    end
                end
                if freeSeat then
                    TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
                end
            end
        end
    end
end)

RegisterNetEvent('wasabi_ambulance:syncObj', function(netObj)
    local obj = NetToObj(netObj)
    deleteObj(obj)
end)

RegisterNetEvent('wasabi_ambulance:useSedative', function()
    useSedative()
end)

RegisterNetEvent('wasabi_ambulance:useMedbag', function()
    useMedbag()
end)

RegisterNetEvent('wasabi_ambulance:treatPatient', function(injury)
    treatPatient(injury)
end)

AddEventHandler('wasabi_ambulance:buyItem', function(data)
    TriggerServerEvent('wasabi_ambulance:restock', data)
end)

RegisterNetEvent('wasabi_ambulance:placeOnStretcher', function()
    placeOnStretcher()
end)

AddEventHandler('wasabi_ambulance:openBossMenu', function()
	TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
		menu.close()
	end, {wash = false})
end)

AddEventHandler('wasabi_ambulance:spawnVehicle', function(data)
    inMenu = false
    local model = data.model
    local category = Config.Locations[data.hospital].Vehicles.Options[data.model].category
    local spawnLoc = Config.Locations[data.hospital].Vehicles.Spawn[category]
    if not IsModelInCdimage(GetHashKey(model)) then
        print('Vehicle model not found: '..model)
    else
        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Wait(100)
        end
        lib.requestModel(model, 100)
        local vehicle = CreateVehicle(GetHashKey(model), spawnLoc.coords.x, spawnLoc.coords.y, spawnLoc.coords.z, spawnLoc.heading, 1, 0)
        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
        if Config.customCarlock then
            -- Leave like this if using wasabi_carlock OR change with your own!
            local plate = GetVehicleNumberPlateText(vehicle)
            TriggerServerEvent('wasabi_carlock:addKey', plate)
        end
        SetModelAsNoLongerNeeded(model)
        DoScreenFadeIn(800)
    end
end)

AddEventHandler('wasabi_ambulance:changeClothes', function(data) -- Change with your own code here if you want?
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        if data == 'civ_wear' then
            if Config.skinScript == 'appearance' then
                    skin.sex = nil
                    exports['fivem-appearance']:setPlayerAppearance(skin)
            else
               TriggerEvent('skinchanger:loadClothes', skin)
            end
        elseif skin.sex == 0 then
			TriggerEvent('skinchanger:loadClothes', skin, data.male)
		elseif skin.sex == 1 then
			TriggerEvent('skinchanger:loadClothes', skin, data.female)
		end
    end)
end)

AddEventHandler('wasabi_ambulance:billPatient', function()
    if ESX.PlayerData.job.name == 'ambulance' then
        local player, dist = ESX.Game.GetClosestPlayer()
        if player == -1 or dist > 4.0 then
            TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
        else
            local targetId = GetPlayerServerId(player)
            local input = lib.inputDialog('Bill Patient', {'Amount'})
            if not input then return end
            local amount = math.floor(tonumber(input[1]))
            if amount < 1 then
                TriggerEvent('wasabi_ambulance:notify', Strings.invalid_entry, Strings.invalid_entry_desc, 'error')
            elseif Config.billingSystem == 'okok' then
                local data =  {
                    target = targetId,
                    invoice_value = amount,
                    invoice_item = Strings.medical_services,
                    society = 'society_ambulance',
                    society_name = 'Hospital',
                    invoice_notes = ''
                }
                TriggerServerEvent('okokBilling:CreateInvoice', data)
            else
                TriggerServerEvent('esx_billing:sendBill', targetId, 'society_ambulance', 'EMS', amount)
            end
        end
    end
end)

AddEventHandler('wasabi_ambulance:medicalSuppliesMenu', function(data)
    medicalSuppliesMenu(data.hospital)
end)

AddEventHandler('wasabi_ambulance:gItem', function(data)
    gItem(data)
end)

AddEventHandler('wasabi_ambulance:interactBag', function()
    interactBag()
end)

AddEventHandler('wasabi_ambulance:pickupBag', function()
    pickupBag()
end)

AddEventHandler('wasabi_ambulance:placeInVehicle', function()
    placeInVehicle()
end)

AddEventHandler('wasabi_ambulance:dispatchMenu', function()
    openDispatchMenu()
end)

AddEventHandler('wasabi_ambulance:setRoute', function(data)
    setRoute(data)
end)

AddEventHandler('wasabi_ambulance:diagnosePatient', function()
    diagnosePatient()
end)

AddEventHandler('wasabi_ambulance:loadStretcher', function()
    loadStretcher()
end)

RegisterNetEvent('wasabi_ambulance:useStretcher')
AddEventHandler('wasabi_ambulance:useStretcher', function()
    useStretcher()
end)

AddEventHandler('wasabi_ambulance:pickupStretcher', function()
    pickupStretcher()
end)

AddEventHandler('wasabi_ambulance:moveStretcher', function()
    moveStretcher()
end)

AddEventHandler('wasabi_ambulance:addTarget', function(d)
    exports.qtarget:AddBoxZone(d.identifier, d.coords, d.width, d.length, {
        name=d.identifier,
        heading=d.heading,
        debugPoly=false,
        minZ=d.minZ,
        maxZ=d.maxZ
    }, {
        options = d.options,
        job = d.job,
        distance = d.distance
    })
end)

AddEventHandler('wasabi_ambulance:removeTarget', function(identifier)
    exports.qtarget:RemoveZone(identifier)
end)

RegisterNetEvent('wasabi_ambulance:reviveTarget')
AddEventHandler('wasabi_ambulance:reviveTarget', function()
    reviveTarget()
end)

RegisterNetEvent('wasabi_ambulance:healTarget')
AddEventHandler('wasabi_ambulance:healTarget', function()
    healTarget()
end)

RegisterCommand('emsJobMenu', function()
    openJobMenu()
end)

AddEventHandler('wasabi_ambulance:emsJobMenu', function()
    openJobMenu()
end)

TriggerEvent('chat:removeSuggestion', '/emsJobMenu')

RegisterKeyMapping('emsJobMenu', Strings.key_map_text, 'keyboard', Config.jobMenu)