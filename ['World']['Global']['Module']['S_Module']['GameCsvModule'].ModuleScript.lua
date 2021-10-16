--- 游戏表格预处理-服务器端
-- @module Csv Config Load - Server Side
-- @copyright Lilith Games, Avatar Team
-- @author Yuancheng Zhang
local GameCsv = {
    preLoad = {
        {
            name = 'PetProperty',
            csv = 'PetProperty',
            ids = {'Area','Zone','PetIndex'}
        },
        {
            name = 'MineProperty',
            csv = 'MineProperty',
            ids = {'Area','Zone','Level'}
        },
        {
            name = 'Goods',
            csv = 'Goods',
            ids = {'Type','Level'}
        },        
        {
			name = 'Potion',
            csv = 'Potion',
			ids = {'Type'}
        },
        {
            name = 'Achieve',
			csv = 'Achieve',
			ids = {'AchieveType','AchieveLev'}
        },
        {
            name = 'LimitMergeProb',
            csv = 'LimitMergeProb',
            ids = {'Type'}
        },
        {
            name = 'UnlockLevelInTime',
            csv = 'UnlockLevelInTime',
            ids = {'Area','Zone'}
        },
        {
            name = 'MoneyForUnlockArea',
            csv = 'MoneyForUnlockArea',
            ids = {'Area'}
        },
        {
            name = 'LevelCoe',
            csv = 'LevelCoe',
            ids = {'Level'}
        },
        {
            name = 'CheckpointData',
            csv = 'CheckpointData',
            ids = {'Area','Zone'}
        },
    }
}

--- 初始化:加载所有预加载表格
function GameCsv:Init()
    --info('GameCsv:Init')
    self:PreloadCsv()
end

function GameCsv:PreloadCsv()
    --info('GameCsv:PreloadCsv')
    for _, pl in pairs(self.preLoad) do
        if not string.isnilorempty(pl.csv) and #pl.ids > 0 then
            self[pl.name] = CsvUtil.GetCsvInfo(Csv[pl.csv], table.unpack(pl.ids))
        end
    end
end

return GameCsv
