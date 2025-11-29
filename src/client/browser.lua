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
    body = {
        background=colors.black,
        textColor=colors.white
    }
}

local pageData = {}
local style = defaultStyle

local page = ""
local site = ""

modem.open(80)

local function resolve(hostname)
    local id = math.random(1000,9999)
    modem.transmit(80,80,{
        ["destination"] = "DNS",
        ["action"] = "get_domain",
        ["arg"] = hostname,
        ["id"] = id, -- This is only so the DNS Server can reply to that ID so requests don't get mixed up!
    })
    local timer = os.startTimer(5)
    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            local p = ev[5]
            if p.destination == "CLIENT" and p.id == id  then
                if p.reply.success then
                    return p.reply.pcId
                else
                    return nil, "Domain not found."
                end
            end
        elseif ev[1] == "timer" and ev[2] == timer then
            return nil, "DNS didnt answer."
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
            if p.destination == "CLIENT" and p.id == id  then
                if p.reply.success then
                    return p.reply.pagedata
                else
                    return nil, "Page not found."
                end
            end
        elseif ev[1] == "timer" and ev[2] == timer then
            return nil, "Page request timed out."
        end
    end
end

function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end
local function separateString(str)
    -- Separate the page and hostname from like example.com/abc and returns {"example.com","abc"}
    local s = split(str,"/")
end
local function getPage(hostname, page)
    -- Get a page for the renderer
    -- If the hostname is file: then automatically go to loadPage
    if hostname == "file:" then
        return loadPage(page)
    end
    -- Otherwise, resolve the domain and request the page over the network
    local pcId, err = resolve(hostname)
    if not pcId then
        -- Failed to resolve domain
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
                ["script"] = "--Disabled--",
            }
        return pagedata
    else
        -- Domain resolved, request page
        local pagedata, err = resolvePage(pcId, page)
        if not pagedata then
            -- Failed to get page
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
                ["script"] = "--Disabled--",
            }
            return pagedata
        else
            pagedata["style"] = pagedata["style"] or defaultStyle
            return pagedata
        end
    end
end
local function loadPage(filePath)
    local pagedata = {}
    if fs.exists(filePath) then
        -- Try to load it
        local file = fs.open(filePath,"r")
        local content = file.readAll()
        file.close()
        local data = textutils.unserialize(content)
        if data then
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
                    {type="text",text="Failed to parse page data."}
                },
                ["style"] = style,
                ["title"] = "Error",
                ["description"] = "The requested file could not be parsed.",
                ["script"] = "--Disabled--",
            }
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
                ["script"] = "--Disabled--",
            }
    end
    return pagedata
end

local function renderPage()
    for i,a in ipairs(pageData.objs) do
        if a.type == "text" then
            term.setCursorPos(1,i)
            local styles = style[a.type]
            if a.class then
                styles = style[a.class]
            end
            
            term.setBackgroundColor(styles.background)
            term.setTextColor(styles.text)
            write(a.text)
        elseif a.type == "button" then
            term.setCursorPos(1,i)
            local styles = style[a.type]
            if a.class then
                styles = style[a.class]
            end
            term.setBackgroundColor(styles.background)
            term.setTextColor(styles.text)
            write(a.text)
        end
    end
end

local function mainLoop()
    while true do
        local ev = {os.pullEvent()}
    end
end

term.clear()

loadPage("Site",true)
renderPage()

--[[
write("Write domain: ")
local domain = read()
print(resolve(domain))]]
