DwwUtils = exports.dww_utils:GetUtils()

InventoryAPI = {}
UsableItemsFunctions = {}
local allplayersammo = {}
-- by default assign this
CustomInventoryInfos = {
	default = {
		name = "Satchel",
		limit = Config.MaxItemsInInventory.Items,
		shared = false,
		---@type table<string, integer>
		limitedItems = {},
		---@type boolean
		ignoreItemStackLimit = false,
		---@type boolean
		whitelistItems = false,
		---@type table<string, integer>
		PermissionTakeFrom = {},
		---@type table<string, integer>
		PermissionMoveTo = {},
		---@type boolean
		UsePermissions = false,
		---@type boolean
		UseBlackList = false,
		---@type table<string>
		BlackListItems = {},
		---@type boolean
		whitelistWeapons = false,
		---@type table<string, integer>
		limitedWeapons = {}
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

InventoryAPI.canCarryAmountItem = function(player, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory and Config.MaxItemsInInventory.Items ~= -1 then
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

InventoryAPI.canCarryItem = function(player, itemName, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charid = sourceCharacter.charIdentifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API CanCarryItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(false)
		return
	end

	local limit = svItem:getLimit()

	if limit ~= -1 then
		local items = SvUtils.FindAllItemsByName("default", identifier, itemName)
		local count = 0
		for _, item in pairs(items) do
			count = count + item:getCount()
		end
		local total = count + amount

		if total <= limit then
			if Config.MaxItemsInInventory.Items ~= -1 then
				local sourceInventoryItemCount = InventoryAPI.getUserTotalCount(identifier, charid)
				local finalAmount = sourceInventoryItemCount + amount
				if finalAmount <= Config.MaxItemsInInventory.Items then
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
		if Config.MaxItemsInInventory.Items ~= -1 then
			local totalAmount = InventoryAPI.getUserTotalCount(identifier, charid)
			local finalAmount = totalAmount + amount
			if finalAmount <= Config.MaxItemsInInventory.Items then
				cb(true)
			else
				cb(false)
			end
		else
			cb(true)
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

InventoryAPI.getCustomInventory = function(player, id, cb)
	local _source = player
	local invData = CustomInventoryInfos[id]
	local userInventory = {}

	if invData.shared then
		userInventory = UsersInventories[id]
	else
		local sourceCharacter = Core.getUser(_source).getUsedCharacter
		local sourceIdentifier = sourceCharacter.identifier
		userInventory = UsersInventories[id][sourceIdentifier]
	end

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
	else
		cb(nil)
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
	local usersWeapons = UsersWeapons["default"]

	local userWeapons2 = {}

	for _, currentWeapon in pairs(usersWeapons) do
		if currentWeapon:getPropietary() == identifier and currentWeapon:getCharId() == charidentifier then
			local weapon = {
				name = currentWeapon:getName(),
				id = currentWeapon:getId(),
				propietary = currentWeapon:getPropietary(),
				used = currentWeapon:getUsed(),
				ammo = currentWeapon:getAllAmmo(),
				desc = currentWeapon:getDesc()
			}
			table.insert(userWeapons2, weapon)
		end
	end
	cb(userWeapons2)
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
	if allplayersammo[_source] then
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
	exports.oxmysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier,['ammo'] = json.encode(allplayersammo[_source]["ammo"]) })
	exports.oxmysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = charidentifier2,['ammo'] = json.encode(allplayersammo[target]["ammo"]) })
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
	exports.oxmysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
		{ ['charidentifier'] = ammoinfo["charidentifier"],['ammo'] = json.encode(ammoinfo["ammo"]) })
end)

InventoryAPI.LoadAllAmmo = function()
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charidentifier = sourceCharacter.charIdentifier
	exports.oxmysql:execute('SELECT ammo FROM characters WHERE charidentifier = @charidentifier ',
		{ ['charidentifier'] = charidentifier }, function(result)
			local ammo = json.decode(result[1].ammo)
			allplayersammo[_source] = { charidentifier = charidentifier, ammo = ammo }
			if next(ammo) then
				for k, v in pairs(ammo) do
					local ammocount = tonumber(v)
					if ammocount and ammocount > 0 then
						TriggerClientEvent("vorpCoreClient:addBullets", _source, k, ammocount)
					end
				end
			end
		end)
end

InventoryAPI.addBullets = function(player, bulletType, amount)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charidentifier = sourceCharacter.charIdentifier
	exports.oxmysql:execute('SELECT ammo FROM characters WHERE charidentifier = @charidentifier;',
		{ ['charidentifier'] = charidentifier }, function(result)
			local ammo = json.decode(result[1].ammo)
			if ammo[bulletType] then
				ammo[bulletType] = tonumber(ammo[bulletType]) + amount
			else
				ammo[bulletType] = amount
			end
			allplayersammo[_source]["ammo"] = ammo
			TriggerClientEvent("vorpinventory:updateuiammocount", _source, allplayersammo[_source]["ammo"])
			TriggerClientEvent("vorpCoreClient:addBullets", _source, bulletType, ammo[bulletType])
			exports.oxmysql:execute("UPDATE characters Set ammo=@ammo WHERE charidentifier=@charidentifier",
				{ ['charidentifier'] = charidentifier,['ammo'] = json.encode(ammo) })
		end)
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

InventoryAPI.getItems = function(player, cb, itemName, metadata)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItems^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(0)
		return
	end
	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)
		if item == nil then
			item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
		end
		if item then
			cb(item:getCount())
		else
			cb(0)
		end
	end
end

InventoryAPI.getItemCountByName = function(player, cb, itemName, metadata)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API getItemCountByName^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(0)
		return
	end
	local userInventory = UsersInventories["default"][identifier]

	local completeQuantity = 0
	for _, item in pairs(userInventory) do
		if item:getName() == itemName and (metadata == nil or SharedUtils.Table_contains(item:getMetadata(), metadata)) then
			completeQuantity = completeQuantity + item:getCount()
		end
	end

	cb(completeQuantity)
end



InventoryAPI.getItemByName = function(player, itemName, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
	if item then
		cb(item)
	else
		cb(nil)
	end
end

InventoryAPI.getItemContainingMetadata = function(player, itemName, metadata, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	local item = SvUtils.FindItemByNameAndContainingMetadata("default", identifier, itemName, metadata)

	if item then
		cb(item)
	else
		cb(nil)
	end
end

InventoryAPI.getItemMatchingMetadata = function(player, itemName, metadata, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	metadata = SharedUtils.MergeTables(svItem.metadata or {}, metadata or {})
	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)

	if item then
		cb(item)
	else
		cb(nil)
	end
end

InventoryAPI.addItem = function(player, name, amount, metadata, cb)
	local _source = player
	local sourceUser = Core.getUser(_source)

	if cb == nil then
		cb = function(r)
		end
	end

	if (sourceUser) == nil then
		return
	end

	local svItem = svItems[name]

	if svItem == nil then
		Log.print("[^2API AddItem^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		return
	end

	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory == nil then
		UsersInventories["default"][identifier] = {}
		userInventory = UsersInventories["default"][identifier] -- create reference to actual table
	end

	if userInventory == nil then
		cb(false)
		return
	end

	if amount <= 0 then
		cb(false)
		return
	end

	local sourceItemLimit = svItem:getLimit()
	local itemLabel = svItem:getLabel()
	local itemType = svItem:getType()
	local itemCanRemove = svItem:getCanRemove()
	local itemDefaultMetadata = svItem:getMetadata()
	local ItemDesc = svItem:getDesc()

	local canAdd = nil
	InventoryAPI.canCarryItem(_source, name, amount, function(res)
		canAdd = res
	end)

	while canAdd == nil do
		Citizen.Wait(100)
	end

	if canAdd then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)

		if item ~= nil then -- Item already exist in inventory
			item:addCount(amount)
			DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
			TriggerClientEvent("vorpCoreClient:addItem", _source, item)
			cb(true)
		else
			DbService.CreateItem(charIdentifier, svItem:getId(), amount, metadata, function(craftedItem)
				item = Item:New({
					id = craftedItem.id,
					count = amount,
					limit = sourceItemLimit,
					label = itemLabel,
					metadata = SharedUtils.MergeTables(itemDefaultMetadata, metadata),
					name = name,
					type = itemType,
					canUse = true,
					canRemove = itemCanRemove,
					owner = charIdentifier,
					desc = ItemDesc
				})
				userInventory[craftedItem.id] = item
				TriggerClientEvent("vorpCoreClient:addItem", _source, item)
			end)
			cb(true)
		end
	else
		-- inventory is full
		TriggerClientEvent("vorp:Tip", _source, _U("fullInventory"), 2000)
		cb(false)
	end
end

InventoryAPI.getItemByMainId = function(player, mainid, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local itemRequested = {}
		for _, item in pairs(userInventory) do
			if mainid == item:getId() then
				itemRequested = {
					id = item:getId(),
					label = item:getLabel(),
					name = item:getName(),
					metadata = item:getMetadata(),
					type = item:getType(),
					count = item:getCount(),
					limit = item:getLimit(),
					canUse = item:getCanUse()
				}
				return cb(itemRequested) -- send table of the item requested
			end
		end
	end
	return cb(nil)
end


InventoryAPI.subItemID = function(player, id, cb)
	local _source = player
	local sourceUser = Core.getUser(_source)

	if cb == nil then
		cb = function(r)
		end
	end

	if (sourceUser) == nil then
		return
	end

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if not userInventory then
		return cb(false)
	end
	local item = userInventory[id]

	if not item then
		return cb(false)
	end

	local sourceItemCount = item:getCount()

	if not sourceItemCount then
		return cb(false)
	end

	item:quitCount(1)

	TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount())

	if item:getCount() <= 0 then
		userInventory[item:getId()] = nil
		DbService.DeleteItem(charIdentifier, item:getId())
	else
		DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
	end
	cb(true)
end

InventoryAPI.deleteFromCustom = function(source, inventoryId, item, amount, cb)
	local invId = inventoryId

	local invData = CustomInventoryInfos[invId]
	if not invData then return end

	if type(item) ~= "table" then
		local userInventory = {}

		if invData.shared then
			userInventory = UsersInventories[invId]
		else
			local sourceCharacter = Core.getUser(source).getUsedCharacter
			local sourceIdentifier = sourceCharacter.identifier
			userInventory = UsersInventories[invId][sourceIdentifier]
		end
		item = userInventory[item]
	end
	if item.type == "item_weapon" then
		exports.oxmysql:execute("DELETE FROM `loadout` WHERE `id` = ?", { item })
		UsersWeapons[invId][item.id] = nil
	else
		InventoryService.subItem(source, invId, item.id, amount)
	end
	cb()
end

InventoryAPI.subItemByName = function(player, name, amount, metadata, cb)
	local _source = player
	local sourceUser = Core.getUser(_source)
	local svItem = svItems[name]
	local removedItems = {}

	if cb == nil then
		cb = function(r)
		end
	end

	if svItem == nil then
		Log.print("[^2API SubItemByName^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		return
	end

	if (sourceUser) == nil then
		return
	end

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		-- find possible items to delete
		local completeQuantity = 0
		for _, item in pairs(userInventory) do
			if item:getName() == name and (metadata == nil or SharedUtils.Table_contains(item:getMetadata(), metadata)) then
				completeQuantity = completeQuantity + item:getCount()
			end
		end

		-- Not enough amount
		if completeQuantity < amount then
			cb(removedItems)
			return
		end

		-- remove item count until amount is 0
		while amount > 0 do
			local possibleItems = {}
			for _, item in pairs(userInventory) do
				if item:getName() == name and (metadata == nil or SharedUtils.Table_contains(item:getMetadata(), metadata)) then
					completeQuantity = completeQuantity + item:getCount()
					table.insert(possibleItems, item)
				end
			end

			for _, item in ipairs(possibleItems) do
				local sourceItemCount = item:getCount()

				local removedItem = {
					id = item:getId(),
					item = item:getName(),
					label = item:getLabel(),
					count = item:getCount(),
					metadata = item:getMetadata(),
				}

				if sourceItemCount < amount then
					item:quitCount(sourceItemCount)
					removedItem["amount"] = sourceItemCount
					amount = amount - sourceItemCount
				else
					item:quitCount(amount)
					removedItem["amount"] = amount + 0
					amount = 0
				end


				table.insert(removedItems, removedItem)

				if item:getCount() == 0 then
					userInventory[item:getId()] = nil
					DbService.DeleteItem(charIdentifier, item:getId())
				else
					DbService.SetItemAmount(charIdentifier, item:getId(), item:getCount())
				end

				TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount())

				if amount == 0 then
					break
				end
			end
		end

		cb(removedItems)
		return
	end

	cb(removedItems)
end

InventoryAPI.subItem = function(player, name, amount, metadata, cb)
	local _source = player
	local sourceUser = Core.getUser(_source)
	local svItem = svItems[name]

	if cb == nil then
		cb = function(r)
		end
	end

	if svItem == nil then
		Log.print("[^2API SubItem^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		return
	end
	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})

	if (sourceUser) == nil then
		return
	end

	local sourceCharacter = sourceUser.getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]

	if userInventory then
		local item = SvUtils.FindItemByNameAndMetadata("default", identifier, name, metadata)
		if item == nil then
			item = SvUtils.FindItemByName("default", identifier, name)
		end
		if item then
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
			cb(true)
		else
			cb(false)
		end
	end
end

---comment
---@param player integer
---@param itemId integer
---@param metadata table
---@param amount integer an ammount if you require to remove this many or set this many
---@param cb any
---@return any
InventoryAPI.setItemMetadata = function(player, itemId, metadata, amount, cb)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier
	local userInventory = UsersInventories["default"][identifier]
	local amountRemove = amount or 1

	if not userInventory then
		return cb(false)
	end

	local item = userInventory[itemId]

	if not item then
		return cb(false)
	end

	local count = item:getCount()

	if amountRemove >= count then -- if greater or equals we set meta data
		DbService.SetItemMetadata(charId, item.id, metadata)
		item:setMetadata(metadata)
		TriggerClientEvent("vorpCoreClient:SetItemMetadata", _source, itemId, metadata)
		return cb(true)
	else                                                                               -- we set meta data to only the amount we want
		item:quitCount(amountRemove)                                                   -- item remove
		DbService.SetItemAmount(charId, item.id, item:getCount())                      --
		TriggerClientEvent("vorpCoreClient:subItem", _source, item:getId(), item:getCount()) -- remove
		DbService.CreateItem(charId, item:getId(), amount or 1, metadata, function(craftedItem)
			item = Item:New(
				{
					id = craftedItem.id,
					count = amount or 1,
					limit = item:getLimit(),
					label = item:getLabel(),
					metadata = SharedUtils.MergeTables(item:getMetadata(), metadata),
					name = item:getName(),
					type = item:getType(),
					canUse = true,
					canRemove = item:getCanRemove(),
					owner = charId,
					desc = item:getDesc()
				})
			userInventory[craftedItem.id] = item
			TriggerClientEvent("vorpCoreClient:addItem", _source, item)
		end)
		return cb(true)
	end
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
InventoryAPI.getItem = function(player, itemName, cb, metadata)
	local _source = player
	if not Core.getUser(_source) then
		print("getitem function source does not exist , make sure its specified")
		return
	end
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local svItem = svItems[itemName]

	if svItem == nil then
		Log.print("[^2API GetItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	metadata = SharedUtils.MergeTables(svItem.metadata or {}, metadata or {})
	local item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, metadata)
	if item == nil then
		item = SvUtils.FindItemByNameAndMetadata("default", identifier, itemName, nil)
	end
	if item then
		cb(item)
	else
		cb(nil)
	end
end



InventoryAPI.getcomps = function(player, weaponid, cb)
	local _source = player
	exports.oxmysql:execute('SELECT comps FROM loadout WHERE id = @id ', { ['id'] = weaponid }, function(result)
		if result[1] ~= nil then
			cb(json.decode(result[1].comps))
		else
			cb({})
		end
	end)
end



InventoryAPI.deletegun = function(player, weaponid)
	local _source = player
	local userWeapons = UsersWeapons["default"]
	userWeapons[weaponid]:setPropietary('')
	exports.oxmysql:execute("DELETE FROM loadout WHERE id=@id", { ['id'] = weaponid })
end

InventoryAPI.registerWeapon = function(target, name, ammos, components, comps, props)
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
				Log.Warning(targetCharacter.firstname ..
					" " .. targetCharacter.lastname .. " ^1Can't carry more weapons^7")
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
		comps = comps or {}
		props = props or {}

		exports.ghmattimysql:execute("INSERT INTO loadout (identifier, charidentifier, name, ammo, components, comps, dirtLevel, mudLevel, conditionLevel, rustLevel) VALUES (@identifier, @charid, @name, @ammo, @components, @comps, @dirtLevel, @mudLevel, @conditionLevel, @rustLevel)", {
			['identifier'] = targetIdentifier,
			['charid'] = targetCharId,
			['name'] = name,
			['ammo'] = json.encode(ammo),
			['components'] = json.encode(component),
			['comps'] = json.encode(comps),
			['dirtLevel'] = props.dirtLevel or 0,
			['mudLevel'] = props.mudLevel or 0,
			['conditionLevel'] = props.conditionLevel or 0,
			['rustLevel'] = props.rustLevel or 0
		}, function(result)
			local weaponId = result.insertId
			local newWeapon = Weapon:New({
				id = weaponId,
				propietary = targetIdentifier,
				name = name,
				ammo = ammo,
				used = false,
				used2 = false,
				charId = targetCharId,
				currInv = "default",
				dropped = 0,
			})
			UsersWeapons["default"][weaponId] = newWeapon

			TriggerEvent("syn_weapons:registerWeapon", weaponId)
			TriggerClientEvent("vorpInventory:receiveWeapon", _target, weaponId, targetIdentifier, name, ammo)
		end)
	else
		Log.Warning("Weapon: [^2" .. name .. "^7] ^1 do not exist on the config or its a WRONG HASH")
	end
end

InventoryAPI.giveWeapon2 = function(player, weaponId, target)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharId = sourceCharacter.charIdentifier
	local _target = tonumber(target)
	local userWeapons = UsersWeapons["default"]
	userWeapons[weaponId]:setPropietary('')
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

	local weaponcomps, weaponprops
	exports.ghmattimysql:execute('SELECT comps, dirtLevel, mudLevel, conditionLevel, rustLevel FROM loadout WHERE id = @id ' , {['id'] = weaponId}, function(result)
		result = result[1]

		if result then
			weaponcomps = json.decode(result.comps)
			weaponprops = {
				dirtLevel = result.dirtLevel,
				mudLevel = result.mudLevel,
				conditionLevel = result.conditionLevel,
				rustLevel = result.rustLevel
			}
		else
			weaponprops = {}
			weaponcomps = {}
		end
	end)
	while weaponcomps == nil do
		Wait(50)
	end
	local weaponname = userWeapons[weaponId]:getName()
	local ammo = { ["nothing"] = 0 }
	local components = { ["nothing"] = 0 }
	InventoryAPI.registerWeapon(_source, weaponname, ammo, components, weaponcomps, weaponprops)
	InventoryAPI.deletegun(_source, weaponId)
	TriggerClientEvent("vorp:TipRight", _target, _U("youGaveWeapon"), 2000)
	TriggerClientEvent("vorp:TipRight", _source, _U("youReceivedWeapon"), 2000)
	TriggerClientEvent("vorpinventory:updateinventorystuff", _target)
	TriggerClientEvent("vorpinventory:updateinventorystuff", _source)
	TriggerClientEvent("vorpCoreClient:subWeapon", _target, weaponId)
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

		exports.oxmysql:execute("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = sourceIdentifier,
				['charid'] = sourceCharId,
				['id'] = weaponId
			}, function()
			end)

		if targetisPlayer then
			TriggerClientEvent('vorp:ShowAdvancedRightNotification', _target, _U("youGaveWeapon"), "inventory_items",
				weaponName,
				"COLOR_PURE_WHITE", 4000)
			TriggerClientEvent("vorpCoreClient:subWeapon", _target, weaponId)
		end

		TriggerClientEvent('vorp:ShowAdvancedRightNotification', _source, _U("youReceivedWeapon"), "inventory_items",
			weaponName, "COLOR_PURE_WHITE", 4000)

		TriggerClientEvent("vorpInventory:receiveWeapon", _source, weaponId, weaponPropietary, weaponName, weaponAmmo)
	end
end

InventoryAPI.subWeapon = function(player, weaponId)
	local _source = player
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charId = sourceCharacter.charIdentifier
	local userWeapons = UsersWeapons["default"]

	if (userWeapons[weaponId]) then
		userWeapons[weaponId]:setPropietary('')

		exports.oxmysql:execute("UPDATE loadout SET identifier = @identifier, charidentifier = @charid WHERE id = @id",
			{
				['identifier'] = '',
				['charid'] = charId,
				['id'] = weaponId
			}, function()
			end)
	end

	TriggerClientEvent("vorpCoreClient:subWeapon", _source, weaponId)
end

InventoryAPI.getUserTotalCount = function(identifier, charid)
	local userTotalItemCount = 0
	local userInventory = UsersInventories["default"][identifier]
	for _, item in pairs(userInventory) do
		if item:getCount() == nil then
			userInventory[item:getId()] = nil
			DbService.DeleteItem(charid, item:getId())
		else
			userTotalItemCount = userTotalItemCount + item:getCount()
		end
	end
	return userTotalItemCount
end

InventoryAPI.getUserTotalCountWeapons = function(identifier, charId)
	local userTotalWeaponCount = 0
	for _, weapon in pairs(UsersWeapons["default"]) do
		if weapon:getPropietary() == identifier and weapon:getCharId() == charId then
			if not contains(Config.notweapons, string.upper(weapon:getName())) then
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

InventoryAPI.registerInventory = function(id, name, limit, acceptWeapons, shared, ignoreItemStackLimit, whitelistItems,
										  UsePermissions, UseBlackList, whitelistWeapons)
	limit = limit and limit or -1
	ignoreItemStackLimit = ignoreItemStackLimit and ignoreItemStackLimit or false
	acceptWeapons = acceptWeapons == nil and true or acceptWeapons
	whitelistItems = whitelistItems and whitelistItems or false
	shared = shared and shared or false
	UsePermissions = UsePermissions and UsePermissions or false
	UseBlackList = UseBlackList and UseBlackList or false
	whitelistWeapons = whitelistWeapons and whitelistWeapons or false


	local alreadyRegistered = false
	if CustomInventoryInfos[id] then
		alreadyRegistered = false
	end

	CustomInventoryInfos[id] = {
		name = name,
		limit = limit,
		acceptWeapons = acceptWeapons,
		shared = shared,
		ignoreItemStackLimit = ignoreItemStackLimit,
		whitelistItems = whitelistItems,
		limitedItems = {},
		PermissionTakeFrom = {},   -- for permissions
		PermissionMoveTo = {},     -- for permissions
		UsePermissions = UsePermissions, -- allow or not
		UseBlackList = UseBlackList,
		BlackListItems = {},
		whitelistWeapons = whitelistWeapons,
		limitedWeapons = {},
	}

	if alreadyRegistered then return end

	if not UsersInventories[id] then
		UsersInventories[id] = {}
	end

	if UsersWeapons[id] == nil then
		UsersWeapons[id] = {}
	end

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] ^2Registered!^7")
	end
end

InventoryAPI.AddPermissionMoveToCustom = function(id, jobName, grade, isAccess)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end
	if Config.DevMode then
		Log.print("AdPermsMoveTo  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end

	if not CustomInventoryInfos[id].PermissionMoveTo[jobName] then
		CustomInventoryInfos[id].PermissionMoveTo[jobName] = {}
	end

	for _, existingGrade in ipairs(CustomInventoryInfos[id].PermissionMoveTo[jobName]) do
		if existingGrade == grade then
			return -- dont add
		end
	end

	table.insert(CustomInventoryInfos[id].PermissionMoveTo[jobName], {
		grade = grade,
		gradeIsAccess = isAccess
	}) -- create table with item name and count
end

InventoryAPI.RemovePermissionMoveToCustom = function(id, jobName, grade, isAccess)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end
	if Config.DevMode then
		Log.print("RemovePermsMoveTo  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end

	if not CustomInventoryInfos[id].PermissionMoveTo[jobName] then
		return -- dont add
	end

	CustomInventoryInfos[id].PermissionMoveTo[jobName] = DwwUtils.RemoveItem(CustomInventoryInfos[id].PermissionMoveTo[jobName], function(x) return x.grade == grade and x.gradeIsAccess == isAccess end)
end

InventoryAPI.AddPermissionTakeFromCustom = function(id, jobName, grade, isAccess)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end
	if Config.DevMode then
		Log.print("AdPermsTakeFrom  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end

	if not CustomInventoryInfos[id].PermissionTakeFrom[jobName] then
		CustomInventoryInfos[id].PermissionTakeFrom[jobName] = {}
	end

	for _, permissionData in ipairs(CustomInventoryInfos[id].PermissionTakeFrom[jobName]) do
		if permissionData.grade == grade and permissionData.gradeIsAccess == isAccess then
			return -- dont add
		end
	end

	table.insert(CustomInventoryInfos[id].PermissionTakeFrom[jobName], {
		grade = grade,
		gradeIsAccess = isAccess
	}) -- create table with item name and count
end

InventoryAPI.RemovePermissionTakeFromCustom = function(id, jobName, grade, isAccess)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not jobName and not grade then
		return -- dont add
	end

	if Config.DevMode then
		Log.print("AdPermsTakeFrom  for [^3" .. jobName .. "^7] and grade [^3" .. grade .. "^7]")
	end

	if not CustomInventoryInfos[id].PermissionTakeFrom[jobName] then
		return -- dont add
	end

	CustomInventoryInfos[id].PermissionTakeFrom[jobName] = DwwUtils.RemoveItem(CustomInventoryInfos[id].PermissionTakeFrom[jobName], function(x) return x.grade == grade and x.gradeIsAccess == isAccess end)
end

InventoryAPI.BlackListCustom = function(id, name)
	if not CustomInventoryInfos[id] then
		return -- dont add
	end

	if not name then
		return -- dont add
	end
	if Config.DevMode then
		Log.print("Blacklisted [^3" .. name .. "^7]")
	end
	CustomInventoryInfos[id].BlackListItems[name] = name
end



InventoryAPI.removeInventory = function(id, name)
	if CustomInventoryInfos[id] == nil then
		return
	end

	CustomInventoryInfos[id] = nil
	UsersInventories[id] = nil
	UsersWeapons[id] = nil

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] ^2Removed!^7")
	end
end

InventoryAPI.setCustomInventoryTotalLimit = function(id, newLimit)
	if CustomInventoryInfos[id] == nil or newLimit == nil then
		return
	end

	CustomInventoryInfos[id].limit = newLimit

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] set limit to ^2" .. newLimit .. "^7")
	end
end

InventoryAPI.setCustomInventoryItemLimit = function(id, itemName, limit)
	if CustomInventoryInfos[id] == nil or itemName == nil or limit == nil then
		return
	end

	CustomInventoryInfos[id].limitedItems[string.lower(itemName)] = limit -- create table with item name and count

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] set item[^3" .. itemName .. "^7] limit to ^2" .. limit .. "^7")
	end
end

InventoryAPI.setCustomInventoryWeaponLimit = function(id, wepName, limit)
	if CustomInventoryInfos[id] == nil or wepName == nil or limit == nil then
		return
	end

	CustomInventoryInfos[id].limitedWeapons[string.lower(wepName)] = limit -- create table with item name and count

	if Config.Debug then
		Wait(9000) -- so it doesn't print everywhere in the console
		Log.print("Custom inventory[^3" .. id .. "^7] set item[^3" .. wepName .. "^7] limit to ^2" .. limit .. "^7")
	end
end

InventoryAPI.reloadInventory = function(player, id)
	local _source = player

	local invData = CustomInventoryInfos[id]
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharIdentifier = sourceCharacter.charIdentifier

	local userInventory = {}
	local itemList = {}

	if invData.shared then
		userInventory = UsersInventories[id]
	else
		userInventory = UsersInventories[id][sourceIdentifier]
	end

	-- arrange userInventory as a list
	for _, value in pairs(userInventory) do
		itemList[#itemList + 1] = value
	end

	-- Add weapons as Item to inventory
	for weaponId, weapon in pairs(UsersWeapons[id]) do
		if invData.shared or weapon.charId == sourceCharIdentifier then
			itemList[#itemList + 1] = Item:New({
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
		itemList = itemList,
		action = "setSecondInventoryItems"
	}

	TriggerClientEvent("vorp_inventory:ReloadCustomInventory", _source, json.encode(payload))
end

InventoryAPI.loadCustomInventory = function(source, id, cb)
	if CustomInventoryInfos[id] == nil then return end

	if CustomInventoryInfos[id].shared then
		DbService.GetSharedInventory(id, function(inventory)
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
						createdAt = item.created_at,
						owner = item.character_id,
						desc = dbItem.desc
					})
				end
			end
			UsersInventories[id] = characterInventory
			cb()
		end)
	else
		local character = Core.getUser(source).getUsedCharacter
		local identifier = character.identifier
		local charIdentifier = character.charIdentifier
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
						createdAt = item.created_at,
						owner = charIdentifier,
						desc = dbItem.desc
					})
				end
			end

			UsersInventories[id][identifier] = characterInventory
			cb()
		end)
	end
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

	if CustomInventoryInfos[id].shared then
		if UsersInventories[id] and #UsersInventories[id] > 0 then
			TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
			InventoryAPI.reloadInventory(_source, id)
		else
			DbService.GetSharedInventory(id, function(inventory)
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
							createdAt = item.created_at,
							owner = item.character_id,
							desc = dbItem.desc
						})
					end
				end

				UsersInventories[id] = characterInventory

				TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
				InventoryAPI.reloadInventory(_source, id)
			end)
		end
	else
		if UsersInventories[id][identifier] then
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
							createdAt = item.created_at,
							owner = charIdentifier,
							desc = dbItem.desc
						})
					end
				end

				UsersInventories[id][identifier] = characterInventory
				TriggerClientEvent("vorp_inventory:OpenCustomInv", _source, CustomInventoryInfos[id].name, id, capacity)
				InventoryAPI.reloadInventory(_source, id)
			end)
		end
	end
end

InventoryAPI.closeCustomInventory = function(player, id)
	local _source = player
	if CustomInventoryInfos[id] == nil then
		return
	end
	TriggerClientEvent("vorp_inventory:CloseCustomInv", _source)
end
