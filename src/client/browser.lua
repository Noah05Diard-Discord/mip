local modem = peripheral.find("modem")

local defaultStyle = {
    text = {
        background=colors.black,
        textColor=colors.white,
    },
    button = {
        background=colors.gray,
        textColor=colors.white
    },
    textbox = {
        background=colors.gray,
        textColor=colors.white
    },
    body = {
        background=colors.black,
        textColor=colors.white
    }
}

local function dumpErr(err)
    local handle = fs.open("dump","w")
    handle.write(err)
    handle.close()
end

local pageData = {}
local style = defaultStyle
local renderedElements = {}

local page = ""
local site = ""
local currentURL = ""

local scriptCoroutine = nil
local scriptEnv = {}
local cookies = {} -- Cookie storage: [domain] = {[name] = value}
local pendingNavigation = nil -- For script-triggered navigation

modem.open(80)

-- Utility Functions
local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function parseURL(url)
    -- Parse URL like "example.com/page" or "file:path/to/file"
    local parts = split(url, "/")
    if #parts == 0 then
        return nil, nil
    end
    
    if parts[1] == "file" then
        table.remove(parts, 1)
        return "file:", table.concat(parts, "/")
    else
        local hostname = parts[1]
        table.remove(parts, 1)
        local pagePath = table.concat(parts, "/")
        if pagePath == "" then
            pagePath = "/"
        end
        return hostname, pagePath
    end
end

-- Network Functions
local function resolve(hostname)
    local id = math.random(1000,9999)
    modem.transmit(80,80,{
        ["destination"] = "DNS",
        ["action"] = "get_domain",
        ["arg"] = hostname,
        ["id"] = id,
    })
    local timer = os.startTimer(5)
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            local p = ev[5]
            if p.destination == "CLIENT" and p.id == id then
                os.cancelTimer(timer)
                if p.reply.success then
                    return p.reply.pcId
                else
                    return nil, "Domain not found."
                end
            end
        elseif ev[1] == "timer" and ev[2] == timer then
            return nil, "DNS didn't answer."
        end
    end
end

local function resolvePage(pcId, page)
    local id = math.random(1000,9999)
    modem.transmit(80,80,{
        ["destination"] = "SERVER",
        ["action"] = "get_page",
        ["page"] = page,
        ["id"] = id,
        ["pcId"] = pcId,
    })
    local timer = os.startTimer(5)
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            local p = ev[5]
            if p.destination == "CLIENT" and p.id == id then
                os.cancelTimer(timer)
                if p.reply.success then
                    return p.reply.data
                else
                    return nil, "Page not found."
                end
            end
        elseif ev[1] == "timer" and ev[2] == timer then
            return nil, "Page request timed out."
        end
    end
end

-- Page Loading Functions
local function loadPage(filePath)
    local pagedata = {}
    if fs.exists(filePath) then
        local file = fs.open(filePath,"r")
        local content = file.readAll()
        file.close()
        local succ, data = load("return "..content,"page",nil,{colors=colors})
        if not succ then
            style = {
                button = {
                    background = colors.orange,
                    textColor = colors.white
                },
                text = {
                    background = colors.red,
                    textColor = colors.white,
                }
            }
            pagedata = {
                objs={
                    {type="text",text="Error:"},
                    {type="text",text="Failed to parse page data."},
                    {type="text",text="Error at unserialize step."},
                    {type="text",text="Error: "..data}
                },
                ["style"] = style,
                ["title"] = "Error",
                ["description"] = "The requested file could not be parsed.",
                ["script"] = "",
            }
            dump(data)
            return pagedata
        end
        local succ,result = data()
        data = result
        if succ then
            pagedata = data
            pagedata["style"] = pagedata["style"] or defaultStyle
            return pagedata
        else
            
            style = {
                button = {
                    background = colors.orange,
                    textColor = colors.white
                },
                text = {
                    background = colors.red,
                    textColor = colors.white,
                }
            }
            pagedata = {
                objs={
                    {type="text",text="Error:"},
                    {type="text",text="Failed to parse"},
                    {type="text",text="Error: "..result}
                },
                ["style"] = style,
                ["title"] = "Error",
                ["description"] = "The requested file could not be parsed.",
                ["script"] = "",
            }
            dump(result)
        end
    else
        style = {
            button = {
                background = colors.orange,
                textColor = colors.white
            },
            text = {
                background = colors.red,
                textColor = colors.white,
            }
        }
        pagedata = {
            objs={
                {type="text",text="Error:"},
                {type="text",text="File not found"}
            },
            ["style"] = style,
            ["title"] = "Error",
            ["description"] = "The requested file was not found.",
            ["script"] = "",
        }
    end
    return pagedata
end

local function getPage(hostname, page)
    if hostname == "file:" then
        return loadPage(page)
    end
    
    local pcId, err = resolve(hostname)
    if not pcId then
        style = {
            button = {
                background = colors.orange,
                textColor = colors.white
            },
            text = {
                background = colors.red,
                textColor = colors.white,
            }
        }
        local pagedata = {
            objs={
                {type="text",text="Error:"},
                {type="text",text="Failed to resolve domain."}
            },
            ["style"] = style,
            ["title"] = "Error",
            ["description"] = "The requested domain could not be resolved. ("..err..")",
            ["script"] = "",
        }
        return pagedata
    else
        local pagedata, err = resolvePage(pcId, page)
        if not pagedata then
            style = {
                button = {
                    background = colors.orange,
                    textColor = colors.white
                },
                text = {
                    background = colors.red,
                    textColor = colors.white,
                }
            }
            local pagedata = {
                objs={
                    {type="text",text="Error:"},
                    {type="text",text="Failed to load page."}
                },
                ["style"] = style,
                ["title"] = "Error",
                ["description"] = "The requested page could not be loaded. ("..err..")",
                ["script"] = "",
            }
            return pagedata
        else
            pagedata["style"] = pagedata["style"] or defaultStyle
            return pagedata
        end
    end
end

-- Script Environment Setup
local function createScriptEnvironment()
    local dummyG = {}
    
    local env = {
        -- Safe standard libraries
        math = math,
        textutils = {
            serialize = textutils.serialize,
            unserialize = textutils.unserialize,
            serializeJSON = textutils.serializeJSON,
            unserializeJSON = textutils.unserializeJSON,
        },
        http = http,
        
        -- Dummy _G that writes to a local table
        _G = setmetatable({}, {
            __index = dummyG,
            __newindex = function(t, k, v)
                dummyG[k] = v
            end
        }),
        
        -- Prevent access to dangerous functions
        os = nil,
        fs = nil,
        shell = nil,
        io = nil,
        loadfile = nil,
        dofile = nil,
        
        -- Safe print/write functions
        print = function(...)
            local args = {...}
            for i, v in ipairs(args) do
                print(tostring(v))
            end
        end,
        
        -- Allow basic string operations
        string = string,
        table = table,
        tostring = tostring,
        tonumber = tonumber,
        type = type,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        select = select,
        
        -- Browser API
        browser = {
            -- Cookie management
            setCookie = function(name, value)
                if not cookies[site] then
                    cookies[site] = {}
                end
                cookies[site][name] = tostring(value)
                return true
            end,
            
            getCookie = function(name)
                if cookies[site] and cookies[site][name] then
                    return cookies[site][name]
                end
                return nil
            end,
            
            deleteCookie = function(name)
                if cookies[site] and cookies[site][name] then
                    cookies[site][name] = nil
                    return true
                end
                return false
            end,
            
            getAllCookies = function()
                if cookies[site] then
                    local result = {}
                    for k, v in pairs(cookies[site]) do
                        result[k] = v
                    end
                    return result
                end
                return {}
            end,
            
            -- Navigation
            navigate = function(url)
                local hostname, pagePath = parseURL(url)
                if hostname then
                    pendingNavigation = {url = url, hostname = hostname, pagePath = pagePath}
                    return true
                end
                return false
            end,
            
            reload = function()
                if site ~= "" then
                    pageData = getPage(site, page)
                    renderPage()
                end
            end,
            
            getCurrentURL = function()
                return currentURL
            end,
            
            getSite = function()
                return site
            end,
            
            getPage = function()
                return page
            end,
            
            -- Element manipulation
            getElementById = function(id)
                for i, obj in ipairs(pageData.objs) do
                    if obj.id == id then
                        return obj
                    end
                end
                return nil
            end,
            
            getElementsByType = function(elemType)
                local results = {}
                for i, obj in ipairs(pageData.objs) do
                    if obj.type == elemType then
                        table.insert(results, obj)
                    end
                end
                return results
            end,
            
            getElementsByClass = function(className)
                local results = {}
                for i, obj in ipairs(pageData.objs) do
                    if obj.class == className then
                        table.insert(results, obj)
                    end
                end
                return results
            end,
            
            createElement = function(elemType)
                return {
                    type = elemType,
                    x = 1,
                    y = 3,
                }
            end,
            
            appendChild = function(element)
                if element and element.type then
                    table.insert(pageData.objs, element)
                    return true
                end
                return false
            end,
            
            removeElement = function(id)
                for i, obj in ipairs(pageData.objs) do
                    if obj.id == id then
                        table.remove(pageData.objs, i)
                        return true
                    end
                end
                return false
            end,
            
            -- Re-render the page
            render = function()
                renderPage()
            end,
            
            -- Get page data
            getPageData = function()
                return {
                    title = pageData.title,
                    description = pageData.description,
                    objs = pageData.objs,
                }
            end,
            
            -- Update page title
            setTitle = function(newTitle)
                pageData.title = newTitle
                drawTitleBar()
            end,
        },
        
        -- Legacy support - direct getElementById
        getElementById = function(id)
            for i, obj in ipairs(pageData.objs) do
                if obj.id == id then
                    return obj
                end
            end
            return nil
        end,
    }
    
    return env
end

local function runScript(script)
    if not script or script == "" or script == "--Disabled--" then
        return
    end
    
    -- Reset pending navigation
    pendingNavigation = nil
    
    -- Create safe environment
    local env = createScriptEnvironment()
    
    -- Compile script with environment
    local func, err = load(script, "page_script", "t", env)
    if not func then
        print("Script error: " .. tostring(err))
        return
    end
    
    -- Run in coroutine with instruction limit
    scriptCoroutine = coroutine.create(function()
        local instructionCount = 0
        local maxInstructions = 1000000
        
        -- Hook to prevent infinite loops
        debug.sethook(function()
            instructionCount = instructionCount + 1
            if instructionCount > maxInstructions then
                error("Script exceeded instruction limit")
            end
        end, "", 1000)
        
        local success, result = pcall(func)
        debug.sethook() -- Remove hook
        
        if not success then
            print("Script runtime error: " .. tostring(result))
        end
    end)
    
    -- Resume the coroutine
    local success, err = coroutine.resume(scriptCoroutine)
    if not success then
        print("Script error: " .. tostring(err))
        scriptCoroutine = nil
    end
    
    -- Handle pending navigation after script completes
    if pendingNavigation then
        currentURL = pendingNavigation.url
        site = pendingNavigation.hostname
        page = pendingNavigation.pagePath
        pageData = getPage(pendingNavigation.hostname, pendingNavigation.pagePath)
        pendingNavigation = nil
        renderPage()
    end
end

-- Rendering Functions
local function drawTitleBar()
    local w, h = term.getSize()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    
    local title = pageData.title or "Browser"
    term.write(" " .. title)
end

local function drawURLBar()
    local w, h = term.getSize()
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black)
    term.clearLine()
    
    term.write(" ")
    local maxURLLength = w - 2
    local displayURL = currentURL
    if #displayURL > maxURLLength then
        displayURL = string.sub(displayURL, 1, maxURLLength - 3) .. "..."
    end
    term.write(displayURL)
end

local function renderPage()
    local d = pageData
    
    -- Prepare style
    d.style = d.style or defaultStyle
    for k,v in pairs(defaultStyle) do
        if not d.style[k] then
            d.style[k] = v
        else
            for k2,v2 in pairs(v) do
                if not d.style[k][k2] then
                    d.style[k][k2] = v[k2]
                end
            end
        end
    end
    
    -- Clear screen with body background
    term.setBackgroundColor(d.style.body.background)
    term.setTextColor(d.style.body.textColor)
    term.clear()
    
    -- Draw title bar and URL bar
    drawTitleBar()
    drawURLBar()
    
    -- Reset rendered elements
    renderedElements = {}
    
    -- Render elements
    local y = 3
    for i, v in ipairs(d.objs) do
        if not v.x then v.x = 1 end
        if not v.y then v.y = y end
        
        -- Apply class styling
        local elemStyle = d.style[v.type] or {}
        if v.class and d.style["."..v.class] then
            for sk, sv in pairs(d.style["."..v.class]) do
                elemStyle[sk] = sv
            end
        end
        
        if v.type == "text" then
            term.setCursorPos(v.x, v.y)
            term.setBackgroundColor(elemStyle.background or d.style.text.background)
            term.setTextColor(elemStyle.textColor or d.style.text.textColor)
            term.write(v.text)
            
            table.insert(renderedElements, {
                type = "text",
                x1 = v.x,
                y1 = v.y,
                x2 = v.x + #v.text - 1,
                y2 = v.y,
                data = v
            })
            
            y = v.y + 1
            
        elseif v.type == "button" then
            term.setCursorPos(v.x, v.y)
            term.setBackgroundColor(elemStyle.background or d.style.button.background)
            term.setTextColor(elemStyle.textColor or d.style.button.textColor)
            local buttonText = "[ " .. v.text .. " ]"
            term.write(buttonText)
            
            table.insert(renderedElements, {
                type = "button",
                x1 = v.x,
                y1 = v.y,
                x2 = v.x + #buttonText - 1,
                y2 = v.y,
                data = v
            })
            
            y = v.y + 1
            
        elseif v.type == "textbox" then
            term.setCursorPos(v.x, v.y)
            term.setBackgroundColor(elemStyle.background or d.style.textbox.background)
            term.setTextColor(elemStyle.textColor or d.style.textbox.textColor)
            local displayText = v.text or ""
            if displayText == "" and v.placeholder then
                term.setTextColor(colors.gray)
                displayText = v.placeholder
            end
            term.write("[" .. displayText .. string.rep(" ", 20 - #displayText) .. "]")
            
            table.insert(renderedElements, {
                type = "textbox",
                x1 = v.x,
                y1 = v.y,
                x2 = v.x + 21,
                y2 = v.y,
                data = v
            })
            
            y = v.y + 1
            
        elseif v.type == "picture" then
            -- Render NFP image
            if v.nfp then
                local py = v.y
                for line, pixels in ipairs(v.nfp) do
                    term.setCursorPos(v.x, py)
                    for px, pixel in ipairs(pixels) do
                        term.setBackgroundColor(pixel)
                        term.write(" ")
                    end
                    py = py + 1
                end
                y = py
            end
        end
    end
    
    -- Run page script
    if d.script then
        runScript(d.script)
    end
end

local function handleClick(x, y)
    -- Check URL bar click
    if y == 2 then
        term.setCursorPos(2, 2)
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        term.clearLine()
        term.write(" ")
        local newURL = read()
        if newURL and newURL ~= "" then
            local hostname, pagePath = parseURL(newURL)
            if hostname then
                currentURL = newURL
                site = hostname
                page = pagePath
                pageData = getPage(hostname, pagePath)
                renderPage()
            end
        else
            drawURLBar()
        end
        return
    end
    
    -- Check element clicks
    for i, elem in ipairs(renderedElements) do
        if x >= elem.x1 and x <= elem.x2 and y >= elem.y1 and y <= elem.y2 then
            if elem.type == "button" then
                local button = elem.data
                
                -- Check if this is an anchor link (# means script handles it)
                if button.page == "#" then
                    -- Fire click event for script to handle
                    if pageData.script and pageData.script ~= "" and pageData.script ~= "--Disabled--" then
                        -- Create event environment
                        local eventEnv = createScriptEnvironment()
                        eventEnv.clickedButton = button
                        eventEnv.buttonId = button.id or ""
                        
                        -- Try to call onClick handler if defined in script
                        local eventScript = [[
                            if onClick then
                                onClick(clickedButton, buttonId)
                            end
                        ]]
                        
                        local func, err = load(pageData.script .. "\n" .. eventScript, "click_event", "t", eventEnv)
                        if func then
                            local success, result = pcall(func)
                            if not success then
                                print("Click handler error: " .. tostring(result))
                            end
                        end
                    end
                    -- Don't navigate, let script handle it
                    return
                end
                
                -- Normal navigation
                if button.web and button.page then
                    local newURL = button.web .. "/" .. button.page
                    currentURL = newURL
                    site = button.web
                    page = button.page
                    pageData = getPage(button.web, button.page)
                    renderPage()
                elseif button.web then
                    currentURL = button.web
                    local hostname, pagePath = parseURL(button.web)
                    if hostname then
                        site = hostname
                        page = pagePath
                        pageData = getPage(hostname, pagePath)
                        renderPage()
                    end
                end
            elseif elem.type == "textbox" then
                local textbox = elem.data
                term.setCursorPos(elem.x1 + 1, elem.y1)
                term.setBackgroundColor(colors.white)
                term.setTextColor(colors.black)
                local input = read()
                if input then
                    textbox.text = input
                    
                    -- Fire change event for script to handle
                    if pageData.script and pageData.script ~= "" and pageData.script ~= "--Disabled--" then
                        local eventEnv = createScriptEnvironment()
                        eventEnv.changedTextbox = textbox
                        eventEnv.textboxId = textbox.id or ""
                        eventEnv.newValue = input
                        
                        local eventScript = [[
                            if onTextChange then
                                onTextChange(changedTextbox, textboxId, newValue)
                            end
                        ]]
                        
                        local func, err = load(pageData.script .. "\n" .. eventScript, "change_event", "t", eventEnv)
                        if func then
                            local success, result = pcall(func)
                            if not success then
                                print("Change handler error: " .. tostring(result))
                            end
                        end
                    end
                end
                renderPage()
            end
            break
        end
    end
end

-- Main Loop
local function mainLoop()
    while true do
        local e = {os.pullEvent()}
        
        if e[1] == "mouse_click" then
            handleClick(e[3], e[4])
        elseif e[1] == "key" and e[2] == keys.r then
            -- Refresh page
            if site ~= "" then
                pageData = getPage(site, page)
                renderPage()
            end
        elseif e[1] == "term_resize" then
            renderPage()
        end
    end
end

-- Initialize
term.clear()
term.setCursorPos(1, 1)

-- Load homepage or show blank page
currentURL = "file:home.table"
local hostname, pagePath = nil, ""
if hostname then
    site = hostname
    page = pagePath
    pageData = getPage(hostname, pagePath)
else
    pageData = {
        objs = {
            {type="text", text="Welcome to MIP Browser"},
            {type="text", text="Enter a URL in the address bar above"},
        },
        title = "Home",
        style = defaultStyle,
        script = "",
    }
end

renderPage()
mainLoop()