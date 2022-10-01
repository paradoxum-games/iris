local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Iris = require(ReplicatedStorage.Common.Iris)

local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui");
ScreenGui.Parent = PlayerGui;

local count = 0
local lastT = os.clock()
local rollingDT = 0
local new = true;

function showDemoWindow(Index)
    Iris.PushId(Index)
        local thisWindow = Iris.Window("Iris Demo - " .. Index)

            if new then
                Iris.SetState(thisWindow,{
                    Position = Vector2.new(35,60) * Index,
                    Size = Vector2.new(400,250)
                })
            end

            Iris.Text("This is a demo window!")
            local tree1 = Iris.Tree("first tree")
                Iris.Text("Im inside the first tree!")
                Iris.Button("Im a button inside the first tree!")
                Iris.Tree("Im a tree inside the first tree!")
                    Iris.Text("I am the innermost text")
                Iris.End()
            Iris.End()
        
            if Iris.Button("Change the collapsed state of the above tree").Clicked then
                Iris.SetState(tree1, {
                    Collapsed = not tree1.state.Collapsed
                })
            end

        Iris.End()
    Iris.End()
end

Iris.Connect(ScreenGui, RunService.Heartbeat, function()
    Iris.Text("This is some useful text.")

    if Iris.Button().Clicked then
        count += 1
    end
    Iris.Text(string.format("counter = %d", count))

    local t = os.clock()
    local dt = t-lastT
    rollingDT += (dt - rollingDT) * .2
    lastT = t
    Iris.Text(string.format("Average %.3f ms/frame (%.1f FPS)", rollingDT*1000, 1/rollingDT))

    showDemoWindow(5)
    new = false
end)