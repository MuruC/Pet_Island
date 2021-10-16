--- 客户端采矿管理模块
-- @module mine manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_MineMgr, this = {}, nil

--- 初始化C_MineMgr 
function C_MineMgr:Init()
    --info('C_MineMgr:Init')
    this = self
    self:InitListeners()

    -- 处理中的限时解锁关卡table
    self.inTimeUnlockLevelTbl = {}
    -- 放限时解锁关卡的文件夹
    self.inTimeUnlockLevelFolder = localPlayer.Local.Independent.Mine
    -- 放金钱解锁门的文件夹
    self.unlockAreaDoorFolder = localPlayer.Local.Independent.AreaDoors
    -- 放限时解锁场景的文件夹
    self.inTimeUnlockAreaFolder = localPlayer.Local.Independent.Mine
    -- 获得金钱的倍率
    self.getMoneyManifaction = 1
    -- 因为药水导致蛋概率增长
    self.potionEggMag = 1
    -- 普通矿生成蛋的概率
    self.normalMineCreateEggProb = 80
    -- 掉钻石概率
    self.diamondProb = 1
    -- 单个金币矿的金币数
    self.coinsInGoldMine = 8
    -- 掉落药水的机率
    self.potionProb = 1
    -- 所有矿的位置总表
    self.allMinePosTbl = {}
    -- 所有挖矿地点的位置总表
    self.allDigMinePosTbl = {}
    -- 所有选中矿特效表
    self.allFocusMineFx = {}

    self:InitInTimeUnLockArea()
    self:InitAllMineTbl()
    self:InitMinePos()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_MineMgr:Update(dt)
    self:CheckInTimeUnlockLevelStatus()
end

--- 初始化C_MineMgr自己的监听事件
function C_MineMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_MineMgr, 'C_MineMgr', this)
end

local constDefMineCategory = ConstDef.mineCategoryEnum  ---矿的类别

--- 初始化限时解锁的关卡
function C_MineMgr:InitInTimeUnLockArea()
    for a = 4, 1, -1 do
        local mineName = 'a' .. tostring(a) .. 'z5'
        local mine = self.inTimeUnlockLevelFolder:GetChild(mineName)
        if mine then
            mine.areaIndex.Value = a
            mine.zoneIndex.Value = 5
            mine.totalProgress.Value = PlayerCsv.CheckpointData[a][5]['ChallengeData']
        end
    end
end

local constDefDigState = ConstDef.guideState.Dig

--- 挖矿完成后接收奖励
--- @param _rewardTbl table 奖励表
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _posTbl table 矿坐标
function C_MineMgr:GetRewardEventHandler(_rewardTbl,_area,_zone,_posIndex,_posTbl)
    C_AudioMgr:Stop(C_AudioMgr.allAudios.sound_game_15)
    local minePos = Vector3(_posTbl.x,_posTbl.y,_posTbl.z)
    if _rewardTbl['eggNum'] then
        local rad = 3
        -- 生成蛋
        for ii = _rewardTbl['eggNum'], 1, -1 do
            local archetypeName = 'Egg_0' .. tostring(_area)..'0'..tostring(_zone)
            local eggObj = world:CreateInstance(archetypeName,'EggInstance',localPlayer.Local.Independent,minePos,EulerDegree(-90,0,0))
            self:RewardsDropTween(eggObj,0,minePos,
                                  Vector3(minePos.x + rad * math.cos(math.rad(30 * (ii - 1))) * (-1) ^ ii + math.random(-2,2)/10, minePos.y, 
                                          minePos.z + rad * math.sin(math.rad(30 * (ii - 1))) * (-1) ^ ii + math.random(-2,2)/10))

            local DestroyEgg = function()
                if eggObj and not eggObj.bPick.Value then
                    eggObj:Destroy()
                end
            end
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(30,false,os.time(),DestroyEgg,true))
        end
    end
    if _rewardTbl['diamond'] then
        -- 生成钻石
        local diamond = world:CreateInstance('Diamond','Diamond',localPlayer.Local.Independent,minePos)
        self:RewardsDropTween(diamond,0,minePos,
                              Vector3(minePos.x + math.randomFloat(-3,3), minePos.y, minePos.z + math.randomFloat(-3,3)))
    end
    if _rewardTbl['potion'] then
        -- 生成药水
        local potion = world:CreateInstance('Potion','Potion',localPlayer.Local.Independent,minePos)
        self:RewardsDropTween(potion,0,minePos,
                              Vector3(minePos.x + math.randomFloat(-3,3), minePos.y, minePos.z + math.randomFloat(-3,3)))
        local type = math.random(1,ConstDef.POTION_TYPE_NUM)
        potion.type.Value = type
    end
    if _rewardTbl['gold'] then
        local rad = 2.5
        -- 生成金币
        for ii = _rewardTbl['gold'], 1, -1 do
            local coinObj = world:CreateInstance('Coin','CoinInstance',localPlayer.Local.Independent,minePos)
            self:RewardsDropTween(coinObj,0,minePos,
                                  Vector3(minePos.x + rad * math.cos(math.rad(40 * (ii - 1))) * (-1) ^ ii + math.random(-2,2)/10, minePos.y, 
                                          minePos.z + rad * math.sin(math.rad(40 * (ii - 1))) * (-1) ^ ii + math.random(-2,2)/10))
            local DestroyCoin = function()
                if coinObj then
                    coinObj:Destroy()
                end
            end
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(60,false,os.time(),DestroyCoin,true))
        end
    end
    C_MineGui:RemoveMineProgressBar(_area,_zone,_posIndex)
	C_PetMgr:PetDoneMining(_area,_zone,_posIndex)
end

--- 检测限时解锁关卡状态
function C_MineMgr:CheckInTimeUnlockLevelStatus()
    for k, v in pairs(self.inTimeUnlockLevelTbl) do
        if not v then
            return
        end
        if v.Gui then
            v.Gui.RemainTime.Text = tostring(v.totalTime.Value - (C_TimeMgr.curSecond - v.startTime.Value))
            v.Gui.RemainProgress.Text = tostring(v.totalProgress.Value - v.curProgress.Value)
        end
        if v.curProgress.Value >= v.totalProgress.Value then
            v:Destroy()
            self.inTimeUnlockLevelTbl[k] = nil
            return
        end
        if C_TimeMgr.curSecond - v.startTime.Value > v.totalTime.Value and v.curProgress.Value > 0 then
            v.curProgress.Value = 0
            v.Gui.RemainTime.Text = '  '
            v.Gui.RemainProgress.Text = '  '
            for k_, v_ in pairs(C_PetMgr.arrCurPets) do
                if v_.workMine.obj == v then
                    v_.bWorking = false
                    v_.workMine.obj = nil
                end
            end
            self.inTimeUnlockLevelTbl[k] = nil
        end
    end
end

--- 初始化每个区域储存矿的表
function C_MineMgr:InitAllMineTbl()
    --- ** 储存所有矿Tbl的总表 **
    for a = 4, 1, -1 do
        for b = 5, 1, -1 do
            local index = 'a' .. tostring(a) .. 'z' .. tostring(b)
            self.allMinePosTbl[index] = {}
            self.allDigMinePosTbl[index] = {}
        end
    end
end

local function getDirBetweenObjs(srcPos, dstPos)
	return Vector3(dstPos.x - srcPos.x, dstPos.y - srcPos.y, dstPos.z - srcPos.z)	
end

--- 初始化矿的出生位置
function C_MineMgr:InitMinePos()
    local focusFxFolder = localPlayer.Local.Independent.FocusMineFxs
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
                local pos = Vector3(posTbl.x,posTbl.y,posTbl.z)
                -- 初始化挖矿的点
                local digMinePos = {}
				local offset = 0.5
				local digPos1 = Vector3(pos.x + offset, pos.y, pos.z + offset)
				local digPos2 = Vector3(pos.x + offset, pos.y, pos.z - offset)
				local digPos3 = Vector3(pos.x - offset, pos.y, pos.z - offset)
				local digPos4 = Vector3(pos.x - offset, pos.y, pos.z + offset)
                digMinePos = {digPos1,digPos2,digPos3,digPos4}
                local posTblName = 'a' .. tostring(a) .. 'z' .. tostring(b)
                table.insert(self.allMinePosTbl[posTblName], posTbl)
                local index = #self.allMinePosTbl[posTblName]
                self.allDigMinePosTbl[posTblName][index] = digMinePos
                -- 初始化点击矿特效
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent((a * b + index) * 0.3,false,C_TimeMgr.curTime,
                                                             function()
                                                                local focusFx = world:CreateInstance('Focus', 'Focus', focusFxFolder, 
                                                                                                     Vector3(posTbl.x,posTbl.y + 0.2,posTbl.z))
                                                                if not self.allFocusMineFx[posTblName] then
                                                                    self.allFocusMineFx[posTblName] = {}
                                                                end
                                                                self.allFocusMineFx[posTblName][index] = focusFx
                                                                focusFx:SetActive(false)
                                                             end,false))
            end
        end
    end
end

--- 接收挖矿进度数据
--- @param _type int 矿的分类constDefMineCategory
--- @param _result int 挖矿信息枚举ConstDef.DigMsgEnum
function C_MineMgr:ReceiveMineDigResultEventHandler(_type,_result,...)
    local args = {...}
    if _type == constDefMineCategory.unlockMine then
        if _result == ConstDef.DigMsgEnum.Done then
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_24)
            C_NoticeGui:HideUnlockMineNtc('UnlockSuccess')
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),function()
                                                                            self:RemoveLevelMine(table.unpack(args))
                                                                            C_PlayerStatusMgr:ReplyUnlockAreaHandler(_result,table.unpack(args))
                                                                           end,true))           
            --PathFinding:CreateNavMap(table.unpack(args))
        elseif _result == ConstDef.DigMsgEnum.Fail then
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_25)
            C_MineGui:ResetUnlockMineProgress(table.unpack(args))
            C_NoticeGui:HideUnlockMineNtc('UnlockFail')
        else
            C_MineGui:ChangeMineProgressBar(_result,table.unpack(args))
        end
    elseif _type <= constDefMineCategory.majorEgg then
        C_MineGui:ChangeMineProgressBar(_result,table.unpack(args))
    elseif _type == constDefMineCategory.guide then
        C_MineGui:ChangeMineProgressBar(_result,table.unpack(args))
    end
end

--- 移除关卡的矿
--- @param _area int 场景
--- @param _zone int 关卡
function C_MineMgr:RemoveLevelMine(_area,_zone)
    local mineName = 'a'..tostring(_area)..'z5'
    local mineObj = localPlayer.Local.Independent.Mine:GetChild(mineName)
    if mineObj then
        mineObj:Destroy()
    end
end

--- 完成新手指引挖矿事件
function C_MineMgr:DoneDigGuideMineEventHandler()
    -- 生成蛋
    local guideMinePos = Vector3(-1514.2, -1.67, -75.7788)
    local archetypeName = 'Egg_0' .. tostring(1)..'0'..tostring(1)
    local eggObj = world:CreateInstance(archetypeName,'EggInstance',localPlayer.Local.Independent,guideMinePos,EulerDegree(-90,0,0))
    self:RewardsDropTween(eggObj,0,guideMinePos,
                          Vector3(guideMinePos.x + math.randomFloat(-2,2), guideMinePos.y, guideMinePos.z + math.randomFloat(-2,2)))
    -- 销毁新手矿
    localPlayer.Local.Independent.Guide.GuideMine:Destroy()
    -- 销毁进度条
    C_MineGui:RemoveMineProgressBar(1,1,ConstDef.GUIDE_MINE_POS_INDEX)

    -- 新手指引更新状态机
    C_Guide:ProcessGuideEvent(ConstDef.guideEvent.doneDigMine)
end

--- 奖励掉落动画
--- @param _obj Object 奖励节点
--- @param _modelRad float 模型半径
--- @param _startPos Vector3 出发点
--- @param _dropPos Vector3 落地点
function C_MineMgr:RewardsDropTween(_obj,_modelRad,_startPos,_dropPos)
    local xDiff = _dropPos.x-_startPos.x
    local zDiff = _dropPos.z-_startPos.z
    local height = 3
    local pos1 = Vector3(_startPos.x + xDiff/3, _startPos.y + height, _startPos.z + zDiff/3)
    local pos2 = Vector3(_startPos.x + xDiff/3 * 2, pos1.y, _startPos.z + zDiff/3 * 2)
    local pos3 = Vector3(_dropPos.x, _dropPos.y + _modelRad, _dropPos.z)
    local tweener01 = Tween:TweenProperty(_obj, {Position = pos1}, 0.3, Enum.EaseCurve.Linear)
    local tweener02 = Tween:TweenProperty(_obj, {Position = pos2}, 0.1, Enum.EaseCurve.Linear)
    local tweener03 = Tween:TweenProperty(_obj, {Position = pos3}, 0.3, Enum.EaseCurve.Linear)
    tweener01.OnComplete:Connect(function()
        tweener02:Play()
        tweener01:Destroy()
    end)
    tweener02.OnComplete:Connect(function()
        tweener03:Play()
        tweener02:Destroy()
    end)
    tweener03.OnComplete:Connect(function()
        tweener03:Destroy()
    end)
    tweener01:Play()
end

return C_MineMgr