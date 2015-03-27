if SERVER then return end

local LocRag = nil

hook.Add("CalcView","RagdollDeathFP",function(ply, pos, angles, fov)
  if LocalPlayer():Alive() then return end --Player's not dead... or is he?
	local Rag = LocRag
	if not Rag or not IsValid(Rag) then return end
	local view = {}

	local head=Rag:GetAttachment( Rag:LookupAttachment( "eyes" ) )
	view.origin = head.Pos
	view.angles = head.Ang
	view.fov = fov
	view.znear = 0.5
 
	return view
end)

local tries = 0

local setupClientRag
setupClientRag = function(ID, Color, firstp)
	tries = tries+1
	if tries>3 then return end
	LocRag = firstp and Entity(ID)
	if not IsValid(LocRag) then
		timer.Simple(0.04,function() setupClientRag(ID,Color, firstp) end)
	end
	local RagEnt = Entity(ID) 
	RagEnt.GetPlayerColor = function(self) 
		return Color
	end
end

net.Receive("ragdeath_client",function()
	local Rag = net.ReadInt(32)
	local firstp = net.ReadInt(2)
	local Color = net.ReadVector()
	
	timer.Simple(0.01,function()
		tries = 0
		setupClientRag(Rag,Color,firstp~=0)
	end)
end)