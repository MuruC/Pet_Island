--- 客户端新手指引ui管理模块
-- @module guide ui, Client-side
-- @copyright Lilith Games, Avatar Team
-- @author Chen Muru

local C_GuideGui, this = {}, nil

--- 初始化
function C_GuideGui:Init()
    --info("C_GuideGui:Init")
    this = self
    self:InitListeners()

    self.guideGui = localPlayer.Local.GuideGui ---指引界面ui
    self.dialogue = self.guideGui.Dialogue           ---对话界面
    self.dialogueTxt = self.dialogue.Bg.Text         ---对话台词
    self.confirmDialogueBtn = self.dialogue.OkBtn    ---确认对话按钮

    -- 全部gui
    self.allGui = {C_HatchGui.hatchGui,C_TransGui.transGui,C_MainGui.mainGui,self.guideGui}

    self:BindClickEventCallback()
end

--- Update函数
-- @param dt delta time 每帧时间
function C_GuideGui:Update(dt)
end

--- 初始化C_UIMgr自己的监听事件
function C_GuideGui:InitListeners()
    EventUtil.LinkConnects(localPlayer.C_Event, C_GuideGui, "C_GuideGui", this)
end

--- 指引事件枚举
local constDefGuide = ConstDef.guideEvent

--- 初始化点击事件
function C_GuideGui:BindClickEventCallback()
    --绑定确认对话按钮
    self.confirmDialogueBtn.OnClick:Connect(function()
        C_Guide:ProcessGuideEvent(constDefGuide.clickDialogue)
    end)

    --绑定点击对话界面
    self.dialogue.OnTouched:Connect(function()
        C_Guide:ProcessGuideEvent(constDefGuide.clickDialogue)
    end)
end

--- 是否显示指引ui
--- @param _bShow boolean 是否显示
function C_GuideGui:CheckIfShowGuideGui(_bShow)
    if _bShow then
        for k, v in pairs(self.allGui) do
            v:SetActive(false)
        end
        self.guideGui:SetActive(true)
    else
        self.guideGui:SetActive(false)
    end
end

--- 是否显示对话框ui
--- @param _bShow boolean 是否显示
function C_GuideGui:CheckIfShowDialogueGui(_bShow)
    self.dialogue:SetActive(_bShow)
end

--- 设置对话文字
--- @param _step string 步骤名称
--- @param _index int 索引
function C_GuideGui:SetDialogueText(_step,_index)
    local allDialogue = PlayerCsv.Guide[_step][_index]
    if allDialogue then
        self.dialogueTxt.Text = allDialogue['Sentence']
    end
end

return C_GuideGui