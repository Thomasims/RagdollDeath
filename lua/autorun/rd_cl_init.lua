if SERVER then return end

hook.Add("CalcView","RagdollDeathFP",function(ply, pos, angles, fov)
  if LocalPlayer():Alive() then return end --Player's not dead...
	local Rag = LocalPlayer():GetNWEntity("RagDeath")
	if not Rag or not IsValid(Rag) then return end
	local view = {}

	local head=Rag:GetAttachment( Rag:LookupAttachment( "eyes" ) )
	view.origin = head.Pos
	view.angles = head.Ang
	view.fov = fov
	view.znear = 0.5
 
	return view
end)

net.Receive("ragdeath_client",function()
	local Rag = net.ReadInt(32)
	
	local Color = net.ReadVector()
	timer.Simple(0.01,function()
		local RagEnt = Entity(Rag) 
		RagEnt.GetPlayerColor = function(self) 
			return Color
		end
	end)
end)