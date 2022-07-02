InventoryAPI = {}
UsableItemsFunctions = {}
local allplayersammo = {}
CustomInventoryInfos = {
	default = {
		name= "Satchel",
		limit = Config.MaxItemsInInventory.Items,
	}
}

local function contains(table, element)
	if table ~= 0 then
		for k, v in pairs(table) do
			if string.upper(v) == string.upper(element) then
				return true
			end
		end
	end
	return false
end

InventoryAPI.canCarryAmountWeapons = function(player, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier

	local sourceInventoryWeaponCount = InventoryAPI.getUserTotalCountWeapons(identifier, charId) + amount

	if Config.MaxItemsInInventory.Weapons ~= -1 then
		if sourceInventoryWeaponCount <= Config.MaxItemsInInventory.Weapons then
			cb(true)
		else
			cb(false)
		end
	else
		cb(true)
	end
end

InventoryAPI.canCarryAmountItem = function(player, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory ~= nil and Config.MaxItemsInInventory.Items ~= -1 then
		local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier) + amount
		if sourceInventoryItemCount <= Config.MaxItemsInInventory.Items then
			cb(true)
		else
			cb(false)
		end
	else
		cb(false)
	end
end

InventoryAPI.canCarryItem = function(player, itemName, amount, cb, metadata)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	metadata = SharedUtils.MergeTables(svItems[itemName].metadata, metadata or {})
	local userInventory = UsersInventories["default"][identifier]

	if svItems[itemName] then
		local limit = svItems[itemName]:getLimit()

		if limit ~= -1 then
			if userInventory ~= nil then
				local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)
				if item ~= nil then
					local count = item:getCount()
					local total = count + amount

					if total <= limit then
						if Config.MaxItemsInInventory.Items ~= -1 then
							local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier) + amount

							if sourceInventoryItemCount <= Config.MaxItemsInInventory.Items then
								cb(true)
							else
								cb(false)
							end
						else
							cb(true)
						end
					else
						cb(false)
					end
				else
					if amount <= limit then
						if Config.MaxItemsInInventory.Items ~= -1 then
							local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier) + amount

							if sourceInventoryItemCount <= Config.MaxItemsInInventory.Items then
								cb(true)
							else
								cb(false)
							end
						else
							cb(true)
						end
					else
						cb(false)
					end
				end
			else
				if amount <= limit then
					if Config.MaxItemsInInventory.Items ~= -1 then
						local totalAmount = amount

						if totalAmount <= Config.MaxItemsInInventory.Items then
							cb(true)
						else
							cb(false)
						end
					else
						cb(true)
					end
				else
					cb(false)
				end
			end
		else
			if Config.MaxItemsInInventory.Items ~= -1 then
				local totalAmount = InventoryAPI.getUserTotalCount(identifier) + amount

				if totalAmount <= Config.MaxItemsInInventory.Items then
					cb(true)
				else
					cb(false)
				end
			else
				cb(true)
			end
		end
	end
end

InventoryAPI.getInventory = function(player, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local playerItems = {}

		for _, item in pairs(userInventory) do
			local newItem = {
				id = item:getId(),
				label = item:getLabel(),
				name = item:getName(),
				metadata = item:getMetadata(),
				type = item:getType(),
				count = item:getCount(),
				limit = item:getLimit(),
				canUse = item:getCanUse()
			}
			table.insert(playerItems, newItem)
		end
		cb(playerItems)
	end
end

InventoryAPI.registerUsableItem = function(name, cb)
	UsableItemsFunctions[name] = cb
	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Callback for item[^3" .. name .. "^7] ^2Registered!^7")
	end
end

InventoryAPI.getUserWeapon = function(player, cb, weaponId)
	local weapon = {}
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		local foundWeapon = userWeapons[weaponId]
		weapon.name = foundWeapon:getName()
		weapon.id = foundWeapon:getId()
		weapon.propietary = foundWeapon:getPropietary()
		weapon.used = foundWeapon:getUsed()
		weapon.ammo = foundWeapon:getAllAmmo()
		weapon.desc = foundWeapon:getDesc()
	end

	cb(weapon)
end

InventoryAPI.getUserWeapons = function(player, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charidentifier = sourceCharacter.charIdentifier
	local userWeapons = UsersWeapons["default"]

	local userWeapons = {}

	for _, currentWeapon in pairs(userWeapons) do
		if currentWeapon:getPropietary() == identifier and currentWeapon:getCharId() == charidentifier then
			local weapon = {
				name = currentWeapon:getName(),
				id = currentWeapon:getId(),
				propietary = currentWeapon:getPropietary(),
				used = currentWeapon:getUsed(),
				ammo = currentWeapon:getAllAmmo(),
				desc = currentWeapon:getDesc()
			}
			table.insert(userWeapons, weapon)
		end
	end
	cb(userWeapons)
end

InventoryAPI.getWeaponBullets = function(player, cb, weaponId)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		if userWeapons[weaponId]:getPropietary() == identifier then
			cb(userWeapons[weaponId]:getAllAmmo())
		end
	end
end

AddEventHandler('playerDropped', function(reason)
	local _source = source
	allplayersammo[_source] = nil
end)
RegisterServerEvent("vorpinventory:removeammo") -- new event
AddEventHandler("vorpinventory:removeammo", function(player)
	local _source = player
	allplayersammo[_source]["ammo"] = {}
	TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
end)
RegisterServerEvent("vorpinventory:getammoinfo")
AddEventHandler("vorpinventory:getammoinfo", function()
	local _source = source
	if allplayersammo[_source] ~= nil then
		TriggerClientEvent("vorpinventory:recammo", _source, allplayersammo[_source])
	end
end)

RegisterServerEvent("vorpinventory:servergiveammo")
AddEventHandler("vorpinventory:servergiveammo", function(ammotype, amount, target, maxcount)
	local _source = source
	local player1ammo = allplayersammo[_source]["ammo"][ammotype]
	local player2ammo = allplayersammo[target]["ammo"][ammotype]

	if allplayersammo[target]["ammo"][ammotype] == nil then
		allplayersammo[target]["ammo"][ammotype] = 0
	end
	if player1ammo == nil or player2ammo == nil then
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	end
	if 0 > (player1ammo - amount) then
		TriggerClientEvent("vorp:Tip", _source, _U("notenoughammo"), 2000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	elseif (player2ammo + amount) > maxcount then
		TriggerClientEvent("vorp:Tip", _source, _U("fullammoyou"), 2000)
		TriggerClientEvent("vorp:Tip", target, _U("fullammo"), 2000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		return
	end
	allplayersammo[_source]["ammo"][ammotype] = allplayersammo[_source]["ammo"][ammotype] - amount
	allplayersammo[target]["ammo"][ammotype] = allplayersammo[target]["ammo"][ammotype] + amount
	local charidentifier = allplayersammo[_source]["charidentifier"]
	local charidentifier2 = allplayersammo[target]["charidentifier"]
	exports.ghmattimysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier, ['ammo'] = json.encode(allplayersammo[_source]["ammo"]) })
	exports.ghmattimysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier2, ['ammo'] = json.encode(allplayersammo[target]["ammo"]) })
	TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
	TriggerClientEvent("vorpinventory:updateuiammocount", target, allplayersammo[target]["ammo"])
	TriggerClientEvent("vorpinventory:setammotoped", _source, allplayersammo[_source]["ammo"])
	TriggerClientEvent("vorpinventory:setammotoped", target, allplayersammo[target]["ammo"])
	TriggerClientEvent("vorp:Tip", _source, _U("transferedammo") .. Config.Ammolabels[ammotype] .. " : " .. amount, 2000)
	TriggerClientEvent("vorp:Tip", target, _U("recammo") .. Config.Ammolabels[ammotype] .. " : " .. amount, 2000)
	TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
end)

RegisterServerEvent("vorpinventory:updateammo")
AddEventHandler("vorpinventory:updateammo", function(ammoinfo)
	local _source = source
	allplayersammo[_source] = ammoinfo
	exports.ghmattimysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = ammoinfo["charidentifier"], ['ammo'] = json.encode(ammoinfo["ammo"]) })
end)

InventoryAPI.LoadAllAmmo = function()
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charidentifier = sourceCharacter.charIdentifier
	exports.ghmattimysql:execute('SELECT ammo FROM characters WHERE charidentifier = @charidentifier ',
		{ ['charidentifier'] = charidentifier }, function(result)
		local ammo = json.decode(result[1].ammo)
		allplayersammo[_source] = { charidentifier = charidentifier, ammo = ammo }
		if next(ammo) ~= nil then
			for k, v in pairs(ammo) do
				local ammocount = tonumber(v)
				if ammocount > 0 then
					TriggerClientEvent("vorpCoreClient:addBullets", _source, k, ammocount)
				end
			end
		end
	end)
end

InventoryAPI.addBullets = function(player, bulletType, amount)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charidentifier = sourceCharacter.charIdentifier
	exports.ghmattimysql:execute('SELECT ammo FROM characters WHERE charidentifier = @charidentifier ',
		{ ['charidentifier'] = charidentifier }, function(result)
		local ammo = json.decode(result[1].ammo)
		if ammo[bulletType] ~= nil then
			ammo[bulletType] = ammo[bulletType] + amount
		else
			ammo[bulletType] = amount
		end
		allplayersammo[_source]["ammo"] = ammo
		TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
		TriggerClientEvent("vorpCoreClient:addBullets", _source, bulletType, ammo[bulletType])
		exports.ghmattimysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
			{ ['charidentifier'] = charidentifier, ['ammo'] = json.encode(ammo) })
	end)

	--[[ if UsersWeapons[weaponId] then
		if UsersWeapons[weaponId]:getPropietary() == identifier then
			UsersWeapons[weaponId]:addAmmo(bulletType, amount)
			TriggerClientEvent("vorpCoreClient:addBullets", _source, weaponId, bulletType, amount)
		end
	end ]]
end

InventoryAPI.subBullets = function(weaponId, bulletType, amount)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		if userWeapons[weaponId]:getPropietary() == identifier then
			userWeapons[weaponId]:subAmmo(bulletType, amount)
			TriggerClientEvent("vorpCoreClient:subBullets", _source, bulletType, amount)
		end
	end
end

InventoryAPI.getItems = function(player, cb, item, metadata)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	metadata = SharedUtils.MergeTables(svItems[item].metadata, metadata or {})
	local userInventory = UsersInventories["default"][identifier]

	if userInventory ~= nil then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, item, metadata)
		if item ~= nil then
			cb(item:getCount())
		else
			cb(0)
		end
	end
end

InventoryAPI.getItem = function(player, item, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory ~= nil then
		if userInventory[item] ~= nil then
			cb(userInventory[item])
		else
			cb(nil)
		end
	else
		cb(nil)
	end
end

InventoryAPI.addItem = function(player, name, amount, metadata)
	local _source = player
	local sourceUser = Core.getUser(_source)
	local added = false

	if (sourceUser) == nil then
		return
	end

	metadata = SharedUtils.MergeTables(svItems[name].metadata, metadata or {})

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if svItems[name] == nil then
		if Config.Debug then
			Log.Warning("Item: [^2" .. name .. "^7] ^1 do not exist on Database please add this item on ^7 Table Items")
		end
		return
	end

	if userInventory == nil then
		UsersInventories["default"][identifier] = {}
		userInventory = {}
	end

	if userInventory == nil then
		return
	end

	if amount <= 0 then
		return
	end

	local sourceItemLimit = svItems[name]:getLimit()
	local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier) + amount

	local itemLabel = svItems[name]:getLabel()
	local itemType = svItems[name]:getType()
	local itemCanRemove = svItems[name]:getCanRemove()
	local itemDefaultMetadata = svItems[name]:getMetadata()

	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)

	if item ~= nil then -- Item already exist in inventory
		if item:getCount() + amount <= sourceItemLimit or sourceItemLimit == -1 then
			if Config.MaxItemsInInventory.Items ~= -1 then
				if sourceInventoryItemCount <= Config.MaxItemsInInventory.Items then
					item:addCount(amount)
					DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
					TriggerClientEvent("vorpCoreClient:addItem", _source, item)
					return
				end
			else
				item:addCount(amount)
				DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
				TriggerClientEvent("vorpCoreClient:addItem", _source, item)
				return
			end
		end
	else -- Item does not exist in inventory
		if Config.MaxItemsInInventory.Items ~= -1 then
			if sourceInventoryItemCount <= Config.MaxItemsInInventory.Items then
				DbService.CreateItem(charIdentifier, svItems[name]:getId(), amount, metadata, function(craftedItem)
					item = Item:New({
						id = craftedItem.id,
						count = amount,
						limit = sourceItemLimit,
						label = itemLabel,
						metadata = SharedUtils.MergeTables(itemDefaultMetadata, metadata),
						name = name,
						type = itemType,
						canUse = true,
						canRemove = itemCanRemove
					})
					userInventory[craftedItem.id] = item
					TriggerClientEvent("vorpCoreClient:addItem", _source, item)
				end)
				return
			end
		else
			DbService.CreateItem(charIdentifier, svItems[name]:getId(), amount, metadata, function(craftedItem)
				item = Item:New({
					id = craftedItem.id,
					count = amount,
					limit = sourceItemLimit,
					label = itemLabel,
					metadata = SharedUtils.MergeTables(itemDefaultMetadata, metadata),
					name = name,
					type = itemType,
					canUse = true,
					canRemove = itemCanRemove
				})
				userInventory[craftedItem.id] = item
				TriggerClientEvent("vorpCoreClient:addItem", _source, item)
			end)
			return
		end
	end

	-- inventory is full
	TriggerClientEvent("vorp:Tip", _source, _U("fullInventory"), 2000)
end

InventoryAPI.subItem = function(player, name, amount, metadata)
	local _source = player
	local sourceUser = Core.getUser(_source)
	metadata = SharedUtils.MergeTables(svItems[name].metadata, metadata or {})


	if (sourceUser) == nil then
		return
	end


	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if svItems[name] == nil then
		if Config.Debug then
			Log.Warning("Item: [^2" .. name .. "^7] ^1 do not exist on Database please add this item on ^7 Table Items")
		end
		return
	end

	if userInventory ~= nil then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)

		if item ~= nil then
			local sourceItemCount = item:getCount()

			if amount <= sourceItemCount then
				item:quitCount(amount)
			else
				return
			end

			TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount())

			if item:getCount() == 0 then
				userInventory[item:getId()] = nil
				DbService.DeleteItem(charIdentifier, item:getId())
			else
				DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
			end
			--InventoryAPI.SaveInventoryItemsSupport(_source)
		end
	end
end

InventoryAPI.registerWeapon = function(target, name, ammos, components)
	local _target = target
	local targetUser = Core.getUser(_target)
	local targetCharacter
	local targetIdentifier
	local targetCharId
	local ammo = {}
	local component = {}

	local canGive = false

	for index, weapons in pairs(Config.Weapons) do
		if weapons.HashName == name then
			canGive = true
			break
		end

	end


	if targetUser then
		targetCharacter = targetUser.getUsedCharacter
		targetIdentifier = targetCharacter.identifier
		targetCharId = targetCharacter.charIdentifier
	end

	if Config.MaxItemsInInventory.Weapons ~= 0 then
		local targetTotalWeaponCount = InventoryAPI.getUserTotalCountWeapons(targetIdentifier, targetCharId) + 1

		if targetTotalWeaponCount > Config.MaxItemsInInventory.Weapons then
			TriggerClientEvent("vorp:TipRight", _target, _U("cantweapons2"), 2000)
			if Config.Debug then
				Log.Warning(targetCharacter.firstname .. " " .. targetCharacter.lastname .. " ^1Can't carry more weapons^7")
			end
			return
		end
	end

	if ammos then
		for _, value in pairs(ammos) do
			ammo[_] = value
		end
	end

	if components then
		for key, value in pairs(components) do
			component[#component + 1] = key
		end
	end
	if canGive then
		exports.ghmattimysql:execute("INSERT INTO loadout (identifier, charidentifier, name, ammo, components) VALUES (@identifier, @charid, @name, @ammo, @components)"
			, {
				['identifier'] = targetIdentifier,
				['charid'] = targetCharId,
				['name'] = name,
				['ammo'] = json.encode(ammo),
				['components'] = json.encode(component)
			}, function(result)
			local weaponId = result.insertId
			local newWeapon = Weapon:New({
				id = weaponId,
				propietary = targetIdentifier,
				name = name,
				ammo = ammo,
				used = false,
				used2 = false,
				charId = targetCharId
			})
			UsersWeapons["default"][weaponId] = newWeapon

			TriggerEvent("syn_weapons:registerWeapon", weaponId)
			TriggerClientEvent("vorpInventory:receiveWeapon", _target, weaponId, targetIdentifier, name, ammo)
		end)
	else
		Log.Warning("Weapon: [^2" .. name .. "^7] ^1 do not exist on the config or its a WRONG HASH")
	end
end

InventoryAPI.giveWeapon = function(player, weaponId, target)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharId = sourceCharacter.charIdentifier
	local _target = tonumber(target)
	local targetisPlayer = false
	local userWeapons = UsersWeapons["default"]

	for _, pl in pairs(GetPlayers()) do
		if tonumber(pl) == _target then
			targetisPlayer = true
			break
		end
	end

	if Config.MaxItemsInInventory.Weapons ~= 0 then
		local sourceTotalWeaponCount = InventoryAPI.getUserTotalCountWeapons(sourceIdentifier, sourceCharId) + 1

		if sourceTotalWeaponCount > Config.MaxItemsInInventory.Weapons then

			TriggerClientEvent("vorp:TipRight", _source, _U("cantweapons"), 2000)
			if Config.Debug then
				Log.print(sourceCharacter.firstname .. " " .. sourceCharacter.lastname .. " ^1Can't carry more weapons^7")
			end
			return
		end
	end

	if userWeapons[weaponId] then
		userWeapons[weaponId]:setPropietary(sourceIdentifier)
		userWeapons[weaponId]:setCharId(sourceCharId)

		local weaponPropietary = userWeapons[weaponId]:getPropietary()
		local weaponName = userWeapons[weaponId]:getName()
		local weaponAmmo = userWeapons[weaponId]:getAllAmmo()

		exports.ghmattimysql:execute("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = sourceIdentifier,
				['charid'] = sourceCharId,
				['id'] = weaponId
			}, function() end)

		if targetisPlayer then
			--TriggerClientEvent("vorp:TipRight", _target, _U("youGaveWeapon"), 2000)
			TriggerClientEvent('vorp:ShowAdvancedRightNotification', _target, _U("youGaveWeapon"), "inventory_items", weaponName,
				"COLOR_PURE_WHITE", 4000)
			TriggerClientEvent("vorpCoreClient:subWeapon", _target, weaponId)
		end

		--TriggerClientEvent("vorp:TipRight", _source, _U("youReceivedWeapon"), 2000)
		TriggerClientEvent('vorp:ShowAdvancedRightNotification', _source, _U("youReceivedWeapon"), "inventory_items",
			weaponName, "COLOR_PURE_WHITE", 4000)
		TriggerClientEvent("vorpInventory:receiveWeapon", _source, weaponId, weaponPropietary, weaponName, weaponAmmo)
	end
end

InventoryAPI.subWeapon = function(player, weaponId)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		userWeapons[weaponId]:setPropietary('')

		exports.ghmattimysql:execute("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = '',
				['charid'] = charId,
				['id'] = weaponId
			}, function() end)
	end

	TriggerClientEvent("vorpCoreClient:subWeapon", _source, weaponId)
end

InventoryAPI.getUserTotalCount = function(identifier)
	local userTotalItemCount = 0
	local userInventory = UsersInventories["default"][identifier]
	for _, item in pairs(userInventory) do
		userTotalItemCount = userTotalItemCount + item:getCount()
	end
	return userTotalItemCount
end

InventoryAPI.getUserTotalCountWeapons = function(identifier, charId)
	local userTotalWeaponCount = 0
	for _, weapon in pairs(UsersWeapons["default"]) do
		if weapon:getPropietary() == identifier and weapon:getCharId() == charId then
			if not contains(Config.notweapons, weapon:getName()) then
				userTotalWeaponCount = userTotalWeaponCount + 1
			end
		end
	end
	return userTotalWeaponCount
end

InventoryAPI.onNewCharacter = function(playerId)
	Wait(5000)
	local player = Core.getUser(playerId)

	if player == nil then
		if Config.Debug then
			Log.print("Player [^2" .. playerId .. "^7] ^1 was not found^7")
		end
		return
	end

	--local identifier = player.getIdentifier()

	-- Attempt to add all starter items/weapons from the Config.lua
	for key, value in pairs(Config.startItems) do
		TriggerEvent("vorpCore:addItem", playerId, tostring(key), tonumber(value), {})
	end

	for key, value in pairs(Config.startWeapons) do
		local auxBullets = {}
		local receivedBullets = {}
		local weaponConfig = nil

		for _, wpc in pairs(Config.Weapons) do
			if wpc.HashName == key then
				weaponConfig = wpc
				break
			end
		end

		if weaponConfig then
			local ammoHash = weaponConfig["AmmoHash"]

			if ammoHash then
				for ammohashKey, ammohashValue in pairs(ammoHash) do
					auxBullets[ammohashKey] = ammohashValue
				end
			end
		end

		for bulletKey, bulletValue in pairs(value) do
			if auxBullets[bulletKey] then
				receivedBullets[bulletKey] = tonumber(bulletValue)
			end
		end

		TriggerEvent("vorpCore:registerWeapon", playerId, key, receivedBullets)
	end
end

InventoryAPI.registerInventory = function(id, name, limit, acceptWeapons)
	limit = limit ~= nil and limit or -1
	acceptWeapons = acceptWeapons ~= nil and acceptWeapons or true
	if CustomInventoryInfos[id] ~= nil then
		return
	end

	CustomInventoryInfos[id] = {
		name = name,
		limit = limit,
		acceptWeapons = acceptWeapons
	}
	UsersInventories[id] = {}
	if UsersWeapons[id] == nil then
		UsersWeapons[id] = {}
	end
end

InventoryAPI.removeInventory = function(id, name)
	if CustomInventoryInfos[id] == nil then
		return
	end

	CustomInventoryInfos[id] = nil
	UsersInventories[id] = nil
	UsersWeapons[id] = nil
end

InventoryAPI.reloadInventory = function(player, id)
	local _source = player

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories[id][sourceIdentifier]
	local itemList = {}

	-- arrange userInventory as a list
	for _, value in pairs(userInventory) do
		itemList[#itemList+1] = value
	end

	-- Add weapons as Item to inventory
	for weaponId, weapon in pairs(UsersWeapons[id]) do
		if weapon.charId == sourceCharIdentifier then
			itemList[#itemList+1] = Item:New({
				id = weaponId,
				count = 1,
				name = weapon.name,
				label = weapon.name,
				limit = 1,
				type = "item_weapon",
				desc = weapon.desc
			})
		end
	end

	local payload = {
		itemList =itemList,
		action = "setSecondInventoryItems"
	}

	--print(json.encode(itemList))

	TriggerClientEvent("vorp_inventory:ReloadCustomInventory", _source, json.encode(payload))
end

InventoryAPI.openCustomInventory = function(player, id)
	local _source = player
	if CustomInventoryInfos[id] == nil or UsersInventories[id] == nil then
		return
	end

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local capacity = CustomInventoryInfos[id].limit > 0 and tostring(CustomInventoryInfos[id].limit) or 'oo'

	if UsersInventories[id][identifier] ~= nil then
		TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
		InventoryAPI.reloadInventory(_source, id)
	else
		DbService.GetInventory(charIdentifier, id, function(inventory)
			local characterInventory = {}
			for _, item in pairs(inventory) do
				if svItems[item.item] ~= nil then
					local dbItem = svItems[item.item]
					characterInventory[item.id] = Item:New({
						count = tonumber(item.amount),
						id = item.id,
						limit = dbItem.limit,
						label = dbItem.label,
						metadata = SharedUtils.MergeTables(dbItem.metadata, item.metadata),
						name = dbItem.item,
						type = dbItem.type,
						canUse = dbItem.usable,
						canRemove = dbItem.can_remove,
						createdAt = item.created_at
					})
				end
			end
			UsersInventories[id][identifier] = characterInventory
			TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
			InventoryAPI.reloadInventory(_source, id)
		end)
	end
end

InventoryAPI.closeCustomInventory = function(player, id)
	local _source = player
	if CustomInventoryInfos[id] == nil then
		return
	end

	TriggerClientEvent("vorp_inventory:CloseCustomInv", _source)
end
