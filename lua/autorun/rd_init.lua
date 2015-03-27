if CLIENT then return end

AddCSLuaFile("rd_cl_init.lua")
util.AddNetworkString("ragdeath_client")

local plyrags = {}
local plydeads = {}
local maxDRagsVar = CreateConVar("ragdeath_keepmax","2",FCVAR_ARCHIVE,"")
local FPRagVar = CreateConVar("ragdeath_firstperson","1",FCVAR_ARCHIVE,"")
local OwnRagVar = CreateConVar("ragdeath_playerown","1",FCVAR_ARCHIVE,"")
local TimeRagVar = CreateConVar("ragdeath_timeremove","120", FCVAR_ARCHIVE,"")
local maxrags = 2

local function pushRag(ply,rag)
	maxrags = math.max(maxDRagsVar:GetInt(),0)
	plyrags[ply] = plyrags[ply] or {}
	if plyrags[ply][maxrags] and IsValid(plyrags[ply][maxrags]) then
		plyrags[ply][maxrags]:Remove()
		plyrags[ply][maxrags] = nil
	end
	for i=math.min(#plyrags[ply],maxrags-1),1,-1 do
		plyrags[ply][i+1] = plyrags[ply][i]
	end
	plyrags[ply][1] = rag
end

function createRagdoll(ply)

	plydeads[ply] = true
	

	local OldRagdoll = ply:GetRagdollEntity()
	if ( OldRagdoll && OldRagdoll:IsValid() ) then OldRagdoll:Remove() end


	local Rag = ents.Create( "prop_ragdoll" )
	Rag:SetModel(ply:GetModel())
	Rag:SetPos(ply:GetPos())
	Rag:Spawn()
	
	local bgs = ""
	for k,v in pairs(ply:GetBodyGroups()) do
	  bgs = bgs .. ply:GetBodygroup(v.id)
	end
	Rag:SetBodyGroups(bgs)
	
	local timedgo = math.max(TimeRagVar:GetInt(),0)
	if timedgo>0 then
	  timer.Simple(timedgo,function()
	    if IsValid(Rag) then 
			Rag:Remove() 
		end 
	  end)
	end
	
	Rag.CanConstrain	= true
	Rag.GravGunPunt		= true
	Rag.PhysgunDisabled	= false
	
	Rag:SetCreator(OwnRagVar:GetBool() and ply or nil)
	
	if CPPI and OwnRagVar:GetBool() then
		Rag:CPPISetOwner( ply )
	end
	
	local Vel = ply:GetVelocity()

	local iNumPhysObjects = Rag:GetPhysicsObjectCount()
	for Bone = 0, iNumPhysObjects-1 do

		local PhysObj = Rag:GetPhysicsObjectNum( Bone )
		if ( PhysObj:IsValid() ) then

			local Pos, Ang = ply:GetBonePosition( Rag:TranslatePhysBoneToBone( Bone ) )
			PhysObj:SetPos( Pos )
			PhysObj:SetAngles( Ang )
			PhysObj:AddVelocity( Vel )

		end

	end

	pushRag(ply,Rag)
	if FPRagVar:GetBool() then
		ply:SetNWEntity( "RagDeath", Rag )
	end
	
	timer.Simple(0.01,function()
	net.Start("ragdeath_client")
		net.WriteInt(Rag:EntIndex(),32)
		net.WriteInt(FPRagVar:GetBool() and 1 or 0,2) 
		local PlayerColor = ply:GetPlayerColor()
		net.WriteVector(Vector( PlayerColor.r, PlayerColor.g, PlayerColor.b ))
	net.Send(player.GetAll())
		
	end)
	
	return

end
hook.Add("PlayerDeath","CreateServerRagdoll",createRagdoll)

hook.Add("PlayerSpawn","MoveRagdollCamera",function(ply) 
	maxrags = math.max(maxDRagsVar:GetInt(),0)
	if maxrags==0 then plyrags[ply][1]:Remove() plyrags[ply][1]=nil end
end)

hook.Add( "PlayerDisconnected", "RagdollDeathDisconnect", function( ply )
	for k,v in pairs(plyrags) do
		if k==ply then
			MsgN("Removing "..ply:Name().."'s ragdolls.")
			for l,b in pairs(v) do
				if IsValid(b) and b then b:Remove() end
			end
			plyrags[k] = nil
		end
	end
end )
MsgN("Ragdoll Death loaded serverside.")





