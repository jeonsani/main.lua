local validKeys = {
    "key123",  -- Example key
    "anotherKey456"
}

-- Function to check if a key is valid
local function isValidKey(inputKey)
    for _, key in ipairs(validKeys) do
        if inputKey == key then
            return true
        end
    end
    return false
end

-- UI for key input
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local TextBox = Instance.new("TextBox")
local Button = Instance.new("TextButton")
local MessageLabel = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui")

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Frame.Position = UDim2.new(0.5, -100, 0.5, -50)
Frame.Size = UDim2.new(0, 200, 0, 100)

TextBox.Parent = Frame
TextBox.PlaceholderText = "Enter Key"
TextBox.Position = UDim2.new(0.1, 0, 0.2, 0)
TextBox.Size = UDim2.new(0.8, 0, 0.3, 0)

Button.Parent = Frame
Button.Text = "Submit"
Button.Position = UDim2.new(0.1, 0, 0.6, 0)
Button.Size = UDim2.new(0.8, 0, 0.3, 0)

MessageLabel.Parent = Frame
MessageLabel.Text = ""
MessageLabel.Position = UDim2.new(0.1, 0, 0.9, 0)
MessageLabel.Size = UDim2.new(0.8, 0, 0.1, 0)
MessageLabel.TextColor3 = Color3.fromRGB(255, 0, 0)

-- Function to load the main script
local function loadMainScript()
    -- Your main script logic here
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jeonsani/main.lua/refs/heads/main/Start.lua"))()
    -- Example: loadstring(game:HttpGet("https://your-main-script-url.com"))()
end

-- Button click event
Button.MouseButton1Click:Connect(function()
    local inputKey = TextBox.Text
    if isValidKey(inputKey) then
        MessageLabel.Text = "Key Valid! Loading..."
        MessageLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        wait(1)
        ScreenGui:Destroy()
        loadMainScript()
    else
        MessageLabel.Text = "Invalid Key. Try Again."
        MessageLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)
