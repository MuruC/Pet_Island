local S_PlayerStatusMgr = {}

function S_PlayerStatusMgr:Init()
    --info('S_PetMgr:Init')
    this = self
    self:InitListeners()
    self.playerIndex = {}
    self:CheckHidePlayerIslandEvent()
end

function S_PlayerStatusMgr:Update(dt)

end

function S_PlayerStatusMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_PlayerStatusMgr, 'S_PlayerStatusMgr', this)
end

local constDefResults = ConstDef.ResultMsgEnum  ---回执结果枚举

--- 解锁场景处理器
--- @param _userId string 玩家UserId
--- @param _area int 场景编号
function S_PlayerStatusMgr:UnlockAreaHandler(_userId,_area)
    local result = constDefResults.None
    local needRes = GameCsv.MoneyForUnlockArea[_area]['Money']
    local curRes = S_PlayerDataMgr:GetValue(_userId,ConstDef.ServerResTypeEnum.Coin)
    --解锁条件：资源足够
    local condition01 = not TStringNumCom(needRes, curRes)
    if condition01 then
        result = constDefResults.Succeed
        --数据中加入新场景
        S_PlayerDataMgr:UnlockArea(_userId,_area)
        --同步数据到客户端
        S_PlayerDataMgr:SyncAllDataToClient(_userId)
    else
        result = constDefResults.ResNotEnough
    end
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.UnlockArea, result, _area)
end

local constDefSub = ConstDef.ChangeResTypeEnum.Sub  ---扣除资源计算方式枚举
local constDefCoin = ConstDef.ServerResTypeEnum.Coin    ---金币资源枚举
local constDefUnlockZoneAction = ConstDef.PlayerActionTypeEnum.UnlockZone   ---解锁区域行为
local constDefAskIndexAction = ConstDef.PlayerActionTypeEnum.AskIndex   ---生成玩家编号行为
--- 解锁关卡处理器
--- @param _userId string 玩家UserId
--- @param _area int 场景编号
--- @param _zone int 关卡编号
function S_PlayerStatusMgr:UnlockZoneHandler(_userId,_area,_zone)
    local result = constDefResults.None
    local needRes = GameCsv.CheckpointData[_area][_zone]['ChallengeData']
    local condition01 = TStringNumCom(needRes,S_PlayerDataMgr:GetValue(_userId,ConstDef.ServerResTypeEnum.Coin))
    if condition01 == 0 or not condition01 then
        --扣除金币
        S_PlayerDataMgr:ChangeServerRes(_userId, constDefCoin, constDefSub, needRes)
        --数据中加入新关卡
        S_PlayerDataMgr:UnlockZone(_userId,_area,_zone)
        --同步数据到客户端
        S_PlayerDataMgr:SyncAllDataToClient(_userId)
        result = constDefResults.Succeed
    else
        result = constDefResults.ResNotEnough
    end
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    constDefUnlockZoneAction, result, _area,_zone)
end

--- 生成玩家编号处理器
--- @param _userId string 玩家UserId
function S_PlayerStatusMgr:GeneratePlayerIndex(_userId)
    for ii = 1, 7, 1 do
        local userId = self.playerIndex[ii]
        if not userId or not world:GetPlayerByUserId(userId) then
            self.playerIndex[ii] = _userId
            self:ShowPlayerIsland(ii)
            return
        end
    end
end

--- 发送玩家编号处理器
--- @param _userId string 玩家UserId
function S_PlayerStatusMgr:GivePlayerIndexHandler(_userId)
    for index, v in pairs(self.playerIndex) do
        if v == _userId then
            NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), constDefAskIndexAction, index)
        end
    end
end

--- 显示玩家岛屿
--- @param index int 玩家编号
function S_PlayerStatusMgr:ShowPlayerIsland(index)
    world.MainIsland:GetChild('Player'..tostring(index)):SetActive(true)
end

--- 隐藏某个玩家岛屿
--- @param _userId string 玩家的UserId
function S_PlayerStatusMgr:HidePlayerIsland(_userId)
    for k, v in pairs(self.playerIndex) do
        if v == _userId then
            world.MainIsland:GetChild('Player'..tostring(k)):SetActive(false)
            self.playerIndex[k] = nil
        end
    end
end

--- 检测隐藏玩家岛屿
function S_PlayerStatusMgr:CheckHidePlayerIslandEvent()
    local hideIsland = function()
        for ii = 7, 1, -1 do
            local userId = self.playerIndex[ii]
            if not userId or not world:GetPlayerByUserId(userId) then
                world.MainIsland:GetChild('Player'..tostring(ii)):SetActive(false)
                self.playerIndex[ii] = nil
            end
        end
    end
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(30,true,os.clock(),hideIsland,true))
    hideIsland()
end

return S_PlayerStatusMgr