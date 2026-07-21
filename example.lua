-- Example usage after publishing init.lua and Lucide.lua to GitHub
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tenzarek/TenzodereUI/main/init.lua"))()

local Window = Library:CreateWindow({
    Name = "TENZODERE",
    Subtitle = "private build",
    Keybind = Enum.KeyCode.Insert,
    Accent = Color3.fromRGB(245, 170, 239),
})

local Combat = Window:CreateTab("Combat", "Target")
local Players = Window:CreateTab("Players", "Eye")
local Configs = Window:CreateTab("Configs", "Settings")

local localSection = Players:CreateSection("Local")
localSection:CreateSlider({Name="Fov", Min=30, Max=120, Default=90, Callback=function(v) print("Fov",v) end})
localSection:CreateToggle({Name="Trail", Default=false, Callback=function(v) print("Trail",v) end})
localSection:CreateDropdown({Name="Sky", Options={"none","purple","night"}, Default="none", Callback=print})

local enemySection = Players:CreateSection("Enemy")
enemySection:CreateToggle({Name="Arm chams", Default=false})
enemySection:CreateButton({Name="Add", Callback=function() print("Added") end})

local controls = Combat:CreateSection("Button")
controls:CreateToggle({Name="ButtonSett", Default=false})
controls:CreateButton({Name="Button", Callback=function() print("Button") end})
controls:CreateSlider({Name="Track", Min=0, Max=100, Default=10})
controls:CreateDropdown({Name="Choose", Options={"Selected","All","Nearest"}, Default="Selected"})
controls:CreateColorPicker({Name="Color", Default=Color3.fromRGB(128,133,255), Callback=function(c) print(c) end})
controls:CreateKeybind({Name="Bind", Default=Enum.KeyCode.None, Callback=function(key) print(key) end})

Configs:CreateConfigManager({Folder="TenzodereUI", DefaultName="srry.cfg"})
