# MIP Browser - Complete Implementation

## Features

### 1. **Title Bar**
- Displays the page title at the top of the screen
- Blue background with white text
- Shows "Browser" as default if no title is set
- Can be dynamically changed via `browser.setTitle()`

### 2. **URL Bar**
- Interactive address bar on line 2
- Click to enter a new URL
- Supports both network URLs (domain.tls/page) and local files (file:path/to/file.table)
- Automatically parses and navigates to entered URLs

### 3. **Page Rendering**
Supports all element types from the specification:
- **Text** - with styling and class support
- **Buttons** - clickable navigation elements
- **TextBox** - interactive input fields
- **Pictures** - NFP image rendering (when data provided)
- **Videos** - frame-based video playback (structure supported)

### 4. **Styling System**
- Full CSS-like styling with element types and classes
- Supports background and text colors
- Class-based styling with `.className` syntax
- Element-type default styles
- Body styling for page background

### 5. **Safe Script Environment**
Advanced security features:

#### Protected Environment
- Scripts run in isolated sandbox
- Cannot access dangerous APIs (os, fs, shell, io)
- Only allowed libraries: math, textutils (serialize functions), http
- `_G` writes to dummy table instead of global environment

#### Instruction Limiting
- Scripts limited to 100,000 instructions
- Prevents infinite loops from crashing browser
- Uses debug hooks to count instructions
- Automatic termination on limit exceeded

#### Safe APIs
- `getElementById(id)` - get page elements by ID (legacy)
- `browser` API - comprehensive browser interaction
- Standard safe functions: string, table, tostring, tonumber, type, pairs, ipairs
- Controlled print function

### 6. **Browser API**
Comprehensive JavaScript-like API for page scripts:

#### Cookie Management
- `browser.setCookie(name, value)` - Set a cookie for current site
- `browser.getCookie(name)` - Retrieve a cookie value
- `browser.deleteCookie(name)` - Remove a cookie
- `browser.getAllCookies()` - Get all cookies for current site
- Cookies are stored per-domain and persist across page loads

#### Navigation
- `browser.navigate(url)` - Navigate to a new URL (executed after script completes)
- `browser.reload()` - Reload current page
- `browser.getCurrentURL()` - Get current URL
- `browser.getSite()` - Get current hostname
- `browser.getPage()` - Get current page path

#### Element Manipulation
- `browser.getElementById(id)` - Get element by ID
- `browser.getElementsByType(type)` - Get all elements of a type
- `browser.getElementsByClass(className)` - Get all elements with a class
- `browser.createElement(type)` - Create a new element
- `browser.appendChild(element)` - Add element to page
- `browser.removeElement(id)` - Remove element by ID
- `browser.render()` - Force re-render of the page

#### Page Information
- `browser.getPageData()` - Get page title, description, and objects
- `browser.setTitle(newTitle)` - Change page title

### 7. **Anchor Navigation (#)**
- Buttons with `page = "#"` don't trigger navigation
- Script handles the click via `onClick(button, buttonId)` function
- Enables single-page applications and dynamic interactions
- No page reload, complete script control

### 8. **Event Handlers**
Scripts can define event handlers:

#### onClick(button, buttonId)
Called when a button with `page = "#"` is clicked:
```lua
function onClick(button, buttonId)
  if buttonId == "myButton" then
    -- Handle click
    browser.getElementById("result").text = "Clicked!"
    browser.render()
  end
end
```

#### onTextChange(textbox, textboxId, newValue)
Called when a textbox value changes:
```lua
function onTextChange(textbox, textboxId, newValue)
  if textboxId == "searchBox" then
    -- Handle text change
    browser.setCookie("lastSearch", newValue)
  end
end
```

### 9. **Coroutine-based Scripting**
- Scripts run in separate coroutines
- Non-blocking execution
- Error handling prevents script crashes from breaking browser

### 7. **Interactive Elements**

#### Buttons
- Click to navigate to web/page combinations
- Visual feedback with styled appearance
- Support for both absolute URLs and web+page format

#### TextBoxes
- Click to edit
- Placeholder text support
- Visual indication when empty
- Stores input in element data

### 8. **Network Protocol Support**
Full implementation of MIP protocol:
- DNS resolution via modem communication
- Page requests with timeout handling
- File protocol for local pages
- Error pages for failed requests

### 9. **Keyboard Shortcuts**
- **R key** - Refresh current page

### 10. **Error Handling**
- Graceful DNS resolution failures
- Page not found errors
- Parse error handling
- Script execution error catching
- Visual error pages with red styling

## Usage

### Starting the Browser
```lua
browser.lua
```

### URL Formats

**Network URLs:**
```
example.com/index
example.com/about
domain.tls/page
```

**Local Files:**
```
file:home.table
file:pages/about.table
```

### Creating Pages

Pages are Lua tables serialized to files:

```lua
{
  ["objs"] = {
    {
      ["type"] = "text",
      ["text"] = "Hello World",
      ["x"] = 1,
      ["y"] = 3,
    },
    {
      ["type"] = "button",
      ["text"] = "Click Me",
      ["web"] = "example.com",
      ["page"] = "next",
      ["x"] = 1,
      ["y"] = 5,
    },
  },
  ["style"] = {
    ["body"] = {
      ["background"] = colors.black,
      ["textColor"] = colors.white,
    }
  },
  ["title"] = "My Page",
  ["description"] = "Page description",
  ["script"] = [[
    -- Your safe Lua code here
    local elem = getElementById("myElement")
    if elem then
      elem.text = "Updated!"
    end
  ]]
}
```

### Writing Safe Scripts

Scripts have access to:

```lua
-- Math operations
math.random(1, 100)
math.floor(3.14)

-- Serialization
textutils.serialize(table)
textutils.unserialize(string)
textutils.serializeJSON(table)
textutils.unserializeJSON(string)

-- HTTP requests (if available)
http.get("http://example.com")

-- Browser API - Cookie Management
browser.setCookie("username", "player123")
local username = browser.getCookie("username")
browser.deleteCookie("username")
local allCookies = browser.getAllCookies()

-- Browser API - Navigation
browser.navigate("file:home.table")
browser.reload()
local url = browser.getCurrentURL()

-- Browser API - DOM Manipulation
local element = browser.getElementById("myId")
element.text = "New text"

local buttons = browser.getElementsByType("button")
local headers = browser.getElementsByClass("header")

local newElem = browser.createElement("text")
newElem.text = "Hello!"
newElem.id = "greeting"
browser.appendChild(newElem)

browser.removeElement("oldElement")
browser.render() -- Force re-render

-- Browser API - Page Info
local pageData = browser.getPageData()
browser.setTitle("New Page Title")

-- Event Handlers
function onClick(button, buttonId)
  if buttonId == "submit" then
    local input = browser.getElementById("userInput")
    browser.setCookie("saved", input.text)
    browser.navigate("file:success.table")
  end
end

function onTextChange(textbox, textboxId, newValue)
  -- Auto-save as user types
  browser.setCookie("draft_" .. textboxId, newValue)
end

-- Safe standard functions
string.upper("hello")
table.insert(myTable, value)
tostring(123)
tonumber("456")
```

### Creating Interactive Single-Page Apps

Use `page = "#"` for buttons to prevent navigation and handle clicks in script:

```lua
{
  ["objs"] = {
    {
      ["type"] = "button",
      ["text"] = "Click Me",
      ["page"] = "#",  -- This prevents navigation!
      ["id"] = "myButton",
      ["x"] = 2,
      ["y"] = 5,
    },
    {
      ["type"] = "text",
      ["text"] = "Not clicked",
      ["id"] = "status",
      ["x"] = 2,
      ["y"] = 7,
    },
  },
  ["script"] = [[
    -- Initialize click counter from cookie
    local clicks = tonumber(browser.getCookie("clicks")) or 0
    
    function onClick(button, buttonId)
      if buttonId == "myButton" then
        clicks = clicks + 1
        browser.setCookie("clicks", tostring(clicks))
        
        local status = browser.getElementById("status")
        status.text = "Clicked " .. tostring(clicks) .. " times!"
        browser.render()
      end
    end
  ]]
}
```

Scripts CANNOT:
- Access file system (fs)
- Access operating system (os)
- Run shell commands
- Create infinite loops (instruction limited)
- Modify global environment (writes to dummy table)
- Load external files

## Architecture

### Main Components

1. **Network Layer** (`resolve`, `resolvePage`)
   - DNS resolution via modem
   - Page fetching with timeouts
   - Error handling

2. **Page Loader** (`loadPage`, `getPage`)
   - File system reading
   - Network page requests
   - Error page generation

3. **Rendering Engine** (`renderPage`)
   - Element positioning
   - Style application
   - Visual output

4. **Script Engine** (`createScriptEnvironment`, `runScript`)
   - Sandbox creation
   - Instruction limiting
   - Coroutine management

5. **Event Handler** (`handleClick`, `mainLoop`)
   - Mouse click processing
   - Keyboard shortcuts
   - Element interaction

## Security Features

### Sandbox Protection
- Isolated environment per script
- No access to dangerous APIs
- Dummy _G table prevents global pollution

### Resource Limits
- 100,000 instruction limit per script
- 5-second network timeouts
- Controlled coroutine execution

### Error Isolation
- Script errors don't crash browser
- Network errors show error pages
- Parse errors handled gracefully

## File Structure

```
browser.lua          - Main browser application
home.table           - Example home page
server.lua           - Server implementation (from your files)
sites/               - Server web pages directory
  index.table        - Default page
  404.table          - Not found page
download/            - Server download directory
upload/              - Server upload directory
```

## Development Notes

### Adding New Element Types

To add new element types, modify the rendering section in `renderPage()`:

```lua
elseif v.type == "myNewType" then
  -- Rendering code here
  table.insert(renderedElements, {
    type = "myNewType",
    x1 = v.x,
    y1 = v.y,
    x2 = v.x + width,
    y2 = v.y + height,
    data = v
  })
```

### Extending Script API

Add new safe functions to `createScriptEnvironment()`:

```lua
local env = {
  -- existing code...
  myCustomFunction = function()
    -- Your safe function
  end
}
```

## Troubleshooting

**Browser won't start:**
- Ensure modem is connected
- Check file permissions

**Page won't load:**
- Verify URL format
- Check network connectivity
- Ensure DNS server is running

**Script not working:**
- Check for syntax errors
- Verify element IDs exist
- Ensure script doesn't exceed instruction limit
- Check browser console for error messages

**Elements not clickable:**
- Verify coordinates are within screen bounds
- Check element positioning (y should be >= 3)
- Ensure renderedElements table is populated

**Cookies not persisting:**
- Cookies are stored per-domain (site)
- Cookies persist only during browser session
- Check cookie name matches between setCookie and getCookie

**Button with page="#" still navigates:**
- Ensure onClick function is defined in script
- Check that buttonId matches the button's id field
- Verify script has no errors (errors may prevent onClick from being called)

## Advanced Examples

### Shopping Cart with Cookies

```lua
{
  ["objs"] = {
    {["type"]="text", ["text"]="Shopping Cart", ["class"]="header", ["y"]=3},
    {["type"]="text", ["text"]="Items: 0", ["id"]="itemCount", ["y"]=5},
    {["type"]="button", ["text"]="Add Item", ["page"]="#", ["id"]="addBtn", ["y"]=7},
    {["type"]="button", ["text"]="Clear Cart", ["page"]="#", ["id"]="clearBtn", ["y"]=9},
  },
  ["script"] = [[
    -- Load cart from cookie
    local cart = browser.getCookie("cart")
    local items = cart and tonumber(cart) or 0
    
    browser.getElementById("itemCount").text = "Items: " .. tostring(items)
    
    function onClick(button, buttonId)
      if buttonId == "addBtn" then
        items = items + 1
        browser.setCookie("cart", tostring(items))
        browser.getElementById("itemCount").text = "Items: " .. tostring(items)
        browser.render()
      elseif buttonId == "clearBtn" then
        items = 0
        browser.deleteCookie("cart")
        browser.getElementById("itemCount").text = "Items: 0"
        browser.render()
      end
    end
  ]]
}
```

### Search with Auto-save

```lua
{
  ["objs"] = {
    {["type"]="textbox", ["placeholder"]="Search...", ["id"]="search", ["y"]=3},
    {["type"]="text", ["text"]="Results will appear here", ["id"]="results", ["y"]=5},
  },
  ["script"] = [[
    -- Restore last search
    local lastSearch = browser.getCookie("lastSearch")
    if lastSearch then
      browser.getElementById("search").text = lastSearch
    end
    
    function onTextChange(textbox, textboxId, newValue)
      if textboxId == "search" then
        -- Save search to cookie
        browser.setCookie("lastSearch", newValue)
        
        -- Update results
        browser.getElementById("results").text = "Searching for: " .. newValue
        browser.render()
      end
    end
  ]]
}
```

## License

This browser implementation is complete and ready for use with the MIP protocol system.