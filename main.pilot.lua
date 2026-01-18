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
    local arrays = {}  -- Array storage
    local functions = {}
    local callStack = {}
    local labels = {}  -- Label mapping
    local pc = 1
    local maxIterations = 100000
    local iterations = 0
    local breakFlag = false
    local continueFlag = false
    
    -- Helper functions
    local function safeNum(val) 
        local n = tonumber(val)
        if n then return n end
        -- Try resolving as variable
        if vars[val] and type(vars[val]) == "number" then return vars[val] end
        return 0
    end
    
    local function resolveValue(val)
        -- Handle variable references
        if vars[val] ~= nil then return vars[val] end
        -- Handle string literals
        if val:sub(1,1) == '"' and val:sub(-1,-1) == '"' then
            return val:sub(2, -2)
        end
        -- Handle numbers
        local num = tonumber(val)
        if num then return num end
        -- Handle booleans
        if val == "true" then return true end
        if val == "false" then return false end
        return val
    end
    
    local function evaluateExpression(expr)
        -- Handle simple math expressions
        expr = expr:gsub("{([^}]+)}", function(v) return tostring(vars[v] or 0) end)
        local success, result = pcall(function() return load("return " .. expr)() end)
        if success then return result end
        return resolveValue(expr)
    end
    
    local function evaluateCondition(cond)
        -- Parse complex conditions with and/or/not
        local function evalSimple(s)
            s = s:match("^%s*(.-)%s*$")
            
            -- Handle 'not' prefix
            if s:sub(1,4) == "not " then
                return not evalSimple(s:sub(5))
            end
            
            -- Check for comparison operators
            local var, op, val = s:match("^(%w+)%s*([<>=!]+)%s*(.+)$")
            if var then
                local left = vars[var]
                if left == nil then return false end
                local right = evaluateExpression(val)
                
                if type(left) == "number" and type(right) == "number" then
                    if op == "==" or op == "=" then return left == right
                    elseif op == "!=" then return left ~= right
                    elseif op == "<" then return left < right
                    elseif op == ">" then return left > right
                    elseif op == "<=" then return left <= right
                    elseif op == ">=" then return left >= right end
                else
                    if op == "==" or op == "=" then return left == right
                    elseif op == "!=" then return left ~= right end
                end
            end
            
            -- Check for truthiness
            local v = vars[s]
            if v ~= nil then
                if type(v) == "boolean" then return v end
                if type(v) == "number" then return v ~= 0 end
                if type(v) == "string" then return v ~= "" end
            end
            return false
        end
        
        -- Handle 'and' operator
        if cond:find(" and ") then
            for part in cond:gmatch("[^and]+") do
                if not evalSimple(part) then return false end
            end
            return true
        end
        
        -- Handle 'or' operator
        if cond:find(" or ") then
            for part in cond:gmatch("[^or]+") do
                if evalSimple(part) then return true end
            end
            return false
        end
        
        return evalSimple(cond)
    end
    
    -- Pre-scan for labels and functions
    for i = 1, #lines do
        local line = lines[i]:match("^%s*(.-)%s*$")
        
        -- Find labels
        local label = line:match("^:(%w+)$")
        if label then
            labels[label] = i
        end
        
        -- Find functions
        local fname, params = line:match("^func%s+(%w+)(.*)$")
        if fname then
            local paramList = {}
            if params and params ~= "" then
                for param in params:gmatch("%w+") do
                    table.insert(paramList, param)
                end
            end
            functions[fname] = {start = i + 1, params = paramList}
        end
    end
    
    printLine("=== EasyExec v3.0 Enhanced - " .. filename .. " ===", Color3.new(0, 1, 0))
    
    while pc <= #lines and pc > 0 do
        iterations = iterations + 1
        if iterations > maxIterations then
            printLine("FATAL: Execution limit exceeded", Color3.new(1, 0, 0))
            break
        end
        
        if breakFlag then break end
        if continueFlag then
            continueFlag = false
            -- Find next endloop
            local depth = 1
            while pc <= #lines do
                pc = pc + 1
                local l = lines[pc]:match("^%s*(.-)%s*$")
                if l:match("^loop%s") or l:match("^while%s") or l:match("^for%s") then
                    depth = depth + 1
                elseif l == "endloop" or l == "endwhile" or l == "endfor" then
                    depth = depth - 1
                    if depth == 0 then break end
                end
            end
        end
        
        local line = lines[pc]:match("^%s*(.-)%s*$")
        
        -- Skip empty lines and comments
        if line == "" or line:sub(1,1) == "#" or line:sub(1,2) == "--" then
            pc = pc + 1
            
        -- Labels (skip them during execution)
        elseif line:match("^:%w+$") then
            pc = pc + 1
            
        -- Variable assignment: set var value
        elseif line:match("^set%s") then
            local var, value = line:match("^set%s+(%w+)%s+(.*)$")
            if var then
                vars[var] = evaluateExpression(value)
            end
            pc = pc + 1
            
        -- Increment/decrement: inc var [amount], dec var [amount]
        elseif line:match("^inc%s") or line:match("^dec%s") then
            local op, var, amount = line:match("^(%w+)%s+(%w+)%s*(.*)$")
            if var and vars[var] and type(vars[var]) == "number" then
                local amt = amount ~= "" and safeNum(amount) or 1
                if op == "inc" then
                    vars[var] = vars[var] + amt
                else
                    vars[var] = vars[var] - amt
                end
            end
            pc = pc + 1
            
        -- Print with variable substitution
        elseif line:match("^print%s") then
            local msg = line:match("^print%s+(.*)$")
            msg = msg:gsub("{([^}]+)}", function(v)
                local val = vars[v]
                if type(val) == "string" then return val
                elseif val ~= nil then return tostring(val)
                else return "nil" end
            end)
            printLine(msg)
            pc = pc + 1
            
        -- Math operations: add/sub/mul/div/mod/pow var value
        elseif line:match("^(%w+)%s+(%w+)%s") then
            local op, var, value = line:match("^(%w+)%s+(%w+)%s+(.+)$")
            if var and vars[var] ~= nil and type(vars[var]) == "number" then
                local current = vars[var]
                local operand = evaluateExpression(value)
                if type(operand) ~= "number" then operand = 0 end
                
                if op == "add" then vars[var] = current + operand
                elseif op == "sub" then vars[var] = current - operand
                elseif op == "mul" then vars[var] = current * operand
                elseif op == "div" and operand ~= 0 then vars[var] = current / operand
                elseif op == "mod" and operand ~= 0 then vars[var] = current % operand
                elseif op == "pow" then vars[var] = current ^ operand
                elseif op == "min" then vars[var] = math.min(current, operand)
                elseif op == "max" then vars[var] = math.max(current, operand)
                else
                    pc = pc + 1
                end
            end
            pc = pc + 1
            
        -- Block-based if statement: if condition {
        elseif line:match("^if%s+.+{$") then
            local cond = line:match("^if%s+(.+){$")
            local result = evaluateCondition(cond)
            
            if not result then
                -- Skip to closing brace or else
                local depth = 1
                while pc < #lines do
                    pc = pc + 1
                    local l = lines[pc]:match("^%s*(.-)%s*$")
                    if l:match("{$") then depth = depth + 1
                    elseif l == "}" then
                        depth = depth - 1
                        if depth == 0 then break end
                    elseif l == "else" and depth == 1 then
                        break
                    end
                end
            end
            pc = pc + 1
            
        -- Else block
        elseif line == "else" then
            -- Skip to closing brace
            local depth = 1
            while pc < #lines do
                pc = pc + 1
                local l = lines[pc]:match("^%s*(.-)%s*$")
                if l:match("{$") then depth = depth + 1
                elseif l == "}" then
                    depth = depth - 1
                    if depth == 0 then break end
                end
            end
            pc = pc + 1
            
        -- Closing brace
        elseif line == "}" then
            pc = pc + 1
            
        -- While loop: while condition {
        elseif line:match("^while%s+.+{$") then
            local cond = line:match("^while%s+(.+){$")
            local loopStart = pc
            
            if evaluateCondition(cond) then
                callStack[#callStack+1] = {type="while", start=loopStart, cond=cond}
                pc = pc + 1
            else
                -- Skip to endwhile
                local depth = 1
                while pc < #lines do
                    pc = pc + 1
                    local l = lines[pc]:match("^%s*(.-)%s*$")
                    if l:match("^while%s") then depth = depth + 1
                    elseif l == "endwhile" then
                        depth = depth - 1
                        if depth == 0 then break end
                    end
                end
                pc = pc + 1
            end
            
        -- End while
        elseif line == "endwhile" then
            if #callStack > 0 and callStack[#callStack].type == "while" then
                local loop = callStack[#callStack]
                if evaluateCondition(loop.cond) then
                    pc = loop.start + 1
                else
                    table.remove(callStack)
                    pc = pc + 1
                end
            else
                pc = pc + 1
            end
            
        -- For loop: for var start end [step]
        elseif line:match("^for%s") then
            local var, startVal, endVal, step = line:match("^for%s+(%w+)%s+(.-)%s+to%s+(.-)%s*step%s*(.*)$")
            if not var then
                var, startVal, endVal = line:match("^for%s+(%w+)%s+(.-)%s+to%s+(.*)$")
                step = "1"
            end
            
            if var then
                local s = safeNum(startVal)
                local e = safeNum(endVal)
                local st = step and safeNum(step) or 1
                vars[var] = s
                callStack[#callStack+1] = {type="for", var=var, current=s, endVal=e, step=st, start=pc}
                pc = pc + 1
            else
                pc = pc + 1
            end
            
        -- End for
        elseif line == "endfor" then
            if #callStack > 0 and callStack[#callStack].type == "for" then
                local loop = callStack[#callStack]
                loop.current = loop.current + loop.step
                vars[loop.var] = loop.current
                
                local shouldContinue = (loop.step > 0 and loop.current <= loop.endVal) or
                                      (loop.step < 0 and loop.current >= loop.endVal)
                
                if shouldContinue then
                    pc = loop.start + 1
                else
                    table.remove(callStack)
                    pc = pc + 1
                end
            else
                pc = pc + 1
            end
            
        -- Break statement
        elseif line == "break" then
            -- Pop loop from stack
            if #callStack > 0 then
                local loopType = callStack[#callStack].type
                table.remove(callStack)
                
                -- Skip to end of loop
                local depth = 1
                while pc < #lines do
                    pc = pc + 1
                    local l = lines[pc]:match("^%s*(.-)%s*$")
                    if loopType == "while" and l == "endwhile" and depth == 1 then break
                    elseif loopType == "for" and l == "endfor" and depth == 1 then break
                    end
                end
            end
            pc = pc + 1
            
        -- Continue statement
        elseif line == "continue" then
            if #callStack > 0 then
                local loop = callStack[#callStack]
                if loop.type == "for" then
                    -- Jump to endfor to increment
                    local depth = 1
                    while pc < #lines do
                        pc = pc + 1
                        local l = lines[pc]:match("^%s*(.-)%s*$")
                        if l:match("^for%s") then depth = depth + 1
                        elseif l == "endfor" then
                            depth = depth - 1
                            if depth == 0 then break end
                        end
                    end
                elseif loop.type == "while" then
                    -- Jump to endwhile to check condition
                    local depth = 1
                    while pc < #lines do
                        pc = pc + 1
                        local l = lines[pc]:match("^%s*(.-)%s*$")
                        if l:match("^while%s") then depth = depth + 1
                        elseif l == "endwhile" then
                            depth = depth - 1
                            if depth == 0 then break end
                        end
                    end
                end
            else
                pc = pc + 1
            end
            
        -- Goto with labels: goto labelname
        elseif line:match("^goto%s") then
            local target = line:match("^goto%s+(%w+)$")
            if target then
                -- Try label first
                if labels[target] then
                    pc = labels[target] + 1
                else
                    -- Try line number
                    pc = safeNum(target)
                end
            else
                pc = pc + 1
            end
            
        -- Array operations: array name size OR array name [val1, val2, ...]
        elseif line:match("^array%s") then
            local name, rest = line:match("^array%s+(%w+)%s+(.*)$")
            if name then
                if rest:match("^%[.+%]$") then
                    -- Initialize with values
                    local values = rest:sub(2, -2)
                    arrays[name] = {}
                    for val in values:gmatch("[^,]+") do
                        table.insert(arrays[name], evaluateExpression(val:match("^%s*(.-)%s*$")))
                    end
                else
                    -- Initialize with size
                    local size = safeNum(rest)
                    arrays[name] = {}
                    for i = 1, size do
                        arrays[name][i] = 0
                    end
                end
            end
            pc = pc + 1
            
        -- Array access: get var array[index]
        elseif line:match("^get%s") then
            local var, arr, idx = line:match("^get%s+(%w+)%s+(%w+)%[(.+)%]$")
            if var and arr and arrays[arr] then
                local index = safeNum(idx)
                vars[var] = arrays[arr][index] or 0
            end
            pc = pc + 1
            
        -- Array set: put array[index] value
        elseif line:match("^put%s") then
            local arr, idx, val = line:match("^put%s+(%w+)%[(.+)%]%s+(.+)$")
            if arr and arrays[arr] then
                local index = safeNum(idx)
                arrays[arr][index] = evaluateExpression(val)
            end
            pc = pc + 1
            
        -- Array length: len var array
        elseif line:match("^len%s") then
            local var, arr = line:match("^len%s+(%w+)%s+(%w+)$")
            if var and arr and arrays[arr] then
                vars[var] = #arrays[arr]
            end
            pc = pc + 1
            
        -- Array push: push array value
        elseif line:match("^push%s") then
            local arr, val = line:match("^push%s+(%w+)%s+(.+)$")
            if arr and arrays[arr] then
                table.insert(arrays[arr], evaluateExpression(val))
            end
            pc = pc + 1
            
        -- Array pop: pop var array
        elseif line:match("^pop%s") then
            local var, arr = line:match("^pop%s+(%w+)%s+(%w+)$")
            if var and arr and arrays[arr] then
                vars[var] = table.remove(arrays[arr]) or 0
            end
            pc = pc + 1
            
        -- String length: strlen var string
        elseif line:match("^strlen%s") then
            local var, str = line:match("^strlen%s+(%w+)%s+(.+)$")
            if var then
                local s = resolveValue(str)
                vars[var] = #tostring(s)
            end
            pc = pc + 1
            
        -- String concatenation: concat var str1 str2
        elseif line:match("^concat%s") then
            local var, s1, s2 = line:match("^concat%s+(%w+)%s+(%S+)%s+(.+)$")
            if var then
                local str1 = tostring(resolveValue(s1))
                local str2 = tostring(resolveValue(s2))
                vars[var] = str1 .. str2
            end
            pc = pc + 1
            
        -- Substring: substr var string start [length]
        elseif line:match("^substr%s") then
            local var, str, start, len = line:match("^substr%s+(%w+)%s+(%S+)%s+(%d+)%s*(%d*)$")
            if var and str then
                local s = tostring(resolveValue(str))
                local st = safeNum(start)
                local ln = len ~= "" and safeNum(len) or #s
                vars[var] = s:sub(st, st + ln - 1)
            end
            pc = pc + 1
            
        -- Random number: rand var min max
        elseif line:match("^rand%s") then
            local var, min, max = line:match("^rand%s+(%w+)%s+(.-)%s+(.+)$")
            if var then
                local minVal = safeNum(min)
                local maxVal = safeNum(max)
                vars[var] = math.random(minVal, maxVal)
            end
            pc = pc + 1
            
        -- Sleep/wait: wait milliseconds
        elseif line:match("^wait%s") then
            local ms = line:match("^wait%s+(%d+)$")
            if ms then
                local msNum = tonumber(ms) or 0
                -- Convert milliseconds to seconds for Roblox wait()
                if msNum > 0 then
                    wait(msNum / 1000)
                end
            end
            pc = pc + 1
            
        -- Function definition
        elseif line:match("^func%s") then
            -- Skip to end
            local depth = 1
            while pc < #lines do
                pc = pc + 1
                local l = lines[pc]:match("^%s*(.-)%s*$")
                if l:match("^func%s") then depth = depth + 1
                elseif l == "endfunc" then
                    depth = depth - 1
                    if depth == 0 then break end
                end
            end
            pc = pc + 1
            
        -- Function call: call funcname [args...]
        elseif line:match("^call%s") then
            local fname, args = line:match("^call%s+(%w+)%s*(.*)$")
            if functions[fname] then
                -- Save current vars (simple scope)
                local savedVars = {}
                for k, v in pairs(vars) do savedVars[k] = v end
                
                -- Parse arguments
                local argList = {}
                if args ~= "" then
                    for arg in args:gmatch("%S+") do
                        table.insert(argList, evaluateExpression(arg))
                    end
                end
                
                -- Set parameters
                for i, param in ipairs(functions[fname].params) do
                    vars[param] = argList[i] or 0
                end
                
                callStack[#callStack+1] = {type="function", returnTo=pc+1, savedVars=savedVars}
                pc = functions[fname].start
            else
                printLine("ERROR: Function not found: " .. fname, Color3.new(1, 0.5, 0))
                pc = pc + 1
            end
            
        -- Return from function
        elseif line == "return" or line == "endfunc" then
            if #callStack > 0 and callStack[#callStack].type == "function" then
                local func = callStack[#callStack]
                -- Restore vars
                vars = func.savedVars
                table.remove(callStack)
                pc = func.returnTo
            else
                break
            end
            
        -- Input: input var prompt
        elseif line:match("^input%s") then
            local var, prompt = line:match("^input%s+(%w+)%s+(.+)$")
            if var then
                printLine("INPUT: " .. prompt, Color3.new(0.8, 0.8, 0))
                vars[var] = ""  -- Placeholder for actual input
            end
            pc = pc + 1
            
        -- Type conversion: int var value OR str var value
        elseif line:match("^int%s") then
            local var, val = line:match("^int%s+(%w+)%s+(.+)$")
            if var then
                vars[var] = math.floor(safeNum(val))
            end
            pc = pc + 1
            
        elseif line:match("^str%s") then
            local var, val = line:match("^str%s+(%w+)%s+(.+)$")
            if var then
                vars[var] = tostring(resolveValue(val))
            end
            pc = pc + 1
            
        -- Boolean operations: bool var value
        elseif line:match("^bool%s") then
            local var, val = line:match("^bool%s+(%w+)%s+(.+)$")
            if var then
                local v = resolveValue(val)
                if type(v) == "boolean" then vars[var] = v
                elseif type(v) == "number" then vars[var] = v ~= 0
                elseif type(v) == "string" then vars[var] = v ~= ""
                else vars[var] = false end
            end
            pc = pc + 1
            
        -- Absolute value: abs var value
        elseif line:match("^abs%s") then
            local var, val = line:match("^abs%s+(%w+)%s+(.+)$")
            if var then
                vars[var] = math.abs(safeNum(val))
            end
            pc = pc + 1
            
        -- Square root: sqrt var value
        elseif line:match("^sqrt%s") then
            local var, val = line:match("^sqrt%s+(%w+)%s+(.+)$")
            if var then
                local n = safeNum(val)
                if n >= 0 then
                    vars[var] = math.sqrt(n)
                else
                    printLine("ERROR: Cannot sqrt negative number", Color3.new(1, 0.5, 0))
                end
            end
            pc = pc + 1
            
        -- Floor/Ceil: floor var value OR ceil var value
        elseif line:match("^floor%s") then
            local var, val = line:match("^floor%s+(%w+)%s+(.+)$")
            if var then
                vars[var] = math.floor(safeNum(val))
            end
            pc = pc + 1
            
        elseif line:match("^ceil%s") then
            local var, val = line:match("^ceil%s+(%w+)%s+(.+)$")
            if var then
                vars[var] = math.ceil(safeNum(val))
            end
            pc = pc + 1
            
        -- Assert: assert condition message
        elseif line:match("^assert%s") then
            local cond, msg = line:match("^assert%s+(.-)%s+(.+)$")
            if cond then
                if not evaluateCondition(cond) then
                    printLine("ASSERTION FAILED: " .. msg, Color3.new(1, 0, 0))
                    break
                end
            end
            pc = pc + 1
            
        -- Debug print: debug var
        elseif line:match("^debug%s") then
            local var = line:match("^debug%s+(%w+)$")
            if var then
                local val = vars[var]
                local typeStr = type(val)
                printLine("[DEBUG] " .. var .. " = " .. tostring(val) .. " (" .. typeStr .. ")", Color3.new(1, 1, 0))
            end
            pc = pc + 1
            
        -- Dump all variables
        elseif line == "dump" then
            printLine("=== Variable Dump ===", Color3.new(0.5, 1, 0.5))
            for k, v in pairs(vars) do
                printLine(k .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
            end
            printLine("=== End Dump ===", Color3.new(0.5, 1, 0.5))
            pc = pc + 1
            
        -- Swap two variables: swap var1 var2
        elseif line:match("^swap%s") then
            local v1, v2 = line:match("^swap%s+(%w+)%s+(%w+)$")
            if v1 and v2 then
                vars[v1], vars[v2] = vars[v2], vars[v1]
            end
            pc = pc + 1
            
        -- Clamp value: clamp var min max
        elseif line:match("^clamp%s") then
            local var, minVal, maxVal = line:match("^clamp%s+(%w+)%s+(.-)%s+(.+)$")
            if var and vars[var] then
                local val = vars[var]
                local min = safeNum(minVal)
                local max = safeNum(maxVal)
                if type(val) == "number" then
                    vars[var] = math.max(min, math.min(max, val))
                end
            end
            pc = pc + 1
            
        -- Switch case (simplified): switch var
        elseif line:match("^switch%s") then
            local var = line:match("^switch%s+(%w+)$")
            if var then
                local switchVal = vars[var]
                local matched = false
                
                -- Look for case statements
                while pc < #lines do
                    pc = pc + 1
                    local l = lines[pc]:match("^%s*(.-)%s*$")
                    
                    if l:match("^case%s") then
                        local caseVal = l:match("^case%s+(.+)$")
                        if evaluateExpression(caseVal) == switchVal then
                            matched = true
                            pc = pc + 1
                            break
                        end
                    elseif l == "default" then
                        matched = true
                        pc = pc + 1
                        break
                    elseif l == "endswitch" then
                        break
                    end
                end
                
                if not matched then
                    -- Skip to endswitch
                    while pc < #lines do
                        pc = pc + 1
                        if lines[pc]:match("^%s*(.-)%s*$") == "endswitch" then
                            break
                        end
                    end
                end
            end
            pc = pc + 1
            
        -- Case in switch
        elseif line:match("^case%s") then
            -- Skip to next case or endswitch
            while pc < #lines do
                pc = pc + 1
                local l = lines[pc]:match("^%s*(.-)%s*$")
                if l:match("^case%s") or l == "default" or l == "endswitch" then
                    pc = pc - 1
                    break
                end
            end
            pc = pc + 1
            
        -- Default case
        elseif line == "default" then
            pc = pc + 1
            
        -- End switch
        elseif line == "endswitch" then
            pc = pc + 1
            
        -- Try-catch block: try {
        elseif line == "try {" then
            callStack[#callStack+1] = {type="try", tryStart=pc}
            pc = pc + 1
            
        -- Catch block: catch {
        elseif line == "catch {" then
            -- Skip catch if no error
            if #callStack > 0 and callStack[#callStack].type == "try" then
                table.remove(callStack)
                -- Skip to end of catch
                local depth = 1
                while pc < #lines do
                    pc = pc + 1
                    local l = lines[pc]:match("^%s*(.-)%s*$")
                    if l:match("{$") then depth = depth + 1
                    elseif l == "}" then
                        depth = depth - 1
                        if depth == 0 then break end
                    end
                end
            end
            pc = pc + 1
            
        -- Throw error: throw message
        elseif line:match("^throw%s") then
            local msg = line:match("^throw%s+(.+)$")
            printLine("ERROR THROWN: " .. msg, Color3.new(1, 0, 0))
            -- Jump to catch if exists
            if #callStack > 0 and callStack[#callStack].type == "try" then
                while pc < #lines do
                    pc = pc + 1
                    if lines[pc]:match("^%s*(.-)%s*$") == "catch {" then
                        break
                    end
                end
            else
                break
            end
            
        -- Sleep comment (cosmetic)
        elseif line:match("^sleep%s") then
            local ms = line:match("^sleep%s+(%d+)$")
            printLine("(sleeping " .. ms .. "ms)", Color3.new(0.4, 0.4, 0.4))
            pc = pc + 1
            
        -- Comment
        elseif line:match("^rem%s") or line:match("^comment%s") then
            pc = pc + 1
            
        else
            printLine("ERROR: Unknown command '" .. line .. "' at line " .. pc, Color3.new(1, 0.5, 0))
            pc = pc + 1
        end
    end
    
    printLine("=== Execution Complete ===", Color3.new(0, 1, 0))
    printLine("Total iterations: " .. iterations, Color3.new(0.5, 0.5, 0.5))
    return vars
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
