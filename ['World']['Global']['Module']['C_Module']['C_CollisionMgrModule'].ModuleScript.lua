--- 客户端碰撞管理模块
-- @module collision manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_CollisionMgr, this = {}, nil

function C_CollisionMgr:Init()
    this = self
    self:InitListeners()

    self.bPassStore = false
    self.myIslands = nil
    self.allMergeRoom = {}  --所有合成室
    self.allPortal = {}     --所有传送门
    self.allPetProbPnl = {} --所有宠物概率面板
    self.allPortalZone = {} --所有传送门附近的区域
end

--- Update函数
-- @param dt delta time 每帧时间
function C_CollisionMgr:Update(dt)
    -- TODO: 其他客户端模块Update
end

--- 初始化C_CollisionMgr自己的监听事件
function C_CollisionMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_CollisionMgr, 'C_CollisionMgr', this)
end

--- 初始化主岛
--- @param _index int 玩家编号
function C_CollisionMgr:InitMyIslands(_index)
    self.myIslands = world.MainIsland:GetChild('Player'..tostring(_index))
    self:InitAllMergeRoom()
    self:InitAllPortals()
    self:InitAllPetProbPnl()
    self:InitAllEggGen()
    self:InitCollisionCallback()
    C_PlayerStatusMgr.fstPortal = self.myIslands.MyIsland1.Portal1
    C_PlayerStatusMgr.fstGen = self.myIslands.MyIsland1.Incubator.Incubator
end

--- 初始化所有的合成室
function C_CollisionMgr:InitAllMergeRoom()
    local mainLand = self.myIslands
    self.allMergeRoom = {mainLand.MyIsland1.MergePet,mainLand.MyIsland2.MergePet,mainLand.MyIsland3.MergePet,mainLand.MyIsland4.MergePet}
end

--- 初始化所有的传送门
function C_CollisionMgr:InitAllPortals()
    local mainLand = self.myIslands
    self.allPortal = {
        mainLand.MyIsland1.Portal1,
        mainLand.MyIsland2.Portal2,
        mainLand.MyIsland3.Portal3,
        mainLand.MyIsland4.Portal4,
    }
    for _, v in pairs(self.allPortal) do
        table.insert(self.allPortalZone,v.PortalZone)
    end
end

--- 初始化所有宠物概率面板
function C_CollisionMgr:InitAllPetProbPnl()
    local mainLand = self.myIslands
    self.allPetProbPnl = {
        mainLand.MyIsland1.PetProbInstruction,
        mainLand.MyIsland2.PetProbInstruction,
        mainLand.MyIsland3.PetProbInstruction,
        mainLand.MyIsland4.PetProbInstruction,
    }
end

--- 初始化所有孵蛋器物体
function C_CollisionMgr:InitAllEggGen()
    local mainLand = self.myIslands
    for k, v in pairs(C_PetMgr.allEggGens) do
        v.obj = mainLand:GetChild('MyIsland' .. tostring(v.area)).Incubator
    end
end

local constDefEnterCollision = ConstDef.collisionEventEnum.Enter    ---进入碰撞
local constDefLeaveCollision = ConstDef.collisionEventEnum.Leave    ---退出碰撞
local constDefGuideState = ConstDef.guideState                      ---新手指引状态
local constDefGuideEvent = ConstDef.guideEvent                      ---指引事件枚举
local constDefHatchCam = ConstDef.CameraModeEnum.FuseRoom           ---合成室相机
local constDefIncubatorCam = ConstDef.CameraModeEnum.Incubator      ---孵蛋机相机  
--- 初始化碰撞函数
function C_CollisionMgr:InitCollisionCallback()
    local hitEggGenEvent = function(k,v)
        C_PetMgr:SetHitIncubator(v)
        C_PetMgr:PutEggsToGenerator(v.obj)
        C_HatchGui:ShowHatchGenUi(true,k,v.eggTbl[#v.eggTbl])
        C_Camera:ChangeMode(constDefIncubatorCam,v.area)
    end
    -- 玩家碰到自己的孵蛋器
    for k, v in pairs(C_PetMgr.allEggGens) do
        local hitEggGen = function(hitObject, hitPoint, hitNormal)
            if hitObject == localPlayer then
                hitEggGenEvent(k,v)
            end
            if hitObject.Name == 'EggInstance' and hitObject.Parent == localPlayer.Eggs then
                hitEggGenEvent(k,v)
            end
        end
        self:BindCollisionCallback(v.obj.Incubator,hitEggGen,constDefEnterCollision)
    end

    -- 玩家碰到合成室
    for ii = #self.allMergeRoom, 1, -1 do
        local hitMergeRoom = function(hitObject, hitPoint, hitNormal)
            if hitObject == localPlayer then
                C_Camera:ChangeMode(constDefHatchCam,ii)
                C_MergeGui:ShowMergeGui(true)
                if C_Guide:CheckGuideIsInState(constDefGuideState.GoToMerge) then
                    C_Guide:ProcessGuideEvent(constDefGuideEvent.goToMerge)
                end
            end
        end
        self:BindCollisionCallback(self.allMergeRoom[ii],hitMergeRoom,constDefEnterCollision)
    end

    -- 玩家碰到传送门
    for k, v in pairs(self.allPortal) do
        local hitPortal = function(hitObject, hitPoint, hitNormal)
            if hitObject == localPlayer then
                C_AudioMgr:Stop(C_AudioMgr.allAudios.sound_game_06)
                C_LoadGui:EnterTransportEvent(k)
                self:PlayerTransByDoor(k)
            end
        end
        self:BindCollisionCallback(v,hitPortal,constDefEnterCollision)
    end

    -- 玩家碰到宠物概率面板
    for k, v in pairs(self.allPetProbPnl) do
        local hitPetProb = function(hitObject, hitPoint, hitNormal)
            if hitObject == localPlayer then
                C_HatchGui:CheckIfShowAllPetProbPnl(true,k)
            end
        end   
        self:BindCollisionCallback(v,hitPetProb,constDefEnterCollision)
    end

    -- 玩家碰到关卡解锁门
    for k, v in pairs(localPlayer.Local.Independent.ZoneDoors:GetChildren()) do
        local hitZoneDoor = function(hitObject, hitPoint, hitNormal)
            if hitObject == localPlayer then
                C_NoticeGui:ShowPayForUnlock(v.areaIndex.Value,v.zoneIndex.Value)
            end
        end
        self:BindCollisionCallback(v.Door,hitZoneDoor,constDefEnterCollision)
    end

    -- 玩家碰到传送门区域
    for _, zone in pairs(self.allPortalZone) do
        local hitPortalZone = function(hitObject,hitPoint,hitNormal)
            if hitObject == localPlayer then
                C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_06)
            end
        end
        local leavePortalZone = function(hitObject,hitPoint,hitNormal)
            if hitObject == localPlayer then
                C_AudioMgr:Stop(C_AudioMgr.allAudios.sound_game_06)
            end
        end
        self:BindCollisionCallback(zone,hitPortalZone,constDefEnterCollision)
        self:BindCollisionCallback(zone,leavePortalZone,constDefLeaveCollision)
    end
end

--- 玩家通过传送门传送
--- @param _area int 地区编号
function C_CollisionMgr:PlayerTransByDoor(_area)
    local index
    local zone = C_PlayerStatusMgr.zoneIndex
    if zone > 5 then
        zone = 5
    end
    if _area == C_PlayerStatusMgr.areaIndex then
        index = 'a' .. tostring(_area) .. 'z' .. tostring(zone)
    else
        index = 'a' .. tostring(_area) .. 'z1'
        C_PlayerStatusMgr.zoneIndex = 1
    end
    local pos = C_PlayerStatusMgr.explorePos[index]
    localPlayer.Position = Vector3(pos.x, pos.y, pos.z)
    C_PlayerStatusMgr.areaIndex = _area
    C_PetMgr:CurPetsMoveToPlayerPos()
    C_PlayerStatusMgr:SetIfPlayerInMainLand(false)
    C_PlayerStatusMgr.bInHome = false
    -- 玩家可以使用自动寻矿的功能
    C_MainGui.autoFindMine.CantFindMine:SetActive(false)
end

--- 连结碰撞函数
--- @param _obj Object 连结函数的节点
--- @param _func function 函数
--- @param _collisionType number 碰撞类型：ConstDef.collisionEventEnum.Enter,Leave
function C_CollisionMgr:BindCollisionCallback(_obj,_func,_collisionType)
    if _collisionType == constDefEnterCollision then
        _obj.OnCollisionBegin:Connect(_func)
    elseif _collisionType == constDefLeaveCollision then
        _obj.OnCollisionEnd:Connect(_func)
    end
end

--- 断开特定的碰撞函数
--- @param _obj Object 连结函数的节点
--- @param _func function 函数
--- @param _collisionType number 碰撞类型：ConstDef.collisionEventEnum.Enter,Leave
function C_CollisionMgr:DisconnectCollisionCallback(_obj,_func,_collisionType)
    if _collisionType == constDefEnterCollision then
        _obj.OnCollisionBegin:Disconnect(_func)
    elseif _collisionType == constDefLeaveCollision then
        _obj.OnCollisionEnd:Disconnect(_func)
    end
end

--- 获得传送门位置
--- @param _area int 场景
function C_CollisionMgr:GetPortalPos(_area)
    return self.allPortal[_area].Position
end

--- 获得孵蛋器位置
--- @param _area int 场景
function C_CollisionMgr:GetEggGenPos(_area)
    return C_PetMgr.allEggGens[_area].obj.Position
end

--- 获得合成室位置
--- @param _area int 场景
function C_CollisionMgr:GetMergeRoomPos(_area)
    return self.allMergeRoom[_area].Position
end

--- 玩家经过商店
function C_CollisionMgr:PlayerPassStore()
    if self.bPassStore then
        return
    end
    C_NoticeGui:ImgNoticeListener('PassStore')
    self.bPassStore = true
end

return C_CollisionMgr