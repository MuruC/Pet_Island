--- 客户端商店模块
-- @module Store, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru
local C_Store, this = {}, nil

-- 商品类
local Goods = {}
--- 初始化商品类
--- @param _type int 商品类型序号
--- @param _handler function 处理器
--- @param _level int 商品等级
--- @param _prefabName string 按钮预制体名
function Goods:Init(_type,_handler,_level,_prefabName)
    self.type = _type
    self.handler = _handler
    self.level = _level
    self.prefabName = _prefabName
end

-- 创建新的商品对象
function CreateNewGoods(_type,_handler,_level,_prefabName)
    local o = {}
    setmetatable(o, {__index = Goods})
    o:Init(_type,_handler,_level,_prefabName)
    return o
end

-- 药水类
local Potions = {}
--- 初始化药水类
--- @param _type int 药水种类
--- @param _hanlder function 处理器
--- @param _prefabName string 按钮预制体名
--- @param _coin int 所需金钱数
--- @param _diamond int 所需钻石数
function Potions:Init(_type,_handler,_prefabName,_coin,_diamond)
    self.type = _type
    self.handler = _handler
    self.prefabName = _prefabName
    self.coin = _coin
    self.diamond = _diamond
end

--- 创建新的药水对象
function CreateNewPotion(_type,_handler,_prefabName,_coin,_diamond)
    local o = {}
    setmetatable(o, {__index = Potions})
    o:Init(_type,_handler,_prefabName,_coin,_diamond)
    return o
end

-- 初始化
function C_Store:Init()
    --info('C_Store:Init')
    this = self
    self:InitListeners()

    -- 所有商品的table
    self.allGoods = {}
    -- 当前商品按钮的table
    self.curGoodsBtn = {}
    -- 所有药水的table
    self.allPotions = {}
    -- 当前药水按钮的table
    self.curPotionBtn = {}

    --self:InitAllGoods()
    self:InitAllPotions()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_Store:Update(dt)

end

--- 初始化C_Store自己的监听事件
function C_Store:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_Store, 'C_Store', this)
end

--- 在all goods的table里加入商品
function C_Store:AddNewGoods(_newGoods)
    self.allGoods[_newGoods.type] = _newGoods
end

--- 在所有药水的table里加入药水
function C_Store:AddNewPotion(_newPotion)
    self.allPotions[_newPotion.type] = _newPotion
end

--- 便捷传送
function C_Store:PortalGoods()    
    local handler = function()
        C_UIMgr.exploreBtn.LockBtn:SetActive(false)
    end
    local goods = CreateNewGoods(1,handler,1,'PortalGoods')
    self:AddNewGoods(goods)
end

--- 稀有宠物概率翻倍
function C_Store:AddRarePetProb()
    local handler = function()
        C_PetMgr.bAddRarePetProb = true
        local EliminateEffect = function()
            C_PetMgr.bAddRarePetProb = false 
        end
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(300,false,os.time(),EliminateEffect,true))
    end
    local goods = CreateNewGoods(2,handler,1,'AddRarePetProb')
    self:AddNewGoods(goods)
end

--- 一个蛋可孵化出三个宠物
function C_Store:AddPetsInOneEgg()
    local handler = function()
        C_PetMgr.bAddPetsInOneEgg = true
        local EliminateEffect = function()
            C_PetMgr.bAddPetsInOneEgg = false 
        end
        C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(300,false,os.time(),EliminateEffect,true))
    end
    local goods = CreateNewGoods(3,handler,1,'AddPetsInOneEgg')
    self:AddNewGoods(goods)
end

--- 宠物储存+100
function C_Store:AddPetBagCapacity()
    local handler = function()
        C_PetMgr.bagCapacity = 100 + C_PetMgr.bagCapacity
    end
    local goods = CreateNewGoods(4,handler,1,'AddPetBagCapacity')
    self:AddNewGoods(goods)
end

--- 获得金币+10%
function C_Store:AddCoinNumAfterMine()
    local handler = function()
        C_MineMgr.getMoneyManifaction = C_MineMgr.getMoneyManifaction + 0.1
    end
    local goods = CreateNewGoods(5,handler,1,'AddCoinNumAfterMine')
    self:AddNewGoods(goods)
end 

--- 移动速度+10%
function C_Store:AddPlayerSpd()
    local handler = function()
        localPlayer.WalkSpeed = localPlayer.WalkSpeed * 1.1
    end
    local goods = CreateNewGoods(6,handler,1,'AddPlayerSpd')
    self:AddNewGoods(goods)
end

--- 额外装备一个宠物
function C_Store:OneMoreFollowPets()
    local handler = function()
        C_PetMgr.maxCurPetNum = C_PetMgr.maxCurPetNum + 1
    end
    local goods = CreateNewGoods(7,handler,1,'OneMoreFollowPets')
    self:AddNewGoods(goods)
end

--- 初始化所有的商品
function C_Store:InitAllGoods()
    self:PortalGoods()
    self:AddRarePetProb()
    self:AddPetsInOneEgg()
    self:AddPetBagCapacity()
    self:AddCoinNumAfterMine()
    self:AddPlayerSpd()
    self:OneMoreFollowPets()

    for k, v in pairs(self.allGoods) do
        local type = v.type
        local diamondNum = PlayerCsv.Goods[type][v.level]['Diamond']
        local prefabName = v.prefabName
        local btn = C_StoreGui.goodsPanel:GetChild(prefabName)
        btn.DiamondTxt.Text = tostring(diamondNum)
        btn.BuyBtn.OnDown:Connect(function()
            NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Buy, ConstDef.GoodsTypeEnum.Goods, type)
            --[[
            if C_PlayerDataMgr.diamondNum < diamondNum then
                return
            else
                C_PlayerDataMgr:ChangeDiamond(-diamondNum)
            end
    
            v.handler()
            v.level = v.level + 1
            if not PlayerCsv.Goods[type][v.level] then
                print('get max level!')
                v.level = v.level - 1
                return
            end
            local diamondNum_ = PlayerCsv.Goods[type][v.level]['Diamond']
            btn.DiamondTxt.Text = tostring(diamondNum_)
            --]]
        end)
    end
end

--- 刷新商店事件处理器
--- @param _goodsTypeTbl table 刷新出来的商品列表的table,key是商品的索引，value是商品是否用钻石支付
function C_Store:RefreshGoodsMenuEventHandler(_goodsTypeTbl)
    -- 清空原来的列表
    for k,v in pairs(self.curGoodsBtn) do
        if v then
            v:destroy()
        end
        self.curGoodsBtn[k] = nil
    end

    local xIndex = 0
    local yIndex = 0
    for k, v in pairs(_goodsTypeTbl) do
        local goods
        local bPayByDiamond = v
        for k_, v_ in pairs(self.allGoods) do
            if k_ == k then
                goods = v_
            end
        end
        local pos = Vector3(-350 + xIndex * 350, 200 - 400 * yIndex)
        local btn = world:CreateInstance(goods.prefabName,goods.prefabName,C_UIMgr.goodsPanel,pos,EulerDegree(0,0,0))
        local diamondNum = PlayerCsv.Goods[k][goods.level]['Diamond']
        local coinNum = PlayerCsv.Goods[k][goods.level]['Money']
        if v then 
            btn.DiamondTxt.Text = tostring(diamondNum)
        else
            btn.MoneyTxt.Text = tostring(coinNum)
        end
        -- 绑定按钮事件
        btn.OnDown:Connect(function()
            --[[
            if v then
                if C_PlayerDataMgr.diamondNum < diamondNum then
                    return
                else
                    C_PlayerDataMgr:ChangeDiamond(-diamondNum)
                end
            else
                if C_PlayerDataMgr.coinNum < coinNum then
                    return
                else
                    C_PlayerDataMgr:ChangeCoin(-coinNum)
                end
            end
            goods.handler()
            btn:Destroy()
            --]]
        end)
        if xIndex < 2 then
            xIndex = xIndex + 1
        else
            xIndex = 0
            yIndex = 1
        end
        table.insert(self.curGoodsBtn,btn)
    end
end

--- 接收服务器购买商品操作回执信息
--- @param _type string 商品类别ConstDef.GoodsTypeEnum.Goods,Potion
--- @param _result number 操作结果：ConstDef.ResultMsgEnum
--- @param _goodsId int 商品id
function C_Store:ReplyBuyRequest(_type,_result, _goodsId)
    if _result == ConstDef.ResultMsgEnum.Succeed then
        if _type == ConstDef.GoodsTypeEnum.Goods then
            if _goodsId == ConstDef.GoodsCategoryEnum.canExplore then
                C_UIMgr.exploreBtn.LockBtn:SetActive(false)
            elseif _goodsId == ConstDef.GoodsCategoryEnum.addPlayerSpd then
                localPlayer.WalkSpeed = C_PlayerDataMgr:GetValue(ConstDef.PlayerAttributeEnum.PlayerSpd)
            end
        elseif _type == ConstDef.GoodsTypeEnum.Potion then
            C_BagGui:AddNewPotionBtn(_goodsId)
        end
    end
end

--- 初始化所有的药水
function C_Store:InitAllPotions()
    for i = 9, 1, -1 do
        local index = tostring(i)
        local positivePropertyIndex = PlayerCsv.Potion[index]['PositiveProperty']        
        local negativePropertyIndex = PlayerCsv.Potion[index]['NegativeProperty']
        local positiveProperty = PlayerCsv.PotionProperty[positivePropertyIndex]['Property']
        local negativeProperty = PlayerCsv.PotionProperty[negativePropertyIndex]['Property']
        local positiveEffectPercent = PlayerCsv.Potion[index]['PositiveEffectPercent']
        local negativeEffectPercent = PlayerCsv.Potion[index]['NegativeEffectPercent']
        local lastTime = PlayerCsv.Potion[index]['EffectMin'] * 60
        local coin = tostring(PlayerCsv.Potion[index]['Coin'])
        local diamond = tostring(PlayerCsv.Potion[index]['Diamond'])
        local handler = function()
            local posMag = (1 + positiveEffectPercent)
            if positiveProperty == 'MoveSpeed' then
                localPlayer.WalkSpeed = localPlayer.WalkSpeed * posMag
                local eliminateEffect = function()
                    localPlayer.WalkSpeed = localPlayer.WalkSpeed / posMag
                end
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
            elseif positiveProperty == 'Power' then
                C_PetMgr.potionPowerMag = C_PetMgr.potionPowerMag * posMag
                local eliminateEffect = function()
                    C_PetMgr.potionPowerMag = C_PetMgr.potionPowerMag / posMag
                end
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
            elseif positiveProperty == 'EggProbability' then
                C_MineMgr.potionEggMag = C_MineMgr.potionEggMag * posMag
                local eliminateEffect = function()
                    C_MineMgr.potionEggMag = C_MineMgr.potionEggMag / posMag
                end
                C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
            end

            local negMag = (1 - negativeEffectPercent)
            if negMag > 0  then
                if negativeProperty == 'MoveSpeed' then
                    localPlayer.WalkSpeed = localPlayer.WalkSpeed * negMag
                    local eliminateEffect = function()
                        localPlayer.WalkSpeed = localPlayer.WalkSpeed / negMag
                    end
                    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
                elseif negativeProperty == 'Power' then
                    C_PetMgr.potionPowerMag = C_PetMgr.potionPowerMag * negMag
                    local eliminateEffect = function()
                        C_PetMgr.potionPowerMag = C_PetMgr.potionPowerMag / negMag
                    end
                    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
                elseif negativeProperty == 'EggProbability' then
                    C_MineMgr.potionEggMag = C_MineMgr.potionEggMag * negMag
                    local eliminateEffect = function()
                        C_MineMgr.potionEggMag = C_MineMgr.potionEggMag / negMag
                    end
                    C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(lastTime,false,os.time(),eliminateEffect,true))
                end
            end
        end
        local potion = CreateNewPotion(i,handler,'PotionBtn',coin,diamond)
        self:AddNewPotion(potion)
    end
end

--- 刷新商店药水事件处理器
--- @param _tbl table 药水索引，刷新出来的商品列表的table,key是药水的索引，value是商品是否用钻石支付
--- @param _salePotion int 折扣的商品
function C_Store:RefreshPotionEventHandler(_tbl,_salePotion)
    -- 清空上一次商品列表
    for k, v in pairs(self.curPotionBtn) do
        if v then
            v:Destroy()
        end
        self.curPotionBtn[k] = nil
    end
    local xIndex = 0
    local yIndex = 0
    local numTbl = {}
    for k, v in pairs(_tbl) do
        local potions
        local bPayByDiamond = v
        local bSale = false
        if k == _salePotion then
            bSale = true
        end
        for k_, v_ in pairs(self.allPotions) do
            if k_ == k then
                potions = v_
            end
        end
        
        if potions then

            local pos = Vector2(-264 + xIndex * 273, 124 - 264 * yIndex)
            local btn = world:CreateInstance(potions.prefabName,potions.prefabName,C_UIMgr.potionPanel)
            btn.Offset = pos
            local diamondNum = potions.diamond
            local coinNum = potions.coin

            -- 促销折扣
            if bSale then
                diamondNum = TStringNumMul(tostring(0.5), diamondNum)
                coinNum = TStringNumMul(tostring(0.5), coinNum)
            end

            if v then
                btn.DiamondTxt.Text = diamondNum
            else
                btn.MoneyBg.MoneyTxt.Text = coinNum
            end
            -- 绑定按钮事件
            btn.OnDown:Connect(function()
                if v then
                    if not TStringNumCom(C_PlayerDataMgr:GetValue(ConstDef.ServerResTypeEnum.Diamond), diamondNum) then
                        return
                    else
                        NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Buy, ConstDef.GoodsTypeEnum.Goods, potions.type)
                        --C_PlayerDataMgr:ChangeDiamond(-diamondNum)
                    end
                else
                    if not TStringNumCom(C_PlayerDataMgr:GetValue(ConstDef.ServerResTypeEnum.Coin), coinNum) then
                        return
                    else
                        NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.Buy, ConstDef.GoodsTypeEnum.Goods, potions.type)
                        --C_PlayerDataMgr:ChangeCoin(-coinNum)
                    end
                end
                --C_UIMgr:AddNewPotionBtnInBag(potions.type)
                --btn:Destroy()
            end)
            table.insert(self.curPotionBtn,btn)
        end
    end
end

return C_Store