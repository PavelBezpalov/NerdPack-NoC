-- Syncronized with simc APL as of simc commit f5fa6c7e95dc496ec391112ccfc4821bf228897c (from a32b6ff633e8ab4f1b9d3cd2c7deb079a318cf52)

local mKey = 'NoC_Monk_WW'
local config = {
	key = mKey,
	profiles = true,
	title = '|T'..NeP.Interface.Logo..':10:10|t'..NeP.Info.Nick..' Config',
	subtitle = 'Monk WindWalker Settings',
	color = NeP.Core.classColor('player'),
	width = 250,
	height = 500,
	config = {
		-- General
		{type = 'header',text = 'General', align = 'center'},
		{type = 'checkbox', text = 'Automatic Res', key = 'auto_res', default = false},
		--{type = 'checkbox', text = 'Automatic Pre-Pot', key = 'auto_pot', default = false},
		{type = 'checkbox', text = '5 min DPS test', key = 'dpstest', default = false},

		-- Survival
		{type = 'spacer'},{type = 'rule'},
		{type = 'header', text = 'Survival', align = 'center'},
		{type = 'spinner', text = 'Healthstone & Healing Tonic', key = 'Healthstone', default = 35},
		{type = 'spinner', text = 'Effuse', key = 'effuse', default = 30},
		{type = 'spinner', text = 'Healing Elixir', key = 'Healing Elixir', default = 0},

		-- Offensive
		{type = 'spacer'},{type = 'rule'},
		{type = 'header', text = 'Offensive', align = 'center'},
		{type = 'checkbox', text = 'SEF usage', key = 'SEF', default = true},
		{type = 'checkbox', text = 'Automatic CJL at range', key = 'auto_cjl', default = false},
		{type = 'checkbox', text = 'Automatic Chi Wave at pull', key = 'auto_cw', default = true},
		{type = 'checkbox', text = 'Automatic Mark of the Crane Dotting', key = 'auto_dot', default = true},
		{type = 'checkbox', text = 'Automatic CJL in melee to maintain Hit Combo', key = 'auto_cjl_hc', default = true},

	}
}

local E = NOC.dynEval
local F = function(key) return NeP.Interface.fetchKey(mKey, key, 100) end

local exeOnLoad = function()
	NeP.Interface.buildGUI(config)
	NOC.ClassSetting(mKey)
end

local SEF_Fixate_Casted = false
local sef = function()
	if E('player.buff(Storm, Earth, and Fire)') then
		if SEF_Fixate_Casted then
			return false
		else
			SEF_Fixate_Casted = true
			return true
		end
	else
		SEF_Fixate_Casted = false
	end
	return false
end


local healthstn = function()
	return E('player.health <= ' .. F('Healthstone'))
end

local HealingElixir = function()
	return E('player.health <= ' .. F('Healing Elixir'))
end

local effuse = function()
	return E('player.health <= ' .. F('effuse'))
end


local _OOC = {

	{ "Effuse", { "player.health < 50", "player.lastmoved >= 1" }, "player" },

	-- Automatic res of dead party members
	{ "%ressdead('Resuscitate')", (function() return F('auto_res') end) },

	-- TODO: Add support for (optional) automatic potion use w/pull timer
}

local _All = {
	-- keybind
	{ "Leg Sweep", "keybind(lcontrol)" },
  { "Touch of Karma", "keybind(lalt)" },

	{ "/stopcasting\n/stopattack\n/cleartarget\n/stopattack\n/cleartarget\n/nep mt", { "player.combat.time >= 300", (function() return F('dpstest') end) }},

	-- Cancel CJL when we're in melee range
	{ "!/stopcasting", { "target.range <= 5", "player.casting(Crackling Jade Lightning)" }},

	-- FREEDOOM!
	{ "116841", 'player.state.disorient' }, -- Tiger's Lust = 116841
	{ "116841", 'player.state.stun' }, -- Tiger's Lust = 116841
	{ "116841", 'player.state.root' }, -- Tiger's Lust = 116841
	{ "116841", 'player.state.snare' }, -- Tiger's Lust = 116841
}

local _Cooldowns = {
	{{
		-- TODO: add logic to handle ToD interaction with legendary item 137057
		{ "Touch of Death", "!player.spell.usable(Gale Burst)" },
		{ "Touch of Death", { "player.spell.usable(Gale Burst)", "player.spell(Strike of the Windlord).cooldown < 8", "player.spell(Fists of Fury).cooldown <= 4", "player.spell(Rising Sun Kick).cooldown < 7" }},
	}, "target.range <= 5" },

	{ "Lifeblood" },
	{ "Berserking" },
	{ "Blood Fury" },
	{ "#trinket1", { "player.buff(Serenity)", "or", "player.buff(Storm, Earth, and Fire)" }},
	{ "#trinket2", { "player.buff(Serenity)", "or", "player.buff(Storm, Earth, and Fire)" }},
	-- Use Xuen only while hero or potion (WOD: 156423, Legion: 188027) is active
	{ "Invoke Xuen, the White Tiger", "player.hashero", "or", "player.buff(156423)", "or", "player.buff(188027)" },
}

local _Survival = {
	{ "Effuse", { "player.energy >= 60", "player.lastmoved >= 0.5", effuse }, "player" },
	{ "Healing Elixir", { HealingElixir }, "player" },

	-- TODO: Update for legion's equivillant to healing tonic 109223
	{ "#109223", healthstn, "player" }, -- Healing Tonic
	{ '#5512', healthstn, "player" }, -- Healthstone
	{ "Detox", "player.dispellable(Detox)", "player" },
}

local _Interrupts = {
	{ "Ring of Peace", { -- Ring of Peace when SHS is on CD
     "!target.debuff(Spear Hand Strike)",
     "player.spell(Spear Hand Strike).cooldown > 1",
     "!lastcast(Spear Hand Strike)"
  }},
  { "Leg Sweep", { -- Leg Sweep when SHS is on CD
     "player.spell(Spear Hand Strike).cooldown > 1",
     "target.range <= 5",
     "!lastcast(Spear Hand Strike)"
  }},
  { "Quaking Palm", { -- Quaking Palm when SHS is on CD
     "!target.debuff(Spear Hand Strike)",
     "player.spell(Spear Hand Strike).cooldown > 1",
     "!lastcast(Spear Hand Strike)"
  }},
  { "Spear Hand Strike" }, -- Spear Hand Strike
}

local _SEF = {
	{{
		{ "Energizing Elixir" },
		{ _Cooldowns, 'toggle(cooldowns)' },
		{ "Storm, Earth, and Fire", { '!toggle(AoE)', sef }},
		{ "Storm, Earth, and Fire", "!player.buff(Storm, Earth, and Fire)" },
	}, { "player.spell(Strike of the Windlord).exists", "player.spell(Strike of the Windlord).cooldown <= 14", "player.spell(Fists of Fury).cooldown <= 6", "player.spell(Rising Sun Kick).cooldown <= 6"  }},
	{{
		{ "Energizing Elixir" },
		{ _Cooldowns, 'toggle(cooldowns)' },
		{ "Storm, Earth, and Fire", { '!toggle(AoE)', sef }},
		{ "Storm, Earth, and Fire", "!player.buff(Storm, Earth, and Fire)" },
	}, { "!player.spell(Strike of the Windlord).exists", "player.spell(Fists of Fury).cooldown <= 9", "player.spell(Rising Sun Kick).cooldown <= 5"  }},
}

local _Ranged = {
	{ "116841", { "player.movingfor > 0.5", "target.alive" }}, -- Tiger's Lust
	{ "Crackling Jade Lightning", { (function() return F('auto_cjl') end), "!player.moving", "player.combat.time > 4", "!lastcast(Crackling Jade Lightning)", "@NOC.hitcombo('Crackling Jade Lightning')" }},
	{ "Chi Wave", { (function() return F('auto_cw') end), "target.range > 8" }},
}

local _Serenity = {
	{ "Energizing Elixir" },
	{ _Cooldowns, { 'toggle(cooldowns)', "target.range <= 5" }},
	{ "Serenity" },
	{ "Strike of the Windlord" },
	{{
		{'Rising Sun Kick', (function() return F('auto_dot') end), 'NOC_NoDebuff(Mark of the Crane)'},
		{ "Rising Sun Kick" },
	}, { 'player.area(5).enemies < 3' }},
	{ "Fists of Fury" },
	{ 'Spinning Crane Kick', { 'player.area(8).enemies >= 3', 'toggle(AoE)', '!lastcast(Spinning Crane Kick)', "@NOC.hitcombo('Spinning Crane Kick')" }},
	{{
		{'Rising Sun Kick', (function() return F('auto_dot') end), 'NOC_NoDebuff(Mark of the Crane)'},
		{ "Rising Sun Kick" },
	}, { 'player.area(5).enemies >= 3' }},
	{{
		{'Blackout Kick', (function() return F('auto_dot') end), 'NOC_NoDebuff(Mark of the Crane)'},
		{ "Blackout Kick" },
	}, { "!lastcast(Blackout Kick)", "@NOC.hitcombo('Blackout Kick')" }},
	{ "Rushing Jade Wind", { "!lastcast(Rushing Jade Wind)", "@NOC.hitcombo('Rushing Jade Wind')" }},
}

local _Melee = {
	{ _Cooldowns, { 'toggle(cooldowns)', "target.range <= 5" }},
	{ "Energizing Elixir", { "player.energydiff > 0", "player.chi <= 1" }},
	{ "Strike of the Windlord", { "talent(7,3)", "or", "player.area(9).enemies < 6" }},
	{ "Fists of Fury" },
	{'Rising Sun Kick', { (function() return F('auto_dot') end), "NOC_NoDebuff(Mark of the Crane).infront" }, 'NOC_NoDebuff(Mark of the Crane)'},
	{ "Rising Sun Kick" },
	--{ 'Spinning Crane Kick', { '!lastcast(Spinning Crane Kick)', "@NOC.hitcombo('Spinning Crane Kick')", { "player.spell(Spinning Crane Kick).count >= 17" }}},
	{ "Whirling Dragon Punch" },
	--{ 'Spinning Crane Kick', { '!lastcast(Spinning Crane Kick)', "@NOC.hitcombo('Spinning Crane Kick')", { "player.spell(Spinning Crane Kick).count >= 12" }}},
	{ 'Spinning Crane Kick', { 'player.area(8).enemies >= 3', 'toggle(AoE)', '!lastcast(Spinning Crane Kick)', "@NOC.hitcombo('Spinning Crane Kick')" }},
	{ "Rushing Jade Wind", { "player.chidiff > 1", "!lastcast(Rushing Jade Wind)", "@NOC.hitcombo('Rushing Jade Wind')" }},
	{{
		{'Blackout Kick', { (function() return F('auto_dot') end), "player.buff(Blackout Kick!)", "NOC_NoDebuff(Mark of the Crane).infront" }, 'NOC_NoDebuff(Mark of the Crane)'},
  	{ "Blackout Kick", "player.buff(Blackout Kick!)" },
		{'Blackout Kick', { (function() return F('auto_dot') end), "player.chi > 1", "NOC_NoDebuff(Mark of the Crane).infront" }, 'NOC_NoDebuff(Mark of the Crane)'},
  	{ "Blackout Kick", "player.chi > 1" },
	}, { "!lastcast(Blackout Kick)", "@NOC.hitcombo('Blackout Kick')" }},
	{{
		{ "Chi Wave" }, -- 40 yard range 0 energy, 0 chi
		{ "Chi Burst", "!player.moving" },
	}, { "player.timetomax >= 2.25" }},
	{{
		{'Tiger Palm', { (function() return F('auto_dot') end), "NOC_NoDebuff(Mark of the Crane).infront" }, 'NOC_NoDebuff(Mark of the Crane)'},
		{ "Tiger Palm" },
	}, { "!lastcast(Tiger Palm)", "@NOC.hitcombo('Tiger Palm')" }},

	{{
		{ "Crackling Jade Lightning", "talent(6,1)" },
		{ "Crackling Jade Lightning", "!talent(6,1)" },
	}, { "player.chidiff = 1", "player.spell(Rising Sun Kick).cooldown > 1", "player.spell(Fists of Fury).cooldown > 1", "player.spell(Strike of the Windlord).cooldown > 1", "!lastcast(Crackling Jade Lightning)", "@NOC.hitcombo('Crackling Jade Lightning')" }},

	-- CJL when we're using Hit Combo as a last resort filler, and it's toggled on
	-- TODO: remove this in 7.1 or add a big energy buffer to the check since it is no longer free to cast
	{ "Crackling Jade Lightning", { (function() return F('auto_cjl_hc') end), "!lastcast(Crackling Jade Lightning)", "@NOC.hitcombo('Crackling Jade Lightning')" }},

	-- Last resort BoK when we only have 1 chi and Hit COmbo <= 4 secs left
	{ "Blackout Kick", { "player.chi = 1", "player.buff(Hit Combo) <= 4", "!lastcast(Blackout Kick)", "@NOC.hitcombo('Blackout Kick')" }},


}

NeP.Engine.registerRotation(269, '[|cff'..NeP.Interface.addonColor..'NoC|r] Monk - Windwalker',
	{ -- In-Combat
		{ '%pause', 'keybind(shift)'},
		{ _All},
		{ _Survival, 'player.health < 100'},
		{ _Interrupts, { 'target.interruptAt(55)', 'target.inMelee' }},
		{ _Serenity, { "target.range <= 5", "talent(7,3)", "!player.casting(Fists of Fury)", {{ "player.spell(Strike of the Windlord).exists", "player.spell(Strike of the Windlord).cooldown <= 14", "player.spell(Rising Sun Kick).cooldown <= 4" }, "or", "player.buff(Serenity)" }}},
		{ _Serenity, { "target.range <= 5", "talent(7,3)", "!player.casting(Fists of Fury)", {{ "!player.spell(Strike of the Windlord).exists", "player.spell(Fists of Fury).cooldown <= 15", "player.spell(Rising Sun Kick).cooldown < 7" }, "or", "player.buff(Serenity)" }}},
		{ _SEF, { "target.range <= 5", (function() return F('SEF') end), "!talent(7,3)", "!player.casting(Fists of Fury)" }},
		{ _Melee, { "target.range <= 9", "!player.casting(Fists of Fury)" }},
		{ _Ranged, { "target.range > 8", "target.range <= 40" }},
	}, _OOC, exeOnLoad)
