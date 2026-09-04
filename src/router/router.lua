-- Code written by Noah with no AI!
-- Modifications are not allowed.
-- Redistribution is not allowed.
-- Stealing the code is not allowed (except if authorized).
-- Using git.lua on this script is strictly prohibited.

print("Smart Router is starting...")
local pcId = os.getComputerID()
local password = "password" -- nvm :D
local oP = peripheral.wrap("back") -- Modem to the public network
-- basically connected to your ISP plug
local iP = peripheral.wrap("front") -- Modem to the internal network
-- basically where your personal devices are plugged in
local panelIP = "router.local" -- in the internal network, type
-- this panelIP to access the panel from your personal device
-- (in your MIP browser)
local exteriorIP = pcId -- this shouldn't be changed to access
-- the same panel from the public network, type the pcId of
-- the router in your MIP browser - Auth will be required
local settingsFilePath = "settings.cfg" -- The path to the
-- settings file, password can't be changed from panel anymore
-- cuz curse you :D
local debugMode = true

local function writeFile(path,content)
    local file = fs.open(path,"w")
    file.write(content)
    file.close()
end

local function readFile(path)
    local file = fs.open(path,"r")
    local content = file.readAll()
    file.close()
    return content
end

local mipLimiter = -1
local normalLimiter = -1
local ports
local settings

local function initializeDatabase()
    if not fs.exists(settingsFilePath) then
        print("Hey, it seems like this is the first time you are running this router.")
        print("setting up default settings...")
        local settings = {
            mipLimiter = -1,
            normalLimiter = -1,
            ports = {
                6060, -- mail yey
                6161, -- idk
                5034, -- hnacc
            }
        }
        writeFile(settingsFilePath, textutils.serialize(settings))
    else
        print("Loading settings")
        settings = textutils.unserialize(readFile(settingsFilePath))
        mipLimiter = settings.mipLimiter
        normalLimiter = settings.normalLimiter
        ports = settings.ports
    end
end

local function saveDatabase()
    writeFile(settingsFilePath, textutils.serialize(settings))
end

initializeDatabase()

print("Basic initializing done")
print("This router's external address is : "..exteriorIP)
print("This router's internal address is : "..panelIP)

local currentMipRequests = 0
local currentRequests = 0

for i,v in ipairs(ports) do
    print("Port "..v.." is open")
    oP.open(v)
    iP.open(v)
end

print("Opening MIP port")
oP.open(80)
iP.open(80)
print("Entering while loop")

-- Source - https://stackoverflow.com/a/7615129
-- Posted by user973713, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-07-02, License - CC BY-SA 4.0

local function mysplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end


local function handleServerRequest(request)
    local pageStore = "routerPages"
    local requestedPage = request.page
    print("Server request : ".. requestedPage)
    local isDynamic = false
    local arg = ""
    if requestedPage == "" then
        requestedPage = "index"
    end
    if string.sub(requestedPage, 1, 1) == "d" then
        isDynamic = true
        requestedPage = string.sub(requestedPage, 2, 3)
        arg = string.sub(request.page, 5)
    end

    if not isDynamic then
        -- Search page in the pageStore
        local pagePath = pageStore.."/"..requestedPage..".table"
        local ctn
        if fs.exists(pagePath) then
            ctn = readFile(pagePath)
        else
            ctn = readFile(pageStore.."/404.table")
        end
        local result = load("return "..ctn)()   
        local response = {
            destination = "CLIENT",
            id = request.id,
            reply = {
                ["success"] = true,
                ["data"] = result
            }
        }
        iP.transmit(80, 80, response)
    end
    if isDynamic then
        print("Dynamic : true")
        print("Dynamic page : "..requestedPage)
        print("Dynamic arg : " .. arg)
        local data = {
            objs = {},
            style = {
                body = {
                    background = colors.black,
                    textColor = colors.white
                },
                text = {
                    background = colors.black,
                    textColor = colors.white
                },
                button = {
                    background = colors.blue,
                    textColor = colors.white
                },
                textbox = {
                    background = colors.white,
                    textColor = colors.black
                },
                [".redbtn"] = {
                    background = colors.red,
                    textColor = colors.white
                },
                [".redtxt"] = {
                    background = colors.black,
                    textColor = colors.red
                }
            },
            title = "title",
            description = {},
            script = nil
        }
        if requestedPage == "pa" then
            -- password check page
            if arg == password then
                data.script = [[event.hook("button", function() document.redirect("router.local",'dho?{"pwd":"]]..password..[["}') end)]]
            else
                data.script = [[event.hook("button", function() document.redirect("router.local","indexerr") end)]]
            end
            data.description = "Password check page, checking password..."
            data.objs = {
                {
                    type = "text",
                    text = "Press the button to continue to your destination",
                    x = 2,
                    y = 2
                },
                {
                    type = "button",
                    text = "Continue",
                    id = "cont",
                    x = 2,
                    y = 4
                }
            }
        end
        if requestedPage == "ho" then
            if arg == '{"pwd":"'..password..'"}' then
                -- page can be sent
                data.title = "NewRouter - Home"
                data.objs = {
                    {
                        type = "text",
                        text = "Router Administration",
                        x = 2,
                        y = 2
                    },
                    {
                        type = "text",
                        text = "MIP Requests : " .. currentMipRequests .. "/" .. mipLimiter,
                        x = 2,
                        y = 4
                    },
                    {
                        type = "text",
                        text = "Other Requests : " .. currentRequests .. "/" .. normalLimiter,
                        x = 2,
                        y = 5
                    },
                    {
                        type = "button",
                        text = "Set Limit",
                        id = "setmip",
                        x = 2,
                        y = 7,
                    },
                    {
                        type = "textbox",
                        text = "",
                        placeholder = "MIP Limit...",
                        id = "miplimit",
                        x = 12,
                        y = 7
                    },
                    {
                        type = "button",
                        text = "Set Limit",
                        id = "setnor",
                        x = 2,
                        y = 9,
                    },
                    {
                        type = "textbox",
                        text = "",
                        placeholder = "NORMAL Limit...",
                        id = "norlimit",
                        x = 12,
                        y = 9
                    },
                    {
                        type = "text",
                        text = "Ports:",
                        x = 2,
                        y = 11
                    }
                }
                for i,v in ipairs(settings.ports) do
                    table.insert(data.objs,{
                        type = "text",
                        text = "- " .. v,
                        x = 3,
                        y = 11+i
                    })
                    table.insert(data.objs,{
                        type = "button",
                        text = "DELETE",
                        class = "redbtn",
                        web = "router.local",
                        page = "dse?"..password.."&pre&"..v,
                        x = 6 + #tostring(v),
                        y = 11+i
                    })
                end
                table.insert(data.objs,{
                    type = "button",
                    text = "ADD",
                    id = "padd",
                    x = 2,
                    y = 12 + #settings.ports,
                })
                table.insert(data.objs,{
                    type = "textbox",
                    text = "",
                    placeholder = "Port Number to add",
                    id = "pad",
                    x = 6,
                    y = 12 + #settings.ports,
                })

                table.insert(data.objs,{
                    type = "text",
                    text = "To apply port changes, you must restart your router",
                    class = "redtxt",
                    x = 2,
                    y = 14 + #settings.ports,
                })

                data.script = [[
event.hook("button",function(id)
    if id == "setmip" then
        local mipBox = document.getElementById("miplimit")
        document.redirect("router.local","dse?]]..password..[[&mip&"..mipBox.text)
    elseif id == "setnor" then
        local mipBox = document.getElementById("norlimit")
        document.redirect("router.local","dse?]]..password..[[&nor&"..mipBox.text)
    elseif id == "padd" then
        local pad = document.getElementById("pad")
        if #pad.text > 0 then
            document.redirect("router.local","dse?]]..password..[[&pad&"..pad.text)
        end
    end
end)
                ]]
            else
                data.objs = {
                    {
                        type = "text",
                        text = "Access Denied",
                        x = 2,
                        y = 2
                    },
                    {
                        type = "button",
                        text = "Continue anyways",
                        web = "router.local",
                        page = "index",
                        x = 2,
                        y = 4
                    }
                }
                data.title = "Access Denied"
            end
        end
        if requestedPage == "se" then
            local sp = mysplit(arg,"&")
            print(table.concat(sp,","))
            print(arg)
            local goHomePage = false
            if #sp == 3 then
                if sp[1] == password and sp[2] == "mip" then
                    local d = tonumber(sp[3])
                    settings.mipLimiter = d
                    mipLimiter = settings.mipLimiter
                    saveDatabase()
                    goHomePage = true
                elseif sp[1] == password and sp[2] == "nor" then
                    local d = tonumber(sp[3])
                    settings.normalLimiter = d
                    normalLimiter = settings.normalLimiter
                    saveDatabase()
                    goHomePage = true
                elseif sp[1] == password and sp[2] == "pre" then
                    local d = tonumber(sp[3])
                    local pTable = {}
                    for i,v in ipairs(settings.ports) do
                        if v ~= d then
                            table.insert(pTable,v)
                        end
                    end
                    settings.ports = pTable
                    saveDatabase()
                    goHomePage = true
                elseif sp[1] == password and sp[2] == "pad" then
                    local d = tonumber(sp[3])
                    table.insert(settings.ports,d)
                    saveDatabase()
                    goHomePage = true
                end
            end
            data.objs = {
                {
                    type = "text",
                    text = "Press the button to continue to your destination",
                    x = 2,
                    y = 2
                }
            }
            if goHomePage then
                data.objs[2] = {
                    type = "button",
                    text = "Continue",
                    x = 2,
                    y = 4,
                    web = "router.local",
                    page = 'dho?{"pwd":"'..password..'"}'
                }
            else
                data.objs[2] = {
                    type = "button",
                    text = "Continue",
                    x = 2,
                    y = 4,
                    web = "router.local",
                    page = "index"
                }
            end
        end
        iP.transmit(80, 80, {
            destination = "CLIENT",
            id = request.id,
            reply = {
                ["success"] = true,
                ["data"] = data
            }
        })
    end
end

while true do
    local e = {os.pullEventRaw()}
    if e[1] == "modem_message" and e[2] == peripheral.getName(oP) then
        print("op to ip")
        for i,v in ipairs(ports) do
            if e[3] == v and (currentRequests < normalLimiter or normalLimiter == -1) then
                -- port is in allow list, forward the message to internal
                iP.transmit(v, v, e[5])
                if type(e[5]) == "table" then
                    currentRequests = currentRequests + #textutils.serialize(e[5],{compact=true})
                else
                    currentRequests = currentRequests + #e[5]
                end
            end
        end
        if e[3] == 80 then
            -- port 80 is always forwarded since MIP and shit
            -- but we need to check limiter
            if mipLimiter == -1 or currentMipRequests < mipLimiter then
                -- we can forward the request
                iP.transmit(80, 80, e[5])
                --currentMipRequests = currentMipRequests + #textutils.serialize(e[5],{compact=true}) - this is oP -> iP, so fuck it:)
            else
                -- limiter reached, check the settings of the request
                if type(e[5]) == "table" and e[5].destination == "SERVER" and e[5].action == "get_page" and e[5].pcid == exteriorIP then
                    -- request will be sent to internal panel server
                    -- todo
                    -- will maybe be never done :D
                end
            end
        end
    end
    if e[1] == "modem_message" and e[2] == peripheral.getName(iP) then
        print("ip to op")
        for i,v in ipairs(ports) do
            if e[3] == v then
                -- port is in allow list, forward the message to external
                oP.transmit(v, v, e[5])
                print("Port is in allow list, forwarding message to external network")
            end
        end
        if e[3] == 80 then
            -- port 80 is always forwarded since MIP and shit
            -- but we need to check limiter
            print("p80")
            print(mipLimiter)
            print("printing currentMipRequests")
            print(currentMipRequests)
            if mipLimiter == -1 or currentMipRequests < mipLimiter then
                -- we can forward the request
                print("limiter is good, sent")
                print("just checking if for router")
                if e[5].destination == "DNS" and e[5].action == "get_domain" and e[5].arg == panelIP then
                    iP.transmit(80, 80, {
                        destination = "CLIENT",
                        id = e[5].id,
                        reply = {
                            ["success"] = true,
                            ["pcId"] = pcId
                        }
                    })
                    -- we done here
                elseif e[5].destination == "SERVER" and e[5].action == "get_page" and e[5].pcid == pcId then
                    -- request will be sent to internal panel server
                    -- todo asap
                    handleServerRequest(e[5])
                else
                    oP.transmit(80, 80, e[5])
                    currentMipRequests = currentMipRequests + #textutils.serialize(e[5],{compact=true})
                end
            else
                print("limiter reached??")
                -- limiter reached, check the settings of the request
                if type(e[5]) == "table" and e[5].destination == "SERVER" and e[5].action == "get_page" and e[5].pcid == exteriorIP then
                    -- request will be sent to internal panel server
                    -- todo
                    handleServerRequest(e[5])
                elseif type(e[5]) == "table" and e[5].destination == "DNS" and e[5].action == "get_domain" and e[5].arg == panelIP then
                    -- reply with faked DNS response to the internal network
                    local response = {
                        destination = "CLIENT",
                        id = e[5].id,
                        reply = {
                            ["success"] = true,
                            ["pcId"] = pcId
                        }
                    }
                    iP.transmit(80, 80, response)
                else 
                    
                    if type(e[5]) == "table" and e[5].destination == "DNS" and e[5].action == "get_domain" then
                        -- say we ok but clearly, GET IT CLEARLY, HAH!
                        local response = {
                            destination = "CLIENT",
                            id = e[5].id,
                            reply = {
                                ["success"] = true,
                                ["pcId"] = 0
                            }
                        }
                        iP.transmit(80, 80, response)
                    elseif type(e[5]) == "table" and e[5].destination == "SERVER" and e[5].action == "get_page" and e[5].pcid > -1 then
                        -- say we ok but clearly, GET IT CLEARLY, HAH!
                        local website = {
  ["objs"] = {
    {
      type = "text",
      text = "Access Denied",
      class = "red",
      x = 1,
      y = 2
    },
    {
        type = "text",
        text = "You have reached the limit of requests.",
        x = 1,
        y = 3,
    },
    {
        type = "text",
        text = "Contact your ISP to get more data.",
        x = 1,
        y = 4
    }
  },
  ["style"] = {
    ["body"] = {
      ["background"] = colors.black,
      ["textColor"] = colors.white,
    },
    ["text"] = {
      ["background"] = colors.black,
      ["textColor"] = colors.white,
    },
    ["button"] = {
      ["background"] = colors.blue,
      ["textColor"] = colors.white,
    },
    ["textbox"] = {
      ["background"] = colors.white,
      ["textColor"] = colors.black
    },
    [".red"] = {
      ["background"] = colors.black,
      ["textColor"] = colors.red
    }
  },
  ["title"] = "Panel",
  ["description"] = "Router Administration",
  ["script"] = [[]]
                        }
                        local response = {
                            destination = "CLIENT",
                            id = e[5].id,
                            reply = {
                                ["success"] = true,
                                ["data"] = website
                            }
                        }
                        -- silly name no?
                        iP.transmit(80, 80, response)
                    end
                end
            end
        end
    end
    if e[1] == "terminate" then
        if debugMode == true then
            print("Terminating...")
            break
        end
    end
end
