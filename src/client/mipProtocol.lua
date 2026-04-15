local protocol = {}

protocol.modem = peripheral.find("modem")

if not protocol.modem then
    error("Modem not available.",0)
end

local function openPort()
    if not protocol.modem.isOpen(80) then protocol.modem.open(80) end
end

function protocol.dnsLookup(addr)
    local id = math.random(1000,9999)

    local payload = {
        ["destination"] = "DNS",
        ["action"] = "get_domain",
        ["arg"] = addr,
        ["id"] = id
    }

    protocol.modem.transmit(80,80,payload)

    openPort()

    local timeout = os.startTimer(10)

    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            if type(ev[5]) == "table" then
                if ev[5].destination == "CLIENT" then
                    if ev[5].id == id then
                        local reply = ev[5].reply
                        return reply.success and reply.pcId or nil, "Address cannot be lookuped"
                    end
                end
            end
        elseif ev[1] == "timer" and ev[2] == timeout then
            return nil, "DNS Unreachable"
        end
    end

end

function protocol.get_page(pcid,page)
    local id = math.random(1000,9999)

    local payload = {
        ["destination"] = "SERVER",
        ["action"] = "get_page",
        ["pcid"] = pcid,
        ["id"] = id,
        ["page"] = page,
    }

    protocol.modem.transmit(80,80,payload)

    openPort()

    local timeout = os.startTimer(10)

    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            if type(ev[5]) == "table" then
                if ev[5].destination == "CLIENT" then
                    if ev[5].id == id then
                        local reply = ev[5].reply
                        return reply.success and reply.data or nil, "Attempt not succesful"
                    end
                end
            end
        elseif ev[1] == "timer" and ev[2] == timeout then
            return nil, "Webserver Unreachable"
        end
    end

end

function protocol.download(pcid,file)
    local id = math.random(1000,9999)

    local payload = {
        ["destination"] = "SERVER",
        ["action"] = "download",
        ["pcid"] = pcid,
        ["id"] = id,
        ["file"] = file,
    }

    protocol.modem.transmit(80,80,payload)

    openPort()

    local timeout = os.startTimer(10)

    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            if type(ev[5]) == "table" then
                if ev[5].destination == "CLIENT" then
                    if ev[5].id == id then
                        local reply = ev[5].reply
                        return reply.success and reply.data or nil, "Attempt not succesful"
                    end
                end
            end
        elseif ev[1] == "timer" and ev[2] == timeout then
            return nil, "Webserver Unreachable"
        end
    end

end

function protocol.upload(pcid,file,data)
    local id = math.random(1000,9999)

    local payload = {
        ["destination"] = "SERVER",
        ["action"] = "upload",
        ["pcid"] = pcid,
        ["id"] = id,
        ["file"] = file,
        ["data"] = data
    }

    protocol.modem.transmit(80,80,payload)

    openPort()

    local timeout = os.startTimer(10)

    while true do
        local ev = {os.pullEvent()}
        if ev[1] == "modem_message" then
            if type(ev[5]) == "table" then
                if ev[5].destination == "CLIENT" then
                    if ev[5].id == id then
                        local reply = ev[5].reply
                        return reply.success or "Unsucces"
                    end
                end
            end
        elseif ev[1] == "timer" and ev[2] == timeout then
            return nil, "Webserver Unreachable"
        end
    end

end

return protocol