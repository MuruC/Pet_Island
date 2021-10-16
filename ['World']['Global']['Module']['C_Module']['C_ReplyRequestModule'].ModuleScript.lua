--- 客户端响应服务器管理模块
-- @module player data manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_ReplyRequest, this = {}, nil

function C_ReplyRequest:Init()
    this = self
    self:InitListeners()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_ReplyRequest:Update(dt)
    -- TODO: 其他客户端模块Update
end

--- 初始化C_ReplyRequest自己的监听事件
function C_ReplyRequest:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_ReplyRequest, 'C_ReplyRequest', this)
end

local ConstDefPlayerAction = ConstDef.PlayerActionTypeEnum	--- 玩家行为枚举

--- 响应服务器对接收玩家的请求信息的反馈
--- @param _actionType number 操作类型: ConstDef.PlayerActionTypeEnum
function C_ReplyRequest:ReplyRequestEventHandler(_actionType, ...)
	local args = {...}

	if _actionType == ConstDefPlayerAction.SellPet then
		C_BagGui:SellPetHandler(table.unpack(args))
		C_PetMgr:SellPetHandler(table.unpack(args))
		C_MergeGui:SellPetHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Buy then
		C_Store:ReplyBuyRequest(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Equip then
		self:EquipHandler(table.unpack(args))		
	elseif _actionType == ConstDefPlayerAction.Hatch then
		C_PetMgr:HatchReplyHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Merge then
		C_PetMgr:MergeReplyHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Achieve then
		C_AchieveGui:UnlockAchieveGui(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Pick then
		self:PickHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.PutEgg then
		C_PetMgr:PutEggsIntoGenHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.UnlockArea then
		C_PlayerStatusMgr:ReplyUnlockAreaHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.Guide then
		self:ProcessGuideEventHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.UnlockZone then
		C_PlayerStatusMgr:ReplyUnlockZoneHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.AskIndex then
		C_PlayerStatusMgr:GetPlayerIndexHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.HatchFive then
		C_PetMgr:HatchFiveReplyHandler(table.unpack(args))
	elseif _actionType == ConstDefPlayerAction.GetGift then
		C_NoticeGui:GetGiftHandler(table.unpack(args))
	end
end

--- 服务器反馈购买处理器
--- @param _goodsType string 购买类型：ConstDef.GoodsTypeEnum
function C_ReplyRequest:BuyHandler(_buyType,...)
    local args = {...}
    if _buyType == ConstDef.GoodsTypeEnum.Goods then
        C_Store:ReplyBuyGoodsRequest(table.unpack(args))        
    elseif _buyType == ConstDef.GoodsTypeEnum.Potion then
        
    end
end

--- 服务器反馈装备
--- @param _equipType string 装备类型：ConstDef.EquipmentTypeEnum
function C_ReplyRequest:EquipHandler(_equipType,...)
	local args = {...}
	if _equipType == ConstDef.EquipmentTypeEnum.Pet then
		C_NoticeGui:NoticeListener('CarrySuccess')
		C_BagGui:RefrshEquipBtn(table.unpack(args))
		C_PetMgr:ReplyEquipPet(table.unpack(args))
	end
end

--- 服务器反馈捡东西
--- @param _pickType number 捡起物品类型：ConstDef.PlayerPickTypeEnum
function C_ReplyRequest:PickHandler(_pickType,...)
	local args = {...}
	if _pickType == ConstDef.PlayerPickTypeEnum.Egg then
		C_BagGui:AddNewEggBtnInBag(table.unpack(args))
	end
end

local ConstDefGuideEvent = ConstDef.guideEvent ---新手指引事件

--- 服务器反馈新手引导事件
--- @param _guideEvent number 新手引导事件枚举：ConstDefGuideEvent
function C_ReplyRequest:ProcessGuideEventHandler(_guideEvent,...)
	local args = {...}
	if _guideEvent == ConstDefGuideEvent.givePet then
		C_PetMgr:GivePlayerPetInGuide(table.unpack(args))
		C_Guide:ProcessGuideEvent(_guideEvent)
	end
end

return C_ReplyRequest