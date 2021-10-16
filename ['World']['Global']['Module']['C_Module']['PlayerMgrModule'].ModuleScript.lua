--- 游戏客户端主逻辑
-- @module Game Manager, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author XXX, XXXX
local PlayerMgr, this =
    {
        dt = 0,
        tt = 0,
        isRun = false,
		--- @type bool 预初始化是否完成
        isEndPreInit = false,
        --- @type bool 玩家数据是否下载完成
        isReady = false,
        --- @type table 本玩家的数据
        myData = {},
        --- @type table 数据改变响应事件
        dataChangeEvent = {}
    },
    nil

--- 初始化
function PlayerMgr:Init()
    localPlayer.Local.LoadingGui:SetActive(true)
    --info("PlayerMgr:Init")
    this = self
    self:InitListeners()
	C_LoadGui:Init()
    AnimationMain:Init()
    PlayerCsv:Init()
    Notice:Init()
	C_UIMgr:Init()
	C_TransGui:Init()
    C_PlayerStatusMgr:Init()
    C_PetMgr:Init()
	C_TimeMgr:Init()
	C_PlayerStatusMgr:AskForPlayerIndex()
    PathFinding:Init()
    C_PlayerDataMgr:Init()
	C_MineMgr:Init()
	C_StoreGui:Init()
    C_Store:Init()
    C_BagGui:Init()
    C_MergeGui:Init()
    C_ReplyRequest:Init()
	C_MainGui:Init()
	C_MineGui:Init()
	C_Guide:Init()
	C_HatchGui:Init()
	C_NoticeGui:Init()
	C_AchieveGui:Init()
	C_Camera:Init()
	C_AudioMgr:Init()
    -- 数据改变响应事件，保证此为最后一个初始化
	self:DataChangeEventInit()
	--向服务器请求玩家数据
	NetUtil.Fire_S('PlayerRequestEvent',localPlayer.UserId, ConstDef.PlayerActionTypeEnum.AskData)
end

--- 数据改变事件初始化
function PlayerMgr:DataChangeEventInit()
    self.dataChangeEvent = 
	{
		--属性相关
		--玩家属性
		attribute = {
		--TODO: 设置玩家属性
			--基础属性
			base = {
				--便捷传送
				canExplore = nil,
				--稀有宠物概率倍率
				rarePetProbMagnification = nil,
				--一个蛋可以孵出三个宠物
				threePetInOneEgg = nil,
				--宠物储存容量
				petStorage = nil,
				--获得金币倍率
				getCoinMagnification = nil,
				--移动速度
				playerSpd = nil,
				--跟随宠物最大数量
				maxCurPet = nil,
				-- 生产蛋的机率
				getEggProb = nil,
				-- 钻石掉率
				getDiamondProb = nil,
				-- 鼓励效率
				encrEffect = nil,
				-- 单个金矿的金币数
				coinNumInGoldMine = nil,
				-- 药水掉落的机率
				getPotionProb = nil,
				-- 直接孵化出成长期宠物的概率
				hatchGrowingPetProb = nil,
				-- 直接孵化出成熟期宠物的概率
				hatchMaturePetProb = nil,
				-- 直接孵化出完全体宠物的概率
				hatchCompletePetProb = nil,
				-- 直接孵化出究极体宠物的概率
				hatchUltimatePetProb = nil,
			},

			--计算后的最终属性
			final = {
				--便捷传送
				canExplore = nil,
				--稀有宠物概率倍率
				rarePetProbMagnification = nil,
				--一个蛋可以孵出三个宠物
				threePetInOneEgg = nil,
				--宠物储存容量
				petStorage = nil,
				--获得金币倍率
				getCoinMagnification = nil,
				--移动速度
				playerSpd = nil,
				--跟随宠物最大数量
				maxCurPet = nil,
				-- 生产蛋的机率
				getEggProb = nil,
				-- 钻石掉率
				getDiamondProb = nil,
				-- 鼓励效率
				encrEffect = nil,
				-- 单个金矿的金币数
				coinNumInGoldMine = nil,
				-- 药水掉落的机率
				getPotionProb = nil,
				-- 直接孵化出成长期宠物的概率
				hatchGrowingPetProb = nil,
				-- 直接孵化出成熟期宠物的概率
				hatchMaturePetProb = nil,
				-- 直接孵化出完全体宠物的概率
				hatchCompletePetProb = nil,
				-- 直接孵化出究极体宠物的概率
				hatchUltimatePetProb = nil,
			},

			-- 当前装备
			equipment = {
				-- 当前装备的宠物
				pet = {
					parentTableEvent = function() C_MainGui:RefreshEquippedPetIcon() end
				},
				-- 当前使用的药水，属性：id,开始使用时间
				potion = {},
			},

			--拥有的buff
			buff = {
				achieve = {},	-- 成就产生的buff
				goods = {}		-- 商品产生的buff
			}
		},
		
		--资源相关 数值类
		--玩家拥有的资源
		resource = {
			--基于服务端的资源
			server = {
                coin = function() C_MainGui:RefreshResInfo() C_MainGui:OnCoinChanged()end,
				diamond = function() C_MainGui:RefreshResInfo() C_MainGui:OnDiamondChanged() end,
			},
			--基于客户端的资源
			client = {
				guideState = nil,
				guideTask = nil,
			}
		},
		
		--物品相关
		--玩家拥有的物品
		item = {
			potion = {}, 	--背包中的药水
			egg = {},		--捡到的蛋
			pet = {},		--所有拥有的宠物,属性：id,name,等级,真实power,实际power
			zones = {		--可前往的场景
				parentTableEvent = function() C_TransGui:RefrshExploreBtns() end
			},		
		},

		--数据统计
		stats = {
			--TODO: 需要统计的数据
			collectEggs = nil,		--收集到蛋的数量
			playTime = nil,			--游玩的总时长
			unlockZones = nil,		--解锁的区域数量
			achieveLevel = {},		--所有成就等级
			achieveCurValue = {},	--所有成就当前进度
			ownPetNum = nil,		--拥有的宠物数量
			limitMergeNum = function() C_MergeGui:RefreshLimitMergeGui() end,
			refreshMagicMergeStartTime = nil	--开始读魔法合成cd时间
		},
	}

	-- 初始化成就的等级和当前数值
	local achieveLevel = self.dataChangeEvent.stats.achieveLevel
	local achieveCurValue = self.dataChangeEvent.stats.achieveCurValue
	for ii = ConstDef.ACHIEVE_TYPE_NUM, 1, -1 do
		table.insert(achieveLevel,nil)
		table.insert(achieveCurValue,function() C_AchieveGui:UpdateAchieveProgGui(ii) end)
	end

end

--- 初始化Game Manager自己的监听事件
function PlayerMgr:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, PlayerMgr, "PlayerMgr", this)
end

--- Update函数
-- @param dt delta time 每帧时间
function PlayerMgr:Update(dt)
	C_LoadGui:Update(dt)
    if not self.isReady then
        return
    end

    -- TODO: 其他客户端模块Update
    C_PlayerStatusMgr:Update(dt)
    C_PetMgr:Update(dt)
    C_UIMgr:Update(dt)
    C_TimeMgr:Update(dt)
    PathFinding:Update(dt)
    C_PlayerDataMgr:Update(dt)
    C_MineMgr:Update(dt)
	C_Store:Update(dt)
	C_MineGui:Update(dt)
	C_GuideGui:Update(dt)
	C_Guide:Update(dt)
	
end

function PlayerMgr:StartUpdate()
    --info("PlayerMgr:StartUpdate")
    if self.isRun then
        warn("PlayerMgr:StartUpdate 正在运行")
        return
    end

    self.isRun = true

    while (self.isRun) do
        self.dt = wait()
        self.tt = self.tt + self.dt
        self:Update(self.dt)
    end
end

function PlayerMgr:StopUpdate()
    --info("PlayerMgr:StopUpdate")
    self.isRun = false
end

--- 接收服务器同其向客户端同步数据的信息
--- @param _key string 键名
--- @param _value mixed 修改值
function PlayerMgr:SyncDataEventHandler(_key, _value)
	local eventTable = table.nums(self.myData) ~= 0 and self.dataChangeEvent or nil

	ValueChangeUtil.ChangeValue(self.myData, _key, _value, eventTable)

	--若为预初始化阶段的数据同步（即初次数据同步）
	if not self.isEndPreInit then
		self.isEndPreInit = true
		--进行第二阶段的初始化
		self:EndLoadDataHandler()
	end
end

--- 接收客户端数据下载完成的信息
function PlayerMgr:EndLoadDataHandler()
    --修改玩家状态
	self.isReady = true
	
    C_UIMgr:InitClientUI()				--初始化UI
	--C_PetMgr:InitAllPets()				--初始化宠物
	--C_PetMgr:InitAllEggs()				--初始化蛋
	C_MainGui:RefreshResInfo()			--刷新主界面的数据显示
	C_BagGui:InitAllPotionBtn()			--初始化药水
	C_MainGui:RefreshEquippedPetIcon()	--初始化主界面已装备宠物icon
	C_MergeGui:RefreshLimitMergeGui()	--初始化限时合成次数限时
	C_AchieveGui:InitAllAchieveGuis()	--初始化成就
	C_Guide:InitGuideState()			--初始化新手指引状态
	C_TransGui:RefrshExploreBtns()		--刷新便捷传送按钮显示
	C_CollisionMgr:Init()
	C_PlayerStatusMgr:InitShowEncrFxEvent()
	self:InitPlayerIndexEvent()			--初始化玩家编号
	C_MergeGui:RequestFstMagicMergeCDTime()	--请求第一个魔法合成cd剩余时间
	C_MainGui:InitResNum()
	--绑定碰撞事件
	--self:StartUpdate()
    --初始化外观
    --AppearanceMgr:InitAppearance()

	---- TODO: 其他数据加载完成后的处理
	C_TimeMgr:AddEvent(C_TimeMgr:CreateNewEvent(3,false,os.time(),
												function() C_LoadGui:StopMainLoadingTweener() 
														   C_AudioMgr:ChangeBgm(ConstDef.bgmEnum.mainIsland) end,
												true))
	
end

function PlayerMgr:InitPlayerIndexEvent()
	local event = C_TimeMgr:CreateNewEvent(1,true,os.time(),nil,true)
	local initPlayerIndexEvent = function()
		if C_PlayerStatusMgr.playerIndex == 0 then
			return
		else
			C_CollisionMgr:InitMyIslands(C_PlayerStatusMgr.playerIndex)
			C_PlayerStatusMgr:InitAllZones()
			C_PetMgr:InitAllPets()				--初始化宠物
			C_PetMgr:InitAllEggs()				--初始化蛋
			C_MergeGui:MarkFiveSamePet()		--标记可以普通合成的宠物
			C_TimeMgr:RemoveEvent(event.id)
		end
	end
	event.handler = initPlayerIndexEvent
	C_TimeMgr:AddEvent(event)
	initPlayerIndexEvent()
end

return PlayerMgr