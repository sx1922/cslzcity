AddCSLuaFile()

if not Glide then return end

ENT.GlideCategory = "GTAV_Helicopters"

ENT.Type = "anim"
ENT.Base = "glide_gtav_skylift"
ENT.PrintName = "天梯直升机(无磁铁)"

if SERVER then
    ENT.ChassisModel = "models/gta5/vehicles/skylift/skylift2_body.mdl"
    ENT.HasMagnet = false
end
