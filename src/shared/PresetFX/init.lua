local RunService = game:GetService("RunService")
return require(RunService:IsServer() and script.Server or script.Client)
