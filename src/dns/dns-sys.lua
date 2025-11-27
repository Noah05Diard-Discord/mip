local modem = peripheral.find"Modem"
local lookup = {}

local function loadLookup()
    local file = fs.open("lookup.table","r")
    local data = file.readAll()
    file.close()
    local uns = textutils.unserialise(data)
    if not uns then return end
    lookup = uns
end

local function saveLookup(file)
    local file = fs.open(file,"r")
    file.write(textutils.serialise(lookup))
    file.close()
end

loadLookup()

local function lookupThread()
    while true do
        local ev = {os.pullEvent("modem_message")}
        local p = ev[5]
        if p.destination == "DNS" then
            if action == "get_domain" then
                
            end
        end
    end
end

local function interfaceThread()
    while true do
        local ev ={os.pullEvent("mouse_click")}

    end
end

parallel.waitForAll(lookupThread)