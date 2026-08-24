AddCSLuaFile()

if not Glide then return end

ENT.GlideCategory = "GTAV_Helicopters"

ENT.Type = "anim"
ENT.Base = "glide_gtav_polmav"
ENT.PrintName = "小牛救护直升机"

if SERVER then
    ENT.ChassisMass = 500
    ENT.ChassisModel = "models/gta5/vehicles/polmav/polmav2_body.mdl"
end
