--- 客户端玩家状态管理模块
-- @module player status manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_PlayerStatusMgr, this = {}, nil

-- 成就类
local Achievement = {}
-- 成就Id
local achievementId = 1
-- 初始化成就
-- @param int _level 等级
-- @param int _reachData 到达下一阶段需要的数据
-- @param int _reward 得到的钻石
-- @param float _changeData 奖励后改变的数值
-- @param Object _UIObj 成就的UI
function Achievement:Init(_level, _reachData, _reward, _changeData, _UIObj)
    self.level = _level
    self.reachData = _reachData
    self.reward = _reward
    self.changeData = _changeData
    self.uiObj = _UIObj
    self.id = achievementId
    achievementId = achievementId + 1
    -- 当前进度
    self.curProgress = 0
end

function C_PlayerStatusMgr:Init()
    --info("C_PetMgr:Init")
    this = self
    self:InitListeners()

    -- 玩家编号
    self.playerIndex = 0

    -- 玩家处在的场景
    self.areaIndex = 1
    -- 玩家处在的关卡
    self.zoneIndex = 1
    -- 玩家是否在家园中
    self.bInHome = true
    -- 玩家是否在主城中
    self.bInMainIsland = false

    -- 玩家鼓励特效
    self.encrFx = localPlayer.Local.Fx.HappyFx
    -- 第一个传送门
    self.fstPortal = nil
    -- 第一个孵蛋机
    self.fstGen = nil

    -- 玩家传送位置
    self.explorePos = {}
    -- 玩家所有成就总表
    self.allAchievements = {}

    -- 初始化玩家传送的位置
    self:InitPlayerExplorePos()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_PlayerStatusMgr:Update(dt)
    -- TODO: 其他客户端模块Update
    self:CheckInteractableObjUnderFeet()
end

--- 初始化C_PlayerStatusMgr自己的监听事件
function C_PlayerStatusMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_PlayerStatusMgr, "C_PlayerStatusMgr", this)
end

-- 初始化玩家关卡传送的位置
function C_PlayerStatusMgr:InitPlayerExplorePos()
    for i = 4, 1, -1 do
        local areaFileName = "TransPos_" .. tostring(i)
        local areaFile = world.TransPos:GetChild(areaFileName)
        for a = 5, 1, -1 do
            local zoneFileName = "TransPos_" .. tostring(i) .. "." .. tostring(a)
            local posObj = areaFile:GetChild(zoneFileName)
            local posTbl = {
                x = posObj.Position.x,
                y = posObj.Position.y,
                z = posObj.Position.z
            }
            local index = "a" .. tostring(i) .. "z" .. tostring(a)
            self.explorePos[index] = posTbl
        end
    end
    C_TransGui:InitExploreBtns()
end

-- 点击回家按钮返回家园
function C_PlayerStatusMgr:ReturnHome()
    self.bInHome = true
    if self.areaIndex == 0 then
        return
    else
        self:PlayerTransportToHome(self.areaIndex)
    end
    self:SetIfPlayerInMainLand(false)
end

-- 返回主城
function C_PlayerStatusMgr:ReturnMainLand()
    localPlayer.Position = Vector3(-1.7771, 14.3748, -319.737)
    self:SetIfPlayerInMainLand(true)
end

-- 点击便捷传送探索
function C_PlayerStatusMgr:ExploreTheLevels(_index)
    if self.explorePos[_index] then
        local pos = Vector3(self.explorePos[_index].x, self.explorePos[_index].y, self.explorePos[_index].z)
        localPlayer.Position = pos
        self.bInHome = false
    end
end

--- 玩家解锁新场景
function C_PlayerStatusMgr:UnlockNewArea()
    local a = self.areaIndex
    local needRes = PlayerCsv.MoneyForUnlockArea[a]['Money']
    local curRes = C_PlayerDataMgr:GetValue(ConstDef.ServerResTypeEnum.Coin)
    local doorName = "AreaDoor" .. tostring(a)
    local condition01 = not TStringNumCom(needRes, curRes)
    local door = C_MineMgr.unlockAreaDoorFolder:GetChild(doorName)
    if door and condition01 then
        NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, ConstDef.PlayerActionTypeEnum.UnlockArea,a)
    end
    if not condition01 then
        
    end
end

local constDefIslandAnimCam = ConstDef.CameraModeEnum.islandAnim    ---岛屿浮起动画相机枚举

--- 服务器反馈场景解锁处理器
function C_PlayerStatusMgr:ReplyUnlockAreaHandler(_result,_area)
    if _result == ConstDef.ResultMsgEnum.Succeed then
        local doorName = "AreaDoor" .. tostring(_area)
        local door = C_MineMgr.inTimeUnlockAreaFolder:GetChild(doorName)
        if door then
            door:Destroy()
        end
        if _area < 4 then
            C_Camera:ChangeMode(constDefIslandAnimCam,1)
            local landName = "MyIsland" .. tostring(_area + 1)
            local land = C_CollisionMgr.myIslands:GetChild(landName)
            local landPos = land.Position
            land.Position = Vector3(landPos.x,-22,landPos.z)    
            land:SetActive(true)
            C_MainGui:CheckIfShowMainGui(false)
            local landTweener = Tween:TweenProperty(land, {Position = landPos}, 3, Enum.EaseCurve.Linear)
            landTweener.OnComplete:Connect(function()
                landTweener:Destroy()
                self:ReturnHome()
                C_MainGui:CheckIfShowMainGui(true)
                C_Camera:ChangeMode(1)
            end)
            C_Camera:IslandAnimCamTween()
            landTweener:Play()
            C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_26)
        end
    elseif _result == ConstDef.ResultMsgEnum.ResNotEnough then
        
    end
end

--- 服务器反馈区域解锁处理器
--- @param _result string 结果
--- @param _area int 场景
--- @param _zone int 关卡
function C_PlayerStatusMgr:ReplyUnlockZoneHandler(_result,_area,_zone)
    if _result == ConstDef.ResultMsgEnum.Succeed then
        local door = localPlayer.Local.Independent.ZoneDoors:GetChild('a'.._area..'z'.._zone)
        if door then
            local pos = door.Door.Position
            local fx = world:CreateInstance('ChallengeSuccess','ChallengeSuccess',localPlayer.Local.Independent,
                                            Vector3(pos.x,localPlayer.Position.y,pos.z))
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),function() fx:Destroy() end,true))
            door:Destroy()
        end
        C_NoticeGui:ClosePayForUnlock()
    else
        
    end
end

--- 初始化场景,包括关卡、场景、岛屿
function C_PlayerStatusMgr:InitAllZones()
    local mainIsland = C_CollisionMgr.myIslands
    local allZones = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Zones)
    local levelDoorFolder = localPlayer.Local.Independent.ZoneDoors
    local areaBossFolder = localPlayer.Local.Independent.Mine
    for a = 4, 1, -1 do
        local areaName = 'Area' .. tostring(a)
        if allZones[areaName] then
            local landName = "MyIsland" .. tostring(a)
            local land = mainIsland:GetChild(landName)    -- 出现家园
            land:SetActive(true)
            if allZones[areaName] then
                local area = allZones[areaName]
                for k, v in pairs(area) do
                    local door = levelDoorFolder:GetChild('a' .. tostring(a) .. 'z' .. tostring(v - 1))
                    if door then
                        door:Destroy()
                    end
                end
            end

            local boss = areaBossFolder:GetChild('a' .. tostring(a - 1) .. 'z5')
            if boss then
                boss:Destroy()
            end
        end
    end
    -- boss播放idle动画
    for k, v in pairs(areaBossFolder:GetChildren()) do
        local bossObj = v.mine
        local playIdle01 = bossObj:AddAnimationEvent('Idle1', 1)
        local playIdle02 = bossObj:AddAnimationEvent('Idle2', 1)
        local randomIdleAnim = function()
            local ran = math.random(1,100)
            if ran <= 70 then
                bossObj:PlayAnimation('Idle1', 2, 1, 0, true, false, 1)
            else
                bossObj:PlayAnimation('Idle2', 2, 1, 0, true, false, 1)
            end
        end
        playIdle01:Connect(randomIdleAnim)
        playIdle02:Connect(randomIdleAnim)
        bossObj:PlayAnimation('Idle1', 2, 1, 0, true, false, 1)
    end
end

--- 跳跃状态检测脚下
function C_PlayerStatusMgr:CheckInteractableObjUnderFeet()
    if localPlayer.State == 3 then
        local playerPos = localPlayer.Position
        local hitResult = Physics:RaycastAll(Vector3(playerPos.x,playerPos.y + 2,playerPos.z), 
						  Vector3(playerPos.x,playerPos.y - 0.5,playerPos.z), false)
        for _, v in pairs(hitResult.HitObjectAll) do
			if v.InteractableObj and v.InteractableObj.Value == 'Mushroom' then
				local playerSpd = localPlayer.LinearVelocity
				if playerSpd.y < 0 then
					localPlayer.LinearVelocity = Vector3(playerSpd.x, playerSpd.y + 30, playerSpd.z)
				end
			end
		end
    end
end

--- 显示鼓励特效
function C_PlayerStatusMgr:ShowEncrFx()
    local fx = self.encrFx
    fx:SetActive(true)
    fx.clickTime.Value = os.time()
end

--- 初始化显示鼓励特效事件
function C_PlayerStatusMgr:InitShowEncrFxEvent()
    local fx = self.encrFx
    local removeFx = function()
        if os.time() - fx.clickTime.Value >= 2 and fx.ActiveSelf then
            fx:SetActive(false)
        end
    end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,true,os.time(),removeFx,true))
end

--- 请求生成玩家编号
function C_PlayerStatusMgr:AskForPlayerIndex()
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),function()
        NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, ConstDef.PlayerActionTypeEnum.AskIndex)
    end,true))
end

--- 获得玩家编号
--- @param _index int 玩家编号
function C_PlayerStatusMgr:GetPlayerIndexHandler(_index)
    self.playerIndex = _index
    self:PlayerTransportToHome(1)
    C_Camera:SetCamConfig(_index)
end

--- 玩家传送回城
--- @param _area int 场景
function C_PlayerStatusMgr:PlayerTransportToHome(_area)
    localPlayer.Position = PlayerCsv.HomePos[self.playerIndex][_area]['Pos']
end

local maxEgg = 20

--- 检测玩家负重
function C_PlayerStatusMgr:CheckPlayerBurden()
    local eggNum = #localPlayer.Eggs:GetChildren()
    if eggNum >= maxEgg then
        localPlayer.WalkSpeed = 1
    else
        localPlayer.WalkSpeed = 6
    end
end

--- 设置玩家是否在主城的参数
--- @param _val boolean 是否在主城
function C_PlayerStatusMgr:SetIfPlayerInMainLand(_val)
    self.bInMainIsland = _val
    if _val then
        -- 玩家可以使用自动寻矿的功能
        C_MainGui.autoFindMine.CantFindMine:SetActive(false)
    else
        if self.bInHome then
            C_MainGui.autoFindMine.CantFindMine:SetActive(true)
        end
    end
end

--- 返回玩家当前所处场景和关卡
function C_PlayerStatusMgr:GetPlayerAreaAndZone()
    return self.areaIndex, self.zoneIndex
end

return C_PlayerStatusMgr