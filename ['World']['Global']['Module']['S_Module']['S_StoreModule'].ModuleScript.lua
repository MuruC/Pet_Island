--- 游戏服务端玩家数据管理模块
-- @module Player Data Manager, Server-side
-- @copyright Lilith Games, Avatar Team
-- @author Muru Chen
local S_Store, this = {}, nil

function S_Store:Init()
    --info('S_Store:Init')
    this = self
    self:InitListeners()
    
    -- 客户端可以购买的药水列表
    self.potionTbl = {}
    -- 打折的药水
    self.salePotion = nil

    -- 每次刷新药水的数量
    self.POTION_NUM_IN_STORE = 6
    -- 刷新药水时间间隔，单位：秒
    self.REFRESH_POTION_TIME = 600

    self:RequestClientRefreshPotion()
end

function S_Store:Update(dt)

end

function S_Store:InitListeners()
    EventUtil.LinkConnects(world.S_Event, S_Store, 'S_Store', this)
end

--- 客户端刷新商店里的药水
function S_Store:RequestClientRefreshPotion()
    local RefreshPotionByTime = function()
        local i = self.POTION_NUM_IN_STORE
        local numTbl = {}
        ClearTable(self.potionTbl)
        local potionNumTbl = {}
        for n = 9, 1, -1 do
            table.insert(numTbl,n)
        end
        while i > 0 do
            local index = math.random(1,#numTbl)
            local prob = math.random(1,100)
            if prob >= 50 then
                self.potionTbl[numTbl[index]] = true --用钻石支付
            else
                self.potionTbl[numTbl[index]] = false --用coin支付
            end
            table.remove(numTbl,index)
            table.insert(potionNumTbl,numTbl[index])
            i = i - 1
        end
        self.salePotion = potionNumTbl[math.random(1,#potionNumTbl)]
        local Players = world:FindPlayers()
        for k, v in pairs(Players) do
            NetUtil.Fire_C('RefreshPotionEvent',v,self.potionTbl,self.salePotion)
        end
    end
    RefreshPotionByTime()
    S_TimeMgr:AddEvent(S_TimeMgr:CreateNewEvent(self.REFRESH_POTION_TIME,true,os.time(),RefreshPotionByTime,true))
end

--- 处理玩家购买
--- @param _userId string 玩家UserId
--- @param _category string 购买类别: ConstDef.GoodsTypeEnum
--- @param _goodsID int 购买物品ID
function S_Store:BuyHandler(_userId,_category,_goodsID)
    -- 默认请求结果
    local result = ConstDef.ResultMsgEnum.None
    local goodsInfoTbl
    local curRes -- 获取玩家拥有的资源数目
    local needRes -- 获取玩家所需要的资源数目
    local serverRes = S_PlayerDataMgr.allPlayersData[_userId].resource.server
    local bUseDiamond = false --是否消耗钻石
    local level -- 购买物品的等级
    local limitTime -- buff持续时间
    if _category == ConstDef.GoodsTypeEnum.Goods then
        -- 获取等级
        level = S_PlayerDataMgr:GetBuffValue(_userId,ConstDef.GoodsTypeEnum.Goods,
        _goodsID,ConstDef.buffValTypeEnum.Level)
        if not level then
            level = 1
        else
            level = level + 1
        end

        -- 获取表格
        goodsInfoTbl = GameCsv.Goods[_goodsID][level]
        -- 获取当前资源
        curRes = serverRes.diamond
        needRes = goodsInfoTbl['Diamond']
        bUseDiamond = true
        limitTime = goodsInfoTbl['LimitTime'] * 60  --单位：秒

    elseif _category == ConstDef.GoodsTypeEnum.Potion then
        limitTime = goodsInfoTbl['EffectMin'] * 60  --单位：秒
        goodsInfoTbl = GameCsv.Potion[_goodsID]
        if self.potionTbl[_goodsID] then
            -- 用钻石支付
            curRes = serverRes.diamond
            needRes = goodsInfoTbl['Diamond']
            bUseDiamond = true
        else
            -- 用金钱支付
            curRes = serverRes.coin
            needRes = goodsInfoTbl['Coin']
        end
        if _goodsID == self.salePotion then
            needRes = TStringNumDiv(needRes, tostring(2))
        end
    end
    -- 定义购买条件：够钱
    local condition01 = TStringNumCom(curRes, needRes)
    if condition01 then
        --扣除玩家的相应资源
        if bUseDiamond then
            S_PlayerDataMgr:ChangeServerRes(_userId, ConstDef.ServerResTypeEnum.Diamond, ConstDef.ChangeResTypeEnum.Sub, needRes)
        else
            S_PlayerDataMgr:ChangeServerRes(_userId, ConstDef.ServerResTypeEnum.Coin, ConstDef.ChangeResTypeEnum.Sub, needRes)
        end

        -- 当购买商品，添加商品到buff
        if _category == ConstDef.GoodsTypeEnum.Goods then
            S_PlayerDataMgr:AddNewBuff(_userId, ConstDef.buffCategoryEnum.Goods, _goodsID, level, GameCsv.Goods[_goodsID][level]['LimitTime'])
        -- 当购买药水，添加药水到库存
        elseif _category == ConstDef.GoodsTypeEnum.Potion then 
            S_PlayerDataMgr:AddNewItem(_userId, ConstDef.ItemCategoryEnum.Potion, _goodsID)
        end

        --同步新数据到客户端
        S_PlayerDataMgr:SyncAllDataToClient(_userId)
        --储存数据
        S_PlayerDataMgr:SaveGameDataAsync(_userId)
		--设置返回结果：成功
		result = ConstDef.ResultMsgEnum.Succeed
    else
        --设置返回结果：所需资源不足
		result = ConstDef.ResultMsgEnum.ResNotEnough
    end

    --通知客户端结果
    if _category == ConstDef.GoodsTypeEnum.Goods then
        --当购买商品时
        NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
        ConstDef.PlayerActionTypeEnum.Buy, ConstDef.GoodsTypeEnum.Goods,result, _goodsID)
    else
        --当购买药水时
        --当购买商品时
        NetUtil.Fire_C('ReplyRequestEvent',world:GetPlayerByUserId(_userId), 
        ConstDef.PlayerActionTypeEnum.Buy, ConstDef.GoodsTypeEnum.Potion,result, _goodsID)
    end	
end

--- 处理玩家使用药水
--- @param _userId string 玩家UserId
--- @param _itemID int 物品ID
function S_Store:UsePotionHandler(_userId, _itemId)
	--默认请求结果
    local result = ConstDef.ResultMsgEnum.None
    
    --定义使用条件：拥有该药水
    local condition01 = S_PlayerDataMgr:IfItemOwned(_userId, 'potion', _itemId)
    if condition01 then
        --更改玩家药水
        S_PlayerDataMgr:EquipPotion(_userId, _itemId)
        --同步新数据到客户端
        S_PlayerDataMgr:SyncAllDataToClient(_userId)
        --设置返回结果：成功
		result = ConstDef.ResultMsgEnum.Succeed
    else
        --设置返回结果：尚未拥有请求装备的物件
		result = ConstDef.ResultMsgEnum.ItemNotOwned
    end
    --通知客户端结果
    --NetUtil.Fire_C('ReplyRequestEvent', world:GetPlayerByUserId(_userId), ConstDef.PlayerActionTypeEnum.Equip, result, _category, _itemID)
end

--- 处理玩家捡到资源
--- @param _userId string 玩家UserId
--- @param _pickType number 捡到资源的类别ConstDef.PlayerPickTypeEnum
function S_Store:PickResource(_userId,_pickType)
    if _pickType == ConstDef.PlayerPickTypeEnum.Coin then
        --更改玩家金钱资源
        S_PlayerDataMgr:ChangeServerRes(_userId, ConstDef.ServerResTypeEnum.Coin, ConstDef.ChangeResTypeEnum.Add, '2000')
        --同步新数据到客户端
        S_PlayerDataMgr:SyncDataToClient(_userId, "resource.server.coin", S_PlayerDataMgr.allPlayersData[_userId].resource.server.coin)
    elseif _pickType == ConstDef.PlayerPickTypeEnum.Diamond then
        --更改玩家钻石资源
        S_PlayerDataMgr:ChangeServerRes(_userId, ConstDef.ServerResTypeEnum.Diamond, ConstDef.ChangeResTypeEnum.Add, '1')
        --同步新数据到客户端
        S_PlayerDataMgr:SyncDataToClient(_userId, "resource.server.diamond", S_PlayerDataMgr.allPlayersData[_userId].resource.server.diamond)
	elseif _pickType == ConstDef.PlayerPickTypeEnum.Potion then
        local potionIndex = math.random(1,ConstDef.POTION_TYPE_NUM)
        --更改玩家药水
        S_PlayerDataMgr:AddNewItem(_userId, ConstDef.ItemCategoryEnum.Potion, potionIndex)
        --同步新数据到客户端
        S_PlayerDataMgr:SyncDataToClient(_userId, "item.potion", S_PlayerDataMgr.allPlayersData[_userId].item.potion)
        --通知客户端结果
        NetUtil.Fire_C('ReplyRequestEvent', world:GetPlayerByUserId(_userId), 
        ConstDef.PlayerActionTypeEnum.Pick, ConstDef.PlayerPickTypeEnum.Potion, 
        potionIndex)
	end
end

return S_Store