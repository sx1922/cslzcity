ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "设施终端"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX 任务入场"
ENT.Spawnable = false
ENT.AdminSpawnable = true

local NW_PA = "MissionIntro_FSP_PAActive"
local NW_OP = "MissionIntro_FSP_PAOperator"
local NW_CD = "MissionIntro_FSP_PACooldown"
local NW_END = "MissionIntro_FSP_PAEndAt"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ScienceCount")
	self:NetworkVar("Int", 1, "ClassDCount")
	self:NetworkVar("Int", 2, "UnknownCount")
	self:NetworkVar("Int", 3, "ScpCount")
end

function ENT:SetPAActive(active)
	self:SetNWBool(NW_PA, active == true)
end

function ENT:GetPAActive()
	return self:GetNWBool(NW_PA, false)
end

function ENT:SetOperator(ply)
	self:SetNWEntity(NW_OP, IsValid(ply) and ply or NULL)
end

function ENT:GetOperator()
	return self:GetNWEntity(NW_OP, NULL)
end

function ENT:SetPACooldownUntil(t)
	self:SetNWFloat(NW_CD, tonumber(t) or 0)
end

function ENT:GetPACooldownUntil()
	return self:GetNWFloat(NW_CD, 0)
end

function ENT:SetPAEndAt(t)
	self:SetNWFloat(NW_END, tonumber(t) or 0)
end

function ENT:GetPAEndAt()
	return self:GetNWFloat(NW_END, 0)
end
