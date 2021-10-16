--- 游戏服务端宠物数据管理模块
-- @module Pet Manager, Server-side
-- @copyright Lilith Games, Avatar Team
-- @author Muru Chen
local S_PetMgr, this = {}, nil

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
    self.id = UUID()
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

--- 宠物类
local Pet = {}

--- 初始化宠物类
--- @param _name string 宠物名
--- @param _salePrice string 售出价格
--- @param _basePower string 基础开采效率
--- @param _realPower string 真实开采效率
--- @param _level float 宠物品阶
--- @param _rarity int 宠物的稀有度
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _index int 宠物序号
function Pet:Init(_name,_salePrice,_basePower,_realPower,_level,_rarity,_area,_zone,_index)
    self.name = _name
    self.salePrice = _salePrice
    self.basePower = _basePower
    self.realPower = _realPower
    self.level = _level
    self.rarity = _rarity
    self.curPower = self.realPower
    self.area = _area
    self.zone = _zone
    self.index = _index
    -- 宠物编号
    self.id = UUID()
    --- 宠物是否被鼓励
    self.bEncr = false
    --- 宠物受到鼓励时间点
    self.getEncrTime = 0
end

--- 创建新的宠物对象
--- @param _name string 宠物名
--- @param _salePrice string 售出价格
--- @param _basePower string 基础开采效率
--- @param _realPower string 真实开采效率
--- @param _level float 宠物品阶
--- @param _rarity int 宠物的稀有度
--- @param _area int 场景
--- @param _zone int 关卡
--- @param _index int 宠物序号
function CreateNewPet(_name,_salePrice,_basePower,_realPower,_level,_rarity,_area,_zone,_index)
    local o = {}
    setmetatable(o, {__index = Pet})
    o:Init(_name,_salePrice,_basePower,_realPower,_level,_rarity,_area,_zone,_index)
    return o
end

function S_PetMgr:Init()
    --info('S_PetMgr:Init')
    this = self
    self:InitListeners()

    self.REQUIRE_MERGE_PET_NUM = 5
    self:InitRefreshMagicMergeCDGuiEvent()
end

function S_PetMgr:Update(dt)

end

function S_PetMgr:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_PetMgr, 'S_PetMgr', this)
end

local ConstDefResultMsg = ConstDef.ResultMsgEnum    --- 处理请求结果
local constDefAchieveCategoryEnum = ConstDef.achieveCategoryEnum    --- 成就枚举
local constDefEquipmentPetEnum = ConstDef.EquipmentTypeEnum.Pet ---装备中的宠物枚举

--- 处理玩家捡到蛋
--- @param _userId string 玩家UserId
--- @param _eggTbl table 蛋的数据
function S_PetMgr:PickEggHandler(_userId,_eggTbl)
    --在玩家数据中增加蛋
    S_PlayerDataMgr:AddNewEggToItem(_userId,_eggTbl)
    --同步新数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Pick, ConstDef.PlayerPickTypeEnum.Egg, _eggTbl)
end

--- 处理玩家将蛋放进孵蛋器
--- @param _userId string 玩家UserId
--- @param _eggTbl table 蛋的id数据表
function S_PetMgr:PutEggIntoGenHandler(_userId,_eggTbl)
    --改变蛋的bInIncubator
    S_PlayerDataMgr:PutEggsIntoGen(_userId,_eggTbl)
    --同步数据到客户端
    S_PlayerDataMgr:SyncDataToClient(_userId, 'item.egg',S_PlayerDataMgr.allPlayersData[_userId].item.egg)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.PutEgg, _eggTbl)
end

--- 处理玩家装备宠物
--- @param _userId string 玩家UserId
--- @param _petId int 宠物Id
function S_PetMgr:EquipPetHandler(_userId,_petId)
    -- 默认请求结果
    local result = ConstDefResultMsg.None
    
    --定义装备条件：拥有该宠物
    local condition01 = S_PlayerDataMgr:IfItemOwned(_userId, ConstDef.ItemCategoryEnum.Pet, _petId)
    --定义装备条件：不在已跟随的宠物中
    local condition02 = not S_PlayerDataMgr:IfPetIsInCurPet(_userId, _petId)
    --定义装备条件：已经装备宠物没有达到上限
    local condition03 = S_PlayerDataMgr:IfEquippedPetLessThanCapacity(_userId)
    local weakestPetId
    if condition01 and condition02 then
        if condition03 then
            --更改玩家当前装备的宠物
            S_PlayerDataMgr:ChangeEquipment(_userId, ConstDef.EquipmentTypeEnum.Pet, _petId)
        else
            -- 卸除最弱的宠物
            weakestPetId = S_PlayerDataMgr:UnequipWeakestPet(_userId)
            --更改玩家当前装备的宠物
            S_PlayerDataMgr:ChangeEquipment(_userId, ConstDef.EquipmentTypeEnum.Pet, _petId)
        end
        --同步新数据到客户端
        S_PlayerDataMgr:SyncDataToClient(_userId, 'attribute.equipment.pet',S_PlayerDataMgr.allPlayersData[_userId].attribute.equipment.pet)
		--设置返回结果：成功
		result = ConstDefResultMsg.Succeed
    end
    if not condition03 then
        result = ConstDefResultMsg.CapacityNotEnough
    end

    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Equip, ConstDef.EquipmentTypeEnum.Pet,result, _petId,weakestPetId)
end

--- 处理宠物待机
--- @param _userId string 玩家UserId
--- @param _petId string 宠物Id
function S_PetMgr:UnequipPetHandler(_userId,_petId)
    S_PlayerDataMgr:RemoveEquipment(_userId,ConstDef.EquipmentTypeEnum.Pet,_petId)
    --同步数据到客户端
    S_PlayerDataMgr:SyncDataToClient(_userId, 'attribute.equipment.pet',S_PlayerDataMgr.allPlayersData[_userId].attribute.equipment.pet)
end

--- 处理玩家孵蛋生成新的宠物
--- @param _userId string 玩家UserId
--- @param _eggId int 蛋Id
function S_PetMgr:HatchHandler(_userId,_eggId)
    local eggArea
    local eggTbl = S_PlayerDataMgr:GetEggInformation(_userId, _eggId)
    if eggTbl then
        eggArea = eggTbl.area
    end
    local result, newPetIdTbl = self:HatchSingleEgg(_userId,_eggId)
    --同步新数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Hatch,result,newPetIdTbl,_eggId,eggArea)
end

--- 处理玩家五连抽孵蛋
--- @param _userId string 玩家UserId
--- @param _eggIdTbl table 蛋Id表
function S_PetMgr:HatchFiveHandler(_userId,_eggIdTbl)
    if #_eggIdTbl ~= 5 then
        return
    end
    local result
    local allNewPetIdTbl = {}
    local eggArea
    local eggInfo = S_PlayerDataMgr:GetEggInformation(_userId, _eggIdTbl[1])
    if eggInfo then
        eggArea = eggInfo.area
    end
    for ii = 5, 1, -1 do
        local result_, newPetIdTbl = self:HatchSingleEgg(_userId,_eggIdTbl[ii])
        result = result_
        for k, v in pairs(newPetIdTbl) do
            table.insert(allNewPetIdTbl,v)
        end
    end
    --同步新数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.HatchFive,result,allNewPetIdTbl,_eggIdTbl,eggArea)
end

--- 玩家孵单个蛋
--- @param _userId string 玩家UserId
--- @param _eggId int 蛋Id
function S_PetMgr:HatchSingleEgg(_userId,_eggId)
    local playerData = S_PlayerDataMgr.allPlayersData[_userId]
    local newPetIdTbl = {}  --- 储存新孵化宠物的ID数据表
    
    -- 默认请求结果
    local result = ConstDefResultMsg.None

    -- 定义孵化条件：当拥有的宠物数量没有超过上限
    local condition01 = S_PlayerDataMgr:IfOwnPetNumLessThanBagCapacity(_userId)
    if not condition01 then
        result = ConstDefResultMsg.CapacityNotEnough
    end
    local condition02 = S_PlayerDataMgr:IfItemOwned(_userId, ConstDef.ItemCategoryEnum.Egg, _eggId)

    if condition01 and condition02 then
        local eggTbl = playerData.item.egg[_eggId]

        local areaIndex = eggTbl.area
        local zoneIndex = eggTbl.zone
        
        -- 计算权重总数
        local totalProb = 0
        local probTable = {}
        local minProb = 999
        local minProbPetIndex = nil
	    for k, v in pairs(GameCsv.PetProperty[areaIndex][zoneIndex]) do            
            probTable[k] = v["Probability"]
            if v["Probability"] < minProb then
                minProb = v["Probability"]
                minProbPetIndex = k
            end	    	
        end

        if self.bAddRarePetProb and minProbPetIndex then
            probTable[minProbPetIndex] = 2 * probTable[minProbPetIndex]
        end

        for k, v in pairs(probTable) do
            totalProb = v + totalProb
        end

        local CreatePet = function()
            local probIndex = 0
            local petProb = math.random(100)
            local breakLoop = false

            -- 权重法判断随机数对应的宠物
            for k, v in pairs(probTable) do            
                local probWeight = 100 * v / totalProb
                if breakLoop == false then
                    if petProb > probWeight then
                        petProb = petProb - probWeight
                    else
                        breakLoop = true
                        probIndex = k
                    end
                end            
            end    

            self:GetNewPetFromEgg(_userId,areaIndex,zoneIndex,probIndex,newPetIdTbl)
            -- 成就
            S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.hatchEggNum,1)
        end

        -- 当购买了一个蛋孵三个宠物时
        if playerData.attribute.final[ConstDef.PlayerAttributeEnum.ThreePetInOneEgg] then
            local a = 3
            while a > 0 do
                CreatePet()
                a = a - 1
            end
        else
            CreatePet()
        end

        -- 从data中移除蛋
        S_PlayerDataMgr:RemoveItem(_userId,ConstDef.ItemCategoryEnum.Egg,_eggId)
        --储存数据
        --S_PlayerDataMgr:SaveGameDataAsync(_userId)
        --设置返回结果：成功
        result = ConstDefResultMsg.Succeed
    end
    return result,newPetIdTbl
end

local constDefAttribute = ConstDef.PlayerAttributeEnum

--- 获得新宠物
--- @param _userId string 玩家UserId
--- @param _area int 大场景编号
--- @param _zone int 关卡编号
--- @param _petIndex int 宠物序号
function S_PetMgr:GetNewPetFromEgg(_userId,_area,_zone, _probIndex,_newPetIdTbl)
    -- 生成新的宠物
    local petProperty = GameCsv.PetProperty[_area][_zone][_probIndex]
    local finalAttribute = S_PlayerDataMgr.allPlayersData[_userId].attribute.final
    --- 等级权重表
    local levelWeightTbl = {
        {value = 1, weight = 100},
        {value = 2, weight = finalAttribute[constDefAttribute.HatchGrowingPetProb]},
        {value = 3, weight = finalAttribute[constDefAttribute.HatchMaturePetProb]},
        {value = 4, weight = finalAttribute[constDefAttribute.HatchCompletePetProb]},
        {value = 5, weight = finalAttribute[constDefAttribute.HatchUltimatePetProb]}
    }
    local level = math.WeightRandom(levelWeightTbl)
    local basePower = petProperty["Power"]
    local pet = CreateNewPet(petProperty.PetChineseName,petProperty["SalePrice"],basePower,
                            TStringNumMul(TStringNumMul(basePower,GameCsv.LevelCoe[level]['PowerCoe']),tostring(1 + math.random(-20,20)/100)),
                            level,petProperty["RarityNum"],_area,_zone,_probIndex)
                             
    S_PlayerDataMgr:AddNewPetToItem(_userId,pet)
    if _newPetIdTbl then
        table.insert(_newPetIdTbl,pet.id)
    end
    --C_UIMgr:AddNewPetToMergeUI(pet)
end

--- 普通合成宠物
--- @param _userId string 玩家UserId
--- @param _normalMergeTbl table 普通合成宠物id的数据表
function S_PetMgr:NormalMergeHandler(_userId,_normalMergeTbl)
    -- 默认请求结果
    local result = ConstDefResultMsg.None
    
    -- 定义孵化条件：数据中的所有宠物都在玩家的item里
    local condition01 = true
    for _, v in pairs(_normalMergeTbl) do
        if not S_PlayerDataMgr:IfItemOwned(_userId, ConstDef.ItemCategoryEnum.Pet, v) then
            condition01 = false
            return
        end
    end

    local pet = S_PlayerDataMgr:GetPetInformation(_userId,_normalMergeTbl[1])

    -- 创建新的宠物数据
    local level = pet.level
    local newLevel = level + 1
    local newPet = CreateNewPet(pet.name,pet.salePrice,pet.basePower,
                                TStringNumMul(TStringNumMul(pet.basePower,GameCsv.LevelCoe[newLevel]['PowerCoe']),tostring(1 + math.random(-20,20)/100)),
                                newLevel,pet.rarity,pet.area,pet.zone,pet.index)
    local newPetId = newPet.id --新宠物Id
    -- 成就
    if newLevel == 2 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveGrowingPet,1)
    elseif newLevel == 3 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveMaturePet,1)
    elseif newLevel == 4 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveCompletePet,1)
    elseif newLevel == 5 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveUltimatePet,1)
    end

    -- 在DataStore中加入宠物
    S_PlayerDataMgr:AddNewPetToItem(_userId,newPet)
    -- 在DataStore中减去原来的宠物
    for _, v in pairs(_normalMergeTbl) do
        S_PlayerDataMgr:RemoveItem(_userId,ConstDef.ItemCategoryEnum.Pet,v)
    end

    --同步新数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --设置返回结果：成功
    result = ConstDefResultMsg.Succeed
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Merge,ConstDef.MergeCategoryEnum.normalMerge, result,newPetId,_normalMergeTbl)
end

local constDefMagicFuseNum = ConstDef.statsCategoryEnum.LimitMergeNum   ---限时合成次数枚举

--- 限时合成宠物
--- @param _limitMergeTbl table 限时合成按钮table
function S_PetMgr:LimitMergeHandler(_userId,_limitMergeTbl)
    -- 默认请求结果
    local result = ConstDefResultMsg.None

    -- 定义孵化条件：数据中的所有宠物都在玩家的item里
    local condition01 = true
    for _, v in pairs(_limitMergeTbl) do
        if not S_PlayerDataMgr:IfItemOwned(_userId, ConstDef.ItemCategoryEnum.Pet, v) then
            condition01 = false
            return
        end
    end

    -- 定义孵化条件：今日限时合成次数没有用完
    local condition02 = S_PlayerDataMgr:GetValue(_userId,constDefMagicFuseNum) > 0

    local ranIndex = math.random(1,self.REQUIRE_MERGE_PET_NUM)
    local pet = S_PlayerDataMgr:GetPetInformation(_userId,_limitMergeTbl[ranIndex])
    local maxLevel = 1
    local minLevel = 99

    -- 找到最高等级和最低等级
    for k, v in pairs(_limitMergeTbl) do
        local level = S_PlayerDataMgr:GetPetInformation(_userId,v).level
        if level > maxLevel then
            maxLevel = level
        end
        if level < minLevel then
            minLevel = level
        end
    end
    -- 计算权重总数
    local totalProb = 0
    local probTbl = {}
	for k, v in pairs(GameCsv.LimitMergeProb) do		
        totalProb = v["Probability"] + totalProb
        probTbl[k] = v		
    end
    local levelChange = 0
	local petProb = math.random(100)
    local breakLoop = false

    table.sort(probTbl,function(a,b)return (tonumber(a) < tonumber(b)) end)

    -- 按权重概率随机升级或降级
    for k,v in pairs(probTbl) do
        if not breakLoop then
            local probWeight = 100 * v["Probability"] / totalProb
			if petProb > probWeight then
                petProb = petProb - probWeight
            else
				breakLoop = true
                levelChange = v["LevelChange"]
			end
        end
    end
    local petLevel = pet.level + levelChange
    
    if petLevel < 1 then
        petLevel = 1
    elseif petLevel > 5 then
        petLevel = 5
    end

    local limitMergeResult = petLevel - maxLevel

    local newPet = CreateNewPet(pet.name,pet.salePrice,pet.basePower,
                                TStringNumMul(TStringNumMul(pet.basePower,GameCsv.LevelCoe[petLevel]['PowerCoe']),tostring(1 + math.random(-20,20)/100)),
                                petLevel,pet.rarity,pet.area,pet.zone,pet.index)
    local newPetId = newPet.id  --新宠物的id

    -- 成就
    if petLevel == 2 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveGrowingPet,1)
    elseif petLevel == 3 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveMaturePet,1)
    elseif petLevel == 4 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveCompletePet,1)
    elseif petLevel == 5 then
        S_Achieve:PlayerChangeAchieveVal(_userId,constDefAchieveCategoryEnum.haveUltimatePet,1)
    end

    -- 在DataStore中加入宠物
    S_PlayerDataMgr:AddNewPetToItem(_userId,newPet)
    -- 在DataStore中减去原来的宠物
    for _, v in pairs(_limitMergeTbl) do
        S_PlayerDataMgr:RemoveItem(_userId,ConstDef.ItemCategoryEnum.Pet,v)
    end
    -- 在DataStore减少今日限时合成次数
    S_PlayerDataMgr:ChangeStats(_userId,constDefMagicFuseNum,-1)
    -- 在DataStore中加入刷新时间
    S_PlayerDataMgr:AddMagicFuseRefreshTime(_userId)
    --同步新数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --储存数据
    S_PlayerDataMgr:SaveGameDataAsync(_userId)
    --设置返回结果：成功
    result = ConstDefResultMsg.Succeed
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Merge,ConstDef.MergeCategoryEnum.limitMerge, result, newPetId, _limitMergeTbl,limitMergeResult)
end

--- 新手指引给一个宠物
--- @param _userId string 玩家UserId
function S_PetMgr:GivePlayerPetInGuide(_userId)
    -- 默认请求结果
    local result = ConstDefResultMsg.None
    local petIdTbl = {}
    self:GetNewPetFromEgg(_userId,1,1,'17' ,petIdTbl)
    --同步数据到客户端
    S_PlayerDataMgr:SyncDataToClient(_userId, 'item.pet',S_PlayerDataMgr.allPlayersData[_userId].item.pet)
    --设置返回结果：成功
    result = ConstDefResultMsg.Succeed
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
    ConstDef.PlayerActionTypeEnum.Guide,ConstDef.guideEvent.givePet,result,petIdTbl)
end

local constDefPetItem = ConstDef.ItemCategoryEnum.Pet               ---item中的宠物
local constDefCoin = ConstDef.ServerResTypeEnum.Coin                ---资源中的金币
local constDefAddRes = ConstDef.ChangeResTypeEnum.Add               ---增加资源
local constDefSellAction = ConstDef.PlayerActionTypeEnum.SellPet    ---出售宠物行为
--- 出售宠物
--- @param _userId string 玩家UserId
--- @param _petId string 宠物Id
function S_PetMgr:SellPetHandler(_userId,_petId)
    local pet = S_PlayerDataMgr:GetPetInformation(_userId,_petId)
    --玩家获得金钱
    S_PlayerDataMgr:ChangeServerRes(_userId, constDefCoin, constDefAddRes, GameCsv.PetProperty[pet.area][pet.zone][pet.index]['SalePrice'])
    --移除宠物
    S_PlayerDataMgr:RemoveItem(_userId,constDefPetItem,_petId)
    --同步数据到客户端
    S_PlayerDataMgr:SyncAllDataToClient(_userId)
    --通知客户端结果
    NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId),constDefSellAction,_petId)
end

local constDefRefreshMagicMergeTime = ConstDef.statsCategoryEnum.RefreshMagicMergeStartTime ---开始读魔法合成cd时间枚举
local constDefMaxMagicFuseNum = ConstDef.magicFuseMaxNum    ---最大

--- 初始化魔法合成刷新cd的ui变化
function S_PetMgr:InitRefreshMagicMergeCDGuiEvent()
    local RefreshCDGui = function()
        local players = world:FindPlayers()
        for _, player in pairs(players) do
            local userId = player.UserId
            if S_PlayerDataMgr.allPlayersData[userId] then
                local refreshMagicMergeTimeTbl = S_PlayerDataMgr:GetValue(userId,constDefRefreshMagicMergeTime)
                if #refreshMagicMergeTimeTbl < 1 then
                    return
                else
                    if os.time() - refreshMagicMergeTimeTbl[1] >= 300 then
                        if S_PlayerDataMgr:GetValue(userId,constDefMagicFuseNum) < constDefMaxMagicFuseNum then
                            -- 增加新的魔法合成次数
                            S_PlayerDataMgr:ChangeStats(userId,constDefMagicFuseNum,1)
                        end
                        table.remove(refreshMagicMergeTimeTbl,1)
                        -- 同步数据到客户端
                        S_PlayerDataMgr:SyncDataToClient(userId, 'stats',S_PlayerDataMgr.allPlayersData[userId].stats)
                    end
                end
            end 
        end
    end
	local event = S_TimeMgr:CreateNewEvent(1,true,os.time(),RefreshCDGui,true)
    S_TimeMgr:AddEvent(event)
    RefreshCDGui()
end

--- 返回魔法合成第一个cd剩余时间
--- @param _userId string 用户编号
function S_PetMgr:AskForFstMagicFuseRemainTimeHandler(_userId)
    local remainTime = S_PlayerDataMgr:GetFstMagicFuseCdRemainTime(_userId)
    if remainTime ~= false then
        NetUtil.Fire_C('InitRefreshMagicMergeTimeEvent',world:GetPlayerByUserId(_userId),remainTime)
    end	
end

return S_PetMgr