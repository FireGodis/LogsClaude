--!strict
local services = script.Parent:WaitForChild("SAG_Services")
local GameService = require(services:WaitForChild("GameService"))
GameService.Init()
