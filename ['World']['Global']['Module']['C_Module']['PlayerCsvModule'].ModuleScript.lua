--- 游戏表格预处理-客户端端
-- @module Csv Config Load - Client Side
-- @copyright Lilith Games, Avatar Team
-- @author Yuancheng Zhang
local PlayerCsv = {
    preLoad = {
        {
            name = 'PetProperty',
            csv = 'PetProperty',
            ids = {'Area','Zone','PetIndex'}
        },
        {
            name = 'LimitMergeProb',
            csv = 'LimitMergeProb',
            ids = {'Type'}
        },
        {
			name = 'Potion',
            csv = 'Potion',
			ids = {'Type'}
		},
		{
			name = 'PotionProperty',
            csv = 'PotionProperty',
			ids = {'Number'}
		},
		{
			name = 'Achieve',
			csv = 'Achieve',
			ids = {'AchieveType','AchieveLev'}
        },
        {
            name = 'Goods',
            csv = 'Goods',
            ids = {'Type','Level'}
        },
        {
            name = 'PathFinding',
            csv = 'PathFinding',
            ids = {'Area','Zone'}
        },
        {
            name = 'MineProperty',
            csv = 'MineProperty',
            ids = {'Area','Zone','Level'}
        },
        {
            name = 'IslandPos',
            csv = 'IslandPos',
            ids = {'Area'}
        },
        {
            name = 'Guide',
            csv = 'Guide',
            ids = {'Step','Index'},
        },
        {
            name = 'Notice',
            csv = 'Notice',
            ids = {'NameId'}
        },
        {
            name = 'Egg',
            csv = 'Egg',
            ids = {'Area','Zone'}
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
        {
            name = 'HomePos',
            csv = 'HomePos',
            ids = {'Index','Area'}
        },
        {
            name = 'Cam',
            csv = 'Cam',
            ids = {'Index','CamType','Area'}
        },
        {
            name = 'HatchPetAnimPos',
            csv = 'HatchPetAnimPos',
            ids = {'Num'}
        },
    }
}

--- 初始化:加载所有预加载表格
function PlayerCsv:Init()
    --info('PlayerCsv:Init')
    self:PreloadCsv()
end

function PlayerCsv:PreloadCsv()
    --info('PlayerCsv:PreloadCsv')
    for _, pl in pairs(self.preLoad) do
        if not string.isnilorempty(pl.csv) and #pl.ids > 0 then
            self[pl.name] = CsvUtil.GetCsvInfo(Csv[pl.csv], table.unpack(pl.ids))
        end
    end
end

return PlayerCsv