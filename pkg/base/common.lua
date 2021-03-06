--[[
    This file is part of Ice Lua Components.

    Ice Lua Components is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ice Lua Components is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Ice Lua Components.  If not, see <http://www.gnu.org/licenses/>.
]]

print("base dir:",common.base_dir)

dofile("pkg/base/version.lua")

-- base dir stuff
DIR_PKG_ROOT = DIR_PKG_ROOT or "pkg/base"
DIR_PKG_LIB = DIR_PKG_LIB or DIR_PKG_ROOT
DIR_PKG_PMF = DIR_PKG_PMF or DIR_PKG_ROOT.."/pmf"
DIR_PKG_GFX = DIR_PKG_GFX or DIR_PKG_ROOT.."/gfx"
DIR_PKG_WAV = DIR_PKG_WAV or DIR_PKG_ROOT.."/wav"
DIR_PKG_MAP = DIR_PKG_MAP or "pkg/maps"

MAP_DEFAULT = MAP_DEFAULT or DIR_PKG_MAP.."/mesa.vxl"

LIB_LIST = LIB_LIST or {
	DIR_PKG_LIB.."/icegui/widgets.lua",

	DIR_PKG_LIB.."/lib_bits.lua",
	DIR_PKG_LIB.."/lib_collect.lua",
	DIR_PKG_LIB.."/lib_gui.lua",
	DIR_PKG_LIB.."/lib_map.lua",
	DIR_PKG_LIB.."/lib_namegen.lua",
	DIR_PKG_LIB.."/lib_pmf.lua",
	DIR_PKG_LIB.."/lib_sdlkey.lua",
	DIR_PKG_LIB.."/lib_util.lua",
	DIR_PKG_LIB.."/lib_vector.lua",
	
	DIR_PKG_LIB.."/obj_player.lua",
	DIR_PKG_LIB.."/obj_intent.lua",
	DIR_PKG_LIB.."/obj_nade.lua",
}

-- load libs
local i
for i=1,#LIB_LIST do
	local asdf_qwerty = i
	i = nil
	dofile(LIB_LIST[asdf_qwerty])
	i = asdf_qwerty
end
i = nil


-- mode stuff
MODE_DEBUG_SHOWBOXES = false
MODE_CHEAT_FLY = false

MODE_AUTOCLIMB = true
MODE_AIRJUMP = false
MODE_SOFTCROUCH = true

MODE_NADE_SPEED = 30.0
MODE_NADE_STEP = 0.1
MODE_NADE_FUSE = 3.0
MODE_NADE_ADAMP = 0.5
MODE_NADE_BDAMP = 1.0
MODE_NADE_RANGE = 8.0
MODE_NADE_DAMAGE = 500.0

MODE_MINIMAP_RCIRC = false
MODE_ENABLE_MINIMAP = true
MODE_MAP_TRACERS = false -- TODO!

MODE_TILT_SLOWDOWN = false -- TODO!
MODE_TILT_DOWN_NOCLIMB = false -- TODO!

MODE_DRUNKCAM_VELOCITY = false -- keep this off unless you want to throw up
MODE_DRUNKCAM_LOCALTURN = true -- this is the one you're looking for.
MODE_DRUNKCAM_CORRECTSPEED = 10.0

MODE_DELAY_SPADE_DIG = 1.0
MODE_DELAY_SPADE_HIT = 0.25
MODE_DELAY_BLOCK_BUILD = 0.5
MODE_DELAY_TOOL_CHANGE = 0.2
MODE_DELAY_NADE_THROW = 0.5

MODE_BLOCK_HEALTH = 100
MODE_BLOCK_DAMAGE_SPADE = 34
MODE_BLOCK_DAMAGE_RIFLE = 34
MODE_BLOCK_REGEN_TIME = 15.0
MODE_BLOCK_PLACE_IN_AIR = false --TODO: make this a server config variable, maybe godmode?
MODE_BLOCK_NO_RED_MARKER = false

MODE_RCIRC_LINGER = 60.0
MODE_RESPAWN_TIME = 8.0

MODE_CHAT_LINGER = 15.0
MODE_CHAT_MAX = 10
MODE_CHAT_STRMAX = 102

-- scoring
SCORE_INTEL = 10
SCORE_KILL = 1
SCORE_TEAMKILL = -1
SCORE_SUICIDE = -1

-- tools
TOOL_SPADE = 0
TOOL_BLOCK = 1
TOOL_GUN = 2
TOOL_NADE = 3

-- sounds
if client then
	client.wav_cube_size(0.5)
	wav_rifle_shot = common.wav_load(DIR_PKG_WAV.."/rifle-shot.wav")
	wav_rifle_reload = common.wav_load(DIR_PKG_WAV.."/rifle-reload.wav")
	wav_whoosh = common.wav_load(DIR_PKG_WAV.."/whoosh.wav")
	wav_buld = common.wav_load(DIR_PKG_WAV.."/buld.wav")
	wav_grif = common.wav_load(DIR_PKG_WAV.."/grif.wav")
	wav_hammer = common.wav_load(DIR_PKG_WAV.."/hammer.wav")
	wav_jump_up = common.wav_load(DIR_PKG_WAV.."/jump-up.wav")
	wav_jump_down = common.wav_load(DIR_PKG_WAV.."/jump-down.wav")
	wav_pin = common.wav_load(DIR_PKG_WAV.."/pin.wav")
	wav_steps = {}
	local i
	for i=1,8 do
		wav_steps[i] = common.wav_load(DIR_PKG_WAV.."/step"..i..".wav")
	end
end

-- weapons
WPN_RIFLE = 1

weapon_models = {}

weapons = {
	[WPN_RIFLE] = function (plr)
		local this = {} this.this = this
		
		this.cfg = {
			dmg = {
				head = 100,
				body = 49,
				legs = 33,
			},
			
			ammo_clip = 10,
			ammo_reserve = 50,
			time_fire = 1/2,
			time_reload = 2.5,
			
			recoil_x = 0.0001,
			recoil_y = -0.05,
			
			name = "Rifle"
		}
		
		function this.restock()
			this.ammo_clip = this.cfg.ammo_clip
			this.ammo_reserve = this.cfg.ammo_reserve
		end
		
		function this.reset()
			this.t_fire = nil
			this.t_reload = nil
			this.reloading = false
			this.restock()
		end
		
		this.reset()
		
		local function prv_fire(sec_current)
			local xlen, ylen, zlen
			xlen, ylen, zlen = common.map_get_dims()
			
			if client then
				tracer_add(plr.x,plr.y,plr.z,
					plr.angy,plr.angx)
				
				client.wav_play_global(wav_rifle_shot, plr.x, plr.y, plr.z)
			end
			
			local sya = math.sin(plr.angy)
			local cya = math.cos(plr.angy)
			local sxa = math.sin(plr.angx)
			local cxa = math.cos(plr.angx)
			local fwx,fwy,fwz
			fwx,fwy,fwz = sya*cxa, sxa, cya*cxa
			
			-- perform a trace
			local d,cx1,cy1,cz1,cx2,cy2,cz2
			d,cx1,cy1,cz1,cx2,cy2,cz2
			= trace_map_ray_dist(plr.x+sya*0.4,plr.y,plr.z+cya*0.4, fwx,fwy,fwz, 127.5)
			d = d or 127.5
			
			-- see if there's anyone we can kill
			local hurt_idx = nil
			local hurt_part = nil
			local hurt_part_idx = 0
			local hurt_dist = d*d
			local i,j
			
			for i=1,players.max do
				local p = players[i]
				if p and p ~= plr and p.alive then
					local dx = p.x-plr.x
					local dy = p.y-plr.y+0.1
					local dz = p.z-plr.z
					
					for j=1,3 do
						local dd = dx*dx+dy*dy+dz*dz
						
						local dotk = dx*fwx+dy*fwy+dz*fwz
						local dot = math.sqrt(dd-dotk*dotk)
						if dot < 0.55 and dd < hurt_dist then
							hurt_idx = i
							hurt_dist = dd
							hurt_part_idx = j
							hurt_part = ({"head","body","legs"})[j]
							
							break
						end
						dy = dy + 1.0
					end
				end
			end
			
			if hurt_idx then
				if server then
					players[hurt_idx].gun_damage(
						hurt_part, this.cfg.dmg[hurt_part], plr)
				else
					common.net_send(nil, common.net_pack("BBB"
						, 0x13, hurt_idx, hurt_part_idx))
				end
			else
				if client then
					common.net_send(nil, common.net_pack("BBB"
						, 0x13, 0, 0))
				end
				
				if cx2 and cy2 <= ylen-3 then
					bhealth_damage(cx2,cy2,cz2,MODE_BLOCK_DAMAGE_RIFLE)
				end
			end
			
			-- apply recoil
			-- attempting to emulate classic behaviour provided i have it right
			plr.recoil(sec_current, this.cfg.recoil_y, this.cfg.recoil_x)
		end
		
		function this.reload()
			if this.ammo_clip ~= this.cfg.ammo_clip then
			if this.ammo_reserve ~= 0 then
			if not this.reloading then
				this.reloading = true
				client.wav_play_global(wav_rifle_reload, plr.x, plr.y, plr.z)
				common.net_send(nil, common.net_pack("BB", 0x1D, 0))
				plr.zooming = false
				this.t_reload = nil
			end end end
		end
		
		function this.click(button, state)
			if button == 1 then
				-- LMB
				if this.ammo_clip > 0 then
					this.firing = state
				else
					this.firing = false
					-- TODO: play sound
				end
			elseif button == 3 then
				-- RMB
				if hold_to_zoom then
					plr.zooming = state
				else
					if state and not this.reloading then
						plr.zooming = not plr.zooming
					end
				end
			end
		end
		
		function this.get_model()
			return weapon_models[WPN_RIFLE]
		end
		
		function this.draw(px, py, pz, ya, xa, ya2)
			client.model_render_bone_global(this.get_model(), 0,
				px, py, pz, ya, xa, ya2, 3)
		end
		
		function this.tick(sec_current, sec_delta)
			if this.reloading then
				if not this.t_reload then
					this.t_reload = sec_current + this.cfg.time_reload
				end
				
				if sec_current >= this.t_reload then
					local adelta = this.cfg.ammo_clip - this.ammo_clip
					if adelta > this.ammo_reserve then
						adelta = this.ammo_reserve
					end
					this.ammo_reserve = this.ammo_reserve - adelta
					this.ammo_clip = this.ammo_clip + adelta
					this.t_reload = nil
					this.reloading = false
					plr.arm_rest_right = 0
				else
					local tremain = this.t_reload - sec_current
					local telapsed = this.cfg.time_reload - tremain
					local roffs = math.min(tremain,telapsed)
					roffs = math.min(roffs,0.3)/0.3
					
					plr.arm_rest_right = roffs
				end
			elseif this.firing and this.ammo_clip == 0 then
				this.firing = false
			elseif this.firing and ((not this.t_fire) or sec_current >= this.t_fire) then
				prv_fire(sec_current)
				
				this.t_fire = this.t_fire or sec_current
				this.t_fire = this.t_fire + this.cfg.time_fire
				if this.t_fire < sec_current then
					this.t_fire = sec_current
				end
				
				this.ammo_clip = this.ammo_clip - 1
				
				-- TODO: poll: do we want to require a new click per shot?
				-- nope - rakiru
			end
			
			if this.t_fire and this.t_fire < sec_current then
				this.t_fire = nil
			end
		end
		
		return this
	end,
}

weapons_enabled = {}
weapons_enabled[WPN_RIFLE] = true

-- teams
TEAM_INTEL_LIMIT = 10
teams = {
	max = 1,
	[0] = {
		name = "Blue Master Race",
		color_mdl = {16,32,128},
		color_chat = {0,0,255},
		score = 0,
	},
	[1] = {
		name = "Green Master Race",
		color_mdl = {16,128,32},
		color_chat = {0,192,0},
		score = 0,
	},
}

function team_players(team)
	local result = {}
	for k,v in ipairs(players) do
		if v.team == team then
			table.insert(result, v)
		end
	end
	return result
end

cpalette_base = {
	0x7F,0x7F,0x7F,
	0xFF,0x00,0x00,
	0xFF,0x7F,0x00,
	0xFF,0xFF,0x00,
	0x00,0xFF,0x00,
	0x00,0xFF,0xFF,
	0x00,0x00,0xFF,
	0xFF,0x00,0xFF,
}

cpalette = {}
do
	local i,j
	for i=0,7 do
		local r,g,b
		r = cpalette_base[i*3+1]
		g = cpalette_base[i*3+2]
		b = cpalette_base[i*3+3]
		for j=0,3 do
			local cr = math.floor((r*j)/3)
			local cg = math.floor((g*j)/3)
			local cb = math.floor((b*j)/3)
			cpalette[#cpalette+1] = {cr,cg,cb}
		end
		for j=1,4 do
			local cr = r + math.floor(((255-r)*j)/4)
			local cg = g + math.floor(((255-g)*j)/4)
			local cb = b + math.floor(((255-b)*j)/4)
			cpalette[#cpalette+1] = {cr,cg,cb}
        end
	end
end

damage_blk = {}
players = {max = 32, current = 1}
intent = {}
nades = {head = 1, tail = 0}

function player_ranking(x, y)
	if x.score == y.score then
		if x.kills == y.kills then
			if x.deaths == y.deaths then
				return x.pid < y.pid
			end
			return x.deaths < y.deaths
		end
		return x.kills > y.kills
	end
	return x.score > y.score
end