--- 玩家成就系统模块
-- @module Module server achieve mgr
-- @copyright Lilith Games, Avatar Team
-- @author Yuhao Peng, Chen Muru
local S_Achieve, this = {}, nil

local Achieve = {} ---成就

local constDefBuffCategoryEnumAchieve = ConstDef.buffCategoryEnum.Achieve  ---buff类别
local constDefResultMsgEnum = ConstDef.ResultMsgEnum        ---回执信息
local constDefPlayerActionAchieve = ConstDef.PlayerActionTypeEnum.Achieve   ---成就
local constDefAchieveNum = ConstDef.ACHIEVE_TYPE_NUM    ---成就总数

--- 初始化成就的类
--- @param _id int 成就id
--- @param _rewardName string 奖励名称
function Achieve:Init(_id)
    self.id = _id
end

--- 增加成就数值
--- @param _userId string 玩家的UserId
--- @param _val mixed 改变的数值
function Achieve:ChangeAchieveValue(_userId,_val)
    S_PlayerDataMgr:ChangeAchieveValue(_userId,self.id,_val)
    --同步新数据到客户端
    S_PlayerDataMgr:SyncDataToClient(_userId, 'stats.achieveCurValue',S_PlayerDataMgr.allPlayersData[_userId].stats.achieveCurValue)
end

--- 通知玩家领取成就升级奖励
--- @param _userId string 玩家的UserId
--- @param _achieveLevel int 成就等级
function Achieve:InformPlayerToGetReward(_userId,_achieveLevel)
    NetUtil.Fire_C('PlayerCanGetAchieveRewardEvent',world:GetPlayerByUserId(_userId),self.id,_achieveLevel)
end

--- 玩家请求解锁成就
--- @param _userId string 玩家的UserId
function Achieve:PlayerRequestUnlock(_userId)
    local result = constDefResultMsgEnum.None
    if S_PlayerDataMgr:CheckIfPlayerCanGetReward(_userId,self.id) then
        self:GivePlayerReward(_userId)
        -- 刷新属性
        S_PlayerDataMgr:RefrshSingleAttribute(_userId,self.id,constDefBuffCategoryEnumAchieve)
        -- 更新成就等级
        S_PlayerDataMgr:PlayerAchieveLevelUp(_userId,self.id)
        -- 向客户端同步数据
        S_PlayerDataMgr:SyncAllDataToClient(_userId)
        -- 通知客户端结果
        result = constDefResultMsgEnum.Succeed
        NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
        constDefPlayerActionAchieve,result,self.id)
    end
end

--- 给予玩家奖励
--- @param _userId string 玩家的UserId
function Achieve:GivePlayerReward(_userId)
    -- 刷新钻石数和成就buff
    S_PlayerDataMgr:UpdateAchieveBuff(_userId,self.id) 
end

--- 初始化
function S_Achieve:Init()
    this = self
    self:InitListeners()

    -- 成就table
    self.allAchieves = {}

    self:InitAllAchieve()
end

--- 初始化Game Manager自己的监听事件
function S_Achieve:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_Achieve, 'S_Achieve', this)
end

--- Update函数
--- @param dt delta time 每帧时间
function S_Achieve:Update(dt)

end

--- 初始化成就对象
function S_Achieve:InitAllAchieve()
    for ii = constDefAchieveNum, 1, -1 do
        local o = {}
        setmetatable(o, {__index = Achieve})
        o:Init(ii)
        self.allAchieves[ii] = o
    end
end

--- 玩家解锁成就处理器
--- @param _userId string 玩家的UserId
--- @param _achieveId number 成就索引
function S_Achieve:PlayerUnlockAchieveHandler(_userId,_achieveId)
    self.allAchieves[_achieveId]:PlayerRequestUnlock(_userId)
end

--- 改变玩家成就数值
--- @param _userId string 玩家的UserId
--- @param _achieveId number 成就索引
--- @param _val mixed 改变的数值
function S_Achieve:PlayerChangeAchieveVal(_userId,_achieveId,_val)
    self.allAchieves[_achieveId]:ChangeAchieveValue(_userId,_val)
end

return S_Achieve