local modem = peripheral.find("modem")

local defaultStyle = {
    text = {
        background=colors.black,
        text=colors.white,
    },
    button = {
        background=colors.gray,
        text=colors.white
    },
    body = {
        background=colors.black,
        text=colors.white
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

local function loadPage(page,file)
    local pagedata = {}
    if file then
        if fs.exists(page) then
            local handle
        else
            style = {
                button = {
                    background = colors.orange,
                    text = colors.white
                },
                text = {
                    background = colors.red,
                    text = colors.white,
                }
            }
            pagedata = {
                objs={
                    {type="text",text="Error:"},
                    {type="text",text="File not found"}
                }
            }
        end
    else
        -- Do request
    end
    pageData = pagedata
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