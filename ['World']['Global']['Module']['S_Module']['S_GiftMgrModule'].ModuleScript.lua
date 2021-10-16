--- 玩家成就系统模块
-- @module Module server gift mgr
-- @copyright Lilith Games, Avatar Team
-- @author Yuhao Peng, Chen Muru
local S_GiftMgr = {}

local giftId = 1

local valueProb = {
    {value = '20', weight = 50},
    {value = '50', weight = 30},
    {value = '88', weight = 14},
    {value = '100', weight = 5},
    {value = '233', weight = 1},
}

--- 礼物Class
local Gift = {}

--- 初始化礼物类
--- @param _obj Object 礼物节点
--- @param _area int 场景
--- @param _index int 位置和旋转角度的索引
function Gift:Init(_obj,_area,_index)
    self.obj = _obj
    self.area = _area
    self.index = _index
    self.id = giftId
    _obj.Id.Value = giftId
    giftId = giftId + 1
    self.val = math.WeightRandom(valueProb)
end

local constDefAddEnum = ConstDef.ChangeResTypeEnum.Add ---增加资源的计算方式
local constDefDiamondResEnum = ConstDef.ServerResTypeEnum.Diamond   ---资源中的钻石
local constGetGiftAction = ConstDef.PlayerActionTypeEnum.GetGift    ---获得礼物行为枚举
--- 碰撞到礼物
--- @param _userId string 玩家的UserId
function Gift:PlayerGetPresent(_userId)
    -- 改变玩家资源
    S_PlayerDataMgr:ChangeServerRes(_userId, constDefDiamondResEnum, constDefAddEnum, self.val)
    -- 同步数据到客户端
    S_PlayerDataMgr:SyncDataToClient(_userId, 'resource.server.diamond',S_PlayerDataMgr.allPlayersData[_userId].resource.server.diamond)
    -- 告诉玩家结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId),constGetGiftAction,self.val)

    self.obj:Destroy()
    self.val = math.WeightRandom(valueProb)
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(1200,false,os.time(),function() 
    self.obj = world:CreateInstance('PresentObj'..tostring(self.area),'PresentInstance',world.Present,
                                        S_GiftMgr.giftPos[self.index],S_GiftMgr.giftRot[self.index])
    end,true))
end

--- 初始化
function S_GiftMgr:Init()
    this = self
    self:InitListeners()

    self.allGifts = {}
    self.giftPos = {}
    self.giftRot = {}

    self:InitAllGiftPos()
end

--- 初始化Game Manager自己的监听事件
function S_GiftMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_GiftMgr, 'S_GiftMgr', this)
end

--- Update函数
--- @param dt delta time 每帧时间
function S_GiftMgr:Update(dt)

end

--- 创建新的矿对象
function CreateNewGift(_obj,_area,_index)
    local o = {}
    setmetatable(o,{__index = Gift})
    o:Init(_obj,_area,_index)
    return o
end

--- 加入新的礼物
--- @param newGift table 新的礼物数据
function S_GiftMgr:AddNewGift(newGift)
    self.allGifts[newGift.id] = newGift
end

--- 初始化礼物
function S_GiftMgr:InitAllGiftPos()
    local index = 1
    for _, v in pairs(world.PresentPos:GetChildren()) do
        local area
        if v.Name == 'a1' then
            area = 1
        elseif v.Name == 'a2' then
            area = 2
        elseif v.Name == 'a3' then
            area = 3
        elseif v.Name == 'a4' then
            area = 4
        end
        for __, v_ in pairs(v:GetChildren()) do
            local pos = Vector3(v_.Position.x,v_.Position.y,v_.Position.z)
            local rot = EulerDegree(v_.Rotation.x,v_.Rotation.y,v_.Rotation.z)
            self.giftPos[index] = pos
            self.giftRot[index] = rot
            v_:SetActive(false)
            self:AddNewGift(CreateNewGift(world:CreateInstance('PresentObj'..tostring(area),'PresentInstance',world.Present,pos,rot),area,index))
            index = index + 1
        end
    end
end

--- 玩家获得礼物处理器
--- @param _userId string 玩家的UserId
--- @param _id int 碰到礼物的id
function S_GiftMgr:GetGiftHandler(_userId,_id)
    self.allGifts[_id]:PlayerGetPresent(_userId)
end

return S_GiftMgr