--- 游戏服务端玩家数据管理模块
-- @module Player Data Manager, Server-side
-- @copyright Lilith Games, Avatar Team
-- @author Yuhao Peng, Muru Chen
local S_PlayerDataMgr, this = {
	--- @type table 本服务器的所有玩家数据总表
	--主键：UserId
	allPlayersData = {} 
}, nil

function S_PlayerDataMgr:Init()
    --info('S_PlayerDataMgr:Init')
    this = self
    self:InitListeners()
    --设定玩家的默认数据
	self:InitListeners()
	self:InitSaveDataTimely()
end

function S_PlayerDataMgr:Update(dt)

end

function S_PlayerDataMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_PlayerDataMgr, 'S_PlayerDataMgr', this)
end

---设置默认的玩家数据
function S_PlayerDataMgr:GetDefaultPlayerData()
	local defaultData = 
	{
		--属性相关
		--玩家属性
		attribute = {
		--TODO: 设置玩家属性
			--基础属性
			base = {
				--便捷传送
				canExplore = false,
				--稀有宠物概率倍率
				rarePetProbMagnification = 1,
				--一个蛋可以孵出三个宠物
				threePetInOneEgg = false,
				--宠物储存容量
				petStorage = 200,
				--获得金币倍率
				getCoinMagnification = 1,
				--移动速度
				playerSpd = 5,
				--跟随宠物最大数量
				maxCurPet = 3,
				-- 生产蛋的机率
				getEggProb = 25,
				-- 钻石掉率
				getDiamondProb = 3,
				-- 鼓励效率
				encrEffect = 1.2,
				-- 单个金矿的金币数
				coinNumInGoldMine = 8,
				-- 药水掉落的机率
				getPotionProb = 1,
				-- 直接孵化出成长期宠物的概率
				hatchGrowingPetProb = 0,
				-- 直接孵化出成熟期宠物的概率
				hatchMaturePetProb = 0,
				-- 直接孵化出完全体宠物的概率
				hatchCompletePetProb = 0,
				-- 直接孵化出究极体宠物的概率
				hatchUltimatePetProb = 0
			},

			--计算后的最终属性
			final = {
				--便捷传送
				canExplore = false,
				--稀有宠物概率倍率
				rarePetProbMagnification = 1,
				--一个蛋可以孵出三个宠物
				threePetInOneEgg = false,
				--宠物储存容量
				petStorage = 200,
				--获得金币倍率
				getCoinMagnification = 1,
				--移动速度
				playerSpd = 5,
				--跟随宠物最大数量
				maxCurPet = 3,
				-- 生产蛋的机率
				getEggProb = 25,
				-- 钻石掉率
				getDiamondProb = 3,
				-- 鼓励效率
				encrEffect = 1.2,
				-- 单个金矿的金币数
				coinNumInGoldMine = 8,
				-- 药水掉落的机率
				getPotionProb = 1,
				-- 直接孵化出成长期宠物的概率
				hatchGrowingPetProb = 0,
				-- 直接孵化出成熟期宠物的概率
				hatchMaturePetProb = 0,
				-- 直接孵化出完全体宠物的概率
				hatchCompletePetProb = 0,
				-- 直接孵化出究极体宠物的概率
				hatchUltimatePetProb = 0
			},

			-- 当前装备
			equipment = {
				-- 当前装备的宠物
				pet = {},
				-- 当前使用的药水，属性：id,开始使用时间
				potion = {},
			},

			--拥有的buff
			buff = {
				achieve = {},	-- 成就产生的buff
				goods = {}		-- 商品产生的buff
			}
		},
		
		--资源相关 数值类
		--玩家拥有的资源
		resource = {
			--基于服务端的资源
			server = {
				coin = '0',
				diamond = '0'
			},
			--基于客户端的资源
			client = {
				guideState = 'Introduction',
				guideTask = 0,
			}
		},
		
		--物品相关
		--玩家拥有的物品
		item = {
			potion = {}, 	--背包中的药水
			egg = {},		--捡到的蛋
			pet = {},		--所有拥有的宠物,属性：id,name,等级,真实power,实际power
			zones = {		--可前往的场景
				Area1 = {
					1,
				}
			},		
		},

		--数据统计
		stats = {
			--TODO: 需要统计的数据
			collectEggs = 0,		--收集到蛋的数量
			playTime = 0,			--游玩的总时长
			unlockZones = 0,		--解锁的区域数量
			achieveLevel = {},		--所有成就等级
			achieveCurValue = {},	--所有成就当前进度
			ownPetNum = 0,			--拥有的宠物数量
			limitMergeNum = 5,		--当日能限时合成的次数
			refreshMagicMergeStartTime = {},	--开始读魔法合成cd时间
		},
	}

	-- 初始化成就的等级和当前数值
	local achieveLevel = defaultData.stats.achieveLevel
	local achieveCurValue = defaultData.stats.achieveCurValue
	for ii = ConstDef.ACHIEVE_TYPE_NUM, 1, -1 do
		table.insert(achieveLevel,0)
		table.insert(achieveCurValue,0)
	end
	
	return defaultData
end

--- 下载玩家的游戏数据
--- @param _userId string 玩家ID
function S_PlayerDataMgr:LoadGameDataAsync(_userId)
	local player = world:GetPlayerByUserId(_userId)
	if not player then print("没有找到该玩家！！！！") return end
	
	local sheet = DataStore:GetSheet('PlayerData')
	sheet:GetValue(_userId, function(val, msg)
		if msg == 0 or msg == 101 then
			print("获取玩家数据成功", player.Name)
			--若以前的数据为空，则让数据等于默认值
			local sheetValue = {}
			if val then sheetValue = val
			else sheetValue = self:GetDefaultPlayerData() end

			--数据验证
			ValueChangeUtil.VerifyTable(sheetValue, self:GetDefaultPlayerData())
			
			--更新到服务器的数据总表
			self.allPlayersData[_userId] = sheetValue
			
			--刷新全部属性最终值
			for k, v in pairs(ConstDef.buffCategoryEnum) do
				self:RefrshAttribute(_userId,v,1,true)
			end
			
			-- 刷新魔法合成次数
			self:RefrshPlayerMagicFuseTimeNum(_userId)
		else
			print("获取玩家数据失败，1秒后重试", player.Name, msg)
			--若失败，则1秒后重新再读取一次
			invoke(function() self:LoadGameDataAsync(_userId) end,1)
		end
	end)
end

--- 上传玩家的游戏数据
--- @param _userId string 玩家ID
function S_PlayerDataMgr:SaveGameDataAsync(_userId)
	local sheet = DataStore:GetSheet('PlayerData')
	local newValue = self.allPlayersData[_userId]
	
	if newValue then
		sheet:SetValue(_userId, newValue, function(val, msg)
			if msg == 0 then
				print("保存玩家数据成功", _userId)
				
			else
				print("保存玩家数据失败，1秒后重试", _userId, msg)
				--若失败，则1秒后重新再读取一次
				invoke(function() self:SaveGameDataAsync(_userId) end,1)
			end
		end)
	else
		print("没有在服务器数据总表找到该玩家的数据", _userId)
	end
end

--- 将玩家数据同步到客户端
--- @param _userId string 玩家ID
function S_PlayerDataMgr:SyncAllDataToClient(_userId)
	local player = world:GetPlayerByUserId(_userId)
	if not player then return end
	if self.allPlayersData[_userId] == nil then
		invoke(function() self:SyncAllDataToClient(_userId) end, 1)
	else
		NetUtil.Fire_C('SyncDataEvent', player, nil, self.allPlayersData[_userId])
	end
end

--- 将一条玩家数据同步到客户端
--- @param _userId string 玩家ID
function S_PlayerDataMgr:SyncDataToClient(_userId, _key, _value)
	local player = world:GetPlayerByUserId(_userId)
	if not player then return end
	
	NetUtil.Fire_C('SyncDataEvent', player, _key, _value)
end

--- 初始化每60秒保存一次
function S_PlayerDataMgr:InitSaveDataTimely()
	local SaveData = function()
		local players = world:FindPlayers()
		for _, v in pairs(players) do
			self:SaveGameDataAsync(v.UserId)
		end
	end
	S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(60,true,os.time() + 1,SaveData,true))	
end


--- 接收服务器同其向客户端同步数据的信息
--- @param _userId string 玩家UserId
--- @param _key string 键名
--- @param _value mixed 修改值
function S_PlayerDataMgr:SyncDataFromClientEventHandler(_userId,_key, _value)
    ValueChangeUtil.ChangeValue(self.allPlayersData[_userId].resource.client, _key, _value)
end

--- 清除玩家长期储存的数据
--- @param _userId string 玩家UserId
function S_PlayerDataMgr:ClearPlayerDataStoreEventHandler(_userId)
	self.allPlayersData[_userId] = self:GetDefaultPlayerData()
end

--------------------------------------------
----------包装好的改变玩家数据的接口-----------
--------------------------------------------

--- 刷新玩家属性
--- @param _userId string 玩家UserId
--- @param _buffCategory string buff的类别:ConstDef.buffCategoryEnum
--- @param _buffIndex int buff索引
--- @param _bRefreshAll bool 是否刷新所有属性
function S_PlayerDataMgr:RefrshAttribute(_userId,_buffCategory,_buffIndex,_bRefreshAll)
	--TODO: 在这里添加玩家属性加成公式
	local buff = self.allPlayersData[_userId].attribute.buff	
	if _bRefreshAll then
		-- 刷新所有属性
		for _, v in pairs(buff) do
			for k, v_ in pairs(v) do
				self:RefrshSingleAttribute(_userId,k,_buffCategory)
			end			
		end
	else
		-- 刷新单个属性
		self:RefrshSingleAttribute(_userId,_buffIndex,_buffCategory)
	end
end

local goodsCategoryEnum = ConstDef.GoodsCategoryEnum		---商品枚举
local achieveCategoryEnum = ConstDef.achieveCategoryEnum	---成就枚举

--- 刷新玩家某个属性
--- @param _userId string 玩家UserId
--- @param _buffLevelTbl table buff等级表
--- @param _buffIndex int buff索引
--- @param _buffCategory string buff的类别:ConstDef.buffCategoryEnum
function S_PlayerDataMgr:RefrshSingleAttribute(_userId,_buffIndex,_buffCategory)
	local attribute = self.allPlayersData[_userId].attribute
	local buffTbl = attribute.buff[_buffCategory]
	local buffLevel = buffTbl[_buffIndex]
	if not buffLevel then
		return
	end
	if _buffCategory == ConstDef.buffCategoryEnum.Goods then		
		
		local finalAttribute = attribute.final
		local baseAttribute = attribute.base
		-- 便捷传送		
		if _buffIndex == goodsCategoryEnum.canExplore then
			finalAttribute.canExplore = true
		-- 稀有宠物概率翻倍
		elseif _buffIndex == goodsCategoryEnum.doubleRarePetProbMagnification then
			finalAttribute.rarePetProbMagnification = 2 * baseAttribute.rarePetProbMagnification
		-- 一个蛋可以孵出三个宠物
		elseif _buffIndex == goodsCategoryEnum.threePetInOneEgg then
			finalAttribute.threePetInOneEgg = true
		-- 宠物储存+100
		elseif _buffIndex == goodsCategoryEnum.addPetStorage then
			finalAttribute.petStorage = buffLevel * 100 + baseAttribute.petStorage
		-- 获得金币+10%
		elseif _buffIndex == goodsCategoryEnum.addGetCoinMagnification then
			finalAttribute.getCoinMagnification = (buffLevel * 0.1 + 1) * baseAttribute.getCoinMagnification
		-- 移动速度+10%
		elseif _buffIndex == goodsCategoryEnum.addPlayerSpd then
			finalAttribute.playerSpd = (buffLevel * 0.1 + 1) * baseAttribute.playerSpd
		-- 额外装备一个宠物
		elseif _buffIndex == goodsCategoryEnum.addMaxCurPet then
			finalAttribute.maxCurPet = buffLevel + baseAttribute.maxCurPet
		end
	elseif _buffCategory == ConstDef.buffCategoryEnum.Achieve then
		local achieveCsv = GameCsv.Achieve[_buffIndex][buffLevel]
		if not achieveCsv then
			return
		end
		local final = attribute.final
		local achieveReward = achieveCsv['AchieveChangeData']
		
		--孵化蛋数量
		if _buffIndex == achieveCategoryEnum.hatchEggNum then
			final.getEggProb = achieveReward
		--游戏时长
		elseif _buffIndex == achieveCategoryEnum.playTime then
			final.getDiamondProb = achieveReward
		--鼓励次数
		elseif _buffIndex == achieveCategoryEnum.encrNum then
			final.encrEffect = achieveReward
		--挖掘金矿
		elseif _buffIndex == achieveCategoryEnum.digGoldMine then
			final.coinNumInGoldMine = achieveReward
		--使用药水
		elseif _buffIndex == achieveCategoryEnum.usePotion then
			final.getPotionProb = achieveReward
		--拥有成长期宠物数量
		elseif _buffIndex == achieveCategoryEnum.haveGrowingPet then
			final.hatchGrowingPetProb = achieveReward
		--拥有成熟期宠物数量
		elseif _buffIndex == achieveCategoryEnum.haveMaturePet then
			final.hatchMaturePetProb = achieveReward
		--拥有完全体宠物数量
		elseif _buffIndex == achieveCategoryEnum.haveCompletePet then
			final.hatchCompletePetProb = achieveReward
		--拥有究极体宠物数量
		elseif _buffIndex == achieveCategoryEnum.haveUltimatePet then
			final.hatchUltimatePetProb = achieveReward
		end
	end
end

--- 刷新玩家魔法合成等待时间
--- @param _userId string 玩家UserId
function S_PlayerDataMgr:RefrshPlayerMagicFuseTimeNum(_userId)
	local stats = self.allPlayersData[_userId].stats
	local refreshMagicFuseTimeTbl = stats.refreshMagicMergeStartTime
	if #refreshMagicFuseTimeTbl < 1 then
		return
	end
	for ii = #refreshMagicFuseTimeTbl, 1, -1 do
		if os.time() - refreshMagicFuseTimeTbl[ii] >= 300 then
			if stats.limitMergeNum < ConstDef.magicFuseMaxNum then
				stats.limitMergeNum = stats.limitMergeNum + 1
			end
			table.remove(refreshMagicFuseTimeTbl,ii)
		end
	end
end

--- 查看指定玩家数据的值
--- @param _userId string 玩家UserId
--- @param _type string 指定的数据
function S_PlayerDataMgr:GetValue(_userId,_type)
	local myData = self.allPlayersData[_userId]	--DataStore数据库
	if _type == ConstDef.statsCategoryEnum.LimitMergeNum then
		return myData.stats.limitMergeNum
	elseif _type == ConstDef.ServerResTypeEnum.Coin then
		return myData.resource.server.coin
	elseif _type == ConstDef.ServerResTypeEnum.Diamond then
		return myData.resource.server.diamond
	elseif _type == ConstDef.statsCategoryEnum.RefreshMagicMergeStartTime then
		return myData.stats.refreshMagicMergeStartTime
	end
end

--- 查看指定玩家属性值
--- @param _userId string 玩家UserId
--- @param _type string 指定的数据：ConstDef.PlayerAttributeEnum
function S_PlayerDataMgr:GetAttributeFinalValue(_userId,_type)
	return self.allPlayersData[_userId].attribute.final[_type]
end

--- 改变玩家资源数
--- @param _userId string 玩家UserId
--- @param _type string 要改动的资源类型: ConstDef.ServerResTypeEnum
--- @param _cal string 计算方式: ConstDef.ChangeResTypeEnum.Add, Sub, Reset
--- @param _value mixed 差量值
function S_PlayerDataMgr:ChangeServerRes(_userId, _type, _cal, _value)
	--加法
	if _cal == ConstDef.ChangeResTypeEnum.Add then
		self.allPlayersData[_userId].resource.server[_type] = TStringNumAdd(self.allPlayersData[_userId].resource.server[_type], _value)
	
	--减法
	elseif _cal == ConstDef.ChangeResTypeEnum.Sub then
		self.allPlayersData[_userId].resource.server[_type] = TStringNumSub(self.allPlayersData[_userId].resource.server[_type], _value)
	
	--重置
	elseif _cal == ConstDef.ChangeResTypeEnum.Reset then
		self.allPlayersData[_userId].resource.server[_type] = '0'
	end
	
end

--- 改变玩家数据统计里的数据,不适用于成就！!
--- @param _userId string 玩家UserId
--- @param _type number 要改动的数据类型 ConstDef.statsCategoryEnum
--- @param _value mixed 差量值
function S_PlayerDataMgr:ChangeStats(_userId,_type,_value)
	if _type == ConstDef.statsCategoryEnum.AchieveLevel or _type == ConstDef.statsCategoryEnum.AchieveCurValue then
		return
	end
	self.allPlayersData[_userId].stats[_type] = self.allPlayersData[_userId].stats[_type] + _value
end

--- 改变玩家装备内容
--- @param _userId string 玩家UserId
--- @param _category string 要改动的装备类型: ConstDef.EquipmentTypeEnum
--- @param _item mixed 物品
function S_PlayerDataMgr:ChangeEquipment(_userId, _category, _item)
	table.insert(self.allPlayersData[_userId].attribute.equipment[_category], _item)
	--刷新属性最终值
	--self:RefrshAttribute(_userId)
end

--- 检查指定ID的物件是否在玩家库存中
--- @param _userId string 玩家UserId
--- @param _category string 物品类别
--- @param _itemID string 物品ID
function S_PlayerDataMgr:IfItemOwned(_userId, _category, _itemID)
	local itemTbl = self.allPlayersData[_userId].item[_category]
	local bFindItem = false
	if _category == ConstDef.ItemCategoryEnum.Egg then
		if itemTbl[_itemID] then
			bFindItem = true
		end
	elseif _category == ConstDef.ItemCategoryEnum.Pet then
		if itemTbl[_itemID] then
			bFindItem = true
		end
	elseif _category == ConstDef.ItemCategoryEnum.Potion then
		for ii = #itemTbl, 1, -1 do
			if itemTbl[ii] == _itemID then
				bFindItem = true
				break
			end
		end
	end
	return bFindItem
end

--- 新增玩家的物件库存
--- @param _userId string 玩家UserId
--- @param _category string item类别:ConstDef.ItemCategoryEnum
--- @param _itemID int 物品ID
function S_PlayerDataMgr:AddNewItem(_userId, _category, ...)
	local args = {...}
	local itemCategoryEnum = ConstDef.ItemCategoryEnum
	if _category == itemCategoryEnum.Potion then
		self:AddNewPotionToItem(_userId,table.unpack(args))
	elseif _category == itemCategoryEnum.Egg then
		self:AddNewEggToItem(_userId,table.unpack(args))
	elseif _category == itemCategoryEnum.Pet then
		self:AddNewPetToItem(_userId,table.unpack(args))
	elseif _category == itemCategoryEnum.Zones then
		self:AddNewZonesToItem(_userId,table.unpack(args))
	end
end

--- 新增玩家Buff
--- @param _userId string 玩家UserId
--- @param _buffCategory string buff的类别：ConstDef.buffCategoryEnum
--- @param _buffId int 商品id
--- @param _level int 商品的等级
--- @param _limitTime int 生效时间
function S_PlayerDataMgr:AddNewBuff(_userId, _buffCategory, _buffId, _level,_limitTime)
	local buffTbl = self.allPlayersData[_userId].attribute.buff[_buffCategory]
	buffTbl[_buffId] = {
		id = _buffId,
		level = _level
	}
	--刷新该属性最终值
	self:RefrshAttribute(_userId,_buffCategory,_buffId,false)

	--在timeMgr里添加事件
	if _limitTime > 0 then
		local removeBuff = function()
			buffTbl[_buffId] = nil
			self:RefrshAttribute(_userId,_buffCategory,_buffId,false)
		end	
		S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(_limitTime,false,os.time(),removeBuff,true))
	end
end

--- 商品升级
--- @param _userId string 玩家UserId
--- @param _goodsId int 商品id
--- @param _level int 商品的等级
function S_PlayerDataMgr:GoodsLevelUp(_userId, _goodsId, _level)
	local goodsLevelTbl = self.allPlayersData[_userId].goodsLevel
	if goodsLevelTbl[_goodsId] then
		-- 判断是否能升级
		local newLevel = _level + 1
		if GameCsv.Goods[_goodsId][newLevel] then
			goodsLevelTbl[_goodsId] = newLevel
		end
	end
end

--- 使用药水
--- @param _userId string 玩家UserId
--- @param _potionId int 商品id
function S_PlayerDataMgr:EquipPotion(_userId, _potionId)
	local myItem = self.allPlayersData[_userId].item
	-- 从item数据表中删除该药水
	self:RemoveEquipment(_userId,ConstDef.EquipmentTypeEnum.Potion,_potionId)
	-- 在装备中加入药水
	local potionTbl = {
		potionId = _potionId,
		equippedPet = {}
	}
	for k, v in pairs(self.allPlayersData[_userId].item.pet) do
		table.insert(potionTbl.equippedPet,v)
	end
	self:ChangeEquipment(_userId, ConstDef.EquipmentTypeEnum.Potion, potionTbl)
end

--- 检查指定的宠物是否在跟随宠物列表中
--- @param _userId string 玩家UserId
--- @param _petId int 宠物Id
function S_PlayerDataMgr:IfPetIsInCurPet(_userId, _petId)
	local bFoundPet = false
	local arrCurPet = self.allPlayersData[_userId].attribute.equipment.pet
	if #arrCurPet > 0 then
		for ii = #arrCurPet, 1, -1 do
			if arrCurPet[ii].id == _petId then
				bFoundPet = true
			end
		end
	end
	return bFoundPet
end

--- item加入新的药水
--- @param _userId string 玩家UserId
--- @param _potionId int 药水Id
function S_PlayerDataMgr:AddNewPotionToItem(_userId,_potionId)
	table.insert(self.allPlayersData[_userId].item.potion,_potionId)
end

--- item加入新的宠物
--- @param _userId string 玩家UserId
--- @param _petTbl table 宠物数据
function S_PlayerDataMgr:AddNewPetToItem(_userId,_petTbl)
	local playerData = self.allPlayersData[_userId]
	playerData.item.pet[_petTbl.id] = _petTbl
	-- 总的宠物数量+1
	playerData.stats.ownPetNum = playerData.stats.ownPetNum + 1	
end

--- item加入新的蛋
--- @param _userId string 玩家UserId
--- @param _eggTbl table 蛋数据
function S_PlayerDataMgr:AddNewEggToItem(_userId,_eggTbl)
	self.allPlayersData[_userId].item.egg[_eggTbl.id] = _eggTbl
	-- 捡到的蛋数量+1
	self.allPlayersData[_userId].stats.collectEggs = self.allPlayersData[_userId].stats.collectEggs + 1
end

--- item移除蛋
--- @param _userId string 玩家UserId
--- @param _eggId string 蛋的id
function S_PlayerDataMgr:RemoveEggFromItem(_userId,_eggId)
	self.allPlayersData[_userId].item.egg[_eggId] = nil
end

--- Item移除物品
--- @param _userId string 玩家UserId
--- @param _category string 物品类别：ConstDef.ItemCategoryEnum
--- @param _itemId string 物品Id
function S_PlayerDataMgr:RemoveItem(_userId,_category,_itemId)
	self.allPlayersData[_userId].item[_category][_itemId] = nil
	if _category == ConstDef.ItemCategoryEnum.Pet then
		-- 当移除宠物，顺带移除当前装备中的宠物
		self:RemoveEquipment(_userId,ConstDef.EquipmentTypeEnum.Pet,_itemId)
		-- 玩家的宠物总数减少
		self.allPlayersData[_userId].stats.ownPetNum = self.allPlayersData[_userId].stats.ownPetNum - 1
	end
end

--- 移除装备
--- @param _userId string 玩家UserId
--- @param _category string 装备类别：ConstDef.EquipmentTypeEnum
--- @param _equipId mixed 装备的id
function S_PlayerDataMgr:RemoveEquipment(_userId,_category,_equipId)
	local arrEquipTbl = self.allPlayersData[_userId].attribute.equipment[_category]
	for ii = #arrEquipTbl, 1, -1 do
		if arrEquipTbl[ii] == _equipId then
			table.remove(arrEquipTbl,ii)
			return
		end
	end
end

--- 返回装备信息
--- @param _userId string 玩家UserId
--- @param _category string 装备类别：ConstDef.EquipmentTypeEnum
function S_PlayerDataMgr:GetEquipment(_userId,_category)
	return self.allPlayersData[_userId].attribute.equipment[_category]
end

--- 获得宠物信息
--- @param _userId string 玩家UserId
--- @param _petId string 宠物Id
function S_PlayerDataMgr:GetPetInformation(_userId,_petId)
	return self.allPlayersData[_userId].item.pet[_petId]
end

--- 获得蛋信息
--- @param _userId string 玩家UserId
--- @param _eggId string 蛋Id
function S_PlayerDataMgr:GetEggInformation(_userId, _eggId)
	return self.allPlayersData[_userId].item.egg[_eggId]
end

--- item加入新解锁的关卡
--- @param _userId string 玩家UserId
--- @param _area int 场景
--- @param _zone int 关卡
function S_PlayerDataMgr:AddNewZonesToItem(_userId,_area,_zone)
	local areaName = 'Area' .. tostring(_area)
	local zonesDataTbl = self.allPlayersData[_userId].item.zones
	if zonesDataTbl[areaName] then
		table.insert(zonesDataTbl[areaName],_zone)
	else
		zonesDataTbl[areaName] = {_zone}
	end
end

--- 比较当前宠物数量和最大背包容量
--- @param _userId string 玩家UserId
function S_PlayerDataMgr:IfOwnPetNumLessThanBagCapacity(_userId)
	local playerData = self.allPlayersData[_userId]
	return playerData.stats.ownPetNum < playerData.attribute.final[ConstDef.PlayerAttributeEnum.PetStorage]
end

--- 比较当前跟随宠物数量和最大跟随宠物数量
--- @param _userId string 玩家UserId
function S_PlayerDataMgr:IfEquippedPetLessThanCapacity(_userId)
	local attribute = self.allPlayersData[_userId].attribute
	return #attribute.equipment.pet < attribute.final.maxCurPet
end

--- 卸除最弱的宠物
--- @param _userId string 玩家UserId
function S_PlayerDataMgr:UnequipWeakestPet(_userId)
	local myData = self.allPlayersData[_userId]
	local curPets = myData.attribute.equipment.pet
	local allPets = myData.item.pet
	local weakestPetId = curPets[1]
	local weakestPetPower = allPets[weakestPetId].curPower
	local weakestPetIndex = 1
	for index, id in pairs(curPets) do
		if TStringNumCom(weakestPetPower, allPets[id].curPower) then
			weakestPetId = id
			weakestPetIndex = index
			weakestPetPower = allPets[id].curPower
		end
	end
	table.remove(curPets,weakestPetIndex)
	return weakestPetId
end

--- 改变成就数值
--- @param _userId string 玩家UserId
--- @param _achieveId number 成就索引
--- @param _changeValue int 改变的数值
function S_PlayerDataMgr:ChangeAchieveValue(_userId,_achieveId,_changeValue)
	local playerData = self.allPlayersData[_userId]
	local curValueTbl = playerData.stats.achieveCurValue
	curValueTbl[_achieveId] = curValueTbl[_achieveId] + _changeValue
end

--- 检测玩家是否可以领取成就升级奖励
--- @param _userId string 玩家UserId
--- @param _achieveId number 成就索引
function S_PlayerDataMgr:CheckIfPlayerCanGetReward(_userId,_achieveId)
	local playerData = self.allPlayersData[_userId]
	local curValueTbl = playerData.stats.achieveCurValue
	local achieveLevel = playerData.stats.achieveLevel[_achieveId] + 1
	if curValueTbl[_achieveId] >= GameCsv.Achieve[_achieveId][achieveLevel]['AchieveData'] then
		return true
	end
	return false
end

--- 获得玩家成就等级
--- @param _userId string 玩家UserId
--- @param _achieveId number 成就索引
function S_PlayerDataMgr:GetPlayerAchieveLevel(_userId,_achieveId)
	return self.allPlayersData[_userId].stats.achieveLevel[_achieveId]
end

--- 更新玩家成就属性奖励
--- @param _userId string 玩家UserId
--- @param _achieveId number 成就索引
function S_PlayerDataMgr:UpdateAchieveBuff(_userId,_achieveId)
	local playerData = self.allPlayersData[_userId]
	local achieveLevel = playerData.stats.achieveLevel[_achieveId] + 1
	local rewardInfo = GameCsv.Achieve[_achieveId][achieveLevel]
	playerData.attribute.buff.achieve[_achieveId] = rewardInfo['AchieveChangeData']
	-- 玩家获得钻石奖励
	self:ChangeServerRes(_userId, ConstDef.ServerResTypeEnum.Diamond, ConstDef.ChangeResTypeEnum.Add, rewardInfo['AchieveAward'])
end

--- 玩家成就升级
--- @param _userId string 玩家UserId
--- @param _achieveId number 成就索引
function S_PlayerDataMgr:PlayerAchieveLevelUp(_userId,_achieveId)
	local achieveLevel = self.allPlayersData[_userId].stats.achieveLevel
	achieveLevel[_achieveId] = achieveLevel[_achieveId] + 1
end

--- 将蛋放进孵蛋器
--- @param _userId string 玩家UserId
--- @param _eggIdTbl table 蛋的id的数据表
function S_PlayerDataMgr:PutEggsIntoGen(_userId,_eggIdTbl)
	local egg = self.allPlayersData[_userId].item.egg
	for k, v in pairs(_eggIdTbl) do
		if egg[v] then
			egg[v].bInIncubator = true
		end
	end
end

--- 获取商品buff数据
--- @param _userId string 玩家UserId
--- @param _buffCategory string buff的类别：ConstDef.buffCategoryEnum
--- @param _buffId number buff的id
--- @param _buffValType string buff里的属性：ConstDef.buffValTypeEnum
function S_PlayerDataMgr:GetBuffValue(_userId,_buffCategory,_buffId,_buffValType)
	local allBuffTbl = self.allPlayersData[_userId].attribute.buff[_buffCategory]
	if allBuffTbl[_buffId] then
		return allBuffTbl[_buffId][_buffValType]
	end
end

--- 设置商品buff数据
--- @param _userId string 玩家UserId
--- @param _buffCategory string buff的类别：ConstDef.buffCategoryEnum
--- @param _buffId number buff的id
--- @param _buffValType string buff里的属性：ConstDef.buffValTypeEnum
--- @param _cal number 计算方式：ConstDef.ChangeResTypeEnum
--- @param _val number 改变的值
function S_PlayerDataMgr:ChangeBuffValue(_userId,_buffCategory,_buffId,_buffValType,_cal,_val)
	local allBuffTbl = self.allPlayersData[_userId].attribute.buff[_buffCategory]
	if allBuffTbl[_buffId] then
		if _cal == ConstDef.ChangeResTypeEnum.Add then
			allBuffTbl[_buffId][_buffValType] = allBuffTbl[_buffId][_buffValType] + _val
		elseif _cal == ConstDef.ChangeResTypeEnum.Sub then
			allBuffTbl[_buffId][_buffValType] = allBuffTbl[_buffId][_buffValType] - _val
		elseif _cal == ConstDef.ChangeResTypeEnum.Reset then
			allBuffTbl[_buffId][_buffValType] = _val
		end
	end
end

--- 解锁关卡
--- @param _userId string 玩家的UserId
--- @param _area int 场景
--- @param _zone int 关卡
function S_PlayerDataMgr:UnlockZone(_userId,_area,_zone)
	local zonesTbl = self.allPlayersData[_userId].item.zones
	local areaName = 'Area' .. tostring(_area)
	if zonesTbl[areaName] then
		table.insert(zonesTbl[areaName], _zone + 1)
	end
	self:ChangeStats(_userId,ConstDef.statsCategoryEnum.UnlockZones,1)
end

--- 解锁场景
--- @param _userId string 玩家的UserId
--- @param _area int 场景
function S_PlayerDataMgr:UnlockArea(_userId,_area)
	local zonesTbl = self.allPlayersData[_userId].item.zones
	local areaName = 'Area' .. tostring(_area)
	zonesTbl[areaName] = {1}
	self:ChangeStats(_userId,ConstDef.statsCategoryEnum.UnlockZones,1)
end

--- 增加魔法合成刷新等待时间
--- @param _userId string 玩家的UserId
function S_PlayerDataMgr:AddMagicFuseRefreshTime(_userId)
	local refreshMagicFuseTimeTbl = self.allPlayersData[_userId].stats.refreshMagicMergeStartTime
	local tblLength = #refreshMagicFuseTimeTbl
	if tblLength < 1 then
		refreshMagicFuseTimeTbl[1] = os.time()
	else
		table.insert(refreshMagicFuseTimeTbl,refreshMagicFuseTimeTbl[tblLength] + 300)
	end
end

--- 获得第一个读取cd剩余时间
--- @param _userId string 玩家的UserId
function S_PlayerDataMgr:GetFstMagicFuseCdRemainTime(_userId)
	local refreshMagicFuseTimeTbl = self.allPlayersData[_userId].stats.refreshMagicMergeStartTime
	if not refreshMagicFuseTimeTbl[1] then
		return false
	else
		return 300 - (os.time() - refreshMagicFuseTimeTbl[1])
	end
end

return S_PlayerDataMgr