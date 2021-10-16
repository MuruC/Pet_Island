--- 玩家请求管理模块
--- @module Module Request Manager
-- @copyright Lilith Games, Avatar Team
-- @author Yuhao Peng, Chen Muru
local S_RequestMgr, this = {}, nil

--- 初始化
function S_RequestMgr:Init()
    --print('[信息] RequestMgr:Init')
    this = self
    self:InitListeners()
end

--- 初始化Game Manager自己的监听事件
function S_RequestMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_RequestMgr, 'S_RequestMgr', this)
end

--- Update函数
--- @param dt delta time 每帧时间
function S_RequestMgr:Update(dt)
    --print(string.format('[测试] 模块:%s, deltaTime = %.4f', 'RequestMgr', dt))
end

local ConstDefPlayerAction = ConstDef.PlayerActionTypeEnum	--- 玩家行为枚举

--- 接收玩家的请求信息
--- @param _userId string 玩家UserId
--- @param _actionType number 操作类型: ConstDef.PlayerActionTypeEnum
function S_RequestMgr:PlayerRequestEventHandler(_userId, _actionType, ...)
	local args = {...}

	if _actionType == ConstDefPlayerAction.AskData then
		S_PlayerDataMgr:SyncAllDataToClient(_userId)
	elseif _actionType == ConstDefPlayerAction.SellPet then
		S_PetMgr:SellPetHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Buy then
		S_Store:BuyHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Equip then
		self:PlayerEquipHandler(_userId, table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Hatch then
		S_PetMgr:HatchHandler(_userId, table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Merge then
		self:MergeHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Achieve then
		S_Achieve:PlayerUnlockAchieveHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Pick then
		self:PlayerPickHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.PutEgg then
		S_PetMgr:PutEggIntoGenHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.UnlockArea then
		S_PlayerStatusMgr:UnlockAreaHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Unequip then
		S_PetMgr:UnequipPetHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Guide then
		self:ProcessGuideHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Encr then
		S_MineMgr:PlayerEncrPetHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.UnlockZone then
		S_PlayerStatusMgr:UnlockZoneHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.AskSave then
		S_PlayerDataMgr:SaveGameDataAsync(_userId)
	elseif _actionType == ConstDefPlayerAction.AskIndex then
		S_PlayerStatusMgr:GivePlayerIndexHandler(_userId)
	elseif _actionType == ConstDefPlayerAction.AskFstCdTime then
		S_PetMgr:AskForFstMagicFuseRemainTimeHandler(_userId)
	elseif _actionType == ConstDefPlayerAction.HatchFive then
		S_PetMgr:HatchFiveHandler(_userId,table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.GetGift then
		S_GiftMgr:GetGiftHandler(_userId,table.unpack(args))
	end
end

--- 处理玩家捡到东西事件
--- @param _userId string 玩家UserId
--- @param _pickType number 捡到东西类型：ConstDef.PlayerPickTypeEnum
function S_RequestMgr:PlayerPickHandler(_userId,_pickType,...)
	local args = {...}
	if _pickType == ConstDef.PlayerPickTypeEnum.Egg then
		S_PetMgr:PickEggHandler(_userId,table.unpack(args))
	else
		S_Store:PickResource(_userId,_pickType)
	end
end

--- 处理玩家装备事件
--- @param _userId string 玩家UserId
--- @param _equipType number 装备类型：ConstDef.EquipmentTypeEnum
function S_RequestMgr:PlayerEquipHandler(_userId, _equipType, ...)
	local args = {...}
	if _equipType == ConstDef.EquipmentTypeEnum.Pet then
		S_PetMgr:EquipPetHandler(_userId,table.unpack(args))
	elseif _equipType == ConstDef.EquipmentTypeEnum.Potion then
		S_Store:UsePotionHandler(_userId,table.unpack(args))
	end
end

--- 处理玩家合成事件
--- @param _userId string 玩家UserId
--- @param _mergeType number 合成类型：ConstDef.MergeCategoryEnum
function S_RequestMgr:MergeHandler(_userId,_mergeType,...)
	local args = {...}
	if _mergeType == ConstDef.MergeCategoryEnum.normalMerge then
		S_PetMgr:NormalMergeHandler(_userId,table.unpack(args))
	elseif _mergeType == ConstDef.MergeCategoryEnum.limitMerge then
		S_PetMgr:LimitMergeHandler(_userId,table.unpack(args))
	end
end

--- 处理某个宠物中断挖矿事件
--- @param _userId string 玩家的UserId
--- @param _petId string 宠物的id
--- @param _mineTbl table 宠物正在挖掘的矿物信息数据:area场景，zone关卡,posIndex位置
function S_RequestMgr:PetStopDiggingEventHandler(_userId,_petId,_mineTbl)
	S_MineMgr:RemovePetFromBeingDiggedMineTbl(_userId,_petId,_mineTbl)
end

local ConstDefGuideState = ConstDef.guideState ---新手指引步骤
--- 处理玩家完成新手指引事件
--- @param _userId string 玩家的UserId
--- @param _guideStep string 玩家正在进行的新手指引步骤:ConstDefGuideState
function S_RequestMgr:ProcessGuideHandler(_userId,_guideStep,...)
	if _guideStep == ConstDefGuideState.GivePet then
		S_PetMgr:GivePlayerPetInGuide(_userId)
	end
end

return S_RequestMgr