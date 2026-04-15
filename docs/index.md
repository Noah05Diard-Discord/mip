# Apis

## Document

### ```getElementById(id: any): table```

This function allows you to get any element with an unique ID you have access to the table of the element

Example
```lua
getElementById("idForText").text = "Hello"
```

### ```addElement(element: table)```

This function accepts a table like an element is.

Example
```lua
addElement({
    ["type"] = "text",
    ["text"] = "Hello",
    ["class"] = "aClass",
    ["id"] = "accessme",
    ["x"] = 1,
    ["y"] = 1,
})
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

# Builtin Events

### Button
Activates on button click

Arguments

```id: Button id | btn the mouse button used```