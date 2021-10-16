--- 将Global.Module目录下每一个用到模块提前require,定义为全局变量
-- @script Module Defines
-- @copyright Lilith Games, Avatar Team

-- Log utility
local LogUtil = require(Utility.LogUtilModule)
-- 封装四个全局接口
test = LogUtil.Test
debug = LogUtil.Debug
info = LogUtil.Info
warn = LogUtil.Warn

-- 定义日志等级、开关
LogUtil.level = LogUtil.LevelEnum.DEBUG
LogUtil.debugMode = true

-- Utilities
NetUtil = require(Utility.NetUtilModule)
CsvUtil = require(Utility.CsvUtilModule)
EventUtil = require(Utility.EventUitlModule)
UUID = require(Utility.UuidModule)
LinkedList = Utility.LinkedListModule
LuaJsonUtil = require(Utility.LuaJsonUtilModule)
ValueChangeUtil = require(Utility.ValueChangeUtilModule)
AudioMgr = require(Utility.AudioMgrModule)
-- Defines
GlobalDef = require(Define.GlobalDefModule)
ConstDef = require(Define.ConstDefModule)

-- Plugin Modules
AnimationMain = require(world.Global.Plugin.FUNC_UIAnimation.Code.AnimationMainModule)
GuideSystem = require(world.Global.Plugin.FUNC_Guide.GuideSystemModule)

-- Server Modules
GameMgr = require(Module.S_Module.GameMgrModule)
S_TimeMgr = require(Module.S_Module.S_TimeMgrModule)
GameCsv = require(Module.S_Module.GameCsvModule)
S_MineMgr = require(Module.S_Module.S_MineMgrModule)
S_PlayerDataMgr = require(Module.S_Module.S_PlayerDataMgrModule)
S_Store = require(Module.S_Module.S_StoreModule)
S_PetMgr = require(Module.S_Module.S_PetMgrModule)
S_PlayerStatusMgr = require(Module.S_Module.S_PlayerStatusMgrModule)
S_RequestMgr = require(Module.S_Module.S_RequestMgrModule)
S_Achieve = require(Module.S_Module.S_AchieveModule)
S_GiftMgr = require(Module.S_Module.S_GiftMgrModule)
-- Client Modules
PlayerMgr = require(Module.C_Module.PlayerMgrModule)
PlayerCsv = require(Module.C_Module.PlayerCsvModule)
Notice = require(Module.C_Module.NoticeModule)
C_PetMgr = require(Module.C_Module.C_PetMgrModule)
C_PlayerStatusMgr = require(Module.C_Module.C_PlayerStatusMgrModule)
C_UIMgr = require(Module.C_Module.C_UIMgrModule)
C_TimeMgr = require(Module.C_Module.C_TimeMgrModule)
a_star = require(Module.C_Module.A_StarModule)
PathFinding = require(Module.C_Module.PathFindingModule)
C_PlayerDataMgr = require(Module.C_Module.C_PlayerDataMgrModule)
C_MineMgr = require(Module.C_Module.C_MineMgrModule)
C_Store = require(Module.C_Module.C_StoreModule)
C_ReplyRequest = require(Module.C_Module.C_ReplyRequestModule)
C_AchieveGui = require(Module.C_Module.C_AchieveGuiModule)
C_BagGui = require(Module.C_Module.C_BagGuiModule)
C_MergeGui = require(Module.C_Module.C_MergeGuiModule)
C_MainGui = require(Module.C_Module.C_MainGuiModule)
C_MineGui = require(Module.C_Module.C_MineGuiModule)
C_Guide = require(Module.C_Module.C_GuideModule)
C_GuideGui = require(Module.C_Module.C_GuideGuiModule)
C_TransGui = require(Module.C_Module.C_TransGuiModule)
C_HatchGui = require(Module.C_Module.C_HatchGuiModule)
C_NoticeGui = require(Module.C_Module.C_NoticeGuiModule)
C_CollisionMgr = require(Module.C_Module.C_CollisionMgrModule)
C_StoreGui = require(Module.C_Module.C_StoreGuiModule)
C_Camera = require(Module.C_Module.C_CameraModule)
C_AudioMgr = require(Module.C_Module.C_AudioMgrModule)
C_LoadGui = require(Module.C_Module.C_LoadGuiModule)