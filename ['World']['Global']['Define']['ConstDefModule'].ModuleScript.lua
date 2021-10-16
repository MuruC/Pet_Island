--- 全局常量的定义,全部定义在ConstDef这张表下面,用于定义全局常量参数或者枚举类型
-- @module Constant Defines
-- @copyright Lilith Games, Avatar Team
local ConstDef = {}

--改变玩家资源数的操作类型
ConstDef.ChangeResTypeEnum = {
    Add = 1,
    Sub = 2,
    Reset = 3
}

--玩家属性枚举
--值与玩家数据中的命名匹配
ConstDef.PlayerAttributeEnum = {	
	CanExplore = 'canExplore',								--便捷传送	
	RarePetProbMagnification = 'rarePetProbMagnification',	--稀有宠物概率倍率	
	ThreePetInOneEgg = 'threePetInOneEgg',					--一个蛋可以孵出三个宠物	
	PetStorage = 'petStorage',								--宠物储存容量	
	GetCoinMagnification = 'getCoinMagnification',			--获得金币倍率	
	PlayerSpd = 'playerSpd',								--移动速度	
	MaxCurPet = 'maxCurPet',								--跟随宠物最大数量
	GetEggProb = 'getEggProb',								--生产蛋的机率	
	GetDiamondProb = 'getDiamondProb',						--钻石掉率	
	EncrEffect = 'encrEffect',								--鼓励效率	
	CoinNumInGoldMine = 'coinNumInGoldMine',				--单个金矿的金币数	
	GetPotionProb = 'getPotionProb',						--药水掉落的机率	
	HatchGrowingPetProb = 'hatchGrowingPetProb',			--直接孵化出成长期宠物的概率	
	HatchMaturePetProb = 'hatchMaturePetProb',				--直接孵化出成熟期宠物的概率	
	HatchCompletePetProb = 'hatchCompletePetProb',			--直接孵化出完全体宠物的概率	
	HatchUltimatePetProb = 'hatchUltimatePetProb'			--直接孵化出究极体宠物的概率
}

--资源类型枚举
--值与玩家数据中的命名匹配
ConstDef.ServerResTypeEnum = {
	Coin = 'coin',				--普通金币
	Diamond = 'diamond'			--钻石
}

--装备类型枚举(包括所有玩家可以选择装备的东西)
--值与玩家数据中的命名匹配
ConstDef.EquipmentTypeEnum = {
	Pet = 'pet',			--当前跟随中的宠物
	Potion = 'potion',		--使用中的药水
}

--商品状态类型枚举
ConstDef.GoodsStateEnum = {
	Locked = 1,       --未解锁
	Unlocked = 2,     --已解锁（未购买）
	Owned = 3,        --已购买
	Equipped = 4,     --已装备
}

--玩家操作类型枚举
ConstDef.PlayerActionTypeEnum = {
	SellPet = 1,       	--出售宠物
	Buy = 2,           	--购买
	Equip = 3,         	--装备药水或者宠物
	Hatch = 4,         	--孵蛋
	Merge = 5,		   	--合成
	Achieve = 6,	   	--解锁成就
	UnlockZone = 7,		--解锁关卡
	Pick = 8,			--捡起
	PutEgg = 9,			--把蛋放进孵蛋器
	AskData = 10,       --请求数据
	UnlockArea = 11,	--解锁场景
	Unequip = 12,		--宠物待命
	Guide = 13,			--进行新手指引
	Encr = 14,			--鼓励
	AskSave = 15,		--请求保存数据
	AskIndex = 16,		--请求玩家编号
	AskFstCdTime = 17,	--请求第一个cd时间
	HatchFive = 18,		--五连抽
	GetGift = 19,		--获得礼物
}

--玩家捡到东西类型枚举
ConstDef.PlayerPickTypeEnum = {
	Egg = 1,
	Coin = 2,
	Diamond = 3,
	Potion = 4,
}

--回执信息枚举
ConstDef.ResultMsgEnum = {
	None = -1,          	--无
	Succeed = 0,        	--成功
	ResNotEnough = 1,   	--所需资源不足
	ItemSoldOut = 2,    	--商品已经卖光
	ItemNotRefresh = 3, 	--商品没有刷新
	CapacityNotEnough = 4, 	--所需容量不够
}

-- 挖矿信息枚举
ConstDef.DigMsgEnum = {
	None = -1,		--无
	Done = 0,		--成功
	Fail = -2,		--失败
	OneTenth = 1,	--十分之一
	TwoTenth = 2,	--十分之二
	ThreeTenth = 3,	--十分之三
	FourTenth = 4,	--十分之四
	FiveTenth = 5,	--十分之五
	SixTenth = 6,	--十分之六
	SevenTenth = 7,	--十分之七
	EightTenth = 8,	--十分之八
	NineTenth = 9,	--十分之九
}

--弹框消息枚举
--值与对应的msgId相同
ConstDef.NoticeMsgEnum = {
	BagIsFull = 1,       --背包已满
	MineReset = 2,       --矿场重置
}

--游戏摄像机模式枚举
ConstDef.CameraModeEnum = {
	Normal = 1,        	--常规
	Hatch = 2,         	--孵化
	Incubator = 3,		--孵蛋器
	Fuse = 4,			--合成动画
	FuseRoom = 5,		--合成室
	islandAnim = 6,		--岛屿浮起动画
}

--购买商品种类枚举
ConstDef.GoodsTypeEnum = {
	Goods = 'goods',		--普通商品
	Potion = 'potion',		--药水
}

--Item种类枚举
ConstDef.ItemCategoryEnum = {
	Potion = 'potion',
	Egg = 'egg',
	Pet = 'pet',		--所有拥有的宠物
	Zones = 'zones'		--解锁的场景
}

-- 商品总数
ConstDef.GOODS_TYPE_NUM = 7
-- 药水总数
ConstDef.POTION_TYPE_NUM = 9

-- 商品类别枚举
ConstDef.GoodsCategoryEnum = {	
	canExplore = 1, 						--便捷传送	
	doubleRarePetProbMagnification = 2,		--稀有宠物概率翻倍	
	threePetInOneEgg = 3, 					--一个蛋可以孵出三个宠物	
	addPetStorage = 4, 						--宠物储存容量 + 100	
	addGetCoinMagnification = 5, 			--获得金币倍率 + 10%	
	addPlayerSpd = 6, 						--移动速度 + 10%	
	addMaxCurPet = 7 						--额外装备一个宠物
}


-- 成就类别枚举
ConstDef.achieveCategoryEnum = {
	hatchEggNum = 1,		--孵化蛋数量
	playTime = 2,			--游戏时长
	encrNum = 3,			--鼓励次数
	digGoldMine = 4,		--挖掘金矿
	usePotion = 5,			--使用药水
	haveGrowingPet = 6,		--拥有成长期宠物数量
	haveMaturePet = 7,		--拥有成熟期宠物数量
	haveCompletePet = 8,	--拥有完全体宠物数量
	haveUltimatePet = 9		--拥有究极体宠物数量
}

-- 成就奖励类别枚举
ConstDef.achieveRewardCategoryEnum = {	
	getEggProb = 1,				--生产蛋的机率
	getDiamondProb = 2,			--钻石掉率	
	encrEffect = 3,				--鼓励效率	
	coinNumInGoldMine = 4,		--单个金矿的金币数	
	getPotionProb = 5,			--药水掉落的机率	
	hatchGrowingPetProb = 6,	--直接孵化出成长期宠物的概率	
	hatchMaturePetProb = 7,		--直接孵化出成熟期宠物的概率	
	hatchCompletePetProb = 8,	--直接孵化出完全体宠物的概率	
	hatchUltimatePetProb = 9	--直接孵化出究极体宠物的概率
}

-- buff类别枚举
ConstDef.buffCategoryEnum = {
	Goods = 'goods',		--商品
	Achieve = 'achieve'		--成就
}

-- buff属性类别枚举
ConstDef.buffValTypeEnum = {
	Level = 'level',			--等级
	StartTime = 'startTime',	--开始时间
}

-- 按钮类别枚举
ConstDef.btnCategoryEnum = {
	petInBag = 1,		-- 宠物在背包中
	petInMerge = 2,		-- 宠物在合成室中
	eggInBag = 3,		-- 蛋在背包中
	potionInBag = 4,	-- 药水在背包中
}

-- 成就总数
ConstDef.ACHIEVE_TYPE_NUM = 9
-- 成就最高等级
ConstDef.MAX_ACHIEVE_LEVEL = 7

-- 合成类别枚举
ConstDef.MergeCategoryEnum = {
	normalMerge = 1,	--普通合成
	limitMerge = 2,		--限时合成
}

-- 数据统计类别枚举
-- 值与玩家在数据中的命名相同
ConstDef.statsCategoryEnum = {
	CollectEggs = 'collectEggs',			--收集到蛋的数量
	PlayTime = 'playTime',					--游玩的总时长
	UnlockZones = 'unlockZones',			--解锁的区域数量
	AchieveLevel = 'achieveLevel',			--所有成就等级
	AchieveCurValue = 'achieveCurValue',	--所有成就当前进度
	OwnPetNum = 'ownPetNum',				--拥有的宠物数量
	LimitMergeNum = 'limitMergeNum',		--当日能限时合成的次数
	RefreshMagicMergeStartTime = 'refreshMagicMergeStartTime',	--开始读魔法合成cd时间
}

-- 矿的类别
ConstDef.mineCategoryEnum = {
	primary = 1,		--低级普通矿
	middle = 2,			--中级普通矿
	advanced = 3,		--高级普通矿
	coinMine = 4,		--金币喷泉矿
	minorEgg = 5,		--小蛋矿
	majorEgg = 6,		--大蛋矿
	unlockMine = 7,		--限时解锁关卡
	boss = 8,			--世界boss
	guide = 9,			--新手指引矿
}

-- 宠物事件索引
ConstDef.petEventCategoryEnum = {
	assignMine = 1,		--分配矿
	doneMining = 2,		--结束挖矿
	transport = 3,		--和玩家一起瞬移
}

-- 关卡矿的posIndex
ConstDef.LEVEL_MINE_POS_INDEX = 20
-- 新手矿的posIndex
ConstDef.GUIDE_MINE_POS_INDEX = -1
-- boss矿的posIndex
ConstDef.BOSS_MINE_POS_INDEX = -2

-- 新手指引事件
ConstDef.guideEvent = {
	clickDialogue = 1,		--点击对话
	goToPortal = 2,			--进入传送门
	givePet = 3,			--给玩家一个宠物
	doneDigMine = 4,		--采矿完成
	getEgg = 5,				--获得蛋
	goToMerge = 6,			--进入合成室
	merge = 7,				--合成宠物
	getAchieve = 8,			--解锁成就
	goToStore = 9,			--进入商店
	getFiveSamePets = 10,	--获得5个相同的宠物
	canGetAchieve = 11,		--可以解锁成就
	hatchEgg = 12,			--孵化出一个宠物
}

-- 新手指引状态
ConstDef.guideState = {
	Introduction = 'Introduction',
	GoToPortal = 'GoToPortal',
	Transport = 'Transport',
	GivePet = 'GivePet',
	IntroDig = 'IntroDig',
	Dig = 'Dig',
	DoneDig = 'DoneDig',
	RequestPickEgg = 'RequestPickEgg',
	PickEgg = 'PickEgg',
	PressTransBtn = 'PressTransBtn',
	PressHomeBtn = 'PressHomeBtn',
	IntroGen = 'IntroGen',
	IntroHatch = 'IntroHatch',
	GoToGen = 'GoToGen',
	PressHatchBtn = 'PressHatchBtn',
	RequestOpenBag = 'RequestOpenBag',
	PressBagBtn = 'PressBagBtn',
	RequestEquip = 'RequestEquip',
	PressEquipBtn = 'PressEquipBtn',
	IntroBag = 'IntroBag',
	Explore = 'Explore',
	RequestGoToMerge = 'RequestGoToMerge',
	GoToMerge = 'GoToMerge',
	TeachMerge = 'TeachMerge',
	Merge = 'Merge',
	IntroMerge = 'IntroMerge',
	PromptAchieve = 'PromptAchieve',
	GetAchieve = 'GetAchieve',
	RequestGoToStore = 'RequestGoToStore',
	GoToStore = 'GoToStore',
	IntroStore = 'IntroStore',
	IntroEnding = 'IntroEnding',
	Ending = 'Ending',
}

-- 按钮枚举
ConstDef.btnEnum = {
	trans = 'trans',		-- 打开传送面板按钮
	home = 'home',			-- 回城按钮
	hatch = 'hatch',		-- 孵化按钮
	bag = 'bag',			-- 打开背包
	sell = 'sell',			-- 贩卖宠物
	findMine = 'findMine',	-- 自动寻矿
	quitContinueHatch = 'quitContinueHatch',	-- 退出继续孵化
	quitFuseAnim = 'quitFuseAnim'	--退出合成动画
}

-- 客户端资源枚举
ConstDef.clientResourceEnum = {
	GuideState = 'guideState',		--新手指引状态
	GuideTask = 'guideTask',		--新手任务进度
}

-- 碰撞类型枚举
ConstDef.collisionEventEnum = {
	Enter = 1,	--进入
	Leave = 2,	--退出
}

-- 检查点类型枚举
ConstDef.checkpointTypeEnum = {
	Pay = 1,	--金钱解锁
	InTime = 2,	--限时解锁
}

--- bgm枚举
ConstDef.bgmEnum = {
	mainIsland = 0,		--主城
	forest = 1,			--森林场景
	grave = 2,			--墓地场景
	sea = 3,			--海底场景
	desert = 4,			--荒漠场景
	boss = 5,			--世界boss
	loading = 6,		--加载过场动画
}

--- 魔法合成最多次数
ConstDef.magicFuseMaxNum = 5

--- 寻路类别枚举
ConstDef.pathFindingType = {
	pet = 1,
	guide = 2,
}

return ConstDef