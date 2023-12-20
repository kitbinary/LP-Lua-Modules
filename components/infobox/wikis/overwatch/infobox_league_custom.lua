---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _BLIZZARD_TIERS = {
	owl = 'Overwatch League',
	owc = 'Overwatch Contenders',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {Game.text{game = _args.game}}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	local args = _args
	if id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(League:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(CustomLeague:_createNoWrappingSpan(
					PageLink.makeInternalLink({}, map, map .. game)
				)))
			end
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'liquipediatier' then
		if CustomLeague:_validPublisherTier(args.blizzardtier) then
			table.insert(widgets,
				Cell{
					name = 'Blizzard Tier',
					content = {'[['.._BLIZZARD_TIERS[args.blizzardtier:lower()]..']]'},
					classes = {'valvepremier-highlighted'}
				}
			)
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.maps = table.concat(League:getAllArgsForBase(args, 'map'), ';')

	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

function CustomLeague:_validPublisherTier(publishertier)
	return String.isNotEmpty(publishertier) and _BLIZZARD_TIERS[publishertier:lower()]
end

function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', _args.tickername or '')
	Variables.varDefine('tournament_tier', _args.liquipediatier or '')

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('tournament_sdate', sdate)
	Variables.varDefine('tournament_edate', edate)
	Variables.varDefine('tournament_date', edate)

	if CustomLeague:_validPublisherTier(args.blizzardtier) then
		Variables.varDefine('tournament_blizzard_premier', args.blizzardtier:lower())
	end

end

function CustomLeague:getWikiCategories(args)
	local categories = {}

	if not Game.name{game = _args.game} then
		table.insert(categories, 'Tournaments without game version')
	else
		table.insert(categories, Game.name{game = _args.game} .. ' Competitions')
	end

	return categories
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
	return span
end

return CustomLeague
