local protocol = require("mipProtocol")
local sandbox = require("sandbox")

local diffY = 0
local maxY = 0

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

local browserRoot = fs.combine(fs.getDir(shell.getRunningProgram()),".mip_browse")

local cookies = {}

local function getCookie(site,k)
    if not cookies[site] then return nil end
    return cookies[site][k]
end

local function saveCookies()
    local f = fs.open(fs.combine(browserRoot,"cookies"),"w")
    f.write(textutils.serialise(cookies))
    f.close()
end

local function loadCookies()
    if fs.exists(fs.combine(browserRoot,"cookies")) then
        local f = fs.open(fs.combine(browserRoot,"cookies"),"r")
        local data = f.readAll()
        f.close()
        cookies = textutils.unserialise(data)
    else
        saveCookies()
        loadCookies()
    end
end

local function setCookie(site,k,v)
    if not cookies[site] then
        cookies[site] = {
            [k] = v
        }
        saveCookies()
    else
        cookies[site][k] = v
        saveCookies()
    end
end

loadCookies()

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
    origin = "browser",
    pcid = 0
}

local function setColors(bg,tx)
    term.setBackgroundColor(bg)
    term.setTextColor(tx)
end

local function getColors(obj)
    local style = {}
    if obj.class and pagedata.page.style["."..tostring(obj.class)] then
        style = pagedata.page.style["."..tostring(obj.class)]
    elseif pagedata.page.style[obj.type] then
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

renderers.text = function(obj,i)
    term.setCursorPos(obj.x or 1,obj.y or i)
    setColors(getColors(obj))
    term.write(obj.text)
end

renderers.button = function(obj,i)
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

local function clr()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    term.clear()
end

local function loadPage(page,pcid)
    page.style = page.style or {}
    page.title = page.title or "Document"
    pagedata.eventHooks = {}
    pagedata.win = window.create(term.current(),1,2,w,h-1)
    pagedata.page = page
    pagedata.selectedTextBox = nil
    pagedata.pcid = pcid or os.getComputerID()
    diffY = 0
    if page.script then
        local func = sandbox.load(page.script)
        local error = false
        local cor = coroutine.wrap(function()
            xpcall(func,function(err)
                clr()
                print(debug.traceback(err))
                error = true
            end)
        end)
        cor()
        if error then
            os.pullEvent("char")
            loadPage({
                objs = {
                    {type="text",text="Continue by pressing [pause]"}
                },
                title = "Script Error"
            })
        end
    end
end

local function loadWeb(web,page)
    -- Check if web is number
    if tonumber(web) ~= nil then
        -- Me : Woman driver; Others << Ahh! >>
        -- What a joke! (hhoy dont kill me)
        -- OMG ITS A PCID!!!!1!1!
        web = tonumber(web)
        print("sup pcid")
        local p, err = protocol.get_page(web,page)
        if p then
            loadPage(p,web)
            pagedata.origin = tostring(web)
        else
            loadPage({
                objs = {
                    {
                        type = "text",
                        text = err
                    },
                    title = "Error"
                },
            })
        end
        return
    end
    local resolve,err = protocol.dnsLookup(web)
    if resolve then
        local p, err = protocol.get_page(resolve,page)
        if p then
            loadPage(p,resolve)
            pagedata.origin = web
        else
            loadPage({
                objs = {
                    {
                        type = "text",
                        text = err
                    },
                    title = "Error"
                },
            })
        end
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
    write(" | Press [pause] to change page or click here")
    term.setCursorPos(w,1)
    term.setBackgroundColor(colors.red)
    write("X")
    term.setBackgroundColor(colors.black)
    local t = term.current()
    term.redirect(pagedata.pagewin)

    term.setBackgroundColor(getBackground())
    term.clear()
    for i,a in ipairs(pagedata.page.objs) do
        a.y = a.y or i
        if a.y > maxY then
            maxY = a.y
        end
    end

    for i,a in ipairs(pagedata.page.objs) do
        a.y = a.y + diffY
        if renderers[a.type] and a.y > 0 then
            renderers[a.type](a,i)
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
        if ev[2] == keys.pause or ev[2] == keys.tab then
            pageChangeDialog()
        end
    elseif ev[1] == "mouse_click" then
        if ev[3] == w and ev[4] == 1 then
            error("Terminated",0)
        elseif ev[3] ~= w and ev[4] == 1 then
            pageChangeDialog()
        end
    elseif ev[1] == "term_resize" then
        w,h = term.getSize()
        pagedata.pagewin.reposition(1,2,w,h-1)
    elseif ev[1] == "mouse_scroll" and diffY+ev[2] < 0 and diffY+ev[2] > maxY then
        diffY = diffY + ev[2]
    end
    if pagedata.eventHooks[ev] then
        for i,a in pairs(pagedata.eventHooks) do
            a(table.unpack(ev,2))
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
    end,
    removeElementById = function(id)
        for i,a in ipairs(pagedata.page.objs) do
            if a.id == id then
                table.remove(pagedata.page.objs,i)
            end
        end
    end,
    getPage = function()
        return pagedata.origin
    end,
    redirect = function(web,page)
        loadWeb(web,page)
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
    end,

    startTimer = os.startTimer,

    cancelTimer = os.cancelTimer
})

sandbox.registerApi("protocol",{
    upload = function(pcid,file,data)
        return protocol.upload(pcid,file,data)
    end,
    download = function(pcid,file)
        return protocol.download(pcid,file)
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

sandbox.registerApi("cookie",{
    set = function(k,v) 
        setCookie(pagedata.origin,k,v)
    end,
    get = function(k)
        return getCookie(pagedata.origin,k)
    end
})

sandbox.registerApi("style",{
    get = function(class)
        return pagedata.page.style["."..tostring(class)]
    end,
    set = function(class,style)
        pagedata.page.style["."..tostring(class)] = style
    end,
    getElement = function(element)
        return pagedata.page.style[element]
    end,
    setElement = function(element)
        return pagedata
    end
})

sandbox.registerApi("serialize",{
    serialize = textutils.serialize,
    serializeJSON = textutils.serializeJSON,
    unserialize = textutils.unserialize,
    unserializeJSON = textutils.unserializeJSON
})

local function browserLoop()
    render()
    local renderTimer = os.startTimer(0.1)
    while true do
        render()
        local ev = {os.pullEvent()}
        handleEvent(ev)
        if not ev[1] == "timer" then
            render()
            os.cancelTimer(renderTimer)
            renderTimer = os.startTimer(0.1)
        elseif ev[1] == "timer" and ev[2] == renderTimer then
            render()
            os.cancelTimer(renderTimer)
            renderTimer = os.startTimer(0.1)
        end
    end
end



loadPage({
    objs = {
        {
            type = "text",
            text = "Browser",
            x = w/2-3,
            y = 1
        },
        {
            type = "textbox",
            text = "",
            id = "domain",
            placeholder = "Type webdomain",
            x = 1,
            y = 2,
        },
        {
            type = "textbox",
            text = "",
            id = "page",
            placeholder = "Type pagename",
            x = 1,
            y = 3,
        },
        {
            type = "button",
            text = "Goto",
            id = "goto",
            x = 1,
            y = 4,
        },
        {
            type = "button",
            text = "Add Bookmark",
            id = "ab",
            x = 6,
            y = 4,
        }
    },
    title = "home",
    script = [[
    local bookmarks = cookie.get("bookmarks") or {
        ["moo.gle"] = ""
    }
    function renderBookmarks()
        document.removeElementById("bookmark")
        local i = 4
        for k,v in pairs(bookmarks) do
            i = i+1
            document.addElement({
                type = "button",
                text = k,
                id = "bookmark",
                web = k,
                page = v,
                x = 1,
                y = i
            })
        end
    end
    renderBookmarks()
    event.hook("button",function(id)
        local domain = document.getElementById("domain").text
        local page = document.getElementById("page").text
        if id == "goto" then
            document.redirect(domain,page)
        elseif id == "ab" then
            bookmarks[domain] = page
            renderBookmarks()
            cookie.set("bookmarks",bookmarks)
        end
    end)
    ]]
})

local er

local suc, r = xpcall(browserLoop,function(err)
    er = err
    if err ~= "Terminated" then
        clr()
        print("MIP Browser Crashed! With error:")
        
        printError(debug.traceback(err))
    end
end)
if not suc then
    if er ~= "Terminated" then
        os.pullEventRaw("char")
    end
end

clr()
r()
