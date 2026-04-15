local protocol = require("mitProtocol")

local w,h = term.getSize()

local defaultStyle = {
    ["body"] = {
        ["background"] = colors.white,
        ["textColor"] = colors.black,
    },
    ["text"] = {
        ["background"] = colors.white,
        ["textColor"] = colors.black,
    },
    ["button"] = {
        ["background"] = colors.lightGray,
        ["textColor"] = colors.black,
    }
}

local pagedata = {
    eventHooks = {},
    page = {
        objs = {},
        style = {},
        title = "title",
        description = {},
        script = nil
    },
    pagewin = window.create(term.current(),1,2,w,h-1)
}

local function setColors(bg,tx)
    term.setBackgroundColor(bg)
    term.setTextColor(tx)
end

local function getColors(obj)
    local style = {}
    if obj.class then
        if pagedata.page.style["."..tostring(obj.class)] then
            style = pagedata.page.style["."..tostring(obj.class)]
        end
    end
    if pagedata.page.style[obj.type] then
        style = pagedata.page.style[obj.type]
    elseif pagedata.page.style["body"] then
        style = pagedata.page.style["body"]
    elseif defaultStyle[obj.type] then
        style = defaultStyle[obj.type]
    else
        style = defaultStyle["body"] 
    end
    return style.background, style.textColor
end

local renderers = {}

renderers.text = function(obj)
    term.setCursorPos(obj.x,obj.y)
    setColors(getColors(obj))
    term.write(obj.text)
end

local function loadPage(page)
    pagedata.eventHooks = {}
    pagedata.win = window.create(term.current(),1,2,w,h-1)
    pagedata.page = page

    
end

local function loadWeb(web,page)
    local resolve,err = protocol.dnsLookup(web)
    if resolve then
        loadPage(protocol.get_page(resolve,page))
    else
        loadPage({
            objs = {
                {
                    type = "text",
                    text = err,
                    x = 1,
                    y = 1,
                }
            },
            title = "Error"
        })
    end
end

local function render()
    local t = term.current()
    term.redirect(pagedata.pagewin)

    for i,a in ipairs(pagedata.page.objs) do
        if renderers[a.type] then
            renderers[a.type](a)
        end
    end

    term.redirect(t)
end

local function isInText(x,y,obj)
    return y==obj.y and x >= obj.x and x < obj.x+#obj.text
end

local function handleEvent(ev)
    for i,a in ipairs(pagedata.page.objs) do
        if a.type == "button" then
            if ev[1] == "mouse_click" then
                if isInText(ev[3],ev[4],a) then
                    if a.web and a.page then
                        
                    end
                end
            end
        end
    end
end

local function browserLoop()
    while true do
        render()
        local ev = {os.pullEvent()}
        handleEvent(ev)
    end
end