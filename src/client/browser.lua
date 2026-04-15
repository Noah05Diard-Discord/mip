local protocol = require("mipProtocol")
local sandbox = require("sandbox")

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
    },
    ["textbox"] = {
        ["background"]= colors.gray,
        ["textColor"] = colors.white
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
    pagewin = window.create(term.current(),1,2,w,h-1),
    selectedTextBox = nil,
    pcid = 0
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

local function getBackground()
    if pagedata.page.style["body"] then
        return pagedata.page.style["body"].background
    else
        return defaultStyle["body"]["background"]
    end
end

local renderers = {}

renderers.text = function(obj)
    term.setCursorPos(obj.x,obj.y)
    setColors(getColors(obj))
    term.write(obj.text)
end

renderers.button = function(obj)
    term.setCursorPos(obj.x,obj.y)
    setColors(getColors(obj))
    term.write(obj.text)
end

renderers.textbox = function(obj)
    term.setCursorPos(obj.x,obj.y)
    setColors(getColors(obj))
    term.write(obj.text == "" and obj.placeholder or obj.text)
end

local function fileDialog()
    local f = {}
    local rf,rd;
    local function setPath(p)
        f = {
            {text="...",call=function()
                setPath(fs.getDir(p))
            end}
        }
        for i,a in ipairs(fs.list(p)) do
            local path = fs.combine(p,a)
            table.insert(f,{
                text = fs.isDir(path) and "folder:"..a or "file:"..a,
                call = function()
                    if fs.isDir(path) then
                        setPath(path)
                    else
                        local fl = fs.open(path,"r")
                        local d = fl.readAll()
                        fl.close()
                        rf,rd = a,d
                    end
                end
            })
        end
    end
    setPath("/")
    repeat
        term.setBackgroundColor(colors.gray)
        term.clear()
        for i,a in ipairs(f) do
            term.setCursorPos(1,i)
            term.write(a.text)
        end
        local e = {os.pullEvent()}
        if e[1] == "mouse_click" then
            local el = f[e[4]]
            if el then
                el.call()
            end
        end
    until rf and rd
    return rf,rd
end

local function loadPage(page,pcid)
    pagedata.eventHooks = {}
    pagedata.win = window.create(term.current(),1,2,w,h-1)
    pagedata.page = page
    pagedata.selectedTextBox = nil
    pagedata.pcid = pcid or os.getComputerID()

    if page.script then
        local func = sandbox.load(page.script)
        local cor = coroutine.wrap(func)
        cor()
    end
end

local function loadWeb(web,page)
    local resolve,err = protocol.dnsLookup(web)
    if resolve then
        loadPage(protocol.get_page(resolve,page),resolve)
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
            style = {},
            title = "Error"
        })
    end
end

local function pageChangeDialog()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.gray)
    term.clear()
    write("Address: ")
    local addr = read()
    write("Page: ")
    local page = read()
    loadWeb(addr,page)
end

local function render()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    write(pagedata.page.title)
    write(" | Press [pause] to change page")
    local t = term.current()
    term.redirect(pagedata.pagewin)

    term.setBackgroundColor(getBackground())
    term.clear()

    for i,a in ipairs(pagedata.page.objs) do
        if renderers[a.type] then
            renderers[a.type](a)
        end
    end

    term.redirect(t)
end

local function isInText(x,y,obj)
    return y==obj.y and (x >= obj.x and x < (obj.x+#obj.text))
end

local function isInTextBox(x,y,obj)
    if #obj.placeholder > #obj.text then
        return y==obj.y and (x >= obj.x and x < (obj.x+#obj.placeholder))
    else
        return y==obj.y and (x >= obj.x and x < (obj.x+#obj.text))
    end
end

local function handleEvent(ev)
    if ev[1] == "key" then
        if ev[2] == keys.pause then
            pageChangeDialog()
        end
    end
    local dmc = false -- "Did mouse collide?"
    for i,a in ipairs(pagedata.page.objs) do
        if a.type == "button" then
            if ev[1] == "mouse_click" then
                if isInText(ev[3],ev[4]-1,a) then
                    dmc = true
                    if a.web and a.page then
                        loadWeb(a.web,a.page)
                    elseif pagedata.eventHooks["button"] then
                        
                        for i,a2 in ipairs(pagedata.eventHooks["button"]) do
                            a2(a.id,ev[2])
                        end
                    end
                end
            end
        elseif a.type == "textbox" then
            if ev[1] == "mouse_click" then
                if isInTextBox(ev[3],ev[4]-1,a) then
                    dmc = true
                    pagedata.selectedTextBox = a
                end
            elseif ev[1] == "char" then
                if pagedata.selectedTextBox == a then
                    a.text = a.text .. ev[2]
                end
            elseif ev[1] == "key" then
                if pagedata.selectedTextBox == a then
                    if ev[2] == keys.backspace then
                        a.text = a.text:sub(1,-2)
                    elseif ev[2] == keys.enter then
                        pagedata.selectedTextBox = nil
                        if pagedata.eventHooks["textbox_enter"] then
                            for i,a2 in ipairs(pagedata.eventHooks["textbox_enter"]) do
                                a2(a.id,a.text)
                            end
                        end
                    end
                end
            end
        end
    end
    if ev[1] == "mouse_click" and not dmc then
        pagedata.selectedTextBox = nil
    end
end

sandbox.registerApi("document",{
    getElementById = function (id)
        for i, a in ipairs(pagedata.page.objs) do
            if a.id == id then
                return a
            end
        end
    end,
    addElement = function(element)
        table.insert(pagedata.page.objs,element)
    end
})

sandbox.registerApi("event",{
    hook = function(event,callback)
        local e = pagedata.eventHooks[event]
        if e then
            table.insert(e,callback)
        else
            pagedata.eventHooks[event] = {
                callback
            }
        end
    end
})

sandbox.registerApi("protocol",{
    upload = function(file,data)
        return protocol.upload(file,data)
    end,
    download = function(file)
        return protocol.download(file)
    end
})

sandbox.registerApi("browser",{
    fileDialog = function()
        return fileDialog()
    end,
    download = function(file,data)
        local f = fs.open(fs.combine("/downloads/",fs.combine(file)),"w")
        f.write(data)
        f.close()
    end
})

local function browserLoop()
    while true do
        render()
        local ev = {os.pullEvent()}
        handleEvent(ev)
    end
end

loadPage({
    objs = {
        {
            type = "text",
            text = "Greetings",
            x = w/2,
            y = 1,
        },
        {
            type = "text",
            text = "Welcome to the BROWSER",
            class = "normal",
            x = 1,
            y = 2,
        },
        {
            type = "button",
            text = "Im a button",
            id = "button",
            x = 1,
            y = 3
        },
        {
            type = "text",
            text = "press the button",
            class = "normal",
            id = "chn",
            x = 1,
            y = 4,
        },
        {
            type = "textbox",
            text = "",
            placeholder = "Type",
            class = "normal",
            id = "s",
            x = 1,
            y = 5
        }
    },
    style = {
        [".normal"] = {
            background = colors.white,
            textColor = colors.lightGray
        }
    },
    title = "Home | Browser",
    script = [[
        document.getElementById("chn").text = "this is chnaged by a script"
        event.hook("button",function()
            document.getElementById("chn").text = "thx"
        end)
    ]]
})

browserLoop()