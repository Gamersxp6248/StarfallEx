-- Global to all starfalls
local checkluatype = SF.CheckLuaType
local checkpermission = SF.Permissions.check
local registerprivilege = SF.Permissions.registerPrivilege

if SERVER then
	-- Register privileges
	registerprivilege("npcs.modify", "Modify", "Allows the user to modify npcs", { entities = {} })
	registerprivilege("npcs.giveweapon", "Give weapon", "Allows the user to give npcs weapons", { entities = {} })
end


--- Npc type
-- @name Npc
-- @class type
-- @libtbl npc_methods
SF.RegisterType("Npc", false, true, debug.getregistry().NPC, "Entity")

return function(instance)

local owrap, ounwrap = instance.WrapObject, instance.UnwrapObject
local npc_methods, npc_meta, wrap, unwrap = instance.Types.Npc.Methods, instance.Types.Npc, instance.Types.Npc.Wrap, instance.Types.Npc.Unwrap
local ent_meta, ewrap, eunwrap = instance.Types.Entity, instance.Types.Entity.Wrap, instance.Types.Entity.Unwrap

local getent
instance:AddHook("initialize", function()
	getent = instance.Types.Entity.GetEntity
end)

local function getnpc(self)
	local ent = unwrap(self)
	if ent:IsValid() then
		return ent
	else
		SF.Throw("Entity is not valid.", 3)
	end
end

function npc_meta:__tostring()
	local ent = unwrap(self)
	if not ent then return "(null entity)"
	else return tostring(ent) end
end


if SERVER then
	--- Adds a relationship to the npc
	-- @server
	-- @param str The relationship string. http://wiki.garrysmod.com/page/NPC/AddRelationship
	function npc_methods:addRelationship(str)
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:AddRelationship(str)
	end

	local dispositions = {
		error = D_ER,
		hate = D_HT,
		fear = D_FR,
		like = D_LI,
		neutral = D_NU,
		[D_ER] = "error",
		[D_HT] = "hate",
		[D_FR] = "fear",
		[D_LI] = "like",
		[D_NU] = "neutral",
	}
	--- Adds a relationship to the npc with an entity
	-- @server
	-- @param ent The target entity
	-- @param disp String of the relationship. (hate fear like neutral)
	-- @param priority number how strong the relationship is. Higher number is stronger
	function npc_methods:addEntityRelationship(ent, disp, priority)
		local npc = getnpc(self)
		local target = getent(ent)
		local relation = dispositions[disp]
		if not relation then SF.Throw("Invalid relationship specified", 2) end
		checkpermission(instance, npc, "npcs.modify")
		npc:AddEntityRelationship(target, relation, priority)
	end

	--- Gets the npc's relationship to the target
	-- @server
	-- @param ent Target entity
	-- @return string relationship of the npc with the target
	function npc_methods:getRelationship(ent)
		return dispositions[getnpc(self):Disposition(getent(ent))]
	end

	--- Gives the npc a weapon
	-- @server
	-- @param wep The classname of the weapon
	function npc_methods:giveWeapon(wep)
		checkluatype(wep, TYPE_STRING)

		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.giveweapon")

		local weapon = npc:GetActiveWeapon()
		if (weapon:IsValid()) then
			if (weapon:GetClass() == "weapon_" .. wep) then return end
			weapon:Remove()
		end

		npc:Give("ai_weapon_" .. wep)
	end

	--- Tell the npc to fight this
	-- @server
	-- @param ent Target entity
	function npc_methods:setEnemy(ent)
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetTarget(getent(ent))
	end

	--- Gets what the npc is fighting
	-- @server
	-- @return Entity the npc is fighting
	function npc_methods:getEnemy()
		return owrap(getnpc(self):GetEnemy())
	end

	--- Stops the npc
	-- @server
	function npc_methods:stop()
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetSchedule(SCHED_NONE)
	end

	--- Makes the npc do a melee attack
	-- @server
	function npc_methods:attackMelee()
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetSchedule(SCHED_MELEE_ATTACK1)
	end

	--- Makes the npc do a ranged attack
	-- @server
	function npc_methods:attackRange()
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetSchedule(SCHED_RANGE_ATTACK1)
	end

	--- Makes the npc walk to a destination
	-- @server
	-- @param vec The position of the destination
	function npc_methods:goWalk(vec)
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetLastPosition(vunwrap(vec))
		npc:SetSchedule(SCHED_FORCED_GO)
	end

	--- Makes the npc run to a destination
	-- @server
	-- @param vec The position of the destination
	function npc_methods:goRun(vec)
		local npc = getnpc(self)
		checkpermission(instance, npc, "npcs.modify")
		npc:SetLastPosition(vunwrap(vec))
		npc:SetSchedule(SCHED_FORCED_GO_RUN)
	end
end

end
