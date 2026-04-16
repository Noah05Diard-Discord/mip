-- Config

local SITE_FOLDER = "sites"
local DOWNLOAD_FOLDER = "download"
local UPLOAD_FOLDER = "upload"
local UPLOAD_OVERWRITING = false

-- end Config

local modem = peripheral.find("modem")

local function getDownload(file)
    local path = fs.combine(DOWNLOAD_FOLDER,fs.combine(file))
    if fs.exists(path) and not fs.isDir(path) then
        local handle = fs.open(path,"r")
        local data = handle.readAll()
        handle.close()
        return data
    else
        return nil
    end
end

local function upload(name,data)
    local path = fs.combine(UPLOAD_FOLDER,fs.combine(name))
    if fs.exists(path) and not UPLOAD_OVERWRITING then return end
    local handle = fs.open(path,"w")
    handle.write(data)
    handle.close()
    return true
end

local function getPage(page)
    local path = fs.combine(SITE_FOLDER,fs.combine(page))
    if fs.exists(path) and not fs.isDir(path) then
        local handle = fs.open(path,"r")
        local data = handle.readAll()
        handle.close()
        local ret;
        local succ, err = load("return "..data,"=webpage",nil,{colors=colors})
        if not succ then
            ret = {objs={{type="text",text="Internal Server Error"}}}
        else
            ret,err = pcall(succ)
            if not ret then
                ret = {objs={{type="text",text="Internal Server Error"}}}
            else
                ret = err
            end
        end
        return ret
    else
        return nil
    end
end

modem.open(80)

while true do
    local ev = {os.pullEvent("modem_message")}
    local pack = ev[5]
    if type(pack) == "table" then
        print("PAK",textutils.serialise(pack))
        if pack.pcid == os.getComputerID() and pack.destination == "SERVER" then
            print("HHHH")
            if pack.action == "get_page" then
                print("Mi wan page")
                local page = getPage(pack.page..".table")
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
                local file = getDownload(pack.file)

                modem.transmit(80,80,{
                    ["destination"] = "CLIENT",
                    ["id"] = pack.id,
                    ["reply"] = {
                        ["success"] = file == true,
                        ["data"] = file
                    }
                })
            elseif pack.action == "upload" then
                local status = upload(pack.file,pack.data)

                modem.transmit(80,80,{
                    ["destination"] = "CLIENT",
                    ["id"] = pack.id,
                    ["reply"] = {
                        ["success"] = status
                    }
                })
            end
        end
    end
end