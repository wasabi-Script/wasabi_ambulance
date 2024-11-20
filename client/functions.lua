-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

CreateBlip = function(coords, sprite, colour, text, scale, flash)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
	if flash then
		SetBlipFlashes(blip, true)
	end
end

addCommas = function(n)
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,")
								  :gsub(",(%-?)$","%1"):reverse()
end

secondsToClock = function(seconds)
	local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0

	if seconds <= 0 then
		return 0, 0
	else
		local hours = string.format('%02.f', math.floor(seconds / 3600))
		local mins = string.format('%02.f', math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format('%02.f', math.floor(seconds - hours * 3600 - mins * 60))

		return mins, secs
	end
end

isPlayerDead = function(serverId)
	local playerDead
	if not serverId then
		playerDead = LocalPlayer.state.dead or false
	else
		playerDead = Player(serverId).state.dead or false
	end
	return playerDead
end

exports('isPlayerDead', isPlayerDead)

DrawGenericTextThisFrame = function()
	SetTextFont(4)
	SetTextScale(0.0, 0.5)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
end

RespawnPed = function(ped, coords, heading)
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
	SetPlayerInvincible(ped, false)
	ClearPedBloodDamage(ped)

	TriggerServerEvent('esx:onPlayerSpawn')
	TriggerEvent('esx:onPlayerSpawn')
	TriggerEvent('playerSpawned') -- compatibility with old scripts, will be removed soon
end

StartRPDeath = function()
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)
	TriggerEvent('esx:onPlayerSpawn')
	CreateThread(function()
		DoScreenFadeOut(800)
		while not IsScreenFadedOut() do
			Wait(100)
		end
		ESX.SetPlayerData('loadout', {})
		if Config.removeItemsOnDeath then
			TriggerServerEvent('wasabi_ambulance:removeItemsOnDeath')
		end
		RespawnPed(cache.ped, Config.RespawnPoint.coords, Config.RespawnPoint.heading)
		lib.requestAnimDict('missarmenian2', 100)
		disableKeys = true
		TaskPlayAnim(cache.ped, 'missarmenian2', 'corpse_search_exit_ped', 8.0, 8.0, -1, 3, 0, 0, 0, 0)
		StopScreenEffect('DeathFailOut')
		DoScreenFadeIn(800)
		while IsScreenFadedOut() do
			Wait(100)
		end
		TriggerEvent('wasabi_ambulance:notify', Strings.alive_again, Strings.alive_again_desc, 'error', 'user-nurse')
		Wait(4000)
		DoScreenFadeOut(800)
		while not IsScreenFadedOut() do
			Wait(100)
		end
		ClearPedTasks(cache.ped)
		disableKeys = false
		DoScreenFadeIn(800)
	end)
end

startDeathTimer = function()
	SetGameplayCamRelativeHeading(-360)
	local earlySpawnTimer = math.floor(Config.RespawnTimer / 1000)
	local bleedoutTimer = math.floor(Config.BleedoutTimer / 1000)
	CreateThread(function()
		while earlySpawnTimer > 0 and isDead do
			Wait(1000)
			if earlySpawnTimer > 0 then
				earlySpawnTimer = earlySpawnTimer - 1
			end
		end
		while bleedoutTimer > 0 and isDead do
			Wait(1000)

			if bleedoutTimer > 0 then
				bleedoutTimer = bleedoutTimer - 1
			end
		end
	end)
	CreateThread(function()
		local text, timeHeld
		while earlySpawnTimer > 0 and isDead do
			Wait(0)
			text = (Strings.respawn_available_in):format(secondsToClock(earlySpawnTimer))
			DrawGenericTextThisFrame()
			SetTextEntry('STRING')
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end
		while bleedoutTimer > 0 and isDead do
			Citizen.Wait(0)
			text = (Strings.respawn_bleedout_in):format(secondsToClock(bleedoutTimer)) .. Strings.respawn_bleedout_prompt
			if IsControlPressed(0, 38) and timeHeld > 60 then
				StartRPDeath()
				break
			end
			if IsControlPressed(0, 38) then
				timeHeld = timeHeld + 1
			else
				timeHeld = 0
			end
			DrawGenericTextThisFrame()
			SetTextEntry('STRING')
			AddTextComponentString(text)
			DrawText(0.5, 0.8)
		end
		if bleedoutTimer < 1 and isDead then
			StartRPDeath()
		end
	end)
end

startDistressSignal = function()
	CreateThread(function()
		local timer = Config.BleedoutTimer
		while timer > 0 and isDead do
			Wait(0)
			timer = timer - 30
			SetTextFont(4)
			SetTextScale(0.45, 0.45)
			SetTextColour(185, 185, 185, 255)
			SetTextDropshadow(0, 0, 0, 0, 255)
			SetTextDropShadow()
			SetTextOutline()
			BeginTextCommandDisplayText('STRING')
			AddTextComponentSubstringPlayerName(Strings.distress_send)
			EndTextCommandDisplayText(0.175, 0.805)
			if IsControlJustReleased(0, 47) then --Old 47
				SendDistressSignal()
				break
			end
		end
	end)
end

SendDistressSignal = function()
	TriggerEvent('wasabi_ambulance:notify', Strings.distress_sent_title, Strings.distress_sent_desc, 'success')
	local ped = cache.ped
	local myPos = GetEntityCoords(ped)
	if Config.gksPhoneDistress then
		local GPS = 'GPS: ' .. myPos.x .. ', ' .. myPos.y
		ESX.TriggerServerCallback('gksphone:namenumber', function(Races)
			local name = Races[2].firstname .. ' ' .. Races[2].lastname
			TriggerServerEvent('gksphone:gkcs:jbmessage', name, Races[1].phone_number, 'Emergency aid notification', '', GPS, '["ambulance"]', false)
		end)
	else
		TriggerServerEvent('wasabi_ambulance:onPlayerDistress')
	end
end

startDeathAnimation = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    NetworkResurrectLocalPlayer(coords, heading, true, false)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped,true)
    TriggerEvent('esx_status:set', 'hunger', 500000)
    TriggerEvent('esx_status:set', 'thirst', 500000)
    if Config.MythicHospital then
        TriggerEvent('mythic_hospital:client:RemoveBleed')
        TriggerEvent('mythic_hospital:client:ResetLimbs')
    end
    lib.requestAnimDict('mini@cpr@char_b@cpr_def', 100)
    lib.requestAnimDict('veh@bus@passenger@common@idle_duck', 100)
    TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, 8.0, -1, 3, 0, 0, 0, 0)
    CreateThread(function()
        while isDead do
            local ped = PlayerPedId()
            local sleep = 1500
            if IsPedInAnyVehicle(ped,false) then
                if not IsEntityPlayingAnim(ped, "veh@bus@passenger@common@idle_duck", "sit", 3) then
                    sleep = 0
                    ClearPedTasks(ped)
                    TaskPlayAnim(ped, "veh@bus@passenger@common@idle_duck", "sit", 8.0, -8, -1, 2, 0, 0, 0, 0)
                end
            else
                if not IsEntityPlayingAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 3) then
					if not IsEntityPlayingAnim(ped, 'nm', 'firemans_carry', 33) 
					and not IsEntityPlayingAnim(ped, 'anim@gangops@morgue@table@', 'body_search', 33) -- If on the stretcher
					and not IsEntityPlayingAnim(ped, 'anim@arena@celeb@flat@paired@no_props@', 'piggyback_c_player_b', 33) then -- If being /piggyback
						sleep = 0
						ClearPedTasks(ped)
						TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, 8.0, -1, 3, 0, 0, 0, 0)
					end
                end
            end
            Wait(sleep)
        end
    end)
    RemoveAnimDict('mini@cpr@char_b@cpr_def')
    RemoveAnimDict('veh@bus@passenger@common@idle_duck')
end

OnPlayerDeath = function()
	isDead = true
	ESX.UI.Menu.CloseAll()
	TriggerServerEvent('wasabi_ambulance:setDeathStatus', true)
	startDeathTimer()
	startDistressSignal()
	startDeathAnimation()
	AnimpostfxPlay('DeathFailOut', 0, true)
end

setRoute = function(data)
	local player = GetPlayerFromServerId(data.plyId)
	local ped = GetPlayerPed(player)
	local coords = GetEntityCoords(ped)
	SetNewWaypoint(coords.x, coords.y)
	TriggerEvent('wasabi_ambulance:notify', Strings.route_set_title, Strings.route_set_desc, 'success', 'location-dot')
end

diagnosePatient = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or dist > 4.0 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	else
		local servId = GetPlayerServerId(player)
		local plyInjury = Player(servId).state.injury
		if not plyInjury then
			TriggerEvent('wasabi_ambulance:notify', Strings.no_injury, Strings.no_injury_desc, 'inform', 'stethoscope')
		else
			TriggerEvent('wasabi_ambulance:notify', Strings.player_injury, (Strings.player_injury_desc):format(plyInjury), 'error', 'stethoscope')
		end
	end
end

exports('diagnosePatient', diagnosePatient)


reviveTarget = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or dist > 3.0 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	elseif not isBusy then
		ESX.TriggerServerCallback('wasabi_ambulance:itemCheck', function(quanity)
			if quanity > 0 then
				local targetId = GetPlayerServerId(player)
				if Player(targetId).state.dead then
					isBusy = true
					local ped = cache.ped
					lib.requestAnimDict('mini@cpr@char_a@cpr_str', 100)
					TriggerEvent('wasabi_ambulance:notify', Strings.player_reviving, Strings.player_reviving_desc, 'success')
					local targetPed = GetPlayerPed(player)
					local tCoords = GetEntityCoords(targetPed)
					TaskTurnPedToFaceCoord(ped, tCoords.x, tCoords.y, tCoords.z, 3000)
					disableKeys = true
					Wait(3000)
					for i=1, 15 do
						Wait(900)
						TaskPlayAnim(ped, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 0, 0.0, false, false, false)
					end
					disableKeys = nil
					RemoveAnimDict('mini@cpr@char_a@cpr_str')
					isBusy = nil
					TriggerServerEvent('wasabi_ambulance:revivePlayer', targetId)
				else
					TriggerEvent('wasabi_ambulance:notify', Strings.player_not_unconcious, Strings.player_not_unconcious_desc, 'error')
				end
			else
				TriggerEvent('wasabi_ambulance:notify', Strings.player_noitem, Strings.player_noitem_desc, 'error')
			end
		end, Config.EMSItems.revive.item)
	else
		TriggerEvent('wasabi_ambulance:notify', Strings.player_busy, Strings.player_busy_desc, 'error')
	end
end

exports('reviveTarget', reviveTarget)

healTarget = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or ESX.PlayerData.job.name ~= 'ambulance' then
		local ped = cache.ped
		if lib.progressBar({
			duration = Config.EMSItems.heal.duration,
			label = Strings.healing_self_prog,
			useWhileDead = false,
			canCancel = true,
			disable = {
				car = true,
			},
			anim = {
				dict = 'missheistdockssetup1clipboard@idle_a',
				clip = 'idle_a' 
			},
		}) then
			TriggerServerEvent('wasabi_ambulance:healPlayer', cache.serverId)
		else
			TriggerEvent('wasabi_ambulance:notify', Strings.action_cancelled, Strings.action_cancelled_desc, 'error')
		end
	elseif player == -1 or dist > 1.5 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	else
		ESX.TriggerServerCallback('wasabi_ambulance:itemCheck', function(quantity)
			if quantity > 0 then
				local targetId = GetPlayerServerId(player)
				if not Player(targetId).state.dead then
					local ped = cache.ped
					TriggerEvent('wasabi_ambulance:notify', Strings.player_healing, Strings.player_healing_desc, 'success')
					lib.requestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 100)
					local targetPed = GetPlayerPed(player)
					local tCoords = GetEntityCoords(targetPed)
					TaskTurnPedToFaceCoord(ped, tCoords.x, tCoords.y, tCoords.z, 3000)
					Wait(1000)
					if lib.progressBar({
						duration = Config.EMSItems.heal.duration,
						label = Strings.healing_self_prog,
						useWhileDead = false,
						canCancel = true,
						disable = {
							car = true,
							move = true
						},
						anim = {
							dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
							clip = 'machinic_loop_mechandplayer' 
						},
					}) then
						TriggerServerEvent('wasabi_ambulance:healPlayer', targetId)
					else
						TriggerEvent('wasabi_ambulance:notify', Strings.action_cancelled, Strings.action_cancelled_desc, 'error')
					end
				else
					TriggerEvent('wasabi_ambulance:notify', Strings.player_unconcious, Strings.player_unconcious_desc, 'error')
				end
			else
				TriggerEvent('wasabi_ambulance:notify', Strings.player_noitem, Strings.player_noitem_desc, 'error')
			end
		end, Config.EMSItems.heal.item)
	end
end

exports('healTarget', healTarget)

useSedative = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or dist > 1.5 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	else
		ESX.TriggerServerCallback('wasabi_ambulance:itemCheck', function(quantity) 
			if quantity > 0 then
				TriggerServerEvent('wasabi_ambulance:sedatePlayer', GetPlayerServerId(player))
			else
				TriggerEvent('wasabi_ambulance:notify', Strings.player_noitem, Strings.player_noitem_desc, 'error')
			end
		end, Config.EMSItems.sedate.item)
	end
end

exports('useSedative', useSedative)

placeInVehicle = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or dist > 7.5 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	else
		local playerPed = GetPlayerPed(player)
		if not IsPedInAnyVehicle(playerPed) then
			if DoesEntityExist(stretcher) then
				SetEntityAsMissionEntity(stretcher)
				TriggerServerEvent('wasabi_ambulance:removeObj', ObjToNet(stretcher))
			end
		end
		TriggerServerEvent('wasabi_ambulance:putInVehicle', GetPlayerServerId(player))
	end
end

exports('placeInVehicle', placeInVehicle)

local placedOnStretcher
local stretcherObj
placeOnStretcher = function()
	if LocalPlayer.state.dead and not placedOnStretcher then
		local coords = GetEntityCoords(cache.ped)
		local objHash = `prop_ld_binbag_01`
		local stretcherObj = GetClosestObjectOfType(coords, 1.5, objHash, false)
		local objCoords = GetEntityCoords(stretcherObj)
		lib.requestAnimDict('anim@gangops@morgue@table@', 100)
		TaskPlayAnim(cache.ped, "anim@gangops@morgue@table@", "body_search", 8.0, 8.0, -1, 33, 0, 0, 0, 0)
		AttachEntityToEntity(cache.ped, stretcherObj, 0, 0, 0.0, 1.0, 195.0, 0.0, 180.0, 0.0, false, false, false, false, 2, true)
		placedOnStretcher = true
	elseif placedOnStretcher then
		RemoveAnimDict('anim@gangops@morgue@table@')
		lib.requestAnimDict('mini@cpr@char_b@cpr_def', 100)
		DetachEntity(cache.ped)
		ClearPedTasks(cache.ped)
		placedOnStretcher = false
		stretcherObj = nil
	end
end

loadStretcher = function()
	local player, dist = ESX.Game.GetClosestPlayer()
	if player ~= -1 and dist < 4 then
		if Player(GetPlayerServerId(player)).state.dead then
			TriggerServerEvent('wasabi_ambulance:placeOnStretcher', GetPlayerServerId(player))
		else
			TriggerEvent('wasabi_ambulance:notify', Strings.player_not_unconcious, Strings.player_not_unconcious_desc, 'error')
		end
	else
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	end
end

exports('loadStretcher', loadStretcher)

moveStretcher = function()
	local ped = cache.ped
	stretcherMoving = true
	local textUI
	lib.requestAnimDict('anim@heists@box_carry@', 100)
	AttachEntityToEntity(stretcher, ped, GetPedBoneIndex(ped,  28422), 0.0, -0.9, -0.52, 195.0, 180.0, 180.0, 0.0, false, false, true, false, 2, true)
    while IsEntityAttachedToEntity(stretcher, ped) do
        Wait(0)
        if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
            TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
        end
		if not textUI then
			lib.showTextUI(Strings.drop_stretch_ui)
			textUI = true
		end
        if IsPedDeadOrDying(ped) then
            DetachEntity(stretcher, true, true)
			lib.hideTextUI()
			textUI = false
        end
        if IsControlJustPressed(0, 38) then
            DetachEntity(stretcher, true, true)
            ClearPedTasks(ped)
            stretcherMoving = false
			lib.hideTextUI()
			textUI = false
            stretcherPlaced(stretcher)
        end
    end
    RemoveAnimDict('anim@heists@box_carry@')

end

openOutfits = function(hospital)
	local data = Config.Locations[hospital].Cloakroom.Uniforms
	local Options = {
		{
			title = Strings.civilian_wear,
			description = '',
			arrow = false,
			event = 'wasabi_ambulance:changeClothes',
			args = 'civ_wear'
		}
	}
	for k,v in pairs(data) do
		table.insert(Options, {
			title = k,
			description = '',
			arrow = false,
			event = 'wasabi_ambulance:changeClothes',
			args = {male = v.male, female = v.female}
		})
	end
	lib.registerContext({
		id = 'ems_cloakroom',
		title = Strings.cloakroom,
		options = Options
	})
	lib.showContext('ems_cloakroom')
end

exports('openOutfits', openOutfits)

pickupStretcher = function()
	local ped = cache.ped
	local coords = GetEntityCoords(ped)
	local stretchHash = `prop_ld_binbag_01`
	local obj = GetClosestObjectOfType(coords, 3.0, stretchHash, false)
	local objCoords = GetEntityCoords(obj)
	TaskTurnPedToFaceCoord(ped, objCoords.x, objCoords.y, objCoords.z, 2000)
	ESX.TriggerServerCallback('wasabi_ambulance:gItem', function(cb, item)
		if cb then
			TriggerEvent('wasabi_ambulance:notify', Strings.successful, Strings.stretcher_pickup, 'success')
		end
	end, Config.EMSItems.stretcher)
	TriggerServerEvent('wasabi_ambulance:removeObj', ObjToNet(obj))
end

stretcherPlaced = function(obj)
	local coords = GetEntityCoords(obj)
	local heading = GetEntityHeading(obj)
	local targetPlaced = false
	CreateThread(function()
		while true do
			if DoesEntityExist(obj) and not targetPlaced then
				local data = {
					identifier = 'stretcherzone',
					coords = coords,
					width = 2.5,
					length = 2.5,
					heading = heading,
					minZ = coords.z-5,
					maxZ = coords.z+5,
					options = {
						{
							event = 'wasabi_ambulance:pickupStretcher',
							icon = 'fas fa-ambulance',
							label = Strings.pickup_bag_target,
						},
						{
							event = 'wasabi_ambulance:moveStretcher',
							icon = 'fas fa-ambulance',
							label = Strings.move_target
						},
						{
							event = 'wasabi_ambulance:loadStretcher',
							icon = 'fas fa-ambulance',
							label = Strings.place_stretcher_target
						},
					},
					job = "ambulance",
					distance = 2.5
				}
				TriggerEvent('wasabi_ambulance:addTarget', data)
				targetPlaced = true
			elseif not DoesEntityExist(obj) or stretcherMoving then
				TriggerEvent('wasabi_ambulance:removeTarget', 'stretcherzone')
				targetPlaced = false
				break
			end
			Wait(1500)
		end
	end)
end

useStretcher = function()
	local ped = cache.ped
	local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(ped,0.0,2.0,0.5))
	local textUI = false
	lib.requestModel('prop_ld_binbag_01', 100)
	lib.requestAnimDict('anim@heists@box_carry@', 100)
	stretcher = CreateObjectNoOffset('prop_ld_binbag_01', x, y, z, true, false)
	SetModelAsNoLongerNeeded('prop_ld_binbag_01')
	AttachEntityToEntity(stretcher, ped, GetPedBoneIndex(ped,  28422), 0.0, -0.9, -0.52, 195.0, 180.0, 180.0, 0.0, false, false, true, false, 2, true)
	while IsEntityAttachedToEntity(stretcher, ped) do
		Wait(0)
		if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
			TaskPlayAnim(ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
		end
		if not textUI then
			lib.showTextUI(Strings.drop_stretch_ui)
			textUI = true
		end
		if IsPedDeadOrDying(ped) then
			RemoveAnimDict('anim@heists@box_carry@')
			DetachEntity(stretcher, true, true)
			lib.hideTextUI()
			textUI = false
		end
		if IsControlJustPressed(0, 38) then
            DetachEntity(stretcher, true, true)
            ClearPedTasks(ped)
			RemoveAnimDict('anim@heists@box_carry@')
			lib.hideTextUI()
			textUI = false
            stretcherPlaced(stretcher)
        end
	end
end

treatPatient = function(injury)
	local player, dist = ESX.Game.GetClosestPlayer()
	if player == -1 or dist > 1.5 then
		TriggerEvent('wasabi_ambulance:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
	elseif ESX.PlayerData.job.name == 'ambulance' or ESX.PlayerData.job.name == 'police' then
		local targetId = GetPlayerServerId(player)
		if Player(targetId).state.injury then
			if Player(targetId).state.injury == injury then
				local ped = cache.ped
				local targetPed = GetPlayerPed(player)
				local tCoords = GetEntityCoords(targetPed)
				TaskTurnPedToFaceCoord(ped, tCoords.x, tCoords.y, tCoords.z, 3000)
				Wait(1000)
				TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
				Wait(Config.TreatmentTime)
				ClearPedTasks(ped)
				TriggerServerEvent('wasabi_ambulance:treatPlayer', targetId, injury)
			else
				TriggerEvent('wasabi_ambulance:notify', Strings.wrong_equipment, Strings.wrong_equipment_desc, 'error')
			end
		else
			TriggerEvent('wasabi_ambulance:notify', Strings.player_not_injured, Strings.player_not_injured_desc, 'error')
		end
	else
		TriggerEvent('wasabi_ambulance:notify', Strings.not_medic, Strings.not_medic_desc, 'error')
	end
end

exports('treatPatient', treatPatient)

gItem = function(data)
	local item = data.item
	ESX.TriggerServerCallback('wasabi_ambulance:gItem', function(cb, item) 
		if cb then
			TriggerEvent('wasabi_ambulance:notify', Strings.successful, Strings.item_grab, 'success')
		else
			TriggerEvent('wasabi_ambulance:notify', Strings.successful, Strings.medbag_pickup_civ, 'success')
		end
	end, item)
end

interactBag = function()
	if ESX.PlayerData.job.name == 'ambulance' or ESX.PlayerData.job.name == 'police' then
		lib.registerContext({
			id = 'medbag',
			title = Strings.medbag,
			options = {
				{
					title = Strings.medbag_tweezers,
					description = Strings.medbag_tweezers_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.TreatmentItems.shot}
				},
				{
					title = Strings.medbag_suture,
					description = Strings.medbag_suture_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.TreatmentItems.stabbed}
				},
				{
					title = Strings.medbag_icepack,
					description = Strings.medbag_icepack_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.TreatmentItems.beat}
				},
				{
					title = Strings.medbag_burncream,
					description = Strings.medbag_burncream_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.TreatmentItems.burncream}
				},
				{
					title = Strings.medbag_defib,
					description = Strings.medbag_defib_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.EMSItems.revive.item}
				},
				{
					title = Strings.medbag_medikit,
					description = Strings.medbag_medikit_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.EMSItems.heal.item}
				},
				{
					title = Strings.medbag_sedative,
					description = Strings.medbag_sedative_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.EMSItems.sedate.item}
				},
				{
					title = Strings.medbag_stretcher,
					description = Strings.medbag_stretcher_desc,
					arrow = false,
					event = 'wasabi_ambulance:gItem',
					args = {item = Config.EMSItems.stretcher}
				},
			}
		})
		lib.showContext('medbag')
	else
		TriggerEvent('wasabi_ambulance:notify', Strings.not_medic, Strings.not_medic_desc, 'error')
	end
end

deleteObj = function(bag)
	if DoesEntityExist(bag) then
		SetEntityAsMissionEntity(bag, true, true)
		DeleteObject(bag)
		DeleteEntity(bag)
	end
end

pickupBag = function()
	local ped = cache.ped
	local coords = GetEntityCoords(ped)
	local bagHash = `xm_prop_x17_bag_med_01a`
	local closestBag = GetClosestObjectOfType(coords, 3.0, bagHash, false)
	local bagCoords = GetEntityCoords(closestBag)
	TaskTurnPedToFaceCoord(ped, bagCoords.x, bagCoords.y, bagCoords.z, 2000)
	TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
	Wait(1000)
	TriggerServerEvent('wasabi_ambulance:removeObj', ObjToNet(closestBag))
	Wait(500)
	if not DoesEntityExist(closestBag) then
		ESX.TriggerServerCallback('wasabi_ambulance:gItem', function(cb) 
			if cb then
				TriggerEvent('wasabi_ambulance:notify', Strings.successful, Strings.medbag_pickup, 'success')
			else
				TriggerEvent('wasabi_ambulance:notify', Strings.successful, Strings.medbag_pickup_civ, 'success')
			end
		end, Config.EMSItems.medbag)
	end
end

medicalSuppliesMenu = function(id)
	if ESX.PlayerData.job.name == 'ambulance' then
		local supplies = Config.Locations[id].MedicalSupplies.Supplies
		local Options = {}
		for i=1, #supplies do
			if supplies[i].price then
				table.insert(Options, {
					title = supplies[i].label..' - '..Strings.currency..''..addCommas(supplies[i].price),
					description = '',
					arrow = false,
					event = 'wasabi_ambulance:buyItem',
					args = { hospital = id, item = supplies[i].item, price = supplies[i].price }
				})
			else
				table.insert(Options, {
					title = supplies[i].label,
					description = '',
					arrow = false,
					event = 'wasabi_ambulance:buyItem',
					args = { hospital = id, item = supplies[i].item }
				})
			end
		end
		lib.registerContext({
			id = 'ems_supply_menu',
			title = Strings.request_supplies_target,
			options = Options
		})
		lib.showContext('ems_supply_menu')
	end
end

openVehicleMenu = function(hosp)
	if ESX.PlayerData.job.name == 'ambulance' then
		inMenu = true
		local Options = {}
		for k,v in pairs(Config.Locations[hosp].Vehicles.Options) do
			if v.category == 'land' then
				table.insert(Options, {
					title = v.label,
					description = '',
					icon = 'car',
					arrow = true,
					event = 'wasabi_ambulance:spawnVehicle',
					args = { hospital = hosp, model = k }
				})
			elseif v.category == 'air' then
				table.insert(Options, {
					title = v.label,
					description = '',
					icon = 'helicopter',
					arrow = true,
					event = 'wasabi_ambulance:spawnVehicle',
					args = { hospital = hosp, model = k, category = v.category }
				})
			end
		end
		lib.registerContext({
			id = 'ems_garage_menu',
			title = Strings.hospital_garage,
			onExit = function()
				inMenu = false
			end,
			options = Options
		})
		lib.showContext('ems_garage_menu')
	end
end

local medbagObj
useMedbag = function()
	local ped = cache.ped
	local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(ped,0.0,2.0,0.55))
	lib.requestModel('xm_prop_x17_bag_med_01a', 100)
	medbagObj = CreateObjectNoOffset('xm_prop_x17_bag_med_01a', x, y, z, true, false)
	SetModelAsNoLongerNeeded('xm_prop_x17_bag_med_01a')
	SetCurrentPedWeapon(ped, `WEAPON_UNARMED`)
	AttachEntityToEntity(medbagObj, ped, GetPedBoneIndex(ped, 57005), 0.42, 0, -0.05, 0.10, 270.0, 60.0, true, true, false, true, 1, true)
	local bagEquipped = true
	local text_ui
	CreateThread(function()
		while bagEquipped do
			Wait(0)
			if not text_ui then
				lib.showTextUI(Strings.drop_bag_ui)
				text_ui = true
			end
			if IsControlJustReleased(0, 38) then
				TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, 8.0, 1000, 50, 0, false, false, false)
				bagEquipped = nil
				text_ui = nil
				lib.hideTextUI()
				Wait(1000)
				DetachEntity(medbagObj)
				PlaceObjectOnGroundProperly(medbagObj)
			end
		end
	end)
end

openDispatchMenu = function()
	if ESX.PlayerData.job.name == 'ambulance' then
		local Options = {
			{
				title = Strings.GoBack,
				description = '',
				icon = 'chevron-left',
				arrow = false,
				event = 'wasabi_ambulance:emsJobMenu',
			},
		}
		for k,v in pairs(plyRequests) do
			table.insert(Options, {
				title = v,
				description = '',
				arrow = true,
				event = 'wasabi_ambulance:setRoute',
				args = {plyId = k}
			}) 
		end
		if #Options < 2 then
			table.insert(Options, {
				title = Strings.no_requests,
				description = '',
				arrow = false,
				event = '',
			})
		end
		lib.registerContext({
			id = 'ems_dispatch_menu',
			title = Strings.DispatchMenuTitle,
			options = Options
		})
		lib.showContext('ems_dispatch_menu')
	end
end

openJobMenu = function()
	if ESX.PlayerData.job.name == 'ambulance' then
		local Options = {
			{
				title = Strings.dispatch,
				description = Strings.dispatch_desc,
				icon = 'truck-medical',
				arrow = true,
				event = 'wasabi_ambulance:dispatchMenu',
			},
			{
				title = Strings.diagnose_patient,
				description = Strings.diagnose_patient_desc,
				icon = 'stethoscope',
				arrow = false,
				event = 'wasabi_ambulance:diagnosePatient',
			},
			{
				title = Strings.revive_patient,
				description = Strings.revive_patient_desc,
				icon = 'kit-medical',
				arrow = false,
				event = 'wasabi_ambulance:reviveTarget',
			},
			{
				title = Strings.heal_patient,
				description = Strings.heal_patient_desc,
				icon = 'bandage',
				arrow = false,
				event = 'wasabi_ambulance:healTarget',
			},
			{
				title = Strings.sedate_patient,
				description = Strings.sedate_patient_desc,
				icon = 'syringe',
				arrow = false,
				event = 'wasabi_ambulance:useSedative',
			},
			{
				title = Strings.place_patient,
				description = Strings.place_patient_desc,
				icon = 'car',
				arrow = false,
				event = 'wasabi_ambulance:placeInVehicle',
			}
		}
		if Config.billingSystem then
			table.insert(Options, {
				title = Strings.bill_patient,
				description = Strings.bill_patient_desc,
				icon = 'file-invoice',
				arrow = false,
				event = 'wasabi_ambulance:billPatient',
			})
		end
		lib.registerContext({
			id = 'ems_job_menu',
			title = Strings.JobMenuTitle,
			options = Options
		})
		lib.showContext('ems_job_menu')
	end
end