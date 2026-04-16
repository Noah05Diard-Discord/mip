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

This function returns the page (not address)

Example
```lua
local page = document.getPage()
```

### ```redirect(web: string, page: string)```

Changes the current website. Web is address and page is the pae

Example
```lua
document.redirect("example.com","/")
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
### ```upload(file,data)```
Uploads a file with data to the server.

example
```lua
protocol.upload("myfile.lua","print(\"Hello, World\")")
```

### ```download(file)```
Downloads a file from the server

example
```lua
local data = protocol.download("myfile.lua")
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

# Builtin Events

### Button
Activates on button click

Arguments

```id: Button id | btn the mouse button used```