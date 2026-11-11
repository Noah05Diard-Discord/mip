# Apis

## Document

### ```getElementById(id: any): table```

This function allows you to get any element with an unique ID you have access to the table of the element

Example
```lua
document.getElementById("idForText").text = "Hello"
```

### ```addElement(element: table)```

This function accepts a table like an element is.

Example
```lua
document.addElement({
    ["type"] = "text",
    ["text"] = "Hello",
    ["class"] = "aClass",
    ["id"] = "accessme",
    ["x"] = 1,
    ["y"] = 1,
})
```

### ```getPage()```

This function returns the address

Example
```lua
local addr = document.getPage()
```

### ```getPageEndpoint()```

This function returns the endpoint (page)

Example
```lua
local page = document.getPageEndpoint()
```

### ```getOldPage()```

This function returns the old "web" like if you were on the domain amongus.com, this will return "amongus.com"

Example
```lua
local oldweb = document.getOldPage()
document.redirect(oldweb, "a page ig")
```

### ```getOldPageEndpoint()```

This function returns the old "page" like if you were on the page amongus, this will return "amongus"

Example
```
-- A go back button
local oldweb = document.getOldPage()
local oldpage = document.getOldPageEndpoint()
document.redirect(oldweb,oldpage)
```

### ```redirect(web: string, page: string)```

Changes the current website. Web is address and page is the pae

Example
```lua
document.redirect("example.com","/")
```

### ```getCanvasFromId(web: string, page: string)```

Gets a canvas from id (Canvas is a terminal object)

Example
```lua
local canvas = browser.getCanvasFromId("myCanvas")
```

---
## Event
### ```hook(event,callback)```
Hook a callback to an event.

example
```lua
event.hook("button",function(id,btn)
    document.getElementById(id).text = tostring(btn)
end)
```

## protocol
### ```upload(pcid,file,data)```
Uploads a file with data to the server.

example
```lua
protocol.upload(0,"myfile.lua","print(\"Hello, World\")")
```

### ```download(pcid,file)```
Downloads a file from the server

example
```lua
local data = protocol.download(0,"myfile.lua")
```

## Browser

### ```fileDialog()```
Opens a file dialog and returns the name and data

example
```lua
local file, data = browser.fileDialog()
```

### ```download(file,data)```
Adds a file to the downloads/ folder

example
```lua
browser.download("myfile.lua","print(\"Hello, World\")")
```

## Cookie

### ```set(key,value)```
Sets the cookie key to value

example
```lua
cookie.set("session","913458967134576891345")
```

### ```get(key)```
Returns the cookie value of key

example
```lua
local ses = cookie.get("session")
```
## style

### ```get(class:string)```
Gets the style for a class

example
```lua
style.get("myBtn")
```

### ```set(class:string,style:table)```
Sets the style for a class

example
```lua
style.set("myBtn",{background=colors.blue,textColor=colors.white})
```

### ```getElement(element:string)```
Gets the style table for an element type

example
```lua
style.getElement("body")
```

### ```setElement(element:string,style:table)```
Sets the style table for an element type

example
```lua
style.setElement("body",{background=colors.gray,textColor=colors.white})
```
# Builtin Events

### ```button```
Activates on button click

Arguments

```id: Button id | btn the mouse button used```

### ```textbox_enter```
Activates when you press enter on a textbox

Arguments

```id: Textbox ID```
