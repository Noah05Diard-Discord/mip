local modem = peripheral.find"modem"
modem.open(80)

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

print(textutils.serialise(lookup))

local function lookupThread()
    while true do
        local ev = {os.pullEvent("modem_message")}
        local p = ev[5]
        if p.destination == "DNS" then
            if p.action == "get_domain" then
                print("\"",p.arg,"\"",lookup[p.arg])
                modem.transmit(80,80,{
                    ["destination"] = "CLIENT",
                    ["id"] = p.id,
                    ["reply"] = {
                        ["success"] = lookup[p.arg] and true or false,
                        ["pcId"] = lookup[p.arg],
                    }
                })
            end
        end
    end
end

local function interfaceThread()
    while true do
        local ev ={os.pullEvent("mouse_click")}

    end
end

parallel.waitForAll(lookupThread,interfaceThread)