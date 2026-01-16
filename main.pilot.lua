-- ===== Devices =====
local screen = GetPartFromPort(1, "TouchScreen")
local keyboard = GetPartFromPort(2, "Keyboard")

if not screen then error("ERROR: No touchscreen on port 1") end
if not keyboard then error("ERROR: No keyboard on port 2") end

screen:ClearElements()

local size = screen:GetDimensions()
local screenWidth, screenHeight = size.x, size.y
local password = "cloudy"
local currentUser = "root"
local systemBooted = false

-- ===== File System =====
local function newFolder(name, parent)
    return { 
        type = "folder", 
        name = name, 
        parent = parent, 
        children = {}, 
        props = { 
            created = os.time(),
            modified = os.time(),
            permissions = "rwx"
        } 
    }
end

local function newFile(name, parent, content)
    return { 
        type = "file", 
        name = name, 
        parent = parent, 
        content = content or "", 
        props = { 
            created = os.time(),
            modified = os.time(),
            size = #(content or ""),
            permissions = "rw-"
        } 
    }
end

local fsRoot = newFolder("/", nil)
local currentDir = fsRoot

-- Enhanced demo structure
fsRoot.children["pilot.lua"] = newFile("pilot.lua", fsRoot, "print('Hello, Pixel Terminal OS!')")
fsRoot.children["script.lua"] = newFile("script.lua", fsRoot, "print('This is a script file.')")
fsRoot.children["startup.ez"] = newFile("startup.ez", fsRoot, "print Welcome to EasyExec!\nset x 42\nprint The answer is {x}")
fsRoot.children["docs"] = newFolder("docs", fsRoot)
fsRoot.children["docs"].children["readme.txt"] = newFile("readme.txt", fsRoot.children["docs"], "Pixel Terminal OS v2.0\n\nFeatures:\n- File system with read/write\n- .ez programming language\n- Math operations\n- System utilities\n\nType 'help' for commands!")
fsRoot.children["docs"].children["ezguide.txt"] = newFile("ezguide.txt", fsRoot.children["docs"], "EasyExec (.ez) Language Guide\n\nCommands:\nprint <text> - Display text\nset <var> <value> - Set variable\nif <var> <op> <value> - Conditional\ngoto <line> - Jump to line\nadd/sub/mul/div <var> <value>\ninput <var> - Get user input\nend - End program")
fsRoot.children["bin"] = newFolder("bin", fsRoot)
fsRoot.children["bin"].children["test.ez"] = newFile("test.ez", fsRoot.children["bin"], "print Testing EasyExec\nset counter 1\nset max 5\nprint Count: {counter}\nadd counter 1\nif counter <= max goto 4\nprint Done!")
fsRoot.children["tmp"] = newFolder("tmp", fsRoot)

local function getPath(obj)
    local parts, current = {}, obj
    while current do
        table.insert(parts, 1, current.name)
        current = current.parent
    end
    return table.concat(parts, "/"):gsub("//","/")
end

local function findItem(dir, name)
    return dir.children[name]
end

local function resolvePath(path)
    if path:sub(1,1) == "/" then
        local parts = {}
        for p in path:gmatch("[^/]+") do
            if p ~= "." then
                if p == ".." then
                    table.remove(parts)
                else
                    table.insert(parts, p)
                end
            end
        end
        local current = fsRoot
        for _, p in ipairs(parts) do
            if current.children[p] then
                current = current.children[p]
            else
                return nil
            end
        end
        return current
    else
        return findItem(currentDir, path)
    end
end

-- ===== Curse word filter =====
local blockedWords = { "fuck", "shit", "bitch", "asshole", "cunt", "bastard" }
local function filterBadWords(text)
    for _, bad in ipairs(blockedWords) do
        local pattern = bad:gsub("%a", function(c) return "["..c:lower()..c:upper().."]" end)
        text = text:gsub(pattern, string.rep("*", #bad))
    end
    return text
end

-- ===== Font (unchanged) =====
local font = {
    ["A"] = { "01110", "10001", "10001", "11111", "10001", "10001", "10001" },
    ["B"] = { "11110", "10001", "11110", "10001", "10001", "11110", "00000" },
    ["C"] = { "11111", "10000", "10000", "10000", "10000", "10000", "11111" },
    ["D"] = { "11110", "10001", "10001", "10001", "10001", "10001", "11110" },
    ["E"] = { "11111", "10000", "10000", "11111", "10000", "10000", "11111" },
    ["F"] = { "11111", "10000", "11100", "10000", "10000", "10000", "10000" },
    ["G"] = { "11111", "10000", "10000", "10111", "10001", "10001", "11111" },
    ["H"] = { "10001", "10001", "10001", "11111", "10001", "10001", "10001" },
    ["I"] = { "11111", "00100", "00100", "00100", "00100", "00100", "11111" },
    ["J"] = { "11111", "00001", "00001", "00001", "00001", "10001", "11111" },
    ["K"] = { "10001", "10010", "10100", "11000", "10100", "10010", "10001" },
    ["L"] = { "10000", "10000", "10000", "10000", "10000", "10000", "11111" },
    ["M"] = { "10001", "11011", "10101", "10001", "10001", "10001", "10001" },
    ["N"] = { "10001", "10001", "11001", "10101", "10011", "10001", "10001" },
    ["O"] = { "11111", "10001", "10001", "10001", "10001", "10001", "11111" },
    ["P"] = { "11111", "10001", "10001", "11111", "10000", "10000", "10000" },
    ["Q"] = { "11111", "10001", "10001", "10001", "10001", "11111", "00001" },
    ["R"] = { "11111", "10001", "11111", "11000", "10100", "10010", "10001" },
    ["S"] = { "11111", "10000", "10000", "10000", "11111", "00001", "11111" },
    ["T"] = { "11111", "00100", "00100", "00100", "00100", "00100", "00100" },
    ["U"] = { "10001", "10001", "10001", "10001", "10001", "10001", "11111" },
    ["V"] = { "10001", "10001", "10001", "01010", "01010", "01010", "00100" },
    ["W"] = { "10001", "10001", "10001", "10001", "10001", "10101", "01010" },
    ["X"] = { "10001", "01010", "01010", "00100", "01010", "10001", "10001" },
    ["Y"] = { "10001", "01010", "00100", "01000", "01000", "10000", "10000" },
    ["Z"] = { "11111", "00001", "00010", "00100", "01000", "10000", "11111" },
    [" "] = { "00000", "00000", "00000", "00000", "00000", "00000", "00000" },
    ["0"] = { "11111", "10001", "10011", "10101", "11001", "10001", "11111" },
    ["1"] = { "00100", "01100", "00100", "00100", "00100", "00100", "11111" },
    ["2"] = { "01110", "10001", "00001", "00110", "01000", "10000", "11111" },
    ["3"] = { "11111", "00001", "00001", "00011", "00001", "00001", "11111" },
    ["4"] = { "10001", "10001", "10001", "11111", "00001", "00001", "00001" },
    ["5"] = { "11111", "10000", "10000", "11110", "00001", "00010", "11110" },
    ["6"] = { "11111", "10000", "10000", "11110", "10001", "10001", "11111" },
    ["7"] = { "11111", "00001", "00001", "00010", "00100", "01000", "10000" },
    ["8"] = { "11111", "10001", "10001", "11111", "10001", "10001", "11111" },
    ["9"] = { "11111", "10001", "10001", "11111", "00001", "00010", "11100" },
    [","] = { "00000", "00000", "00000", "00000", "00110", "00010", "00100" },
    ["."] = { "00000", "00000", "00000", "00000", "00000", "01000", "01000" },
    ["▮"] = { "11111", "11111", "11111", "11111", "11111", "11111", "11111" },
    ["/"] = { "00001", "00010", "00100", "00100", "01000", "01000", "10000" },
    [">"] = { "01000", "00100", "00010", "00001", "00010", "00100", "01000" },
    ["<"] = { "00010", "00100", "01000", "10000", "01000", "00100", "00010" },
    ["!"] = { "00100", "00100", "00100", "00100", "00100", "00000", "00100" },
    [":"] = { "00100", "00100", "00100", "00000", "00100", "00100", "00100" },
    ["?"] = { "01110", "10001", "00001", "00010", "00100", "00000", "00100" },
    ["-"] = { "00000", "00000", "01110", "00000", "00000", "00000", "00000" },
    ["+"] = { "00000", "00100", "00100", "11111", "00100", "00100", "00000" },
    ["("] = { "00100", "01000", "10000", "10000", "10000", "01000", "00100" },
    [")"] = { "00100", "00010", "00001", "00001", "00001", "00010", "00100" },
    ['"'] = { "01010", "01010", "00000", "00000", "00000", "00000", "00000" },
    ["'"] = { "00100", "00100", "00000", "00000", "00000", "00000", "00000" },
    ["*"] = { "00000", "00100", "10101", "01110", "10101", "00100", "00000" },
    ["a"] = { "00000", "00000", "01110", "00001", "01111", "10001", "01111" },
    ["b"] = { "10000", "10000", "10110", "10001", "10001", "10001", "11110" },
    ["c"] = { "00000", "00000", "01110", "10001", "10000", "10001", "01110" },
    ["d"] = { "00001", "00001", "01111", "10001", "10001", "10001", "01111" },
    ["e"] = { "00000", "00000", "01110", "10001", "10111", "10000", "01110" },
    ["f"] = { "00110", "01001", "01000", "11100", "01000", "01000", "01000" },
    ["g"] = { "00000", "01110", "10001", "10001", "01111", "00001", "01110" },
    ["h"] = { "10000", "10000", "11110", "10001", "10001", "10001", "10001" },
    ["i"] = { "00100", "00000", "01100", "00100", "00100", "00100", "01110" },
    ["j"] = { "00001", "00000", "00011", "00001", "00001", "01001", "00110" },
    ["k"] = { "10000", "10000", "10010", "10100", "11100", "10010", "10001" },
    ["l"] = { "01100", "00100", "00100", "00100", "00100", "00100", "01110" },
    ["m"] = { "00000", "00000", "11010", "10101", "10101", "10101", "10001" },
    ["n"] = { "00000", "00000", "10110", "11001", "10001", "10001", "10001" },
    ["o"] = { "00000", "00000", "01110", "10001", "10001", "10001", "01110" },
    ["p"] = { "00000", "11110", "10001", "10001", "11110", "10000", "10000" },
    ["q"] = { "00000", "01111", "10001", "10001", "01111", "00001", "00001" },
    ["r"] = { "00000", "10110", "11001", "10000", "10000", "10000", "00000" },
    ["s"] = { "00000", "00000", "01110", "10000", "01110", "00001", "11110" },
    ["t"] = { "01000", "01000", "11100", "01000", "01000", "01001", "00110" },
    ["u"] = { "00000", "00000", "10001", "10001", "10001", "10011", "01101" },
    ["v"] = { "00000", "00000", "10001", "10001", "10001", "01010", "00100" },
    ["w"] = { "00000", "00000", "10001", "10001", "10101", "10101", "01010" },
    ["x"] = { "00000", "00000", "10001", "01010", "00100", "01010", "10001" },
    ["y"] = { "00000", "10001", "10001", "10001", "01111", "00001", "01110" },
    ["z"] = { "00000", "00000", "11111", "00011", "00110", "01100", "11111" },
    ["="] = { "00000", "11111", "00000", "11111", "00000", "00000", "00000" },
    ["_"] = { "00000", "00000", "00000", "00000", "00000", "00000", "11111" },
    ["&"] = { "01100", "10010", "01100", "10101", "10010", "10010", "01101" },
    ["#"] = { "01010", "11111", "01010", "01010", "11111", "01010", "00000" },
    ["%"] = { "11001", "11010", "00100", "01000", "01011", "10011", "00000" },
    ["@"] = { "01110", "10001", "10111", "10101", "10111", "10000", "01110" },
    ["|"] = { "00100", "00100", "00100", "00100", "00100", "00100", "00100" },
    ["~"] = { "00000", "01101", "10010", "00000", "00000", "00000", "00000" },
    ["^"] = { "00100", "01010", "10001", "00000", "00000", "00000", "00000" },
    ["{"] = { "00110", "01000", "01000", "11000", "01000", "01000", "00110" },
    ["}"] = { "01100", "00010", "00010", "00011", "00010", "00010", "01100" },
    ["["] = { "01110", "01000", "01000", "01000", "01000", "01000", "01110" },
    ["]"] = { "01110", "00010", "00010", "00010", "00010", "00010", "01110" },
    ["$"] = { "00100", "01111", "10100", "01110", "00101", "11110", "00100" },
    [";"] = { "00000", "00100", "00100", "00000", "00110", "00010", "00100" },
    ["—"] = { "00000", "00000", "00000", "11111", "00000", "00000", "00000" },
    [string.char(92)] = { "10000", "01000", "00100", "00100", "00010", "00010", "00001" },
}

-- ===== Draw text pixels =====
local function drawTextPixel(parent, text, startX, startY, color)
    local pxSize, pxSpacing, charSpacing = 1, 0, 1
    local cColor = color or Color3.new(0, 1, 0)
    local xCursor = startX
    for char in text:gmatch(".") do
        local charData = font[char] or font[char:upper()] or font[" "]
        for row = 1, #charData do
            for col = 1, #charData[row] do
                if charData[row]:sub(col, col) == "1" then
                    local px = screen:CreateElement("Frame", {
                        Size = UDim2.new(0, pxSize, 0, pxSize),
                        Position = UDim2.new(0, xCursor + (col - 1) * (pxSize + pxSpacing),
                                             0, startY + (row - 1) * (pxSize + pxSpacing)),
                        BackgroundColor3 = cColor, BorderSizePixel = 0, Visible = true
                    })
                    px.Parent = parent
                end
            end
        end
        xCursor = xCursor + (5 * pxSize + (4 * pxSpacing) + charSpacing)
    end
end

-- ===== Output container =====
local outputHeight = screenHeight - 40
local outputFrame = screen:CreateElement("Frame", {
    Size = UDim2.new(1, 0, 0, outputHeight),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1, Visible = true
})
local outputLines, maxLines, lineSpacing, lastDrawnLines = {}, math.floor(outputHeight / 12), 12, 0

-- ===== Word wrapping =====
local function wordWidth(word) return #word * (5+1) - 1 end
local function wrapTextByWords(text, maxPixelWidth)
    local lines, line, lineWidth = {}, "", 0
    local spaceWidth = wordWidth(" ") + 1
    for word in text:gmatch("%S+") do
        local wWidth = wordWidth(word)
        if line == "" then line, lineWidth = word, wWidth
        elseif lineWidth + spaceWidth + wWidth <= maxPixelWidth then
            line, lineWidth = line.." "..word, lineWidth + spaceWidth + wWidth
        else
            table.insert(lines, line)
            line, lineWidth = word, wWidth
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local function clearLineY(yPos)
    for _, child in ipairs(outputFrame:GetChildren()) do
        if math.floor(child.Position.Y.Offset / lineSpacing) == math.floor(yPos / lineSpacing) then
            child:Destroy()
        end
    end
end

local function printLine(line, color)
    line = filterBadWords(line)
    local wrapped = wrapTextByWords(line, screenWidth - 4)
    for _, wl in ipairs(wrapped) do
        table.insert(outputLines, wl)
        if #outputLines > maxLines then
            table.remove(outputLines, 1)
            clearLineY(0)
            lastDrawnLines = math.max(lastDrawnLines - 1, 0)
            for _, child in ipairs(outputFrame:GetChildren()) do
                child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset,
                                           child.Position.Y.Scale, child.Position.Y.Offset - lineSpacing)
            end
        end
    end
    for i = lastDrawnLines + 1, #outputLines do
        clearLineY((i - 1) * lineSpacing)
        drawTextPixel(outputFrame, outputLines[i], 2, (i - 1) * lineSpacing, color)
    end
    lastDrawnLines = #outputLines
end

-- ===== Input area =====
local inputFrame = screen:CreateElement("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, outputHeight),
    BackgroundColor3 = Color3.new(0.1, 0.1, 0.1), Visible = true
})
local promptText = screen:CreateElement("TextLabel", {
    Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(0, 5, 0, 0),
    Text = ">", TextColor3 = Color3.new(0, 1, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left, Visible = true
})
promptText.Parent = inputFrame
local inputText = screen:CreateElement("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 35, 0, 0),
    Text = "", TextColor3 = Color3.new(0, 1, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left, Visible = true
})
inputText.Parent = inputFrame
local currentInput = ""

-- ===== EasyExec (.ez) Interpreter =====
local function executeEZ(code, filename)
    local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    local vars = {}
    local pc = 1
    local maxIterations = 10000
    local iterations = 0
    
    printLine("--- Running " .. filename .. " ---", Color3.new(0, 0.8, 1))
    
    while pc <= #lines do
        iterations = iterations + 1
        if iterations > maxIterations then
            printLine("Error: Program exceeded max iterations", Color3.new(1, 0, 0))
            break
        end
        
        local line = lines[pc]:match("^%s*(.-)%s*$") -- trim
        
        if line == "" or line:sub(1,1) == "#" then
            -- Comment or empty
            pc = pc + 1
        elseif line:sub(1,5) == "print" then
            local msg = line:sub(7)
            msg = msg:gsub("{(%w+)}", function(v) return tostring(vars[v] or "nil") end)
            printLine(msg)
            pc = pc + 1
        elseif line:sub(1,3) == "set" then
            local var, val = line:match("^set%s+(%w+)%s+(.+)$")
            if var then
                local num = tonumber(val)
                vars[var] = num or val
            end
            pc = pc + 1
        elseif line:sub(1,3) == "add" then
            local var, val = line:match("^add%s+(%w+)%s+(.+)$")
            if var and vars[var] then
                vars[var] = (tonumber(vars[var]) or 0) + (tonumber(val) or 0)
            end
            pc = pc + 1
        elseif line:sub(1,3) == "sub" then
            local var, val = line:match("^sub%s+(%w+)%s+(.+)$")
            if var and vars[var] then
                vars[var] = (tonumber(vars[var]) or 0) - (tonumber(val) or 0)
            end
            pc = pc + 1
        elseif line:sub(1,3) == "mul" then
            local var, val = line:match("^mul%s+(%w+)%s+(.+)$")
            if var and vars[var] then
                vars[var] = (tonumber(vars[var]) or 0) * (tonumber(val) or 0)
            end
            pc = pc + 1
        elseif line:sub(1,3) == "div" then
            local var, val = line:match("^div%s+(%w+)%s+(.+)$")
            if var and vars[var] then
                local divisor = tonumber(val) or 1
                if divisor ~= 0 then
                    vars[var] = (tonumber(vars[var]) or 0) / divisor
                else
                    printLine("Error: Division by zero", Color3.new(1, 0, 0))
                end
            end
            pc = pc + 1
        elseif line:sub(1,2) == "if" then
            local rest = line:sub(4)
            local var, op, val, gotoLine = rest:match("^%s*(%w+)%s*([<>=!]+)%s*(%S+)%s+goto%s+(%d+)$")
            if var and op and val then
                local varVal = tonumber(vars[var]) or 0
                local cmpVal = tonumber(val) or 0
                local condition = false
                
                if op == "==" or op == "=" then condition = (varVal == cmpVal)
                elseif op == "!=" or op == "<>" then condition = (varVal ~= cmpVal)
                elseif op == "<" then condition = (varVal < cmpVal)
                elseif op == ">" then condition = (varVal > cmpVal)
                elseif op == "<=" then condition = (varVal <= cmpVal)
                elseif op == ">=" then condition = (varVal >= cmpVal)
                end
                
                if condition then
                    pc = tonumber(gotoLine) or (pc + 1)
                else
                    pc = pc + 1
                end
            else
                pc = pc + 1
            end
        elseif line:sub(1,4) == "goto" then
            local lineNum = line:match("^goto%s+(%d+)$")
            if lineNum then
                pc = tonumber(lineNum)
            else
                pc = pc + 1
            end
        elseif line:sub(1,3) == "end" then
            break
        else
            printLine("Unknown command: " .. line, Color3.new(1, 0.5, 0))
            pc = pc + 1
        end
    end
    
    printLine("--- Program finished ---", Color3.new(0, 0.8, 1))
end

-- ===== Command Handler =====
local function trim(s) return s:match("^%s*(.-)%s*$") end

local function handleCommand(input)
    local cmd = string.lower(trim(input))

    if cmd == "help" then
        printLine("=== Pixel Terminal OS v2.0 ===")
        printLine("File System: ls, cd, pwd, cat, write, append, mkdir, rm, cp, mv, touch, tree")
        printLine("Utilities: clear, echo, about, date, whoami, uptime, neofetch")
        printLine("Programming: run <file.ez>, execute <pass> code <code>")
        printLine("Math: math <expr>, math:<func> <num>")
        printLine("Info: help, sysinfo, diskusage")

    elseif cmd == "clear" then
        outputLines = {}
        outputFrame:ClearAllChildren()
        lastDrawnLines = 0

    elseif cmd:sub(1, 5) == "echo " then
        local msg = input:sub(6)
        printLine(msg)

    elseif cmd == "cat" then
        printLine("  /\\_/\\  ")
        printLine(" ( o.o ) meow!")
        printLine("  > ^ <  ")

    elseif cmd == "about" then
        printLine("Pixel Terminal OS v2.0")
        printLine("By Cloudy Industries")
        printLine("Enhanced with .ez programming language")
        printLine("Full filesystem implementation")

    elseif cmd == "date" then
        printLine("Date: " .. os.date("%Y-%m-%d"))

    elseif cmd == "date exact" then
        printLine("Date & Time: " .. os.date("%Y-%m-%d %H:%M:%S"))

    elseif cmd == "whoami" then
        printLine(currentUser)

    elseif cmd == "uptime" then
        printLine("System uptime: " .. math.floor(os.clock()) .. " seconds")

    elseif cmd == "neofetch" then
        printLine("OS: Pixel Terminal OS v2.0")
        printLine("User: " .. currentUser)
        printLine("Shell: PTShell")
        printLine("Uptime: " .. math.floor(os.clock()) .. "s")
        printLine("Resolution: " .. screenWidth .. "x" .. screenHeight)

    elseif cmd == "sysinfo" then
        printLine("=== System Information ===")
        printLine("OS: Pixel Terminal OS v2.0")
        printLine("Screen: " .. screenWidth .. "x" .. screenHeight)
        printLine("User: " .. currentUser)
        printLine("Working Dir: " .. getPath(currentDir))

    elseif cmd == "diskusage" then
        local function countItems(dir)
            local files, folders = 0, 0
            for _, item in pairs(dir.children) do
                if item.type == "file" then
                    files = files + 1
                elseif item.type == "folder" then
                    folders = folders + 1
                    local f, d = countItems(item)
                    files = files + f
                    folders = folders + d
                end
            end
            return files, folders
        end
        local f, d = countItems(fsRoot)
        printLine("Disk Usage: " .. f .. " files, " .. d .. " folders")

    elseif cmd == "ls" or cmd == "dir" then
        printLine("Contents of " .. getPath(currentDir) .. ":")
        if currentDir.type ~= "folder" then 
            printLine("Error: Not a directory")
            return 
        end
        
        local isEmpty = true
        for name, obj in pairs(currentDir.children) do
            isEmpty = false
            if obj.type == "folder" then
                printLine("[DIR]  " .. name, Color3.new(0.3, 0.8, 1))
            else
                local ext = name:match("%.([^%.]+)$")
                if ext == "ez" then
                    printLine("[FILE] " .. name, Color3.new(1, 0.8, 0))
                else
                    printLine("[FILE] " .. name)
                end
            end
        end
        if isEmpty then
            printLine("(empty)")
        end

    elseif cmd:sub(1,3) == "cd " then
        local target = trim(input:sub(4))
        if target == ".." then
            if currentDir.parent then
                currentDir = currentDir.parent
                printLine("Changed to: " .. getPath(currentDir))
            else
                printLine("Already at root directory")
            end
        elseif target == "/" or target == "\\" then
            currentDir = fsRoot
            printLine("Changed to root directory")
        else
            local item = resolvePath(target) or findItem(currentDir, target)
            if item and item.type == "folder" then
                currentDir = item
                printLine("Changed to: " .. getPath(currentDir))
            else
                printLine("Directory not found: " .. target)
            end
        end

    elseif cmd:sub(1,4) == "cat " then
        local filename = trim(input:sub(5))
        local file = resolvePath(filename) or findItem(currentDir, filename)
        if file and file.type == "file" then
            if file.content and file.content ~= "" then
                printLine("--- " .. filename .. " ---", Color3.new(0, 0.8, 1))
                for line in file.content:gmatch("[^\r\n]+") do
                    printLine(line)
                end
                printLine("--- End of file ---", Color3.new(0, 0.8, 1))
            else
                printLine("File is empty: " .. filename)
            end
        else
            printLine("File not found: " .. filename)
        end

    elseif cmd:sub(1,6) == "mkdir " then
        local foldername = trim(input:sub(7))
        if foldername == "" then
            printLine("Usage: mkdir <folder_name>")
        elseif findItem(currentDir, foldername) then
            printLine("Item already exists: " .. foldername)
        else
            currentDir.children[foldername] = newFolder(foldername, currentDir)
            printLine("Created folder: " .. foldername)
        end

    elseif cmd:sub(1,6) == "write " then
        local args = input:sub(7)
        local filename, content = args:match("^([^%s]+)%s+(.+)$")
        if not filename then
            printLine("Usage: write <filename> <content>")
            printLine("Note: This OVERWRITES the file. Use 'append' to add lines.")
            return
        end
        
        local existing = findItem(currentDir, filename)
        if existing and existing.type == "folder" then
            printLine("Error: " .. filename .. " is a folder")
            return
        end
        
        -- Replace \n with actual newlines
        content = content:gsub("\\n", "\n")
        
        if existing then
            existing.content = content
            existing.props.modified = os.time()
            existing.props.size = #content
            printLine("Overwrote file: " .. filename)
        else
            currentDir.children[filename] = newFile(filename, currentDir, content)
            printLine("Created file: " .. filename)
        end

    elseif cmd:sub(1,7) == "append " then
        local args = input:sub(8)
        local filename, content = args:match("^([^%s]+)%s+(.+)$")
        if not filename then
            printLine("Usage: append <filename> <content>")
            return
        end
        
        local existing = findItem(currentDir, filename)
        if existing and existing.type == "folder" then
            printLine("Error: " .. filename .. " is a folder")
            return
        end
        
        -- Replace \n with actual newlines
        content = content:gsub("\\n", "\n")
        
        if existing and existing.type == "file" then
            existing.content = existing.content .. "\n" .. content
            existing.props.modified = os.time()
            existing.props.size = #existing.content
            printLine("Appended to file: " .. filename)
        else
            currentDir.children[filename] = newFile(filename, currentDir, content)
            printLine("Created file: " .. filename)
        end

    elseif cmd:sub(1,6) == "touch " then
        local filename = trim(input:sub(7))
        if filename == "" then
            printLine("Usage: touch <filename>")
        elseif findItem(currentDir, filename) then
            local file = findItem(currentDir, filename)
            if file.type == "file" then
                file.props.modified = os.time()
                printLine("Updated timestamp: " .. filename)
            else
                printLine("Cannot touch folder: " .. filename)
            end
        else
            currentDir.children[filename] = newFile(filename, currentDir, "")
            printLine("Created empty file: " .. filename)
        end

    elseif cmd:sub(1,3) == "pwd" then
        printLine(getPath(currentDir))

    elseif cmd:sub(1,3) == "rm " then
        local target = trim(input:sub(4))
        local item = findItem(currentDir, target)
        if item then
            currentDir.children[target] = nil
            printLine("Removed: " .. target)
        else
            printLine("Item not found: " .. target)
        end

    elseif cmd:sub(1,3) == "cp " then
        local args = input:sub(4)
        local src, dst = args:match("^([^%s]+)%s+([^%s]+)$")
        if not src or not dst then
            printLine("Usage: cp <source> <destination>")
            return
        end
        
        local srcItem = findItem(currentDir, src)
        if not srcItem then
            printLine("Source not found: " .. src)
            return
        end
        
        if srcItem.type == "file" then
            local newFile = {
                type = "file",
                name = dst,
                parent = currentDir,
                content = srcItem.content,
                props = {
                    created = os.time(),
                    modified = os.time(),
                    size = srcItem.props.size,
                    permissions = srcItem.props.permissions
                }
            }
            currentDir.children[dst] = newFile
            printLine("Copied " .. src .. " to " .. dst)
        else
            printLine("Cannot copy folders (yet)")
        end

    elseif cmd:sub(1,3) == "mv " then
        local args = input:sub(4)
        local src, dst = args:match("^([^%s]+)%s+([^%s]+)$")
        if not src or not dst then
            printLine("Usage: mv <source> <destination>")
            return
        end
        
        local srcItem = findItem(currentDir, src)
        if not srcItem then
            printLine("Source not found: " .. src)
            return
        end
        
        srcItem.name = dst
        currentDir.children[dst] = srcItem
        currentDir.children[src] = nil
        printLine("Moved " .. src .. " to " .. dst)

    elseif cmd == "tree" then
        local function printTree(dir, prefix)
            local items = {}
            for n in pairs(dir.children) do 
                table.insert(items, n) 
            end
            table.sort(items)
            
            for i = 1, #items do
                local name = items[i]
                local item = dir.children[name]
                local isLastItem = (i == #items)
                
                local marker = isLastItem and "└─ " or "├─ "
                local color = item.type == "folder" and Color3.new(0.3, 0.8, 1) or Color3.new(0, 1, 0)
                printLine(prefix .. marker .. name, color)
                
                if item.type == "folder" then
                    local newPrefix = prefix .. (isLastItem and "   " or "│  ")
                    printTree(item, newPrefix)
                end
            end
        end
        
        printLine(getPath(currentDir))
        printTree(currentDir, "")

    elseif cmd:sub(1,4) == "run " then
        local filename = trim(input:sub(5))
        local file = resolvePath(filename) or findItem(currentDir, filename)
        
        if not file then
            printLine("File not found: " .. filename)
        elseif file.type ~= "file" then
            printLine("Not a file: " .. filename)
        elseif not filename:match("%.ez$") then
            printLine("Error: Only .ez files can be run")
        else
            executeEZ(file.content, filename)
        end

    elseif cmd:sub(1,8) == "execute " then
        if cmd:sub(9, 9 + #password - 1) == password then
            local rest = cmd:sub(9 + #password + 1)
            if rest:sub(1, 5) == "code " then
                local expression = input:sub(15 + #password)
                local success, result = pcall(function()
                    return load("return " .. expression)()
                end)
                if success then
                    printLine("Result: " .. tostring(result))
                else
                    -- Try without return
                    success, result = pcall(function()
                        return load(expression)()
                    end)
                    if success then
                        printLine("Executed successfully")
                        if result then
                            printLine("Result: " .. tostring(result))
                        end
                    else
                        printLine("Error: " .. tostring(result))
                    end
                end
            else
                printLine("Unknown execute type")
            end
        else
            printLine("Higher Privileges Required")
        end

    elseif cmd:sub(1,5) == "math:" then
        local prop, args = cmd:match("^math:([a-z]+)%s*(.*)$")
        if not prop then
            printLine("Usage: math:<function> <number>")
            return
        end

        if prop == "random" then
            local minStr, maxStr = args:match("^%s*(%-?[%d%.]+)%s*:%s*(%-?[%d%.]+)%s*$")
            if not minStr or not maxStr then
                printLine("Usage: math:random <min>:<max>")
                return
            end
            local minVal, maxVal = tonumber(minStr), tonumber(maxStr)
            if not minVal or not maxVal then
                printLine("Invalid numbers for random range")
                return
            end
            if minVal > maxVal then minVal, maxVal = maxVal, minVal end
            local result
            if minVal % 1 == 0 and maxVal % 1 == 0 then
                result = math.random(minVal, maxVal)
            else
                result = minVal + math.random() * (maxVal - minVal)
            end
            printLine("Random: " .. tostring(result))
            return
        end

        local num = tonumber(args)
        if not num then
            printLine("Invalid number: " .. tostring(args))
            return
        end

        local result
        if prop == "abs" then result = math.abs(num)
        elseif prop == "sin" then result = math.sin(num)
        elseif prop == "cos" then result = math.cos(num)
        elseif prop == "tan" then result = math.tan(num)
        elseif prop == "asin" then result = math.asin(num)
        elseif prop == "acos" then result = math.acos(num)
        elseif prop == "atan" then result = math.atan(num)
        elseif prop == "sqrt" then
            if num < 0 then printLine("Error: sqrt of negative") return end
            result = math.sqrt(num)
        elseif prop == "log" then
            if num <= 0 then printLine("Error: log of non-positive") return end
            result = math.log(num)
        elseif prop == "log10" then
            if num <= 0 then printLine("Error: log10 of non-positive") return end
            result = math.log10(num)
        elseif prop == "exp" then result = math.exp(num)
        elseif prop == "floor" then result = math.floor(num)
        elseif prop == "ceil" then result = math.ceil(num)
        else
            printLine("Unknown function: " .. prop)
            return
        end
        printLine("Result: " .. tostring(result))

    elseif cmd:sub(1,5) == "math " then
        local expr = input:sub(6)
        if expr:find("[^%d%+%-%*%/%.%(%)%s]") then
            printLine("Invalid math expression")
            return
        end

        local tokens = {}
        local i, len = 1, #expr
        while i <= len do
            local c = expr:sub(i,i)
            if c:match("%d") then
                local num = c
                i = i+1
                while i <= len do
                    local cc = expr:sub(i,i)
                    if cc:match("[%d%.]") then
                        num = num .. cc
                        i = i + 1
                    else break end
                end
                table.insert(tokens, num)
            elseif c:match("[%+%-%*/%(%)%)]") then
                table.insert(tokens, c)
                i = i + 1
            elseif c:match("%s") then
                i = i + 1
            else
                printLine("Invalid character: " .. c)
                return
            end
        end

        local prec = { ["+"] = 1, ["-"] = 1, ["*"] = 2, ["/"] = 2 }
        local outputQ, opStack = {}, {}
        for _, token in ipairs(tokens) do
            if tonumber(token) then
                table.insert(outputQ, token)
            elseif token == "(" then
                table.insert(opStack, token)
            elseif token == ")" then
                while opStack[#opStack] ~= "(" do
                    if #opStack == 0 then printLine("Mismatched parentheses") return end
                    table.insert(outputQ, table.remove(opStack))
                end
                table.remove(opStack)
            else
                while prec[opStack[#opStack]] and prec[opStack[#opStack]] >= prec[token] do
                    table.insert(outputQ, table.remove(opStack))
                end
                table.insert(opStack, token)
            end
        end
        while #opStack > 0 do
            if opStack[#opStack] == "(" or opStack[#opStack] == ")" then
                printLine("Mismatched parentheses") return
            end
            table.insert(outputQ, table.remove(opStack))
        end

        local stackEval = {}
        for _, token in ipairs(outputQ) do
            if tonumber(token) then
                table.insert(stackEval, tonumber(token))
            else
                local b = table.remove(stackEval)
                local a = table.remove(stackEval)
                if not a or not b then printLine("Error evaluating") return end
                if token == "+" then table.insert(stackEval, a + b)
                elseif token == "-" then table.insert(stackEval, a - b)
                elseif token == "*" then table.insert(stackEval, a * b)
                elseif token == "/" then
                    if b == 0 then printLine("Error: Division by zero") return end
                    table.insert(stackEval, a / b)
                end
            end
        end
        if #stackEval == 1 then
            printLine("= " .. tostring(stackEval[1]))
        else
            printLine("Error evaluating expression")
        end

    elseif cmd == "math" or cmd == "math " then
        printLine("Usage: math <expression> or math:<func> <num>")

    elseif cmd == "" then
        -- Do nothing for empty input
    else
        printLine("Unknown command: '" .. cmd .. "'", Color3.new(1, 0.5, 0))
        printLine("Type 'help' for available commands")
    end
end

-- ===== Keyboard events =====
keyboard:Connect("KeyPressed", function(keyCode, keyString)
    if keyString then
        currentInput = currentInput .. keyString
        inputText:ChangeProperties({ Text = currentInput })
    elseif keyCode == Enum.KeyCode.Backspace then
        currentInput = currentInput:sub(1, -2)
        inputText:ChangeProperties({ Text = currentInput })
    end
end)

keyboard:Connect("TextInputted", function(text)
    printLine(">" .. text, Color3.new(0.7, 0.7, 0.7))
    handleCommand(text)
    currentInput = ""
    inputText:ChangeProperties({ Text = "" })
end)

-- ===== Startup Sequence =====
if not systemBooted then
    printLine("Booting Pixel Terminal OS...", Color3.new(0, 1, 1))
    printLine("Loading filesystem...", Color3.new(0, 0.8, 0.8))
    printLine("Initializing EasyExec runtime...", Color3.new(0, 0.8, 0.8))
    printLine("")
    printLine("Welcome to Pixel Terminal OS v2.0", Color3.new(0, 1, 0))
    printLine("Type 'help' for available commands")
    printLine("Type 'run startup.ez' to see .ez in action!")
    printLine("")
    systemBooted = true
end
