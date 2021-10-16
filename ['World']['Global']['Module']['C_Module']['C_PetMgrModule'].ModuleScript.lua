--- 客户端宠物管理模块
-- @module pet manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_PetMgr, this = {}, nil

local constDefGuideState = ConstDef.guideState          ---新手指引状态
local constDefGuideEvent = ConstDef.guideEvent          ---新手指引事件
local constDefMineCategory = ConstDef.mineCategoryEnum  ---矿的类别

-- 蛋的id
local eggId = 1
-- 宠物id
local petId = 1

-- Egg类
local Egg = {}

--- 初始化蛋类
--- @param _area int  大场景编号
--- @param _zone int  小关卡编号
--- @param _obj object  蛋的物体
function Egg:Init(_area,_zone,_obj)
    self.area = _area
    self.zone = _zone
    self.obj = _obj
    self.bInIncubator = false   --- @type bool 是否放入孵蛋器
    self.id = UUID()
end

-- Pet类
local Pet = {}
local constDefPetEnum = ConstDef.EquipmentTypeEnum.Pet
local constDefPetEventEnum = ConstDef.petEventCategoryEnum

-- Pet状态
local petStandState = {}        ---静止
local petFollowUpState = {}     ---跟随
local petPlayState = {}         ---玩耍
local petWorkState = {}         ---工作
local petFindPathState = {}		---寻路

--- 初始化宠物类
--- @param _obj Object 宠物的物体对象
function Pet:Init(_obj,_id)
    self.bWorking = false
    self.obj = _obj
    -- ***寻路系统***
    -- 储存寻路上的点的table
    self.path = {}
    -- 寻路点序号
    self.pointIndex = 1
    -- 寻路点索引
    self.pointKey = nil
    -- 是否正在寻路
    self.bPathFinding = false
    -- 正在开采的矿
    self.workMine = {
        area = 0,
        zone = 0,
        posIndex = 0,
        level = 0,
        obj = nil
    }
    self.workPos = nil
	self.id = _id
	self.playPosition = nil
	self.invokePlayTime = 0
	self.curState = petPlayState
end

function Pet:ChangeState(nextState)
	local curState = self.curState
	if curState and curState.OnLeave then
		curState.OnLeave(self)
	end
	
	self.curState = nextState
	if nextState.OnEnter then
		nextState.OnEnter(self)
	end
end

function Pet:IsInState(state)
	if self.curState == state then
		return true
	end
	
	return false
end

function Pet:ProcessEvent(event)
	-- global process
	if event == constDefPetEventEnum.assignMine then
		self:ChangeState(petFindPathState)
        return
    elseif event == constDefPetEventEnum.doneMining then
        self:ChangeState(petFollowUpState)
    elseif event == constDefPetEventEnum.transport then
		self:ChangeState(petFollowUpState)
        invoke(function() 
		    self:ChangeState(petStandState) 
		    local petPos = self.obj.Position
            self.obj.Position = Vector3(petPos.x,localPlayer.Position.y,petPos.z)
		end, 0.5)
	end
	
	local curState = self.curState
	if curState and curState.OnEvent then
		curState.OnEvent(self,event)
	end
end

-- 宠物状态
local function isObjectMoving(obj)
	if obj.bPathFinding or
		obj.LinearVelocity.Magnitude > 0.1 then
		--
		return true
	end

	return false
end

local function getDirBetweenObjs(srcPos, dstPos)
	return Vector3(dstPos.x - srcPos.x, dstPos.y - srcPos.y, dstPos.z - srcPos.z)	
end

-- 静止
petStandState.OnEnter = function(pet)
	print("petStandState.OnEnter")

	local petObj = pet.obj
	local dir = getDirBetweenObjs(petObj.Position, localPlayer.Position)
	petObj.LinearVelocity = 0.01 * dir.Normalized
	petObj:PlayAnimation ('Idle',2,1,0,true,true,1)
end

petStandState.OnUpdate = function(pet)
	if not C_PlayerDataMgr:CheckIfPetIsEquipped(pet.id) then
		pet:ChangeState(petPlayState)
		return
	end
	
	if pet.bWorking then
		pet:ChangeState(petWorkState)
		return
	end
	
	if pet.bPathFinding then
		pet:ChangeState(petFindPathState)
		return
	end
	
	local petObj = pet.obj
	local dir = getDirBetweenObjs(petObj.Position, localPlayer.Position)
	if dir.Magnitude > 4 then
		pet:ChangeState(petFollowUpState)
		return
	end
end

petStandState.OnEvent = function(pet,event)
    
end

-- 跟随
petFollowUpState.OnEnter = function(pet)
	print("petFollowUpState.OnEnter")
    local petObj = pet.obj
    --petObj:StopAnimation('Idle', 2)
	petObj:PlayAnimation ('Run',2,1,0,true,true,1)
end

petFollowUpState.OnUpdate = function(pet)
	if not C_PlayerDataMgr:CheckIfPetIsEquipped(pet.id) then
		pet:ChangeState(petPlayState)
		return
	end
	
	--if pet.bPathFinding then
		--pet:ChangeState(petFindPathState)
		--return
	--end
	
	local petObj = pet.obj
    petObj:LookAt(localPlayer, Vector3.Up)
	petObj:PlayAnimation ('Run',2,1,0,false,true,1)
    local index = C_PlayerDataMgr:GetEquippedPetIndex(pet.id)
    local targetPos = calPos(3,30,index)
	local dir = getDirBetweenObjs(petObj.Position, targetPos)
	local distance = dir.Magnitude
	if distance > 10 then
		petObj.LinearVelocity = 10 * dir.Normalized
	elseif distance > 1.5 then
		petObj.LinearVelocity = 5 * dir.Normalized
	else
		if math.abs(petObj.Position.y - localPlayer.Position.y) > 0.1 then
			petObj.LinearVelocity = 5 * Vector3(0,dir.y,0).Normalized
		else
			local dir = getDirBetweenObjs(petObj.Position, localPlayer.Position)
			--print("player dist = ", dir.Magnitude)
			if distance < 0.5 then
				pet:ChangeState(petStandState)
				return
			end
		end	
	end
end

-- 玩耍(初始状态)
petPlayState.OnEnter = function(pet)
	-- 传送回家
    C_PetMgr:PetReturnHome(pet.id)
    -- 设置playPosition
    C_PetMgr:GeneratePlayPosition(pet.id)
    pet.obj.TailingFx:SetActive(false)
end
petPlayState.OnUpdate = function(pet)
	if C_PlayerDataMgr:CheckIfPetIsEquipped(pet.id) then
		pet:ChangeState(petFollowUpState)
		return
	end
	
	-- 随机地跑
	--记一个目标点，取当前坐标，取随机数算一个距离，得到目标，用vector存下来
    local petObj = pet.obj
    local playPos = pet.playPosition
	local dir = getDirBetweenObjs(petObj.Position, playPos)
    local distance = dir.Magnitude
    petObj.Forward = (playPos - petObj.Position).Normalized
	if distance > 10 then
		petObj.LinearVelocity = 4 * dir.Normalized
    elseif distance > 1.5 then
		petObj.LinearVelocity = 2 * dir.Normalized
	else
        petObj.LinearVelocity = Vector3(0,0,0)
        petObj:PlayAnimation ('Idle',2,1,0,false,true,1)
        -- 更新pet.playPosition
		local curTime = os.time()
		if curTime - pet.invokePlayTime > 4 then
			pet.invokePlayTime = curTime
			local invokeTime = math.random(0,4)
			local a = function()
				if C_PlayerDataMgr:CheckIfPetIsEquipped(pet.id) then
					return
				end
				
				if pet:IsInState(petPlayState) then
					C_PetMgr:GeneratePlayPosition(pet.id)
				end
			end
			C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(invokeTime,false,os.time(),a,true))
		end
	end	
end
petPlayState.OnLeave = function(pet)
    local obj = pet.obj
    obj.TailingFx:SetActive(true)
    obj.TailingFx.Position = obj.Position
end
-- 挖矿
petWorkState.OnEnter = function(pet)
    print("petWorkState.OnEnter")
    pet.obj:StopAnimation('Run', 2)
    pet.obj:PlayAnimation ('Excavate',2,1,0,false,true,1)
    if C_Guide:CheckGuideIsInState(constDefGuideState.Dig) then
        localPlayer.Local.Independent.Guide.GuideMine.GuideMineObj.digFx:SetActive(true)
    end
    C_AudioMgr:PlayDigAudio()
end
petWorkState.OnUpdate = function(pet)
	if not pet.bPathFinding and not pet.bWorking then
		pet:ChangeState(petFollowUpState)
		return
	end
	
	if pet.bPathFinding then
        pet:ChangeState(petFindPathState)
        return
	else
		if pet.bWorking then
			
		end
    end
    
    if not pet.workMine.obj then
        pet:ChangeState(petFollowUpState)
		return
    end

    -- 当检测到宠物不在装备中时
    if not C_PlayerDataMgr:CheckIfPetIsEquipped(pet.id) then
        C_PetMgr:PetStopMining(pet)
        pet:ChangeState(petPlayState)
    end
    
    local petObj = pet.obj
    petObj:PlayAnimation ('Excavate',2,1,0,false,true,1)
    petObj.Forward = (pet.workMine.obj.Position - petObj.Position).Normalized
end
petWorkState.OnLeave = function(pet)
    local workMine = pet.workMine
    NetUtil.Fire_S('RemovePetFromBeingDiggedMineEvent',localPlayer.UserId,pet.id,
    {area = workMine.area,zone = workMine.zone,posIndex = workMine.posIndex})
    pet.bWorking = false
    if C_Guide:CheckGuideIsInState(constDefGuideState.Dig) then
        localPlayer.Local.Independent.Guide.GuideMine.GuideMineObj.digFx:SetActive(false)
    end
end

-- 寻路
petFindPathState.OnEnter = function(pet)
    print('petFindPathState.OnEnter')
    pet.obj:PlayAnimation ('Run',2,1,0,true,true,1)
end
petFindPathState.OnUpdate = function(pet)

    local petId = pet.id
    local workMine = pet.workMine
    -- 当宠物走到一半，矿已经被挖完时
    if workMine.obj == nil then
        pet.obj.LinearVelocity = Vector3(0, 0, 0)
        pet.bWorking = false
        pet.bPathFinding = false
        pet:ChangeState(petFollowUpState)
    end

    --if pet.path and pet.path[pet.pointIndex] then
        local targetPos = pet.workPos
        --pet.pointKey = pet.path[pet.pointIndex].id
        local playerPos = pet.obj.Position
        if workMine and workMine.obj then
            targetPos = Vector3(targetPos.x, targetPos.y, targetPos.z)
            local dir = targetPos - playerPos
            local petObj = pet.obj
            petObj.LinearVelocity = Vector3.Lerp(petObj.LinearVelocity,5 * dir.Normalized,0.5)
            --petObj.Forward = (targetPos - petObj.Position).Normalized
            if dir.Magnitude < 0.1 then
                pet.obj.LinearVelocity = Vector3(0, 0, 0)
                pet.bWorking = true
                pet.bPathFinding = false
                local mineObj = workMine.obj
				if mineObj then
                -- 向服务器发送该宠物参与挖矿的信息               
                NetUtil.Fire_S('AddDidMinPlayerEvent',localPlayer.UserId,
                mineObj.areaIndex.Value,mineObj.zoneIndex.Value,mineObj.posIndex.Value,workMine.level,
                petId,C_PlayerDataMgr:GetPetInformation(petId).curPower)
                -- 设置宠物挖矿信息
                workMine.area = mineObj.areaIndex.Value
                workMine.zone = mineObj.zoneIndex.Value
                workMine.posIndex = mineObj.posIndex.Value
                -- 生成进度条
                C_MineGui:AddNewMineProgressBar(workMine.area,workMine.zone,workMine.level,workMine.posIndex)
        
        		pet:ChangeState(petWorkState)			
				else
					pet:ChangeState(petFollowUpState)
				end
            end
        end
    --end
end

petFindPathState.OnLeave = function(pet)
    pet.bPathFinding = false
end

--- 孵蛋器类
local EggGen = {}

--- 初始化孵蛋器类
--- @param _area int  场景编号
--- @param _obj Object  孵化器对象
function EggGen:Init(_area,_obj)
    -- 放在孵化器中的蛋
    self.eggTbl = {}
    self.area = _area
    self.obj = _obj
end

--- 创建新的egg对象
--- @param _area int 大场景编号
--- @param _zone int 小关卡编号
--- @param _obj object 蛋的物体
function CreateNewEgg(_area,_zone,_obj)
    local o = {}
    setmetatable(o, {__index = Egg})
    o:Init(_area,_zone,_obj)
    return o
end

--- 创建新的宠物对象
--- @param _obj Object 宠物的物体对象
function C_CreateNewPet(_obj,_id)
    local o = {}
    setmetatable(o, {__index = Pet})
    o:Init(_obj,_id)
    return o
end

--- 创建新的孵化器对象
function CreateNewEggGen(_area,_obj)
    local o = {}
    setmetatable(o,{__index = EggGen})
    o:Init(_area,_obj)
    return o
end

--- 初始化
function C_PetMgr:Init()
    --info('C_PetMgr:Init')
    this = self
    self:InitListeners()

    -- 玩家拥有过的所有蛋
    self.allEggNum = 0
    -- 玩家当前拥有的蛋table
    self.curEgg = {}
    --- 客户端储存的玩家当前拥有的所有宠物table
    self.allPets = {}
    -- 玩家当前携带的宠物
    self.arrCurPets = {}
    -- 所有孵蛋器table
    self.allEggGens = {}
    -- 当前宠物正在开采的矿，储存obj
    self.workingMineObjTbl = {}
    -- 鼓励宠物的倍率
    self.encourMag = 1.2
    -- 是否购买了一个蛋可孵出三个宠物的商品
    self.bAddPetsInOneEgg = false
    -- 背包容量
    self.bagCapacity = 200
    -- 最多跟随数量
    self.maxCurPetNum = 3
    -- 是否购买了稀有宠物概率翻倍的商品
    self.bAddRarePetProb = false
    -- 药水导致的效率倍率
    self.potionPowerMag = 1
    -- 直接拥有高级宠物的概率,由成就带来的
    self.ownHighLevelPetsProb = {
        growing = 0,
        mature = 0,
        complete = 0,
        ultimate = 0
    }
    -- 碰到的孵蛋器
    self.hitIncubator = nil
    -- 孵蛋动画
    self.allHatchTweener = {}

    -- 蛋的长度
    self.EGG_HEIGHT = 0.9872
    -- 第一个蛋在怀里的位置
    self.EGG_POS_IN_HAND = Vector3(0.1, 0.8, 0.6)
    -- 距离孵蛋器的最远距离
    self.MAX_DISTANCE_TO_EGG_GEN = 3
    -- 合成所需宠物个数
    self.REQUIRE_MERGE_PET_NUM = 3
    -- 玩家可以鼓励的最远距离
    self.MAX_ENCOUR_DIST = 2
    -- 鼓励作用持续时间
    self.ENCOUR_LAST_TIME = 3


    -- 初始化孵蛋器
    for ii = 1, 4, 1 do
        self:AddEggGen(CreateNewEggGen(ii,nil))
    end
    -- 游戏一开始先给玩家一个宠物
    --self:GetNewPet(1,'b1')
    --self:GetNewPet(1,'b1')
    --self:GetNewPet(1,'b1')
    --self:GetNewPet(1,'b1')
    --self:GetNewPet(1,'b1')
end

--- Update函数
--- @param dt delta time 每帧时间
function C_PetMgr:Update(dt)
    self:UpdatePetStates()
    self:CheckIfPlayerIsNearWorkingPet()
end

local constDefAllPetEnum = ConstDef.ItemCategoryEnum.Pet
function C_PetMgr:UpdatePetStates()
    local allPetTbl = C_PlayerDataMgr:GetItem(constDefAllPetEnum)
    for k, v in pairs(allPetTbl) do
        local pet = self.allPets[k]
		-- DataStore exist : has pet id, but can not query pet instance
		if pet then
			local curState = pet.curState
			if curState then
				curState.OnUpdate(pet)
			end
		end
    end	
end

--- 初始化C_PetMgr自己的监听事件
function C_PetMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_PetMgr, 'C_PetMgr', this)
end

--- 获得新的蛋
--- @param _newEgg table 新的蛋的表
function C_PetMgr:AddEgg(_newEgg)
    local egg = {
        area = _newEgg.area,
        zone = _newEgg.zone,
        bInIncubator = _newEgg.bInIncubator,
        id = _newEgg.id
    }
    self.curEgg[_newEgg.id] = _newEgg.obj
    -- 让服务器同步蛋的数据
    NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId,ConstDef.PlayerActionTypeEnum.Pick,
    ConstDef.PlayerPickTypeEnum.Egg,egg)
end

--- 孵化新的宠物
--- @param _newPet table 新宠物的表
--- @param _id string 宠物的id,从服务端同步过来
function C_PetMgr:AddPet(_newPet,_id)
    self.allPets[_id] = _newPet
    _newPet.curState.OnEnter(_newPet)
end

--- 建造新的孵蛋器
--- @param _newEggGen table 新的孵蛋器表
function C_PetMgr:AddEggGen(_newEggGen)
    self.allEggGens[_newEggGen.area] = _newEggGen
end

--- 设置碰到的孵蛋器
--- @param _eggGen table 碰到的孵蛋器
function C_PetMgr:SetHitIncubator(_eggGen)
    self.hitIncubator = _eggGen
end

local constDefHatchCam = ConstDef.CameraModeEnum.Hatch      ---孵化动画相机
--- 孵蛋
function C_PetMgr:HatchEgg()
    local eggGen = self.hitIncubator
    if not eggGen then
        return
    end
    if not eggGen.eggTbl[#eggGen.eggTbl] then
        return
    end
    local eggId = eggGen.eggTbl[#eggGen.eggTbl]
    if not eggId then
        warn('egg id 不存在！！')
    end
    C_HatchGui:QuitHatchGui()
    C_Camera:ResetHatchCam()
    C_Camera:ChangeMode(constDefHatchCam)
    
    local eggObj = self.curEgg[eggId]
    local eggInfo = C_PlayerDataMgr:GetEggInformation(eggId)
    local eggName = 'Egg_0' .. tostring(eggGen.area) .. '0' .. tostring(eggInfo.zone)
    local newEggObj = world:CreateInstance(eggName,'EggInstance',localPlayer.Local.Independent.HatchPlat.Eggs,
                                           Vector3(482.228, 31.8388, -367.632),EulerDegree(90,0,0))
    self:HatchEggTween(newEggObj,3)
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(0.6,false,C_TimeMgr.curTime,function() C_Camera:HatchCamTween() end,false))

	eggObj:Destroy()
    NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Hatch, eggId)
end

local constDefHatchFiveAction = ConstDef.PlayerActionTypeEnum.HatchFive ---五连抽行为
--- 五连抽孵蛋
function C_PetMgr:HatchFiveEgg()
    local eggGen = self.hitIncubator
    if not eggGen then
        return
    end
    local eggs = eggGen.eggTbl
    local allEggNum = #eggs
    if allEggNum < 5 then
        return
    end
    C_HatchGui:QuitHatchGui()
    C_Camera:ResetHatchCam()
    C_Camera:ChangeMode(constDefHatchCam)
    local eggIds = {}
    local maxEggIndex = 5
    for ii = allEggNum, allEggNum - 4, -1 do
        local eggId = eggs[allEggNum]
        local eggInfo = C_PlayerDataMgr:GetEggInformation(eggId)
        local eggObj = self.curEgg[eggId]
        local eggName = 'Egg_0' .. tostring(eggGen.area) .. '0' .. tostring(eggInfo.zone)
        ---*************************技术债！！！！！！！！！！！！！！！！****************************
        ---*************************照理来说eggObj不会不存在！！！！！！！！！！！！！*********
        if eggObj then
            eggObj:Destroy()
        end
        local pos = PlayerCsv.HatchPetAnimPos[maxEggIndex]['EggPos']
        local eggIndex = maxEggIndex
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(0.1 * (ii - 1),false,C_TimeMgr.curTime,
                                                    function()
                                                        local newEggObj = world:CreateInstance(eggName,'EggInstance',
                                                        localPlayer.Local.Independent.HatchPlat.Eggs,
                                                        Vector3(pos.x,pos.y,pos.z),EulerDegree(90,0,0))
                                                        newEggObj.Scale = 2
                                                        self:HatchEggTween(newEggObj,eggIndex)
                                                    end,false))
        table.insert(eggIds,eggs[allEggNum])
        allEggNum = allEggNum - 1
        maxEggIndex = maxEggIndex - 1
    end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,false,C_TimeMgr.curTime,function() C_Camera:HatchCamTween() end,false))
    NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, constDefHatchFiveAction, eggIds)
end

--- 获得当前宠物蛋总数
function C_PetMgr:GetCurEggNum()
    local curEggNum = 0
    for k, v in pairs(self.curEgg) do
        if v ~= nil then
            curEggNum = curEggNum + 1
        end
    end
    return curEggNum
end

--- 获得一个新的宠物蛋
--- @param Object _obj 碰撞的宠物蛋
function C_PetMgr:GetNewEgg(_obj)
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_16)
    local eggPos = Vector3(self.EGG_POS_IN_HAND.x,self.EGG_POS_IN_HAND.y,self.EGG_POS_IN_HAND.z)
    local eggFolder = localPlayer.Eggs
    eggPos.y = eggPos.y + self.EGG_HEIGHT * #eggFolder:GetChildren()
    local area = _obj.area.Value
    local zone = _obj.zone.Value
    local eggName = 'Egg_0' .. tostring(area) .. '0' .. tostring(zone)
    local newEggObj = world:CreateInstance(eggName,'EggInstance')
	newEggObj:SetParentTo(eggFolder,eggPos,EulerDegree(270,0,0))
    newEggObj.bPick.Value = true
	_obj:Destroy()
    local newEgg = CreateNewEgg(C_PlayerStatusMgr.areaIndex,C_PlayerStatusMgr.zoneIndex,newEggObj)
    self:AddEgg(newEgg)

    localPlayer.Avatar:SetBlendSubtree(Enum.BodyPart.UpperBody, 3)
    localPlayer.Avatar:PlayAnimation('FarmHoldOn', 3, 1, 0, true, true, 1)

    -- 当处于新手教程中
    if C_Guide:CheckGuideIsInState(constDefGuideState.PickEgg) then
        C_Guide:ProcessGuideEvent(constDefGuideEvent.getEgg)
    end

    -- 检测玩家负重
    C_PlayerStatusMgr:CheckPlayerBurden()
end

--- 将宠物蛋放进孵蛋器
--- @param Object _eggGen 碰到的孵蛋器
function C_PetMgr:PutEggsToGenerator(_eggGen)
    local eggTbl = C_PlayerDataMgr:GetValue(ConstDef.ItemCategoryEnum.Egg)
    local bHasEgg = false --- @type bool 背包里是否有需要放进孵蛋器的蛋
    local putIntoGenEggTbl = {}
    for k,v in pairs(eggTbl) do
        local areaIndex = v.area
        if _eggGen.areaIndex.Value == areaIndex and not v.bInIncubator then
            bHasEgg = true
            local eggGenPos = self.allEggGens[areaIndex].obj.Position
            local newEggPos = Vector3(eggGenPos.x,eggGenPos.y,eggGenPos.z)
            local eggObj = self.curEgg[v.id]    --- @type Object 蛋的节点
            newEggPos.y = newEggPos.y + 1.8211
            eggObj.Position = newEggPos
            eggObj:SetParentTo(localPlayer.Independent,newEggPos,EulerDegree(90,0,0))
            table.insert(putIntoGenEggTbl,v.id)
        end
    end
    -- 将数据同步给服务器
    if bHasEgg then
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_03)
        NetUtil.Fire_S('PlayerRequestEvent', localPlayer.UserId, ConstDef.PlayerActionTypeEnum.PutEgg, putIntoGenEggTbl)
    end

    localPlayer.Avatar:StopAnimation('FarmHoldOn', 3)
    --检测负重
    C_PlayerStatusMgr:CheckPlayerBurden()
end

--- 玩家鼓励宠物
function C_PetMgr:PlayerEncouragePet()
    for k, v in pairs(self.arrCurPets) do
        if v.bWorking then
            local petPos = v.obj.Position
            local playerPos = localPlayer.Position
            local dist = GetDistance(petPos.x,petPos.y,petPos.z,playerPos.x,petPos.y,playerPos.z)
            if dist < self.MAX_ENCOUR_DIST then
                v.curPower = v.realPower * self.encourMag
                local restorePower = function()
                    v.curPower = v.realPower
                end
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(self.ENCOUR_LAST_TIME,false,C_TimeMgr.curSecond,restorePower,true))
                C_PlayerStatusMgr:ChangeDataInAchievement(3, 1)
            end
        end
    end
end

--- 宠物瞬移到玩家身边
function C_PetMgr:CurPetsMoveToPlayerPos()
    for k, v in pairs(C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)) do
        local playerPos = localPlayer.Position
        self.allPets[v].obj.Position = Vector3(playerPos.x + k * 0.5, playerPos.y, playerPos.z + k * 0.5)
        self.allPets[v]:ProcessEvent(constDefPetEventEnum.transport)
    end
end

local constDefPetPathfindingType = ConstDef.pathFindingType.pet ---宠物寻路枚举
--- 给宠物分配最近的矿
function C_PetMgr:AssignNearestMineToPet()
    -- 当玩家在城里的时候返回
    if C_PlayerStatusMgr.bInHome and not C_PlayerStatusMgr.bInMainIsland then
        print("player is in the home!")
        return
    end
    local arrCurPets = C_PlayerDataMgr:GetValue(ConstDef.EquipmentTypeEnum.Pet)
    -- 当前没有装备宠物时，则直接跳过
    if #arrCurPets < 1 then
        print("The is no following pet!")
        return
    end
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_13)

    local petNum = #arrCurPets
    local nearestMine = nil
    local nearestDist = 11
    local playerPos = localPlayer.Position
    local petTbl = {}
    local foundNotWorking = false
    local petIndex
    local id
    for k, v in pairs(arrCurPets) do
        local pet = C_PetMgr.allPets[v]
        if pet:IsInState(petFollowUpState) or pet:IsInState(petStandState) then
            petTbl = pet
            petIndex = k
            id = v
            foundNotWorking = true
            break
        end
    end

    if not foundNotWorking then
        petIndex = math.random(1,petNum)
        id = arrCurPets[petIndex]
        petTbl = C_PetMgr.allPets[id]
    end

    local digMinePos
    if C_PlayerStatusMgr.bInMainIsland then
        local bossPosFolder = world.BossPos
        local pos = bossPosFolder:GetChild('pos'..tostring(math.random(1,#bossPosFolder:GetChildren()))).Position
        digMinePos = Vector3(pos.x + math.random(-2,2)/10,pos.y,pos.z + math.random(-2,2)/10)
        nearestMine = world.Boss
    else
        local area = C_PlayerStatusMgr.areaIndex
        local zone = C_PlayerStatusMgr.zoneIndex
        local fileName = 'a' .. tostring(area) .. 'z' .. tostring(zone)
        local file = world.Mine:GetChild(fileName)

        for k, v in pairs(file:GetChildren()) do
            local minePos = v.Position       
            local dist = GetDistance(minePos.x,minePos.y,minePos.z,playerPos.x,playerPos.y,playerPos.z)
            if dist < nearestDist then
                nearestDist = dist
                nearestMine = v
            end
        end
        if not nearestMine then
            print('there is no nearest mine!')
            return
        end
        
        
        local digMinePosIndex = petIndex
        while digMinePosIndex > 4 do
            digMinePosIndex = digMinePosIndex - 4
        end
        digMinePos = C_MineMgr.allDigMinePosTbl[fileName][nearestMine.posIndex.Value][digMinePosIndex]
    end
    
    -- 获得像素点的方格索引
    --local blockKey = PathFinding:GetGridKey(digMinePos.x,digMinePos.z)

    if petTbl.path then
        ClearTable(petTbl.path)
    end
    petTbl.bWorking = false
    --PathFinding:GeneratePath(blockKey,petTbl)
    petTbl.workPos = digMinePos
    petTbl.pointIndex = 1
    petTbl.bPathFinding = true

    petTbl.workMine.level = nearestMine.level.Value
    petTbl.workMine.obj = nearestMine
    C_PetMgr:PetLeaveMine(id)
    petTbl:ProcessEvent(constDefPetEventEnum.assignMine)
    -- 生成寻路路径
    PathFinding:CreatePathFindingWayPoints(petTbl.obj.Position,digMinePos,constDefPetPathfindingType)
    
    if petTbl.workMine.level ~= constDefMineCategory.boss then
        -- 显示特效
        local fx = C_MineMgr.allFocusMineFx['a' .. tostring(nearestMine.areaIndex.Value) .. 'z' .. tostring(nearestMine.zoneIndex.Value)][nearestMine.posIndex.Value]
        if fx then
            fx:SetActive(true)
            fx.clickTime.Value = os.time()
            local event = C_TimeMgr:CreateNewEvent(1,true,os.time(),nil,true)
            local removeFx = function()
                if os.time() - fx.clickTime.Value >= 2 then
                    fx:SetActive(false)
                    C_TimeMgr:RemoveEvent(event.id)
                end
            end
            event.handler = removeFx
            C_TimeMgr:AddEvent(event)
        end
    end
end

local constDefExploreState = ConstDef.guideState.Explore    ---新手指引中自由探索状态
local constDefGetFiveSamePetsEvent = ConstDef.guideEvent.getFiveSamePets    ---获得五个相同的宠物

--- 接收服务器孵化宠物信息
--- @param _result number 回执信息：ConstDef.ResultMsgEnum
--- @param _petIdTbl table 新孵化宠物的id
--- @param _eggId string 被孵化的蛋的id
--- @param _eggArea int 蛋的所在场景，方便索引孵蛋器
function C_PetMgr:HatchReplyHandler(_result,_petIdTbl, _eggId,_eggArea)
    local PetInfo = PlayerCsv.PetProperty
    if _result == ConstDef.ResultMsgEnum.Succeed then
        local modelNameTbl = {}
        for _, v in pairs(_petIdTbl) do
            table.insert(modelNameTbl,self:HatchSinglePet(v))
        end
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(3,false,os.time(),
                                                    function()
                                                        self:CreatePetAnimation(modelNameTbl) 
														C_NoticeGui:HatchResultNtc(self:GetHighestRarityAmongPets(_petIdTbl))
                                                    end,true))
        if _eggId and _eggArea then
            -- 从孵蛋器表中的蛋数据删除这个蛋id
            local eggTblInGen = self.allEggGens[_eggArea].eggTbl
            for ii = #eggTblInGen, 1, -1 do
                if _eggId == eggTblInGen[ii] then
                    table.remove(eggTblInGen,ii)
                end
            end
        end

        -- 当处于新手指引状态时        
        if C_Guide:CheckGuideIsInState(constDefExploreState) then
            if C_PlayerDataMgr:CheckIfHaveFiveSamePet() then
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,false,os.time(),
                                                            function()
                                                                C_Guide:ProcessGuideEvent(constDefGetFiveSamePetsEvent) 
                                                            end,true))
            end
        end
    end
end

--- 接收服务器五连抽孵化宠物信息
--- @param _result number 回执信息：ConstDef.ResultMsgEnum
--- @param _petIdTbl table 新孵化宠物的id
--- @param _eggIdTbl table 被孵化的蛋的table
--- @param _eggArea int 蛋的所在场景，方便索引孵蛋器
function C_PetMgr:HatchFiveReplyHandler(_result,_petIdTbl, _eggIdTbl,_eggArea)
    if #_petIdTbl > 0 then
        local modelNameTbl = {}
        for _, v in pairs(_petIdTbl) do
            table.insert(modelNameTbl,self:HatchSinglePet(v))
        end
        local event = C_TimeMgr:CreateNewEvent(0.05,true,C_TimeMgr.curTime,nil,true)
        local handler = function()
            if #localPlayer.Local.Independent.HatchPlat.Eggs:GetChildren() < 5 then
                return
            end
            self:CreatePetAnimation(modelNameTbl)
			local highestRarity = self:GetHighestRarityAmongPets(_petIdTbl)
			C_NoticeGui:HatchResultNtc(highestRarity)
            
            C_TimeMgr:RemoveEvent(event.id)
        end
        event.handler = handler
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(3,false,os.time(),
                                                    function() C_TimeMgr:AddEvent(event) handler() end,true))
        if _eggIdTbl and _eggArea then
            for _, eggId in pairs(_eggIdTbl) do
                -- 从孵蛋器表中的蛋数据删除这个蛋id
                local eggTblInGen = self.allEggGens[_eggArea].eggTbl
                for ii = #eggTblInGen, 1, -1 do
                    if eggId == eggTblInGen[ii] then
                        table.remove(eggTblInGen,ii)
                    end
                end
            end
        end
        -- 当处于新手指引状态时        
        if C_Guide:CheckGuideIsInState(constDefExploreState) then
            if C_PlayerDataMgr:CheckIfHaveFiveSamePet() then
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(1,false,os.time(),
                                                            function()
                                                                C_Guide:ProcessGuideEvent(constDefGetFiveSamePetsEvent) 
                                                            end,true))
            end
        end
    end
end

--- 比较宠物列表中最高的稀有度
--- @param _petIdTbl table 宠物id表
function C_PetMgr:GetHighestRarityAmongPets(_petIdTbl)
    local highestRarity = 1
    for k, v in pairs(_petIdTbl) do
        local rarity = C_PlayerDataMgr:GetPetInformation(v).rarity
        if rarity > highestRarity then
            highestRarity = rarity
        end
    end
    return highestRarity
end

--- 生成单个宠物
--- @param petId string 宠物id
function C_PetMgr:HatchSinglePet(petId)
    local PetInfo = PlayerCsv.PetProperty
    local pet = C_PlayerDataMgr:GetPetInformation(petId)
    local modelName = PetInfo[pet.area][pet.zone][pet.index]['ModelName'] .. '0'.. tostring(pet.level)
    local obj = world:CreateInstance(modelName,'PetInstance',world,self:GetPetHomePos(pet.area),EulerDegree(0,0,0))
    self:CreateTailingFx(obj,pet.area,pet.level)
    obj.Scale = PlayerCsv.LevelCoe[pet.level]['SizeCoe']
    self:AddPet(C_CreateNewPet(obj,petId),petId)           
    -- 增加宠物按钮
    C_BagGui:AddNewPetButton(C_BagGui:CreateNewPetButton(petId, nil))
    C_MergeGui:AddNewPetButton(C_MergeGui:CreateNewPetButton(petId, nil))
    --- 按钮布局
    C_BagGui:ArrangeBtnInBag()
    C_MergeGui:ArrangeBtnInMerge(C_MergeGui.petBtnList)
    C_BagGui:SetPetBtnPnlRange()
    C_MergeGui:SetPetBtnPnlRange()
    C_MergeGui:MarkFiveSamePet()
    return modelName
end

local constDefNormalMerge = ConstDef.MergeCategoryEnum.normalMerge  ---普通合成的枚举
local constDefMagicMerge = ConstDef.MergeCategoryEnum.limitMerge    ---魔法合成枚举
--- 接收服务器合成宠物信息
--- @param _mergeType number 合成的类型ConstDef.MergeCategoryEnum
--- @param _result number 回执信息：ConstDef.ResultMsgEnum
--- @param _newPetId string 新合成出的宠物的id
--- @param _mergeTbl table 参与合成的宠物id
--- @param _limitMergeResult int 魔法合成等级变化结果
function C_PetMgr:MergeReplyHandler(_mergeType,_result,_newPetId,_mergeTbl,_limitMergeResult)
    -- 生成新的宠物模型
    local PetInfo = PlayerCsv.PetProperty
    local pet = C_PlayerDataMgr:GetPetInformation(_newPetId)
    local modelName = PetInfo[pet.area][pet.zone][pet.index]['ModelName'] .. '0'.. tostring(pet.level)
    local obj = world:CreateInstance(modelName,'PetInstance',world,
    self:GetPetHomePos(pet.area),EulerDegree(0,0,0))
    self:CreateTailingFx(obj,pet.area,pet.level)
    self:AddPet(C_CreateNewPet(obj,_newPetId),_newPetId)

    -- 移除用于合成的宠物数据
    for _, v in pairs(_mergeTbl) do
        self:RemovePet(v)
    end
    -- 生成新的宠物按钮
    C_BagGui:AddNewPetButton(C_BagGui:CreateNewPetButton(_newPetId, nil))
    C_MergeGui:AddNewPetButton(C_MergeGui:CreateNewPetButton(_newPetId, nil))
    --- 按钮布局
    C_BagGui:ArrangeBtnInBag()
    C_MergeGui:ArrangeBtnInMerge(C_MergeGui.petBtnList)
    C_MergeGui:SetPetBtnPnlRange()
    C_BagGui:SetPetBtnPnlRange()
    C_MergeGui:ClearChosenPetsImgInMergeRoom()
    C_MergeGui:MarkFiveSamePet()
    self:CreateNewFusedPetAnim(modelName)

    if _mergeType == constDefMagicMerge then
        C_MergeGui:AddRefreshMagicMergeTime()
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(5,false,os.time(),
                           function()  C_NoticeGui:FuseResultNtc(_limitMergeResult) end,true))
    end
end

--- 移除宠物相关数据
--- @param _petId string 宠物id
function C_PetMgr:RemovePet(_petId)
    self.allPets[_petId].obj:Destroy()  -- 销毁宠物的模型
    self.allPets[_petId] = nil
    -- 移除宠物按钮
    C_BagGui:RemovePetBtn(_petId)
    C_MergeGui:RemovePetBtn(_petId)
end

--- 接收服务器将蛋放进孵蛋器信息
--- @param _eggIdTbl table 放进的蛋的id数据表
function C_PetMgr:PutEggsIntoGenHandler(_eggIdTbl)
    local allEggs = C_PlayerDataMgr:GetValue(ConstDef.ItemCategoryEnum.Egg)
    for _,v in pairs(_eggIdTbl) do
        local area = allEggs[v].area
        local zone = allEggs[v].zone
        table.insert(self.allEggGens[area].eggTbl,v)
        C_BagGui:RemoveEggBtnInBag(area,zone)
    end
    C_HatchGui:CheckIfShowHatchFiveBtn()
end

--- 接收服务器装备宠物信息
--- @param _petId string 宠物id
--- @param _weakestPetId string 卸除的最弱宠物id
function C_PetMgr:ReplyEquipPet(_result,_petId,_weakestPetId)
    local pet = self.allPets[_petId]
    if pet:IsInState(petPlayState) then
        local playerPos = localPlayer.Position
        pet.obj.Position = Vector3(playerPos.x + math.random(1,3) * 0.5, playerPos.y, playerPos.z + math.random(1,3) * 0.5)
        pet:ProcessEvent(constDefPetEventEnum.transport)
    end
    if _weakestPetId then
        C_BagGui:UnequipWeakestPetHandler(_weakestPetId)
        self:UnequipPetHandler(_petId)
    end
end

--- 卸除宠物处理器
--- @param _petId string 宠物id
function C_PetMgr:UnequipPetHandler(_petId)
    local pet = self.allPets[_petId]
    if pet:IsInState(petWorkState) then
        self:PetLeaveMine(_petId)
        self:PetStopMining(pet)
    end
    self:PetReturnHome(_petId)
end

--- 根据Datastore初始化宠物
function C_PetMgr:InitAllPets()
    local PetInfo = PlayerCsv.PetProperty
    local allPets = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Pet)
    for k, v in pairs(allPets) do
        local pet = C_PlayerDataMgr:GetPetInformation(k)
		if not pet then
			break
		end
        local modelName = PetInfo[pet.area][pet.zone][pet.index]['ModelName'] .. '0'.. tostring(pet.level)
        local obj = world:CreateInstance(modelName,'PetInstance',world,C_PetMgr:GetPetHomePos(pet.area),EulerDegree(0,0,0))
        self:CreateTailingFx(obj,pet.area,pet.level)
        obj.Scale = PlayerCsv.LevelCoe[pet.level]['SizeCoe']
        self:AddPet(C_CreateNewPet(obj,k),k)
    end
    C_BagGui:InitAllPetBtn()
    C_MergeGui:InitAllPetBtn()
    C_MergeGui:MarkFiveSamePet()		--标记所有可以普通合成的宠物
end

--- 获得宠物出生地
--- @param _area int 场景
function C_PetMgr:GetPetHomePos(_area)
    return PlayerCsv.HomePos[C_PlayerStatusMgr.playerIndex][_area]['Pos']
end

--- 根据Datastore初始化蛋
function C_PetMgr:InitAllEggs()
    local allEggs = C_PlayerDataMgr:GetItem(ConstDef.ItemCategoryEnum.Egg)
    local eggInHandNum = 0  --手里蛋的个数
    for k, v in pairs(allEggs) do
        local eggName = 'Egg_0' .. tostring(v.area) .. '0' .. tostring(v.zone)
        local newEggObj = world:CreateInstance(eggName,'EggInstance')
        newEggObj.bPick.Value = true
        self.curEgg[k] = newEggObj
        if v.bInIncubator then  -- 放进孵蛋器里的蛋
            local eggGenPos = self.allEggGens[v.area].obj.Position
            local newEggPos = Vector3(eggGenPos.x,eggGenPos.y,eggGenPos.z)
            newEggPos.y = newEggPos.y + 1.8211
            newEggObj.Position = newEggPos
            newEggObj:SetParentTo(localPlayer.Independent,newEggPos,EulerDegree(90,0,0))
            table.insert(self.allEggGens[v.area].eggTbl,k)
        else    -- 捧在手里的蛋
            local eggPos = Vector3(self.EGG_POS_IN_HAND.x,self.EGG_POS_IN_HAND.y,self.EGG_POS_IN_HAND.z)
            eggPos.y = eggPos.y + eggInHandNum * self.EGG_HEIGHT
            newEggObj:SetParentTo(localPlayer.Eggs,eggPos,EulerDegree(270,0,0))
            eggInHandNum = eggInHandNum + 1
        end
    end
    if eggInHandNum > 0 then
        localPlayer.Avatar:SetBlendSubtree(Enum.BodyPart.UpperBody, 3)
        localPlayer.Avatar:PlayAnimation('FarmHoldOn', 3, 1, 0, true, true, 1)
    end
    -- 生成UI
    C_BagGui:InitAllEggBtn()
    -- 检测玩家负重
    C_PlayerStatusMgr:CheckPlayerBurden()
end

--- 移除所有正在工作的宠物
function C_PetMgr:RemoveAllWorkingPets()
    local allCurPets = C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)
    local mines = {}
    for _, id in pairs(allCurPets) do
        local pet = self.allPets[id]
        local mine = {
            area = pet.workMine.area,
            zone = pet.workMine.zone,
            posIndex = pet.workMine.posIndex
        }
        table.insert(mines,mine)
        pet.bWorking = false
        pet.bPathFinding = false
        pet.workMine.obj = nil
        pet.obj:PlayAnimation('Idle',2,1,0,false,true,1)
    end
    -- 服务器储存的被挖掘的矿数据中移除该玩家
    NetUtil.Fire_S('RemovePlayerFromCurDiggingMineEvent',localPlayer.UserId,mines)
end

--- 宠物离开矿
--- @param string _petId 宠物id
function C_PetMgr:PetLeaveMine(_petId)
    local pet = self.allPets[_petId]
    local workMine = pet.workMine
    local area = workMine.area
    local zone = workMine.zone
    local posIndex = workMine.posIndex
    local allCurPetId = C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)
    local bFindPetDiggingSameMine = false
    for k, v in pairs(allCurPetId) do
        if v ~= _petId then
            local pet_ = self.allPets[v]
            if not pet_:IsInState(petWorkState) then
                break
            end
            local workMine_ = pet_.workMine
            if zone == workMine_.zone and posIndex == workMine_.posIndex then
                bFindPetDiggingSameMine = true
            end
        end
    end
    if not bFindPetDiggingSameMine then
        C_MineGui:RemoveMineProgressBar(area,zone,posIndex)
    end
end

--- 宠物传送回家
--- @param _petId string  宠物id
function C_PetMgr:PetReturnHome(_petId)
    local petInfo = C_PlayerDataMgr:GetPetInformation(_petId)
    local area = petInfo.area
    local pet = self.allPets[_petId]
    pet.obj.Position = self:GetPetHomePos(area)
end

--- 宠物中断开采
--- @param _petId string 宠物id
function C_PetMgr:PetStopMining(_pet)
    _pet.bWorking = false
    _pet.bPathFinding = false
    local workMine = _pet.workMine
    workMine.obj = nil
    local mine = {
        area = workMine.area,
        zone = workMine.zone,
        posIndex = workMine.posIndex
    }
    NetUtil.Fire_S('PetStopDiggingEvent',localPlayer.UserId,_pet.id,mine)
end

--- 随机生成playPosition
--- @param _petId string 宠物id
function C_PetMgr:GeneratePlayPosition(_petId)
    local bGeneratePos = false

    local pet = self.allPets[_petId]
    --------***********技术债！！！！！***********---------
	if not pet then
		return
    end
    
    local petObj = pet.obj
    local petPos = petObj.Position
    local playPos
    while not bGeneratePos do
        local ranX = math.randomFloat(-5,5)
        local ranZ = math.randomFloat(-5,5)
        playPos = Vector3(petPos.x + ranX, petPos.y, petPos.z + ranZ)
        local hitResult = Physics:Raycast(Vector3(playPos.x,playPos.y+10,playPos.z), Vector3(playPos.x,playPos.y-3,playPos.z), false)
        if hitResult.HitObject and hitResult.HitObject.Name == 'Fudao' then
            bGeneratePos = true
        end
    end
    pet.playPosition = playPos
    petObj.Forward = playPos
    petObj:StopAnimation('Idle', 2)
    petObj:PlayAnimation ('Run',2,1,0,true,true,1)
end

--- 计算坐标
function calPos(_r,_a,_index)
    local r = _r    -- 半径
    local a = math.rad(_a)    -- 夹角
    local playerPos = localPlayer.Position
    local x = playerPos.x
    local y = playerPos.y
    local z = playerPos.z
    --相对坐标
    local frstPetPos_ = Vector3(r, y, 0)
    local scdPetPos_ = Vector3(r * math.cos(a), y, r * math.sin(a))
    local trdPetPos_ = Vector3(r * math.cos(a), y, -1 * r * math.sin(a))
    --绝对坐标
    local absAngle = math.rad(localPlayer.Rotation.y)
    local frstPetPos =  Vector3(frstPetPos_.x * math.cos(absAngle) - frstPetPos_.z * math.sin(absAngle) + x,
                        frstPetPos_.y,
                        frstPetPos_.z * math.cos(absAngle) + frstPetPos_.x * math.sin(absAngle) + z)
    local scdPetPos  =  Vector3(scdPetPos_.x * math.cos(absAngle) - scdPetPos_.z * math.sin(absAngle) + x,
                        scdPetPos_.y,
                        scdPetPos_.z * math.cos(absAngle) + scdPetPos_.x * math.sin(absAngle) + z)
    local trdPetPos =   Vector3(trdPetPos_.x * math.cos(absAngle) - trdPetPos_.z * math.sin(absAngle) + x,
                        trdPetPos_.y,
                        trdPetPos_.z * math.cos(absAngle) + trdPetPos_.x * math.sin(absAngle) + z)
    if _index == 1 then
        return frstPetPos
    elseif _index == 2 then
        return scdPetPos
    else
        return trdPetPos
    end
end

---宠物完成挖矿
function C_PetMgr:PetDoneMining(_area,_zone,_posIndex)
	local allCurPetId = C_PlayerDataMgr:GetValue(constDefPetEnum)
	for _, v in pairs(allCurPetId) do
		local pet = self.allPets[v]
		local workMine = pet.workMine
		if workMine.area == _area and workMine.zone == _zone and workMine.posIndex == _posIndex then
			pet.bWorking = false
		end
	end
end

---新手教程送的宠物
function C_PetMgr:GivePlayerPetInGuide(_result,_petIdTbl)
    self:HatchReplyHandler(_result,_petIdTbl)
    for k, v in pairs(_petIdTbl) do
        local pet = self.allPets[v]
        -- 请求服务器装备宠物
        NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Equip, 
        ConstDef.EquipmentTypeEnum.Pet, v)
    end
end

--- 检测玩家是否在工作中的宠物附近
function C_PetMgr:CheckIfPlayerIsNearWorkingPet()
    local arrCurPets = C_PlayerDataMgr:GetValue(ConstDef.EquipmentTypeEnum.Pet)
    local findWorkingPet = false
    for k, v in pairs(arrCurPets) do
        local pet = self.allPets[v]
        if not pet then
            break
        end
        if pet:IsInState(petWorkState) and 
        getDirBetweenObjs(localPlayer.Position, pet.obj.Position).Magnitude < 5 then
            findWorkingPet = true
        end
    end
    C_MainGui:ShowEncrBtn(findWorkingPet)
end

--- 返回附近工作中的宠物id
function C_PetMgr:ReturnNearbyWorkingPets()
    local arrCurPets = C_PlayerDataMgr:GetValue(ConstDef.EquipmentTypeEnum.Pet)
    local nearbyPets = {}
    for k, v in pairs(arrCurPets) do
        local pet = self.allPets[v]
        if pet:IsInState(petWorkState) and 
        getDirBetweenObjs(localPlayer.Position, pet.obj.Position).Magnitude < 5 then
            local workMine = pet.workMine
            nearbyPets[v] = {
                area = workMine.area,
                zone = workMine.zone,
                posIndex = workMine.posIndex
            }
        end
    end
    return nearbyPets
end

--- 解锁关卡矿的宠物中断开采
function C_PetMgr:PetStopUnlockLevelMine()
    local arrCurPets = C_PlayerDataMgr:GetValue(ConstDef.EquipmentTypeEnum.Pet)
    for k, v in pairs(arrCurPets) do
        local pet = self.allPets[v]
        if pet:IsInState(petWorkState) then
            if pet.workMine.level == constDefMineCategory.unlockMine then
                pet:ChangeState(petFollowUpState)
            end
        end
    end
end

--- 服务器反馈出售宠物处理器
--- @param _petId string 宠物id
function C_PetMgr:SellPetHandler(_petId)
    self.allPets[_petId].obj:Destroy()
    self.allPets[_petId] = nil
end

--- 孵蛋动画
--- @param eggObj Object 蛋
--- @param eggNum int 蛋的序号
function C_PetMgr:HatchEggTween(eggObj,eggNum)
    local pos = PlayerCsv.HatchPetAnimPos[eggNum]['EggPos']
    Egg.Position = pos
    Egg.Rotation = EulerDegree(90,0,0)
    local eggUpTweener = Tween:TweenProperty(eggObj, 
                                            {Position = Vector3(pos.x, pos.y + 4, pos.z) , 
                                            Rotation = EulerDegree(270,180,0)}, 0.6, Enum.EaseCurve.CubicOut)
    local eggDownTweener = Tween:TweenProperty(eggObj, 
                                              {Position = pos}, 
                                               0.3, Enum.EaseCurve.CubicIn)
    local eggLeftTweener = Tween:TweenProperty(eggObj, 
                                              {Rotation = EulerDegree(260,0,0)}, 
                                               0.2, Enum.EaseCurve.BackOut)
    local eggSmallLeftTweener01 = Tween:TweenProperty(eggObj, 
                                                   {Rotation = EulerDegree(245,0,0)}, 
                                                    0.08, Enum.EaseCurve.BackOut)
    local eggSmallRightTweener01 = Tween:TweenProperty(eggObj, 
                                                    {Rotation = EulerDegree(275,0,0)}, 
                                                     0.08, Enum.EaseCurve.BackOut)
    local eggSmallLeftTweener02 = Tween:TweenProperty(eggObj, 
                                                     {Rotation = EulerDegree(255,0,0)}, 
                                                      0.08, Enum.EaseCurve.BackOut)
    local eggSmallRightTweener02 = Tween:TweenProperty(eggObj, 
                                                      {Rotation = EulerDegree(265,0,0)}, 
                                                       0.08, Enum.EaseCurve.BackOut)                                                    
    local eggSmallLeftTweener03 = Tween:TweenProperty(eggObj, 
                                                     {Rotation = EulerDegree(275,0,0)}, 
                                                      0.08, Enum.EaseCurve.BackOut)
    local eggSmallRightTweener03 = Tween:TweenProperty(eggObj, 
                                                      {Rotation = EulerDegree(305,0,0)}, 
                                                       0.08, Enum.EaseCurve.BackOut)
    local eggRightTweener = Tween:TweenProperty(eggObj, 
                                              {Rotation = EulerDegree(290,0,0)}, 
                                               0.2, Enum.EaseCurve.BackOut)
    local eggSmallLeftTweener04 = Tween:TweenProperty(eggObj, 
                                                     {Rotation = EulerDegree(285,0,0)}, 
                                                      0.08, Enum.EaseCurve.BackOut)
    local eggSmallRightTweener04 = Tween:TweenProperty(eggObj, 
                                                      {Rotation = EulerDegree(295,0,0)}, 
                                                       0.08, Enum.EaseCurve.BackOut)

    eggUpTweener.OnComplete:Connect(function()
        eggDownTweener:Play()
        eggUpTweener:Destroy()
    end)
    eggDownTweener.OnComplete:Connect(function()
        eggLeftTweener:Play()
		eggObj.AngularVelocity = Vector3(0,0,0)
		eggDownTweener:Destroy()
    end)
    eggLeftTweener.OnComplete:Connect(function()
        eggSmallRightTweener01:Play()
    end)
    eggSmallRightTweener01.OnComplete:Connect(function()
        eggSmallLeftTweener01:Play()
    end)
    eggSmallLeftTweener01.OnComplete:Connect(function()
        eggSmallRightTweener02:Play()
    end)
    eggSmallRightTweener02.OnComplete:Connect(function()
        eggSmallLeftTweener02:Play()
    end)
    eggSmallLeftTweener02.OnComplete:Connect(function()
        eggRightTweener:Play()
    end)
    eggRightTweener.OnComplete:Connect(function()
        eggSmallLeftTweener03:Play()
    end)
    eggSmallLeftTweener03.OnComplete:Connect(function()
        eggSmallRightTweener03:Play()
    end)
    eggSmallRightTweener03.OnComplete:Connect(function()
        eggSmallLeftTweener04:Play()
    end)
    eggSmallLeftTweener04.OnComplete:Connect(function()
        eggSmallRightTweener04:Play()
    end)
    eggSmallRightTweener04.OnComplete:Connect(function()
        eggLeftTweener:Play()
    end)
    local allHatchTweener = {eggLeftTweener,eggSmallRightTweener01,eggSmallLeftTweener01,eggSmallRightTweener02,eggSmallLeftTweener02,
    eggRightTweener,eggSmallLeftTweener03,eggSmallRightTweener03,eggSmallLeftTweener04,eggSmallRightTweener04}
    for _, v in pairs(allHatchTweener) do
        table.insert(self.allHatchTweener,v)
    end
    eggUpTweener:Play()
	eggObj.AngularVelocity = Vector3(100,100,100)
end

--- 生成宠物动画
--- @param _pets Table 宠物table:aktpName
function C_PetMgr:CreatePetAnimation(_pets)
    local petObjs = {}
    local hatchPlat = localPlayer.Local.Independent.HatchPlat
    if #hatchPlat.Eggs:GetChildren() < 1 then
		return
	end
    local fx = hatchPlat.FX_Hatch
    fx:SetActive(true)
    for k, v in pairs(hatchPlat.Eggs:GetChildren()) do
        v:Destroy()
    end 
    local posConfig = PlayerCsv.HatchPetAnimPos
    for k, v in pairs(_pets) do
        local pos = posConfig[k]['PetPos']
        local rot = EulerDegree(0, -90, 0)
        local obj = world:CreateInstance(v,'PetInstance',hatchPlat.Pets,pos,rot)
        obj:PlayAnimation ('Idle',2,1,0,true,true,1)
        table.insert(petObjs,obj)
    end
    C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_04)
    C_NoticeGui:NoticeListener('HatchPet')
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(0.5,false,C_TimeMgr.curTime,function() fx:SetActive(false) end,false))
    C_HatchGui:CheckIfShowContinueHatchGui(true)
    if #self.hitIncubator.eggTbl < 1 then
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,C_TimeMgr.curTime,
                           function()
                                for k, v in pairs(localPlayer.Local.Independent.HatchPlat.Pets:GetChildren()) do
                                    v:Destroy()
                                end
                                self:ClearHatchTweeners()
                                C_HatchGui:CheckIfShowContinueHatchGui(false)
                                C_Guide:ProcessGuideEvent(constDefGuideEvent.hatchEgg)
                           end,
                           false))
    end
end

--- 清除孵蛋动画
function C_PetMgr:ClearHatchTweeners()
    for k, v in pairs(self.allHatchTweener) do
        if v.Destroy then
            v:Destroy()
        end
        self.allHatchTweener[k] = nil
    end
end

--- 合成宠物动画
--- @param _petNames table 宠物aktp的名字
function C_PetMgr:FusePetTween(_petNames)
    C_Camera:ChangeMode(ConstDef.CameraModeEnum.Fuse)
    C_MergeGui:QuitMergePetPanel()
    local fuseFlat = localPlayer.Local.Independent.FusePlat
    local oldPosY = 10.8167
    local newPosY = 5.8167
    local timeInterval = 0.2
    for k, v in pairs(_petNames) do
        local petPos
        local petRot
        if k == 1 then
            petPos = Vector3(-6.9357, oldPosY, -1.8288)
            petRot = EulerDegree(0, -161.787, 0)
        elseif k == 2 then
            petPos = Vector3(-6.4232, oldPosY, -2.5692)
            petRot = EulerDegree(0, -164.545, 0)
        elseif k == 3 then
            petPos = Vector3(-5.5123, oldPosY, -2.92)
            petRot = EulerDegree(0, 177.6514, 0)
        elseif k == 4 then
            petPos = Vector3(-4.5684, oldPosY, -2.5692)
            petRot = EulerDegree(0, 161.2544, 0)
        else
            petPos = Vector3(-3.9783, oldPosY, -1.8288)
            petRot = EulerDegree(0, 151.9477, 0)
        end
        local petObj = world:CreateInstance(v,'PetInstance',fuseFlat.FusePets,petPos,petRot)
        petObj.Scale = 1
        local objTweener = Tween:TweenProperty(petObj, 
                                              {Position = Vector3(petPos.x,newPosY,petPos.z)}, 
                                               0.2, Enum.EaseCurve.CubicIn)
        objTweener.OnComplete:Connect(function()
            petObj:PlayAnimation ('Idle',2,1,0,true,true,1)
            if k == 5 then
                fuseFlat.AllPetShownFx:SetActive(true)
            end
            objTweener:Destroy()
        end)
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(timeInterval * k,false,C_TimeMgr.curTime,function() if objTweener then objTweener:Play() end end,false))
    end
end

--- 生成合成宠物动画
--- @param _modelName string 模型名称
function C_PetMgr:CreateNewFusedPetAnim(_modelName)
    local fuseFlat = localPlayer.Local.Independent.FusePlat
    local newPetPos = Vector3(-5.5123, 11, -2.0923)
    local newPet = world:CreateInstance(_modelName,'PetInstance',fuseFlat.NewPet,newPetPos,EulerDegree(0, 180, 0))
    local showNewPet = function()
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_05)
        newPet.Position = Vector3(newPetPos.x,5.8167,newPetPos.z)
        fuseFlat.AllPetShownFx:SetActive(false)
        for _, pet in pairs(fuseFlat.FusePets:GetChildren()) do
            pet:Destroy()
        end
        newPet.Scale = 2
        newPet:PlayAnimation ('Idle',2,1,0,true,true,1)
        C_MergeGui:CheckIfShowQuitFuseAnimBtn(true)
    end
    local showNewPetFx = function()
        fuseFlat.FuseNewPetFx:SetActive(true)
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(0.3,false,C_TimeMgr.curTime,showNewPet,false))
    end
    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(4,false,os.time(),showNewPetFx,true))
end

--- 生成拖尾粒子
--- @param _petObj Object 宠物节点
--- @param _area int 场景
--- @param _level int 等级
function C_PetMgr:CreateTailingFx(_petObj,_area,_level)
    world:CreateInstance(tostring(_area)..'.'..tostring(_level),'TailingFx',_petObj)
end

--- 检测是否有其他宠物一起挖同样的矿
--- @param pet table 宠物
function C_PetMgr:CheckIfOtherPetDigSameMine(pet)
    local id = pet.id
    local mine = pet.workMine
    if mine.obj then
        for k, v in pairs(C_PlayerDataMgr:GetValue(constDefPetEnum)) do
            if v ~= id then
                local workMine = self.allPets[v].workMine
                if workMine.obj and workMine.zone == mine.zone and workMine.posIndex == mine.posIndex then
                    return true
                end
            end
        end
    end
    return false
end

return C_PetMgr