if CLIENT then return end

AddCSLuaFile("rd_cl_init.lua")
util.AddNetworkString("ragdeath_client")

local MaxDRagsVar = CreateConVar("ragdeath_keepmax","2",FCVAR_ARCHIVE,"")
local FPRagVar = CreateConVar("ragdeath_firstperson","1",FCVAR_ARCHIVE,"")
local OwnRagVar = CreateConVar("ragdeath_playerown","1",FCVAR_ARCHIVE,"")
local TimeRagVar = CreateConVar("ragdeath_timeremove","120", FCVAR_ARCHIVE,"")
local CollideRagVar = CreateConVar("ragdeath_playercollide","1", FCVAR_ARCHIVE,"")

local DeathRagdolls = {}

local function createRagdoll(player)
	
	local OldRagdoll = player:GetRagdollEntity()
	if ( OldRagdoll && OldRagdoll:IsValid() ) then OldRagdoll:Remove() end


	local Ragdoll = ents.Create( "prop_ragdoll" )
	Ragdoll:SetModel(player:GetModel())
	Ragdoll:SetPos(player:GetPos())
	
	for k,v in pairs(player:GetBodyGroups()) do
		Ragdoll:SetBodygroup(v.id,player:GetBodygroup(v.id))
	end
	
	Ragdoll:Spawn()
	
	Ragdoll:SetCollisionGroup(not CollideRagVar:GetBool() and COLLISION_GROUP_WEAPON or COLLISION_GROUP_NONE)
	
	local PlyVel = player:GetVelocity()
	
	for ID = 0, Ragdoll:GetPhysicsObjectCount()-1 do
		local PhysBone = Ragdoll:GetPhysicsObjectNum( ID )
		if ( PhysBone:IsValid() ) then
			local Pos, Ang = player:GetBonePosition( Ragdoll:TranslatePhysBoneToBone( ID ) )
			PhysBone:SetPos( Pos )
			PhysBone:SetAngles( Ang )
			PhysBone:AddVelocity( PlyVel )
		end
	end
	
	Ragdoll.CanConstrain = true
	Ragdoll.GravGunPunt = true
	Ragdoll.PhysgunDisabled = false
	
	local PlayerColor = player:GetPlayerColor()
	Ragdoll.RagColor = Vector(PlayerColor.r, PlayerColor.g, PlayerColor.b)
	
	Ragdoll:SetCreator(OwnRagVar:GetBool() and player or nil)
	
	if CPPI and OwnRagVar:GetBool() then
		Ragdoll:CPPISetOwner( player )
	end
	
	local timedgo = math.max(TimeRagVar:GetInt(),0)
	if timedgo>0 then
	  timer.Simple(timedgo,function() if IsValid(Ragdoll) then Ragdoll:Remove() end end)
	end
	
	return Ragdoll
end

local hasntRespawned = {}

local function playerDie(ply)
	hasntRespawned[ply] = true
	local Ragdoll = createRagdoll(ply)
	if not IsValid(Ragdoll) then return end
	DeathRagdolls[ply] = DeathRagdolls[ply] or {}
	maxrags = math.max(MaxDRagsVar:GetInt(),1)
	while #DeathRagdolls[ply]>=maxrags do
		local olrag = DeathRagdolls[ply][1]
		if IsValid(olrag) then olrag:Remove() end
		table.remove(DeathRagdolls[ply],1)
	end
	DeathRagdolls[ply][#DeathRagdolls[ply]+1] = Ragdoll
	
	net.Start("ragdeath_client")
		net.WriteInt(Ragdoll:EntIndex(),32)
		net.WriteInt(ply:EntIndex(),32)
		net.WriteVector(Ragdoll.RagColor)
		net.WriteBool(FPRagVar:GetBool())
	net.Send(player.GetAll())
end
hook.Add("PlayerDeath","RagDeath_Death",playerDie)

local function doRespawnPly(ply)
	hasntRespawned[ply] = nil
	DeathRagdolls[ply] = DeathRagdolls[ply] or {}
	maxrags = math.max(MaxDRagsVar:GetInt(),0)
	if maxrags==0 then 
		local olrag = DeathRagdolls[ply][1]
		if IsValid(olrag) then olrag:Remove() end
		table.remove(DeathRagdolls[ply],1)
	end
end

hook.Add("PlayerSpawn","RagDeath_Spawn",doRespawnPly)

hook.Add("Think","RagDeath_FixSp",function()
	if #hasntRespawned == 0 then return end
	for k,v in pairs(hasntRespawned) do
		if k:Alive() then
			doRespawnPly(k)
		end
	end
	
end)

hook.Add( "PlayerDisconnected", "RagDeath_RemDC", function( ply )
	hasntRespawned[ply] = nil
	for k,v in pairs(DeathRagdolls[ply] or {}) do
		if IsValid(v) and v then v:Remove() end
	end
	DeathRagdolls[ply] = nil
end )