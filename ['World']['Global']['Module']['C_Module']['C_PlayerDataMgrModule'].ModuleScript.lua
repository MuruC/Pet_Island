--- 客户端玩家数据管理模块
-- @module player data manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_PlayerDataMgr, this = {}, nil

function C_PlayerDataMgr:Init()
    this = self
    self:InitListeners()
	-- 玩家游戏时长
    self.playingTime = 0
	-- 玩家蛋数收集
    self.eggNum = 0
	-- 玩家解锁关卡
    self.areaZone = 0
    -- 玩家持有金币
    self.coinNum = 10000
    -- 玩家持有钻石数量
    self.diamondNum = 1000
    -- 玩家解锁场景数
    self.areaNum = 1
end

--- Update函数
-- @param dt delta time 每帧时间
function C_PlayerDataMgr:Update(dt)
    -- TODO: 其他客户端模块Update
end

--- 初始化C_PlayerDataMgr自己的监听事件
function C_PlayerDataMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_PlayerDataMgr, 'C_PlayerDataMgr', this)
end

-- 给服务器发送玩家收集蛋的总数
function C_PlayerDataMgr:ChangeEggData(_eggNum)
    self.eggNum = self.eggNum + _eggNum
	NetUtil.Fire_S('ReceiveEggNumEvent', localPlayer.UserId , self.EggNum)
end

-- 给服务器发送玩家总的游戏时长
function C_PlayerDataMgr:GameTimeData()
	NetUtil.Fire_S('ReceiveGameTimeEvent', localPlayer.UserId , self.playingTime)
end

-- 给服务器发送玩家解锁关卡的总数
function C_PlayerDataMgr:AreaZoneData(_areaZone)
    self.areaZone = _areaZone
	NetUtil.Fire_S('ReceiveAreaZoneEvent', localPlayer.UserId , self.areaZone)
end

-- 改变金钱的数目
-- @param float _value 改变的金钱的数量
function C_PlayerDataMgr:ChangeCoin(_value)
    self.coinNum = self.coinNum + _value
    C_UIMgr.moneyTxt.Text = tostring(self.coinNum)
end 

-- 改变钻石的数目
-- @param int _value 改变的钻石的数量
function C_PlayerDataMgr:ChangeDiamond(_value)
	self.diamondNum = self.diamondNum + _value
	C_UIMgr.diamondTxt.Text = tostring(self.diamondNum)
end

--- 查看指定玩家数据的值
--- @param _type string 指定的数据
function C_PlayerDataMgr:GetValue(_type)
	local myData = PlayerMgr.myData	--DataStore数据库
	if _type == ConstDef.PlayerAttributeEnum.PlayerSpd then
		return myData.attribute.final.playerSpd
	elseif _type == ConstDef.PlayerAttributeEnum.CanExplore then
		return myData.attribute.final.canExplore
	elseif _type == ConstDef.EquipmentTypeEnum.Pet then
		return myData.attribute.equipment.pet
	elseif _type == ConstDef.ItemCategoryEnum.Egg then
		return myData.item.egg
	elseif _type == ConstDef.statsCategoryEnum.LimitMergeNum then
		return myData.stats.limitMergeNum
	elseif _type == ConstDef.ServerResTypeEnum.Coin then
		return myData.resource.server.coin
	elseif _type == ConstDef.ServerResTypeEnum.Diamond then
		return myData.resource.server.diamond
	elseif _type == ConstDef.clientResourceEnum.GuideState then
		return myData.resource.client.guideState
	elseif _type == ConstDef.clientResourceEnum.GuideTask then
		return myData.resource.client.guideTask
	elseif _type == ConstDef.statsCategoryEnum.RefreshMagicMergeStartTime then
		return myData.stats.refreshMagicMergeStartTime
	end
end

--- 获取玩家的物品
--- @param _type string 物品类别ConstDef.ItemCategoryEnum.Potion,Egg,Pet,Zones
function C_PlayerDataMgr:GetItem(_type)
	return PlayerMgr.myData.item[_type]
end

--- 获取玩家当前装备的ID
--- @param _category string 物品类别
function C_PlayerDataMgr:GetCurrentEquipped(_category)
	return PlayerMgr.myData.attribute.equipment[_category]
end

--- 查看指定ID的物品是否已装备
--- @param _category string 物品类别
--- @param _itemID string 物品ID
function C_PlayerDataMgr:IsEquipped(_category, _itemID)
	if PlayerMgr.myData.attribute.equipment[_category] == nil or PlayerMgr.myData.attribute.equipment[_category] ~= _itemID then
		return false
	else
		return true
	end
end

--- 查看指定ID的物品是否在库存中
--- @param _category string 物品类别
--- @param _itemID string 物品ID
function C_PlayerDataMgr:IsOwned(_category, _itemID)
	if PlayerMgr.myData.item[_category] == nil then return false end
	return table.exists(PlayerMgr.myData.item[_category],_itemID)
end

--- 增加新的蛋
--- @param _eggTbl table 蛋数据
function C_PlayerDataMgr:AddNewEggToItem(_eggTbl)	
	PlayerMgr.myData.item.egg[_eggTbl.id] = _eggTbl
	PlayerMgr.myData.stats.collectEggs = PlayerMgr.myData.stats.collectEggs + 1	
end

--- 移除当前装备中的指定宠物
--- @param _petId string 宠物id
function C_PlayerDataMgr:RemoveCurPetInEquipment(_petId)
	local arrCurPetTbl = PlayerMgr.myData.attribute.equipment.pet
	for ii = #arrCurPetTbl, 1, -1 do
		if arrCurPetTbl[ii] == _petId then
			table.remove(arrCurPetTbl,ii)
		end
	end
end

--- 查看该宠物是否处于装备中
--- @param _petId string 宠物id
function C_PlayerDataMgr:CheckIfPetIsEquipped(_petId)
	local arrCurPetTbl = PlayerMgr.myData.attribute.equipment.pet
	local bFoundPet = false
	for ii = #arrCurPetTbl, 1, -1 do
		if arrCurPetTbl[ii] == _petId then
			bFoundPet = true
		end
	end
	return bFoundPet
end

--- 获取某个宠物的信息
--- @param _petId string 宠物的id
function C_PlayerDataMgr:GetPetInformation(_petId)
	return PlayerMgr.myData.item.pet[_petId]
end

--- 获取某个蛋的信息
--- @param _eggId string 蛋的id
function C_PlayerDataMgr:GetEggInformation(_eggId)
	return PlayerMgr.myData.item.egg[_eggId]
end

--- 检测物品中是否有五个相同的宠物
function C_PlayerDataMgr:CheckIfHaveFiveSamePet()
	local pets = PlayerMgr.myData.item.pet
	local petCategory = {}
	for petId,petTbl in pairs(pets) do
		local index = petTbl.index
		if not petCategory[index] then
			petCategory[index] = {}
		end
		table.insert(petCategory[index],petId)
	end
	for k, v in pairs(petCategory) do
		if #v >= 5 then
			return true
		end
	end
	return false
end

--- 获取装备数据表
--- @param _equipType string 装备类别
function C_PlayerDataMgr:GetEquipmentTable(_equipmentType)
	return PlayerMgr.myData.attribute.equipment[_equipmentType]
end

--- 获取手上抱着的蛋的数量
function C_PlayerDataMgr:GetEggInHandNum()
	local eggNum = 0
	for k, v in pairs(PlayerMgr.myData.item.egg) do
		if not v.bInIncubator then
			eggNum = eggNum + 1
		end
	end
	return eggNum
end

--- 获取装备宠物的排序
--- @param _petId string 宠物id
function C_PlayerDataMgr:GetEquippedPetIndex(_petId)
	local equippedPets = PlayerMgr.myData.attribute.equipment.pet
	local index = 1
	for ii = #equippedPets,1, -1 do
		if equippedPets[ii] == _petId then
			index = ii
		end
	end
	return index
end

--- 更改新手指引状态
--- @param _guideState number 新手指引状态枚举
function C_PlayerDataMgr:ChangeGuideState(_guideState)
	PlayerMgr.myData.resource.client.guideState = _guideState
end

--- 更改新手指引任务完成度
--- @param _guideTaskProgress int 完成度
function C_PlayerDataMgr:ChangeGuideTaskProgress(_guideTaskProgress)
	PlayerMgr.myData.resource.client.guideTask = _guideTaskProgress
end

local constDefMaxLevel = ConstDef.MAX_ACHIEVE_LEVEL     --最高成就等级

--- 获得成就等级
--- @param _achieveId number 成就索引
function C_PlayerDataMgr:GetAchieveLevel(_achieveId)
	return PlayerMgr.myData.stats.achieveLevel[_achieveId]
end

--- 比较玩家是否可以领取奖励
--- @param _achieveId number 成就索引
function C_PlayerDataMgr:CheckIfPlayerCanGetReward(_achieveId)
	local curProgress = PlayerMgr.myData.stats.achieveCurValue[_achieveId]
	local nxtLevel = self:GetAchieveLevel(_achieveId) + 1
	if nxtLevel <= constDefMaxLevel then
		local needProgress = PlayerCsv.Achieve[_achieveId][nxtLevel]['AchieveData']
		return curProgress >= needProgress 
	end
	return false	
end

--- 获得成就当前进度数值
--- @param _achieveId number 成就索引
function C_PlayerDataMgr:GetAchieveCurValue(_achieveId)
	return PlayerMgr.myData.stats.achieveCurValue[_achieveId]
end

return C_PlayerDataMgr