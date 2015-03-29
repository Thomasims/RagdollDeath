if SERVER then return end

local LocRag = nil
local FP = false

hook.Add("CalcView","RagDeath_Cam",function(ply, pos, angles, fov)
	
	if LocalPlayer():Alive() then return end
	if not IsValid(LocRag) then return end
	if not FP then 
		local rd = util.TraceLine({start=LocRag:GetPos(),endpos=LocRag:GetPos()-angles:Forward()*105,filter={LocRag,LocalPlayer()}})
		return {origin=LocRag:GetPos()-angles:Forward()*(100*rd.Fraction),angles=angles,fov=fov,znear=0.5} 
	end
	local view = {}

	local head = LocRag:GetAttachment( LocRag:LookupAttachment( "eyes" ) )
	view.origin = head.Pos
	view.angles = head.Ang
	view.fov = fov
	view.znear = 0.5
 
	return view
end)

local HoldOnEnt = {}

net.Receive("ragdeath_client",function()
	local Rag = net.ReadInt(32)
	local Ply = net.ReadInt(32)
	local Color = net.ReadVector()
	FP = net.ReadBool()
	HoldOnEnt = {rag=Rag,ply=Ply,color=Color}
end)

hook.Add("NetworkEntityCreated","RagDeath_Setup",function(ent)
	if not HoldOnEnt.rag then return end
	if HoldOnEnt.rag==ent:EntIndex() then
		if HoldOnEnt.ply==LocalPlayer():EntIndex() then LocRag=ent end
		local getcol = HoldOnEnt.color
		Entity(HoldOnEnt.rag).GetPlayerColor = function(self) return getcol end
		HoldOnEnt = {}
	end
end)