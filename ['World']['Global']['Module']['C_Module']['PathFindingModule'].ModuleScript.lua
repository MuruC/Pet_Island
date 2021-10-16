local PathFinding = {}

local path, scenePoint = nil, nil
local pointIndex = 1
local pointKey = nil

local gridSize = 0.5

--- 初始化
function PathFinding:Init()
	self._area = nil
	self._zone = nil
	self._xLPos = nil
	self._xRPos = nil
	self._zFPos = nil
	self._zBPos = nil
	self.mapDataCaches = {}
    self.guideWayPoint = {}

    --info("PathFinding:Init")
    --this = self
    self:InitListeners()

    -- 设置寻路的宠物序号
    self.findPathPetIndex = 1

    --self:CreateNavMap(1, 1)
    self:BindCheckPointOnScreenCallBack()
end

--- Update函数
-- @param dt delta time 每帧时间
function PathFinding:Update(dt)
    --[[
    local arrCurPets = C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)
    for k, v in ipairs(arrCurPets) do
      
    end
    --]]
end

--- 初始化PathFinding自己的监听事件
function PathFinding:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, PathFinding, "PathFinding", this)
end

--- 计算场地中的地图范围内的可行走区域
--- @param _xLPos float x左边坐标
--- @param _xRPos float x右边坐标
--- @param _zFPos float z前面坐标
--- @param _zBPos float z后面坐标
function PathFinding:CalculateWalkableZone()
	print("PathFinding:CalculateWalkableZone()")

	local _xLPos = self._xLPos
	local _xRPos = self._xRPos
	local _zFPos = self._zFPos
	local _zBPos = self._zBPos
	local checkRange = 0.9 * gridSize
	local tabRayHitResult = {}
	local cantCrossNodeCount = 0
	
	local function DecideIfCrossable()
		for _, hitResult in pairs(tabRayHitResult) do
			for _, v in pairs(hitResult.HitObjectAll) do
				local parentObj = v.Parent
				if parentObj and parentObj.Name == "Obstacle" then
					---这个点所在的方块不能通过
					cantCrossNodeCount = cantCrossNodeCount + 1
					return false
				end
			end
		end
		
		return true
	end
	
	local navMap = {}
    for x = _xLPos, _xRPos, -gridSize do
        for y = _zFPos, _zBPos, -gridSize do
            ---在指定位置向下生成五个射线,进行是否可以行走的判定
			tabRayHitResult = {
				Physics:RaycastAll(Vector3(x + checkRange, 100, y + checkRange),
								   Vector3(x + checkRange, -10000, y + checkRange), false),
				Physics:RaycastAll(Vector3(x + checkRange, 100, y - checkRange),
								   Vector3(x + checkRange, -10000, y - checkRange), false),
				Physics:RaycastAll(Vector3(x - checkRange, 100, y + checkRange),
								   Vector3(x - checkRange, -10000, y + checkRange), false),
				Physics:RaycastAll(Vector3(x - checkRange, 100, y - checkRange),
								   Vector3(x - checkRange, -10000, y - checkRange), false),
				Physics:RaycastAll(Vector3(x, 100, y),
								   Vector3(x, -10000, y), false)
			}
			
			local key = x.."_"..y
            navMap[key] = {id = key, x = x, y = y, pos = Vector2(x, y), canCross = DecideIfCrossable()}	
			if navMap[key].canCross == false then
				print("cantCrossNode : ", key)
			end
        end
    end
	print("cantCrossNodeCount = ", cantCrossNodeCount)
	
	self.mapDataCaches[self._area.."_"..self._zone] = navMap
	printTable(self.mapDataCaches)
end

function PathFinding:GetCurrentNavMap()
	return self.mapDataCaches[self._area.."_"..self._zone]
end

---进行每个相邻的有效的格子的计算
function PathFinding:CalculateValidNeighbor()
	local navMap = self:GetCurrentNavMap()
    for k, v in pairs(navMap) do
		local neighbor = {}
		for offsetX = -gridSize, gridSize, gridSize do
			for offsetY = -gridSize, gridSize, gridSize do
				if offsetX == 0 and offsetY == 0 then
				
				else
					-- other 8 points
					local nodeKey = (v.x + offsetX).."_"..(v.y + offsetY)
					local neighborNode = navMap[nodeKey]
					if neighborNode and neighborNode.canCross then
						table.insert(neighbor, neighborNode)
					end
				end
			end
		end
		v.neighbor = neighbor
    end
end

--- 生成场景路线
--- @param _blockKeway string 目标点所在方块索引
--- @param _petTbl table 宠物表
function PathFinding:GeneratePath(_blockKey, _petTbl)
	local navMap = self:GetCurrentNavMap()
    ---计算自己的坐标所在的方块
	local petObjPos = _petTbl.obj.Position
    local blockKey = self:GetGridKey(petObjPos.x, petObjPos.z)
    print("自己所在的格子为", blockKey)
    local startTime = os.clock()
    print(navMap[blockKey])
    if not navMap[blockKey] then
        return
    end
    local path = a_star.path(navMap[blockKey], navMap[_blockKey], navMap, true)
    for k, v in pairs(path) do
        _petTbl.path[k] = v
    end
    local endTime = os.clock()
    print("寻路完成,所用时间为", endTime - startTime)
    for k, v in pairs(_petTbl.path) do
        print(v.id, v.pos)
    end
end

-- 计算坐标所在方块
-- [_xLPos - gridSize, xLPos) => _xLPos - 0 * gridSize
-- [_xLPos - 2 * gridSize, xLPos - gridSize) => xLPos - gridSize
function PathFinding:GetGridKey(_posX, _posZ)
	local offsetGridXNum = math.floor((self._xLPos - _posX) / gridSize)
	local x_key = self._xLPos - offsetGridXNum * gridSize
	
	local offsetGridZNum = math.floor((self._zFPos - _posZ) / gridSize)
	local z_key = self._zFPos - offsetGridZNum * gridSize	
	
	local gridKey = x_key.."_"..z_key
	print("gridKey = "..gridKey)
	return gridKey
end

local constDefPetEventEnum = ConstDef.petEventCategoryEnum
local constDefMineType = ConstDef.mineCategoryEnum
local constDefGuideState = ConstDef.guideState

-- 连结鼠标点击和寻路事件
function PathFinding:BindCheckPointOnScreenCallBack()
    --鼠标左键点击
    Input.OnKeyDown:Connect(
        function()
            if not self:CheckIfCanFindPath() then
                return
            end
            if Input.GetPressKeyData(Enum.KeyCode.Mouse0) == 1 then
                --获取鼠标在屏幕上的像素位置并从摄像机向该位置打一条射线
                local mouseHit = Input.GetMouseScreenPos()
                local Ray = world.CurrentCamera:ScreenPointToRay(Vector3(mouseHit.x, mouseHit.y, 0))
                local mousePos = world.CurrentCamera:ScreenToViewportPoint(Vector3(mouseHit.x, mouseHit.y, 0))
                local bClickUI = false
                if mousePos.x < 0.26 and mousePos.x > 0.1 then
                    if mousePos.y < 0.58 and mousePos.y > 0.11 then
                        bClickUI = true
                    end
                end
                if mousePos.x < 0.99 and mousePos.x > 0.82 then
                    if mousePos.y < 0.455 and mousePos.y > 0.1 then
                        bClickUI = true
                    end
                end

                -- 当没点到UI时
                if not bClickUI then
                    --假设射线上的20米为击中点，若中间无物体阻隔则其为最终的击中点
                    self:CheckPointOnScreen(Ray)
                end
            end
        end
    )
    --触屏
    localPlayer.Local.ControlGui.TouchFig.OnTap:Connect(function(position)
        -- 新手教程中某些步骤无法自动寻路
        if not self:CheckIfCanFindPath() then
            return
        end
		
        local fingerHit = position
        local Ray = world.CurrentCamera:ScreenPointToRay(Vector3(fingerHit.x, fingerHit.y, 0))
        self:CheckPointOnScreen(Ray)
    end)
end

local constDefPetPathfindingType = ConstDef.pathFindingType.pet ---宠物寻路枚举
local constDefGuidePathfindingType = ConstDef.pathFindingType.guide ---新手引导寻路枚举

--- 寻路回调函数
--- @param _hitPos Vector2 点击屏幕的位置
function PathFinding:CheckPointOnScreen(_hitPos)
    --进行射线检测，判定中间是否有阻隔，若有则将其设为击中点
    local HitResults = Physics:RaycastAll(_hitPos.Origin, _hitPos.Origin + _hitPos.Direction * 20, false)
    local HitPosition
    local hitMine
    local FindBoss = false
    for i, v in pairs(HitResults.HitObjectAll) do
        local findMine = false
        if v.Block and v.Parent and v.Parent.level and v.Parent.posIndex then
            if C_Guide:CheckGuideIsInState(ConstDef.guideState.Dig) then
                if v.Parent and v.Parent.Name == 'GuideMineObj' then
                    findMine = true
                end
            else
                findMine = true
            end
        end
        if findMine then
            Dir = (HitResults.HitPointAll[i] - localPlayer.Position).Normalized
            HitPosition = HitResults.HitPointAll[i]
            hitMine = v
            break
        end
    end

    if HitPosition == nil then
        return
    end

    -- 当前跟随的宠物轮流设置寻路点
    local arrCurPets = C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)
    if arrCurPets[self.findPathPetIndex] then
        local petId = arrCurPets[self.findPathPetIndex]
        local digMinePosIndex = C_PlayerDataMgr:GetEquippedPetIndex(petId)
        while digMinePosIndex > 4 do
            digMinePosIndex = digMinePosIndex - 4
        end
        local mineParent = hitMine.Parent
        local areaZoneIndex = 'a' .. tostring(mineParent.areaIndex.Value) .. 'z' .. tostring(mineParent.zoneIndex.Value)
        local digMinePos
        local level = mineParent.level.Value
        if level < constDefMineType.unlockMine then
            digMinePos = C_MineMgr.allDigMinePosTbl[areaZoneIndex][mineParent.posIndex.Value][digMinePosIndex]                         
        elseif level == constDefMineType.unlockMine or level == constDefMineType.guide then
            digMinePos = mineParent.DigPos:GetChild('pos'..tostring(digMinePosIndex)).Position
        elseif level == constDefMineType.boss then
            local bossPosFolder = world.BossPos
            local pos = bossPosFolder:GetChild('pos'..tostring(math.random(1,#bossPosFolder:GetChildren()))).Position
            digMinePos = Vector3(pos.x + math.random(-2,2)/10,pos.y,pos.z + math.random(-2,2)/10)
        end
        -- 获得点击矿物边上的挖矿点的方格索引
        --local blockKey = self:GetGridKey(digMinePos.x, digMinePos.z)

        local pet = C_PetMgr.allPets[petId]
        --if pet.path then
        --    ClearTable(pet.path)
        --end
        pet.bWorking = false
        pet.workPos = digMinePos
        --self:GeneratePath(blockKey, pet)
        --pet.pointIndex = 1
        --pet.bPathFinding = true
        if self.findPathPetIndex + 1 <= #arrCurPets then
            self.findPathPetIndex = self.findPathPetIndex + 1
        else
            self.findPathPetIndex = 1
        end

        pet.workMine.level = mineParent.level.Value
        pet.workMine.obj = mineParent
        C_PetMgr:PetLeaveMine(petId)
        pet:ProcessEvent(constDefPetEventEnum.assignMine)
        C_AudioMgr:PlayChooseMineAudio(mineParent.level.Value)
        -- 生成寻路路径
        self:CreatePathFindingWayPoints(pet.obj.Position,digMinePos,constDefPetPathfindingType)
        if pet.workMine.level ~= constDefMineType.boss then
            -- 显示特效
            local fx = C_MineMgr.allFocusMineFx[areaZoneIndex][mineParent.posIndex.Value]
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
end

--- 创建新的寻路地图
--- @param _area int 场景
--- @param _zone int 关卡
function PathFinding:CreateNavMap(_area, _zone)
    if _zone == 6 then
        return
    end
	
	local posTbl = PlayerCsv.PathFinding[_area][_zone]
	self._area = _area
	self._zone = _zone
	self._xLPos = posTbl["xLPos"]
	self._xRPos = posTbl["xRPos"]
	self._zFPos = posTbl["zFPos"]
	self._zBPos = posTbl["zBPos"]
	
	local key = _area.."_".._zone
	print("PathFinding:CreateNavMap : ", key)
	local mapDataNode = self.mapDataCaches[_area.."_".._zone]
	if mapDataNode == nil then
		print("mapDataNode == nil")
		self:CalculateWalkableZone()
		self:CalculateValidNeighbor()
	else
		print("mapDataNode ~= nil")
	end
end

--- 检测是否可以寻路
function PathFinding:CheckIfCanFindPath()
    -- 新手教程中某些步骤无法自动寻路
    if  C_Guide:CheckGuideIsInState(constDefGuideState.RequestPickEgg) or 
        C_Guide:CheckGuideIsInState(constDefGuideState.PressTransBtn) or
        C_Guide:CheckGuideIsInState(constDefGuideState.PressHomeBtn) or
        C_Guide:CheckGuideIsInState(constDefGuideState.PickEgg)
    then
        return false
    end
    return true
end

--- 新手教程中自动分配新手矿
function PathFinding:AssignGuideMine()
    if C_Guide:CheckGuideIsInState(constDefGuideState.Dig) then
        if not localPlayer.Local.Independent.Guide.GuideMine then
            return
        end
        local mine = localPlayer.Local.Independent.Guide.GuideMine.GuideMineObj
        if not mine then
            return
        end
        C_AudioMgr:Play(C_AudioMgr.allAudios.sound_game_13)
        local digMinePos = mine.DigPos:GetChild('pos1').Position

        -- 获得点击矿物边上的挖矿点的方格索引
        --local blockKey = PathFinding:GetGridKey(digMinePos.x, digMinePos.z)
        local petId = C_PlayerDataMgr:GetEquipmentTable(ConstDef.EquipmentTypeEnum.Pet)[1]
        local pet = C_PetMgr.allPets[petId]
        --if pet.path then
        --    ClearTable(pet.path)
        --end
        pet.bWorking = false
        pet.workPos = digMinePos
        --PathFinding:GeneratePath(blockKey, pet)
        pet.pointIndex = 1
        pet.bPathFinding = true
        pet.workMine.level = mine.level.Value
        pet.workMine.obj = mine
        C_PetMgr:PetLeaveMine(petId)
        pet:ProcessEvent(constDefPetEventEnum.assignMine)
        -- 生成寻路路径
        PathFinding:CreatePathFindingWayPoints(pet.obj.Position,digMinePos,constDefPetPathfindingType)
        -- 显示特效
        local fx = localPlayer.Local.Independent.Guide.GuideMine.Focus
        fx:SetActive(true)
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(2,false,os.time(),
                                                    function()
                                                       if not fx then
                                                           return
                                                       end
                                                       fx:SetActive(false)
                                                    end,true))
    end
end

local function getDirBetweenObjs(srcPos, dstPos)
	return Vector3(dstPos.x - srcPos.x, dstPos.y - srcPos.y, dstPos.z - srcPos.z)	
end

local constDefInterval = 0.3

--- 生成寻路路径
--- @param srcPos Vector3 出发点
--- @param dstPos Vector3 目的点
--- @param type int 寻路类别
function PathFinding:CreatePathFindingWayPoints(srcPos,dstPos,type)
    local dist = getDirBetweenObjs(srcPos, dstPos).Magnitude
    local newDist = dist - dist % constDefInterval
    local wayPointNum = newDist/constDefInterval
    local allWayPoints = {}
    local folder = localPlayer.Local.Independent.WayPoints
    for ii = 1, wayPointNum, 1 do
        local pos = Vector3(srcPos.x + (dstPos.x - srcPos.x)/wayPointNum * ii,srcPos.y + (dstPos.y - srcPos.y)/wayPointNum * ii + 0.1,
                            srcPos.z + (dstPos.z - srcPos.z)/wayPointNum * ii)
        local wayPointObj = world:CreateInstance('WayPoint','WayPoint',folder,pos)
        table.insert(allWayPoints,wayPointObj)
    end
    if type == constDefPetPathfindingType then
        for k, v in pairs(allWayPoints) do
            C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(0.03 * k,false,C_TimeMgr.curTime,
                                                        function()
                                                            v:Destroy()
                                                        end,false))
       end
    elseif type == constDefGuidePathfindingType then
        self.guideWayPoint = allWayPoints
    end
end

--- 销毁新手引导寻路路标
function PathFinding:DestroyGuideWayPoint()
    for k, v in pairs(self.guideWayPoint) do
        v:Destroy()
    end
end

return PathFinding