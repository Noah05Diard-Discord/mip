-- Config

local SITE_FOLDER = "sites"

-- end Config

local modem = peripheral.find("modem")

local function getPage(page)
    local path = fs.combine(SITE_FOLDER,page)
    if fs.exists(path) and not fs.isDir(path) then
        local handle = fs.open(path,"r")
        local data = handle.readAll()
        handle.close()
        return data
    else
        return nil
    end
end

modem.open(80)

while true do
    local ev = {os.pullEvent("modem_message")}
    local pack = ev[5]
    if type(pack) == "table" then
        if pack.pcId == os.getComputerID() and pack.destination == "SERVER" then
            if pack.action == "get_page" then
                local page = getPage(pack.page)
                if not page then
                    if pack.page == "/" or pack.page == "" then
                        page = getPage("index.table")
                    end
                end
                if not page then
                    page = getPage("404.table")
                end
                if not page then
                    page = {objs={{type="text",text="Page not found"}}}
                end
                modem.transmit(80,80,{
                    ["destination"] = "CLIENT",
                    ["id"] = pack.id,
                    ["reply"] = {
                        ["success"] = page and true or false,
                        ["data"] = page,
                    }
                })
            elseif pack.action == "download" then
                
            end
        end
    end
end