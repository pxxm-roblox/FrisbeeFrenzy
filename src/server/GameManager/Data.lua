local DataManager = {}

local gameData = {
	Frisbee = nil,
}

function DataManager.RegisterFrisbee(frisbeeObject)
	gameData.Frisbee = frisbeeObject
end

function DataManager.DestroyAllFrisbees()
	if gameData.Frisbee then
		gameData.Frisbee:Destroy()
		gameData.Frisbee = nil
	end
end

function DataManager.GetFrisbee()
	return gameData.Frisbee
end

function DataManager.GetTargettedFrisbee(mainChar: Model)
	return (gameData.Frisbee and gameData.Frisbee:GetTarget() == mainChar and gameData.Frisbee)
end

function DataManager.OnCharacterLeave(mainChar: Model)
	local targettedFrisbee = DataManager.GetTargettedFrisbee(mainChar)
	if targettedFrisbee then
		return targettedFrisbee:TotalReset()
	end
end

function DataManager.GetWhiteListPlayers(mainChar: Model): { Model }
	local playerCharacters: { Model } = workspace.InGame:GetChildren()
	table.remove(playerCharacters, table.find(playerCharacters, mainChar))
	return playerCharacters
end

return DataManager
