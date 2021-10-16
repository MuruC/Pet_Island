--- 游戏服务端采矿管理模块
-- @module Mine Manager, Server-side
-- @copyright Lilith Games, Avatar Team
-- @author Muru Chen
local S_MineMgr, this = {}, nil

-- 矿class
local Mine = {}

--- 初始化矿class
--- @param _area int 矿的场景
--- @param _zone int 矿的关卡
--- @param _totalProgress string 矿的总进度数
--- @param _getCoin string 玩家可以获得金币数量
--- @param _obj Object 矿的节点
--- @param _level int 矿的品级
--- @param _posIndex int 矿的位置索引
function Mine:Init(_area,_zone,_totalProgress,_getCoin,_obj,_level,_posIndex)
    self.area = _area
    self.zone = _zone
    self.totalProgress = _totalProgress
    self.getCoin = _getCoin
    self.obj = _obj
    self.level = _level
    self.posIndex = _posIndex
    -- 参与过挖矿的玩家
    self.didMinePlayers = {}
    -- 是否已经发放过奖励
    self.bSendReward = false
end

-- 创建新的矿对象
function CreateNewMine(_area,_zone,_totalProgress,_getCoin,_obj,_level,_posIndex)
    local o = {}
    setmetatable(o,{__index = Mine})
    o:Init(_area,_zone,_totalProgress,_getCoin,_obj,_level,_posIndex)
    return o
end

-- 世界boss的class
local Boss = {}

-- Boss状态
local bossIdleState = {}    ---静止
local bossFightState = {}   ---战斗状态

--- 初始化世界boss
--- @param _totalProgress string boss血量
--- @param _obj Object boss节点
function Boss:Init(_totalProgress,_obj)
    self.totalProgress = _totalProgress
    self.obj = _obj
    self.allPlayers = {}
    self.curPlayers = {}
    self.timeEventId = nil
    self.curProgress = '0'
    self.posIndex = ConstDef.BOSS_MINE_POS_INDEX
    self.level = 8
    self.progressProprotion = 0
    self.curState = bossIdleState
end

function Boss:ChangeState(nextState)
    local curState = self.curState
	if curState and curState.OnLeave then
		curState.OnLeave(self)
	end
	
	self.curState = nextState
	if nextState.OnEnter then
		nextState.OnEnter(self)
	end
end

function Boss:IsInState(state)
	if self.curState == state then
		return true
	end
	
	return false
end

bossIdleState.OnEnter = function(boss)

end

bossIdleState.OnUpdate = function(boss)

end

bossIdleState.OnLeave = function(boss)

end

bossFightState.OnEnter = function(boss)

end

bossFightState.OnUpdate = function(boss)

end

bossFightState.OnLeave = function(boss)

end

-- 初始化S_MineMgr
function S_MineMgr:Init()
    --info('S_MineMgr:Init')
    this = self
    self:InitListeners()

    -- 所有矿的位置总表
    self.allMinePosTbl = {}
    -- 所有矿的总表
    self.allMineTbl = {}
    -- 矿概率的排序表
    self.mineProb = {}
    -- 矿概率权重
    self.mineTotalProb = 0
    -- 当前世界boss
    self.curBoss = nil
    -- 所有被击败的世界boss的tbl
    self.allDefeatBossTbl = {}
    -- 正在被挖掘的矿
    self.beingDiggedMines = {}
    -- 正在被挖掘的关卡矿
    self.beingDiggedLevelMine = {}
    ---正在被挖掘的新手矿
    self.beingDiggedGuideMine = {}

    -- 第一个大场景的关卡1
    self.a1z1Pos = world.Area1.Zone1MinePos
    -- 第二个大场景
    self.area2 = world.Area2
    -- 第三个大场景
    self.area3 = world.Area3
    -- 第四个大场景
    self.area4 = world.Area4

    -- 前一个boss模型
    self.prevBoss = 2
    -- 世界boss力量
    self.bossPower = {}
    -- 击败boss获得的奖励
    self.bossReward = {}

    -- 关卡内矿的数量
    self.MAX_MINE_NUM = 10
    -- 每次刷新矿的间隔，单位：秒
    self.ADD_MINE_INTERVAL = 10
    -- 世界boss刷新间隔时间，单位：秒
    self.WORLD_BOSS_INTERAVL_TIME = 1800
    
    self:InitMineProb()
    self:InitWorldBossPower()
    self:InitBossReward()
    self:InitAllMineTbl()
    self:InitMinePos()
    self:InitGenerateMine()
    self:InitCreateBossByTimeEvent()
    self:InitBeingDiggedMineTable() 
	self:CheckMineProgress()
end

-- Update函数
function S_MineMgr:Update(dt)
end

--- 初始化S_MineMgr自己的监听事件
function S_MineMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_MineMgr, 'S_MineMgr', this)
end

--- 初始化矿的概率
function S_MineMgr:InitMineProb()
    self.mineProb[1] = 50
    self.mineProb[2] = 30
    self.mineProb[3] = 15
    self.mineProb[4] = 6
    self.mineProb[5] = 6
    self.mineProb[6] = 2
    for k, v in pairs(self.mineProb) do
        self.mineTotalProb = self.mineTotalProb + v
    end
end

--- 初始化世界boss力量
function S_MineMgr:InitWorldBossPower()
    self.bossPower['0'] = '1000'
    self.bossPower['1'] = '1000'
    self.bossPower['2'] = '8000'
    self.bossPower['3'] = '15000'
    self.bossPower['4'] = '25000'
    self.bossPower['5'] = '40000'
    self.bossPower['6'] = '70000'
    self.bossPower['7'] = '100000'
end

--- 初始化世界boss奖励
function S_MineMgr:InitBossReward()
    self.bossReward[1] = '100'
    self.bossReward[2] = '60'
    self.bossReward[3] = '40'
    self.bossReward[4] = '20'
    self.bossReward[5] = '10'
    self.bossReward[6] = '10'
    self.bossReward[7] = '10'
end

--- 初始化每个区域储存矿的表
function S_MineMgr:InitAllMineTbl()
    --- ** 储存所有矿Tbl的总表 **
    for a = 4, 1, -1 do
        for b = 5, 1, -1 do
            local index = 'a' .. tostring(a) .. 'z' .. tostring(b)
            self.allMineTbl[index] = {}
            self.allMinePosTbl[index] = {}
        end
    end
end

--- 初始化矿的出生位置
function S_MineMgr:InitMinePos()
    for a = 4, 1, -1 do
        local areaName = 'Area' .. tostring(a)
        local area = world:GetChild(areaName)
        for b = 5, 1, -1 do
            local zoneName = 'Zone' .. tostring(b) .. 'MinePos'
            local zone = area:GetChild(zoneName)
            for k, v in pairs(zone:GetChildren()) do
                local posTbl = {
                    x = v.Position.x,
                    y = v.Position.y,
                    z = v.Position.z
                }
                local posTblName = 'a' .. tostring(a) .. 'z' .. tostring(b)
                table.insert(self.allMinePosTbl[posTblName], posTbl)
            end
        end
    end
end

--- 初始化当前被挖掘矿数据表
function S_MineMgr:InitBeingDiggedMineTable()
    for a = 4, 1, -1 do
        for z = 5, 1, -1 do
            local areaZoneIndex = 'a' .. tostring(a) .. 'z' .. tostring(z)
            self.beingDiggedMines[areaZoneIndex] = {}
        end
    end
end

--- 把新的矿加入Table
--- @param _newMine table 矿
function S_MineMgr:AddNewMine(_newMine)
    local areaIndex = _newMine.area
    local zoneIndex = _newMine.zone
    local index = 'a'.. tostring(areaIndex) .. 'z' .. tostring(zoneIndex)
    self.allMineTbl[index][_newMine.posIndex] = _newMine
end

local ConstDefMineCategory = ConstDef.mineCategoryEnum  ---矿的类别

--- 初始化所有矿
function S_MineMgr:InitGenerateMine()
    for k,v in pairs(self.allMineTbl) do
        local areaIndex = string.sub(k,2,2)
        local zoneIndex = string.sub(k,4,4)
        local areaZoneIndex = 'a' .. areaIndex .. 'z' .. zoneIndex
        local maxMineNum = GetTableLength(self.allMinePosTbl[areaZoneIndex])
        local mineNum = GetTableLength(v)
        while mineNum < maxMineNum do
            local posIndex = 0
            local breakLoop_ = false
            for _i,_v in pairs(self.allMinePosTbl[areaZoneIndex]) do
                if not breakLoop_ then
                    local findSameIndex = false
                    if GetTableLength(self.allMineTbl[areaZoneIndex]) < 1 then
                        breakLoop_ = true
                        posIndex = 1
                    else
                        for i_,v_ in pairs(self.allMineTbl[areaZoneIndex]) do
                            if v_.posIndex == _i then
                                findSameIndex = true
                            end
                        end
                    end
            
                    -- 当位置索引没有被用到，则赋予新蛋一个位置
                    if not findSameIndex and _i <= maxMineNum then
                        self:GenerateNewMine(tonumber(areaIndex),tonumber(zoneIndex),_i)
                        mineNum = mineNum + 1
                    end
                end
            end
        end            
    end       
end

--- 生成新的矿
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _posIndex int 坐标索引
function S_MineMgr:GenerateNewMine(_area,_zone,_posIndex)
    -- 权重算概率
    local mineProb = math.random(100)
    local breakLoop = false
    local mineLevel = 0
    for _i,_v in pairs(self.mineProb) do
        if not breakLoop then
            local probWeight = 100 * _v / self.mineTotalProb
            if mineProb > probWeight then
                mineProb = mineProb - probWeight
            else
                breakLoop = true
                mineLevel = _i
            end
        end
    end

    local areaZoneIndex = 'a' .. tostring(_area) .. 'z' .. tostring(_zone)
    local posTbl = self.allMinePosTbl[areaZoneIndex][_posIndex]
    local minePos = Vector3(posTbl.x,posTbl.y,posTbl.z)
    local mineName
    if mineLevel <= ConstDefMineCategory.advanced then
        mineName = 'Mine_0' .. tostring(_area) .. '0' .. tostring(_zone) .. '0' .. tostring(mineLevel)
    else
        mineName = 'Mine_00000' .. tostring(mineLevel)                       
    end
    local mineObj = world:CreateInstance(mineName,'MineInstance'..areaZoneIndex, world.Mine:GetChild(areaZoneIndex), minePos, EulerDegree(0,0,0))
    
    local totalProgress
    if mineLevel <= ConstDefMineCategory.unlockMine then
        totalProgress = GameCsv.MineProperty[_area][_zone][mineLevel]['TotalProgress']
    elseif mineLevel == ConstDefMineCategory.unlockMine then
        totalProgress = GameCsv.CheckpointData[_area][_zone]['ChallengeData']
    end
    local getCoin = GameCsv.MineProperty[_area][_zone][mineLevel]['GetCoin']
    local newMine = CreateNewMine(_area,_zone,totalProgress,getCoin,mineObj,mineLevel,_posIndex)                    
    self:AddNewMine(newMine)
    -- obj节点下面的变量子节点赋值
    mineObj.areaIndex.Value = _area
    mineObj.zoneIndex.Value =_zone
    mineObj.totalProgress.Value = tostring(totalProgress)
    mineObj.getCoin.Value = tostring(getCoin)
    mineObj.posIndex.Value = _posIndex
    mineObj.level.Value = mineLevel
end

--- 宠物开采完毕事件处理器
--- @param _area int 场景编号
--- @param _zone int 关卡编号
--- @param _posIndex int 矿位置索引
function S_MineMgr:DonePetMineEventHandler(_area,_zone,_posIndex)
    local areaZoneIndex = 'a' .. tostring(_area) .. 'z' .. tostring(_zone)
    for k, v in pairs(self.allMineTbl[areaZoneIndex]) do
        if v.posIndex == _posIndex then
            if not v.bSendReward then
                for k_,v_ in pairs(v.didMinePlayers) do
                    local player = world:GetPlayerByUserId(v_)
                    if player then
                        local posTbl = {
                            x = v.obj.Position.x,
                            y = v.obj.Position.y,
                            z = v.obj.Position.z
                        }
                       NetUtil.Fire_C('GetRewardEvent', player, _area, _zone, _posIndex,posTbl,v.level,v.getCoin) 
                    end
                end
                v.obj:Destroy()
                self.allMineTbl[areaZoneIndex][k] = nil
                v.bSendReward = true
            end
        end
    end
end

--- 接收参与过挖矿玩家事件处理器
--- @param _userId string 玩家Id
--- @param _area int 场景编号
--- @param _zone int 关卡编号
--- @param _posIndex int 位置索引
--- @param _mineLevel int 矿等级
--- @param _petId string 宠物id
--- @param _petPower string 宠物挖矿效率
function S_MineMgr:AddDidMinPlayerEventHandler(_userId,_area,_zone,_posIndex,_mineLevel,_petId,_petPower)
    if _mineLevel <= ConstDef.mineCategoryEnum.majorEgg then
        local areaZoneIndex = 'a' .. tostring(_area) .. 'z' .. tostring(_zone)
        local mineTbl = self.beingDiggedMines[areaZoneIndex][_posIndex]
        if mineTbl then
            -- 在所有挖过该矿的玩家中插入宠物id
            if mineTbl.allPlayers[_userId] then
                local thisUserInAllPlayer = mineTbl.allPlayers[_userId]
                local bFoundPetInAllPlayer = false     --是否已经储存过该宠物的数据
                for ii = #thisUserInAllPlayer, 1, -1 do
                    if thisUserInAllPlayer[ii] == _petId then
                        bFoundPetInAllPlayer = true
                    end
                end
                -- 能储存的宠物不能超过玩家可以携带宠物数量的上限
                if not bFoundPetInAllPlayer and 
                #thisUserInAllPlayer < S_PlayerDataMgr:GetAttributeFinalValue(_userId, ConstDef.PlayerAttributeEnum.MaxCurPet) then 
                    table.insert(thisUserInAllPlayer,_petId)
                end
            else
                mineTbl.allPlayers[_userId] = {_petId}
            end
            -- 在当前挖过该矿的玩家中插入宠物id
            local thisUserInCurPlayer = mineTbl.curPlayers[_userId]
            if thisUserInCurPlayer then
                -- 能储存的宠物不能超过玩家可以携带宠物数量的上限
                if not table.exists(thisUserInCurPlayer,_petId) and 
                #thisUserInCurPlayer < S_PlayerDataMgr:GetAttributeFinalValue(_userId, ConstDef.PlayerAttributeEnum.MaxCurPet) then 
                    table.insert(thisUserInCurPlayer,_petId)
                end
            else
                mineTbl.curPlayers[_userId] = {_petId}
            end
            mineTbl.eff = TStringNumAdd(mineTbl.eff, _petPower)
        else
            -- 在所有矿的总表中找到该矿
            local mine
            for k, v in pairs(self.allMineTbl[areaZoneIndex]) do
                if v.posIndex == _posIndex then
                    mine = v
                end
            end
            mine.obj.digFx:SetActive(true)
            mineTbl = {
                allPlayers = {},        -- 储存所有参与挖过该矿的玩家的userId
                curPlayers = {},        -- 储存正在参与挖矿的玩家的userId
                area = _area,
                zone = _zone,
                posIndex = _posIndex,
                eff = _petPower,        --- @type string 总效率
                totalProgress = mine.totalProgress,
                obj = mine.obj,
                level = mine.level,
                progressProprotion = 0, -- 当前进度占总进度的比例
            }
            mineTbl.allPlayers[_userId] = {_petId}
            mineTbl.curPlayers[_userId] = {_petId}
	    	self.beingDiggedMines[areaZoneIndex][_posIndex] = mineTbl		
        end
    elseif _mineLevel == ConstDefMineCategory.unlockMine then
        self:AddPetInDiggingLevelMine(_userId,_area,_zone,_petId)
    elseif _mineLevel == ConstDefMineCategory.guide then
        self:AddPlayerDiggingGuideMine(_userId)
    elseif _mineLevel == ConstDefMineCategory.boss then
        self:AddPlayerDiggingBossMine(_userId,_petId)
    end
end

local levelMinePosIndex = ConstDef.LEVEL_MINE_POS_INDEX
local guideMinePosIndex = ConstDef.GUIDE_MINE_POS_INDEX
local bossMinePosIndex = ConstDef.BOSS_MINE_POS_INDEX

--- 检查被挖的矿当前的进度,每秒一次
function S_MineMgr:CheckMineProgress()
    local a = function()    --普通矿进度检测
        for _, v in pairs(self.beingDiggedMines) do
            for k_, v_ in pairs(v) do
                if GetTableLength(v_.curPlayers) > 0 then
                    v_.obj.curProgress.Value = TStringNumAdd(v_.obj.curProgress.Value, v_.eff)
					print(v_.obj.curProgress.Value)
                    -- 检查是否达到总进度:返回结果,第一个整数大返回true，反之false，相等返回0
                    local compareNum = TStringNumCom(v_.obj.curProgress.Value, tostring(v_.totalProgress))
                    -- 进度每过十分之一报告给玩家
                    local proportion = math.floor(tonumber((TStringNumDiv(v_.obj.curProgress.Value, v_.totalProgress))) * 10)
                    if proportion < 10 and proportion ~= v_.progressProprotion then
                        v_.progressProprotion = proportion
                        for p,_v in pairs(v_.curPlayers) do
                            NetUtil.Fire_C('ReceiveMineDigResultEvent',world:GetPlayerByUserId(p),v_.level,
                            proportion,v_.area,v_.zone,v_.posIndex)
                        end 
                    end
                    if compareNum or compareNum == 0 then
                        
                        local allPlayers = {}
                        local areaZoneIndex = 'a' .. tostring(v_.area) .. 'z' .. tostring(v_.zone)
                        for k, _v in pairs(v_.allPlayers) do
                            allPlayers[k] = {}
                            local mineLevel = v_.level --蛋等级
                            -- 将蛋生成在参与过挖矿的玩家周围
                            local eggNum = 0 --生成蛋的个数
                            if mineLevel <= ConstDefMineCategory.advanced then
                                local eggProb = S_PlayerDataMgr:GetAttributeFinalValue(k,ConstDef.PlayerAttributeEnum.GetEggProb) --生成蛋的机率                       
                                for ___, p in pairs(_v) do
                                    local ranVal = math.random(1,100)
                                    if ranVal <= eggProb then
                                        eggNum = eggNum + 1
                                    end
                                end
                            elseif mineLevel == ConstDefMineCategory.minorEgg then
                                eggNum = 6
                            elseif mineLevel == ConstDefMineCategory.majorEgg then
                                eggNum = 10
                            end
                            allPlayers[k]['eggNum'] = eggNum
                            if mineLevel == ConstDefMineCategory.coinMine then
                                allPlayers[k]['gold'] = S_PlayerDataMgr:GetAttributeFinalValue(k,ConstDef.PlayerAttributeEnum.CoinNumInGoldMine)
                            end
                        end

                        for k, _v in pairs(v_.curPlayers) do
                            -- 将金币给正在挖矿的玩家
                            local coinCoe = S_PlayerDataMgr:GetAttributeFinalValue(k,ConstDef.PlayerAttributeEnum.GetCoinMagnification) --金币倍率
                            local coin = self.allMineTbl[areaZoneIndex][v_.posIndex].getCoin
                            local finalCoin = TStringNumMul(tostring(coinCoe), coin)
                            allPlayers[k]['coin'] = finalCoin
                            -- 更改玩家当前资源
                            S_PlayerDataMgr:ChangeServerRes(k, ConstDef.ServerResTypeEnum.Coin, ConstDef.ChangeResTypeEnum.Add, finalCoin)
                            -- 同步新数据到客户端
                            S_PlayerDataMgr:SyncDataToClient(k, 'resource.server.coin',S_PlayerDataMgr.allPlayersData[k].resource.server.coin)
                            -- 掉落钻石
                            local diamondProb = S_PlayerDataMgr:GetAttributeFinalValue(k,ConstDef.PlayerAttributeEnum.GetDiamondProb) --获得钻石概率
                            local ranVal01 = math.random(1,100)
                            if ranVal01 <= diamondProb then
                                allPlayers[k]['diamond'] = true
                            end
                            -- 掉落药水
                            local potionProb = S_PlayerDataMgr:GetAttributeFinalValue(k,ConstDef.PlayerAttributeEnum.GetPotionProb) --获得药水概率
                            local ranVal02 = math.random(1,100)
                            if ranVal02 <= potionProb then
                                allPlayers[k]['potion'] = true
                            end
                        end

                        for k, t in pairs(allPlayers) do
                            local player = world:GetPlayerByUserId(k)
                            NetUtil.Fire_C('GetRewardEvent',player,t,v_.area,v_.zone,v_.posIndex,self.allMinePosTbl[areaZoneIndex][v_.posIndex])
                        end

                        ------ 销毁矿
                        -- 一定时间后生成新的矿
                        local generateMineEvent = function()
                            S_MineMgr:GenerateNewMine(v_.area,v_.zone,v_.posIndex)
                        end
                        -- 在S_TimeMgr中添加事件
                        S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(self.ADD_MINE_INTERVAL,false,S_TimeMgr.curSecond,generateMineEvent,true))
                        -- 销毁矿节点
                        v_.obj:Destroy()
                        -- 移除所有矿数据表中的矿
                        self.allMineTbl[areaZoneIndex][v_.posIndex] = {}
                        -- 移除当前正在被挖掘的数据表中的矿                    
                        v[k_] = nil
                    end
                end
            end
        end
    end

    -- 关卡解锁矿进度检测
    local checkLevelMineProgress = function()
        for k, v in pairs(self.beingDiggedLevelMine) do
            v.curProgress = TStringNumAdd(v.curProgress, v.eff)
            print(v.curProgress)
			-- 进度每过十分之一报告给玩家
            local proportion = math.floor(tonumber((TStringNumDiv(v.curProgress, v.totalProgress))) * 10)
            if proportion < 10 and proportion ~= v.progressProprotion then
                v.progressProprotion = proportion
                NetUtil.Fire_C('ReceiveMineDigResultEvent',world:GetPlayerByUserId(k),ConstDefMineCategory.unlockMine,
                proportion,v.area,v.zone,levelMinePosIndex)
            end

            if not TStringNumCom(v.totalProgress, v.curProgress) or TStringNumCom(v.totalProgress, v.curProgress) == 0 then
                ----解锁该关卡
                --在Datastore中改变数据
                S_PlayerDataMgr:UnlockZone(k,v.area,v.zone)
                --同步新数据到客户端
                S_PlayerDataMgr:SyncAllDataToClient(k)
                S_PlayerDataMgr:SaveGameDataAsync(k)
                NetUtil.Fire_C('ReceiveMineDigResultEvent',world:GetPlayerByUserId(k),ConstDefMineCategory.unlockMine,
                ConstDef.DigMsgEnum.Done,v.area,v.zone,levelMinePosIndex)
                self.beingDiggedLevelMine[k] = nil
            end
        end
    end

    -- 新手矿进度检测
    local checkGuideMineProgress = function()
        for k, v in pairs(self.beingDiggedGuideMine) do
            v.curProgress = TStringNumAdd(v.curProgress, v.eff)
            -- 进度每过十分之一报告给玩家
            local proportion = math.floor(tonumber((TStringNumDiv(v.curProgress, v.totalProgress))) * 10)
            if proportion < 10 and proportion ~= v.progressProprotion then
                v.progressProprotion = proportion
                NetUtil.Fire_C('ReceiveMineDigResultEvent',world:GetPlayerByUserId(k),ConstDefMineCategory.guide,
                proportion,v.area,v.zone,guideMinePosIndex)
            end
            if not TStringNumCom(v.totalProgress, v.curProgress) or TStringNumCom(v.totalProgress, v.curProgress) == 0 then
                local player = world:GetPlayerByUserId(k)
                -- 更改玩家当前资源
                S_PlayerDataMgr:ChangeServerRes(k, ConstDef.ServerResTypeEnum.Coin, ConstDef.ChangeResTypeEnum.Add, '100')
                -- 同步新数据到客户端
                S_PlayerDataMgr:SyncDataToClient(k, 'resource.server.coin',S_PlayerDataMgr.allPlayersData[k].resource.server.coin)
                NetUtil.Fire_C('DoneDigGuideMineEvent',player)
                self.beingDiggedGuideMine[k] = nil
            end
        end
    end

    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(1,true,os.time(),a,true))
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(1,true,os.time(),checkLevelMineProgress,true))
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(1,true,os.time(),checkGuideMineProgress,true))
end

--- 将检查矿进度事件添加到S_TimeMgr里
function S_MineMgr:InitCheckMineProgressEventByTime()
    local a = self.CheckMineProgress
    
end

--- 从正在被挖掘的矿数据中移除某个玩家的宠物
--- @param _userId string 玩家的UserId
--- @param _petId string 宠物的id
--- @param _mineTbl table 宠物正在挖掘的矿物信息数据:area场景，zone关卡,posIndex位置
function S_MineMgr:RemovePetFromBeingDiggedMineEventHandler(_userId,_petId,_mineTbl)
    if not _mineTbl then
        return
    end
    local areaZoneIndex = 'a' .. tostring(_mineTbl.area) .. 'z' .. tostring(_mineTbl.zone)
    if not self.beingDiggedMines[areaZoneIndex] then
        return
    end
    local mineTbl
    if _mineTbl.posIndex == levelMinePosIndex then
        mineTbl = self.beingDiggedLevelMine[_userId]
    elseif _mineTbl.posIndex == guideMinePosIndex then
        mineTbl = self.beingDiggedGuideMine[_userId]
    elseif _mineTbl.posIndex == bossMinePosIndex then
        local thisUserInCurPlayer = self.curBoss.curPlayers[_userId]
        local petIds = thisUserInCurPlayer.petIds
        for ii = #petIds, 1, -1 do
            if petIds[ii] == _petId then
                table.remove(petIds,ii)
                thisUserInCurPlayer.eff = TStringNumSub(thisUserInCurPlayer.eff, S_PlayerDataMgr:GetPetInformation(_userId,_petId).curPower)
            end
        end
        if #thisUserInCurPlayer < 1 then
            thisUserInCurPlayer = nil
        end
    else
        mineTbl = self.beingDiggedMines[areaZoneIndex][_mineTbl.posIndex]
    end
    if mineTbl and mineTbl.curPlayers[_userId] then
        local thisUserInCurPlayer = mineTbl.curPlayers[_userId]
        for ii = #thisUserInCurPlayer, 1, -1 do
            if thisUserInCurPlayer[ii] == _petId then
                table.remove(thisUserInCurPlayer,ii)
                mineTbl.eff = TStringNumSub(mineTbl.eff, S_PlayerDataMgr:GetPetInformation(_userId,_petId).curPower)
                if #thisUserInCurPlayer < 1 then
                    thisUserInCurPlayer = nil
                end
            end
        end
        if #mineTbl.curPlayers < 1 then
            self.allMineTbl[areaZoneIndex][_mineTbl.posIndex].obj.digFx:SetActive(false)
        end
    end
end

local constDefEquipmentPet = ConstDef.EquipmentTypeEnum.Pet ---装备中正在跟随的宠物

--- 从被挖掘的矿数据中移除某个玩家
--- @param _userId string 玩家的UserId
--- @param _mines table 玩家挖掘的所有矿,例_mines = {mine1 = {area,zone,posIndex}}
function S_MineMgr:RemovePlayerFromCurDiggingMineEventHandler(_userId,_mines)
    if not _mines or #_mines < 1 then
        return
    end
    local allCurPets = S_PlayerDataMgr:GetEquipment(_userId,constDefEquipmentPet)
    for _, v in pairs(_mines) do
        local mineTbl
        if v.posIndex == levelMinePosIndex then
        elseif v.posIndex == guideMinePosIndex then
        elseif v.posIndex == bossMinePosIndex then
            if self.curBoss then
                self.curBoss.curPlayers[_userId] = nil
            end
        else
            local areaZoneIndex = 'a' .. tostring(v.area) .. 'z' .. tostring(v.zone)
            if self.beingDiggedMines[areaZoneIndex] then
                mineTbl = self.beingDiggedMines[areaZoneIndex][v.posIndex]                
                if mineTbl then
                    local thisUserInCurPlayer = mineTbl.curPlayers[_userId]
                    if thisUserInCurPlayer then
                        for ii = #thisUserInCurPlayer, 1, -1 do
                            mineTbl.eff = TStringNumSub(mineTbl.eff, S_PlayerDataMgr:GetPetInformation(_userId,thisUserInCurPlayer[ii]).curPower)
                        end
                        thisUserInCurPlayer = nil
                    end
                    if #mineTbl.curPlayers < 1 then
                        self.allMineTbl[areaZoneIndex][v.posIndex].obj.digFx:SetActive(false)
                    end
		        end
            end
        end
    end
end

--- 玩家离开游戏
--- @param _userId string 玩家的UserId
function S_MineMgr:PlayerLeaveGameHandler(_userId)
    self.beingDiggedLevelMine[_userId] = nil
    self.beingDiggedGuideMine[_userId] = nil
    for _, v in pairs(self.beingDiggedMines) do
        for __, mine in pairs(v) do
            local thisUserInCurPlayer = mine.curPlayers[_userId]
            if thisUserInCurPlayer then
                for ii = #thisUserInCurPlayer, 1, -1 do
                    mine.eff = TStringNumSub(mine.eff, S_PlayerDataMgr:GetPetInformation(_userId,thisUserInCurPlayer[ii]).curPower)
                end
                thisUserInCurPlayer = nil
            end
        end
    end
end

--- 初始化定期生成世界boss时间
function S_MineMgr:InitCreateBossByTimeEvent()
    local CreateBossByTime = function()
        if self.curBoss ~= nil then
            self.curBoss.obj:Destroy()
            S_TimeMgr:RemoveEvent(self.curBoss.timeEventId)
        end
        self.curBoss = {}
        setmetatable(self.curBoss,{__index = Boss})
        local bossPos = Vector3(1.0871, 14.3044, -330.297)
        if self.prevBoss == 2 then
            self.prevBoss = 1
        else
            self.prevBoss = 2
        end
        local bossObj = world:CreateInstance('Boss'..tostring(self.prevBoss),'Boss',world,bossPos)
        self.curBoss:Init(self.bossPower[tostring(#world:FindPlayers())],bossObj)
        local event = S_TimeMgr:CreateNewEvent(1,true,S_TimeMgr.curSecond,function() S_MineMgr:CheckBossProgress() end,true)
        self.curBoss.timeEventId = event.id
        S_TimeMgr:AddEvent(event)
    end
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(3,false,S_TimeMgr.curSecond,CreateBossByTime,true))
    -- 在S_TimeMgr中添加事件
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(self.WORLD_BOSS_INTERAVL_TIME,true,S_TimeMgr.curSecond,CreateBossByTime,true))
end

local constDefDiamondResource = ConstDef.ServerResTypeEnum.Diamond
local constDefAdd = ConstDef.ChangeResTypeEnum.Add
--- 检测世界boss进度
function S_MineMgr:CheckBossProgress()
    local curBoss = self.curBoss
    if self.curBoss then
        local curPlayers = curBoss.curPlayers
        local allPlayer = curBoss.allPlayers
        local allPlayerNum = #allPlayer
        for userId, v in pairs(curPlayers) do
            if not world:GetPlayerByUserId(userId) then
                --将玩家移除这个矿
                for ii = allPlayerNum, 1, -1 do
                    if allPlayer[ii].userId == userId then
                        table.remove(allPlayer,ii)
                    end
                    allPlayerNum = allPlayerNum - 1
                end
                curPlayers[userId] = nil
            else
                for ii = allPlayerNum, 1, -1 do
                    if allPlayer[ii].userId == userId then
                        allPlayer[ii].totalProgress = TStringNumAdd(allPlayer[ii].totalProgress, v.eff)
                    end
                end
                curBoss.curProgress = TStringNumAdd(curBoss.curProgress, v.eff)
            end
        end
        local compareResult = TStringNumCom(curBoss.curProgress, curBoss.totalProgress)
        -- 当boss的挖掘进度满了
        if compareResult or compareResult == 0 then
            -- 排名
            local function compare(a, b)
                --1. a,b不允许为空
                local aProgress = a.totalProgress
                local bProgress = b.totalProgress
                if not aProgress or not bProgress then
                    return false
                end
                local result = TStringNumCom(aProgress, bProgress)
                if result == 0 then
                    return false
                end
                -- 降序
                return result
            end
            table.sort(allPlayer,compare)

            local rewardPlace = 1
            -- 发放世界boss奖励
            for ii = 1, allPlayerNum, 1 do
                if ii > 1 then
                    local compareResult = TStringNumCom(allPlayer[ii].totalProgress, allPlayer[ii - 1].totalProgress)
                    if not compareResult then
                        rewardPlace = ii
                    end
                end
                local userId = allPlayer[ii].userId
                -- 更改玩家当前资源
                S_PlayerDataMgr:ChangeServerRes(userId, constDefDiamondResource, constDefAdd, self.bossReward[rewardPlace])
                -- 同步到客户端
                S_PlayerDataMgr:SyncDataToClient(userId, 'resource.server.diamond',S_PlayerDataMgr.allPlayersData[userId].resource.server.diamond)
                -- 通知客户端结果
                NetUtil.Fire_C('GetRewardFromBossEvent',world:GetPlayerByUserId(userId),rewardPlace)
                -- 保存数据
                S_PlayerDataMgr:SaveGameDataAsync(userId)
            end
            -- 移除Time Mgr里的循环事件
            S_TimeMgr:RemoveEvent(curBoss.timeEventId)
            -- 删除boss
            curBoss.obj:Destroy()
            curBoss = nil
        end
    end
end

--[[
    function Boss:Init(_totalProgress,_obj,_type)
    self.totalProgress = _totalProgress
    self.obj = _obj
    self.allPlayers = {
        value = {totalProgress = '0', userId = ''}
    }
    self.curPlayers = {
        userId = {
            eff = '0'
            petIds = {}
        }
    }
    self.type = _type
    self.id = bossId
    bossId = bossId + 1
    self.curProgress = '0'
    self.progressProprotion = 0
    self.eff = '0'
end
]]

--- 添加玩家正在挖关卡矿事件
--- @param _userId string 玩家的UserId
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _petId string 宠物的id
function S_MineMgr:AddPetInDiggingLevelMine(_userId,_area,_zone,_petId)
    local petPower = S_PlayerDataMgr:GetPetInformation(_userId,_petId).curPower
    if not self.beingDiggedLevelMine[_userId] then
        local mineInfo = GameCsv.CheckpointData[_area][5]
        local mine = {
            area = _area,
            zone = _zone,
            pet = {
                _petId,
            },
            eff = petPower,
            totalProgress = mineInfo['ChallengeData'],  
            DigTime = 60,
            curProgress = '0',
            progressProprotion = 0,  --当前进度占总进度的比例
        }
        self.beingDiggedLevelMine[_userId] = mine
        local removeMine = function()
            if not TStringNumCom(mine.curProgress, mine.totalProgress) then
                NetUtil.Fire_C('ReceiveMineDigResultEvent',world:GetPlayerByUserId(_userId),ConstDefMineCategory.unlockMine,
                ConstDef.DigMsgEnum.Fail,_area,_zone,levelMinePosIndex)
                self.beingDiggedLevelMine[_userId] = nil
            end
        end
        local event = S_TimeMgr:CreateNewEvent(mine.DigTime,false,os.time(),removeMine,true)
        S_TimeMgr:AddEvent(event)
    else
        local mine = self.beingDiggedLevelMine[_userId]
        local pets = mine.pet
        if not table.exists(pets,_petId) then
            table.insert(pets,_petId)
            mine.eff = TStringNumAdd(mine.eff, petPower)
        end
    end
end

---添加玩家正在挖新手矿事件
--- @param _userId string 玩家的UserId
function S_MineMgr:AddPlayerDiggingGuideMine(_userId)
    if not self.beingDiggedGuideMine[_userId] then
        local mine = {
            area = 1,
            zone = 1,
            posIndex = -1,
            eff = '4',
            totalProgress = '30',
            curProgress = '0',
            progressProprotion = 0,  --当前进度占总进度的比例
        }
        self.beingDiggedGuideMine[_userId] = mine
    end
end

---添加玩家正在挖boss事件
---@param _userId string 玩家的UserId
---@param _petId string 宠物的id
function S_MineMgr:AddPlayerDiggingBossMine(_userId,_petId)
    local curPlayers = self.curBoss.curPlayers
    local allPlayer = self.curBoss.allPlayers
    local petPower = S_PlayerDataMgr:GetPetInformation(_userId,_petId).curPower
    if curPlayers[_userId] then
        table.insert(curPlayers[_userId].petIds,_petId)
        curPlayers[_userId].eff = TStringNumAdd(curPlayers[_userId].eff, petPower)
    else
        curPlayers[_userId] = {
            eff = petPower,
            petIds = {_petId}
        }
    end
    for ii = #allPlayer, 1, -1 do
        if allPlayer[ii].userId == _userId then
            return
        end
    end
    table.insert(allPlayer,{userId = _userId,totalProgress = '0'})
end

local constDefEncrEffAttribute = ConstDef.PlayerAttributeEnum.EncrEffect    ---鼓励效率属性枚举
--- 玩家鼓励宠物处理
--- @param _userId string 玩家的UserId
--- @param _nearbyPet table 附近宠物 key:petId value:{area,zone,posIndex}
function S_MineMgr:PlayerEncrPetHandler(_userId,_nearbyPet)
    for petId, workMine in pairs(_nearbyPet) do
        if workMine.posIndex == levelMinePosIndex then
            local mineTbl = self.beingDiggedLevelMine[_userId]
            local pets = mineTbl.pet
            for ii = #pets, 1, -1 do
                if pets[ii] == petId then
                    local encrEff = S_PlayerDataMgr:GetAttributeFinalValue(_userId,constDefEncrEffAttribute)
                    local thisPet = S_PlayerDataMgr:GetPetInfo(_userId,petId)
                    local petCurPower = thisPet.curPower
                    local addEff = TStringNumMul(tostring(encrEff - 1), petCurPower)
                    if not thisPet.bEncr then
                        thisPet.bEncr = true
                        mineTbl.eff = TStringNumAdd(addEff,mineTbl.eff)
                        -- 五秒后移除效果
                        local newTimerEvent = S_TimeMgr:CreateNewEvent(1,true,os.time(),nil,true)
                        local removeEffect = function()
                            if not mineTbl or not thisPet then
                                S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                return
                            end
                            for ii = #pets, 1, -1 do
                                if pets[ii] == petId and thisPet.getEncrTime + 5 <= os.time() then
                                    thisPet.bEncr = false
                                    mineTbl.eff = TStringNumSub(mineTbl.eff, addEff)
                                    S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                end
                            end
                        end
                        newTimerEvent.handler = removeEffect
                        S_TimeMgr:AddEvent(newTimerEvent)
                    end
                    thisPet.getEncrTime = os.time()

                    self:PlayerEncrCallback(_userId)
                end
            end
        elseif workMine.posIndex == guideMinePosIndex then
        
        elseif workMine.posIndex == bossMinePosIndex then
            local thisUserInCurPlayer = self.curBoss.curPlayers[_userId]
            local petIds = thisUserInCurPlayer.petIds
            for ii = #petIds, 1, -1 do
                if petIds[ii] == petId then
                    local encrEff = S_PlayerDataMgr:GetAttributeFinalValue(_userId,constDefEncrEffAttribute)
                    local thisPet = S_PlayerDataMgr:GetPetInformation(_userId,petId)
                    local petCurPower = thisPet.curPower
                    local addEff = TStringNumMul(tostring(encrEff - 1), petCurPower)                    

                    if not thisPet.bEncr then
                        thisPet.bEncr = true
                        thisUserInCurPlayer.eff = TStringNumAdd(addEff,thisUserInCurPlayer.eff)
                        -- 五秒后移除效果
                        local newTimerEvent = S_TimeMgr:CreateNewEvent(1,true,os.time(),nil,true)
                        local removeEffect = function()
                            if not thisUserInCurPlayer or not self.curBoss or not thisPet then
                                S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                return
                            end
                            for ii = #petIds, 1, -1 do
                                if petIds[ii] == petId and thisPet.getEncrTime + 5 <= os.time() then
                                    thisPet.bEncr = false
                                    thisUserInCurPlayer.eff = TStringNumSub(thisUserInCurPlayer.eff, addEff)
                                    S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                end
                            end
                        end
                        newTimerEvent.handler = removeEffect
                        S_TimeMgr:AddEvent(newTimerEvent)
                    end
                    thisPet.getEncrTime = os.time()                    
                    self:PlayerEncrCallback(_userId)
                end
            end
        else
            local areaZoneIndex = 'a' .. tostring(workMine.area) .. 'z' .. tostring(workMine.zone)
            local mineTbl = self.beingDiggedMines[areaZoneIndex][workMine.posIndex]
            if not mineTbl then
                return
            end
            local thisUserInCurPlayer = mineTbl.curPlayers[_userId]
            for ii = #thisUserInCurPlayer, 1, -1 do
                if thisUserInCurPlayer[ii] == petId then
                    local encrEff = S_PlayerDataMgr:GetAttributeFinalValue(_userId,constDefEncrEffAttribute)
                    local thisPet = S_PlayerDataMgr:GetPetInformation(_userId,petId)
                    local petCurPower = thisPet.curPower
                    local addEff = TStringNumMul(tostring(encrEff - 1), petCurPower)                    

                    if not thisPet.bEncr then
                        thisPet.bEncr = true
                        mineTbl.eff = TStringNumAdd(addEff,mineTbl.eff)
                        -- 五秒后移除效果
                        local newTimerEvent = S_TimeMgr:CreateNewEvent(1,true,os.time(),nil,true)
                        local removeEffect = function()
                            if not thisUserInCurPlayer or not mineTbl or not thisPet then
                                S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                return
                            end
                            for ii = #thisUserInCurPlayer, 1, -1 do
                                if thisUserInCurPlayer[ii] == petId and thisPet.getEncrTime + 5 <= os.time() then
                                    thisPet.bEncr = false
                                    mineTbl.eff = TStringNumSub(mineTbl.eff, addEff)
                                    S_TimeMgr:RemoveEvent(newTimerEvent.id)
                                end
                            end
                        end
                        newTimerEvent.handler = removeEffect
                        S_TimeMgr:AddEvent(newTimerEvent)
                    end
                    thisPet.getEncrTime = os.time()                    
                    self:PlayerEncrCallback(_userId)
                end
            end

        end
    end
end

local constDefSucceedResult = ConstDef.ResultMsgEnum.Succeed        ---成功信息回执
local constDefEncrAchieve = ConstDef.achieveCategoryEnum.encrNum    ---鼓励成就枚举
--- 玩家鼓励宠物反馈事件
--- @param _userId string 玩家的UserId
function S_MineMgr:PlayerEncrCallback(_userId)
    --成就
    S_Achieve:PlayerChangeAchieveVal(_userId,constDefEncrAchieve,1)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    constDefEncrAchieve,constDefSucceedResult)
end

return S_MineMgr