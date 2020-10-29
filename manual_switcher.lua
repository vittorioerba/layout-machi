local machi = {
   layout = require((...):match("(.-)[^%.]+$") .. "layout"),
}

local api = {
   client     = client,
   beautiful  = require("beautiful"),
   wibox      = require("wibox"),
   awful      = require("awful"),
   screen     = require("awful.screen"),
   layout     = require("awful.layout"),
   naughty    = require("naughty"),
   gears      = require("gears"),
   lgi        = require("lgi"),
   dpi        = require("beautiful.xresources").apply_dpi,
}

local ERROR = 2
local WARNING = 1
local INFO = 0
local DEBUG = -1

local module = {
   log_level = WARNING,
}

local function log(level, msg)
   if level > module.log_level then
      print(msg)
   end
end

local function min(a, b)
   if a < b then return a else return b end
end

local function max(a, b)
   if a < b then return b else return a end
end

local function with_alpha(col, alpha)
   local r, g, b
   _, r, g, b, _ = col:get_rgba()
   return api.lgi.cairo.SolidPattern.create_rgba(r, g, b, alpha)
end

function module.move(c, key)

    -- for comparing floats
    local threshold = 0.1
    local traverse_radius = api.dpi(5)

    local screen = c and c.screen or api.screen.focused()
    local start_x = screen.workarea.x
    local start_y = screen.workarea.y

    local layout = api.layout.get(screen)
    if (c ~= nil and c.floating) or layout.machi_get_regions == nil then return end

    local regions, draft_mode = layout.machi_get_regions(screen.workarea, screen.selected_tag)
    if regions == nil or #regions == 0 then
        return
    end


    local traverse_x, traverse_y
    if c then
        traverse_x = c.x + traverse_radius
        traverse_y = c.y + traverse_radius
    else
        traverse_x = screen.workarea.x + screen.workarea.width / 2
        traverse_y = screen.workarea.y + screen.workarea.height / 2
    end


    local current_region = nil

    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
            break
        end
    end

    if current_region == nil or
        regions[current_region].x ~= c.x or
        regions[current_region].y ~= c.y
        then
        traverse_x = c.x + traverse_radius
        traverse_y = c.y + traverse_radius
        current_region = nil
    end

    local choice = nil
    local choice_value

    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
        end

        local v
        if key == "Up" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = traverse_y - a.y - a.height
            else
                v = -1
            end
        elseif key == "Down" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = a.y - traverse_y
            else
                v = -1
            end
        elseif key == "Left" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = traverse_x - a.x - a.width
            else
                v = -1
            end
        elseif key == "Right" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = a.x - traverse_x
            else
                v = -1
            end
        end

        if (v > threshold) and (choice_value == nil or choice_value > v) then
            choice = i
            choice_value = v
        end
    end

    if choice == nil then
        choice = current_region
        if key == "Up" then
            traverse_y = screen.workarea.y
        elseif key == "Down" then
            traverse_y = screen.workarea.y + screen.workarea.height
        elseif key == "Left" then
            traverse_x = screen.workarea.x
        else
            traverse_x = screen.workarea.x + screen.workarea.width
        end
    end

    if choice ~= nil then
        traverse_x = max(regions[choice].x + traverse_radius, min(regions[choice].x + regions[choice].width - traverse_radius, traverse_x))
        traverse_y = max(regions[choice].y + traverse_radius, min(regions[choice].y + regions[choice].height - traverse_radius, traverse_y))

        -- move the window
        if draft_mode then
            c.x = regions[choice].x
            c.y = regions[choice].y
        else
            machi.layout.set_geometry(c, regions[choice], regions[choice], 0, c.border_width)
            c.machi_region = choice
        end
    end

    c:raise()
    api.layout.arrange(screen)
end

function module.resize_topleft(c, key)
    -- for comparing floats
    local threshold = 0.1
    local traverse_radius = api.dpi(5)

    local screen = c and c.screen or api.screen.focused()
    local start_x = screen.workarea.x
    local start_y = screen.workarea.y

    local layout = api.layout.get(screen)
    if (c ~= nil and c.floating) or layout.machi_get_regions == nil then return end

    local regions, draft_mode = layout.machi_get_regions(screen.workarea, screen.selected_tag)
    if regions == nil or #regions == 0 then
        return
    end

    local traverse_x, traverse_y
    if c then
        traverse_x = c.x + traverse_radius
        traverse_y = c.y + traverse_radius
    else
        traverse_x = screen.workarea.x + screen.workarea.width / 2
        traverse_y = screen.workarea.y + screen.workarea.height / 2
    end
         
    local current_region = nil

    
    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
            break
        end
    end

    if current_region == nil or
        regions[current_region].x ~= c.x or
        regions[current_region].y ~= c.y
        then
        traverse_x = c.x + traverse_radius
        traverse_y = c.y + traverse_radius
        current_region = nil
    end

    local choice = nil
    local choice_value

    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
        end

        local v
        if key == "Up" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = traverse_y - a.y - a.height
            else
                v = -1
            end
        elseif key == "Down" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = a.y - traverse_y
            else
                v = -1
            end
        elseif key == "Left" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = traverse_x - a.x - a.width
            else
                v = -1
            end
        elseif key == "Right" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = a.x - traverse_x
            else
                v = -1
            end
        end

        if (v > threshold) and (choice_value == nil or choice_value > v) then
            choice = i
            choice_value = v
        end
    end

    if choice == nil then
        choice = current_region
        if key == "Up" then
            traverse_y = screen.workarea.y
        elseif key == "Down" then
            traverse_y = screen.workarea.y + screen.workarea.height
        elseif key == "Left" then
            traverse_x = screen.workarea.x
        else
            traverse_x = screen.workarea.x + screen.workarea.width
        end
    end

    if choice ~= nil then
        traverse_x = max(regions[choice].x + traverse_radius, min(regions[choice].x + regions[choice].width - traverse_radius, traverse_x))
        traverse_y = max(regions[choice].y + traverse_radius, min(regions[choice].y + regions[choice].height - traverse_radius, traverse_y))
        tablist = nil

        if c and draft_mode then
            local lu = c.machi_lu
            local rd = c.machi_rd

            lu = choice
            if regions[rd].x + regions[rd].width <= regions[lu].x or
                regions[rd].y + regions[rd].height <= regions[lu].y
                then
                rd = nil
            end

            if lu ~= nil and rd ~= nil then
                machi.layout.set_geometry(c, regions[lu], regions[rd], 0, c.border_width)
            elseif lu ~= nil then
                machi.layout.set_geometry(c, regions[lu], nil, 0, c.border_width)
            elseif rd ~= nil then
                c.x = min(c.x, regions[rd].x)
                c.y = min(c.y, regions[rd].y)
                machi.layout.set_geometry(c, nil, regions[rd], 0, c.border_width)
            end
            c.machi_lu = lu
            c.machi_rd = rd

            c:raise()
            api.layout.arrange(screen)
        end
    end
end

function module.resize_bottomright(c, key)
    -- for comparing floats
    local threshold = 0.1
    local traverse_radius = api.dpi(5)

    local screen = c and c.screen or api.screen.focused()
    local start_x = screen.workarea.x
    local start_y = screen.workarea.y

    local layout = api.layout.get(screen)
    if (c ~= nil and c.floating) or layout.machi_get_regions == nil then return end

    local regions, draft_mode = layout.machi_get_regions(screen.workarea, screen.selected_tag)
    if regions == nil or #regions == 0 then
        return
    end

    local traverse_x, traverse_y
    if c then
        traverse_x = c.x + traverse_radius
        traverse_y = c.y + traverse_radius
    else
        traverse_x = screen.workarea.x + screen.workarea.width / 2
        traverse_y = screen.workarea.y + screen.workarea.height / 2
    end
         
    local current_region = nil

    
    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
            break
        end
    end
   
    local ex = c.x + c.width + c.border_width * 2
    local ey = c.y + c.height + c.border_width * 2
    if current_region == nil or
        regions[current_region].x + regions[current_region].width ~= ex or
        regions[current_region].y + regions[current_region].height ~= ey
        then
        traverse_x = ex - traverse_radius
        traverse_y = ey - traverse_radius
        current_region = nil
    end


    local choice = nil
    local choice_value

    for i, a in ipairs(regions) do
        if a.x <= traverse_x and traverse_x < a.x + a.width and
            a.y <= traverse_y and traverse_y < a.y + a.height
            then
            current_region = i
        end

        local v
        if key == "Up" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = traverse_y - a.y - a.height
            else
                v = -1
            end
        elseif key == "Down" then
            if a.x < traverse_x + threshold
                and traverse_x < a.x + a.width + threshold then
                v = a.y - traverse_y
            else
                v = -1
            end
        elseif key == "Left" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = traverse_x - a.x - a.width
            else
                v = -1
            end
        elseif key == "Right" then
            if a.y < traverse_y + threshold
                and traverse_y < a.y + a.height + threshold then
                v = a.x - traverse_x
            else
                v = -1
            end
        end

        if (v > threshold) and (choice_value == nil or choice_value > v) then
            choice = i
            choice_value = v
        end
    end

    if choice == nil then
        choice = current_region
        if key == "Up" then
            traverse_y = screen.workarea.y
        elseif key == "Down" then
            traverse_y = screen.workarea.y + screen.workarea.height
        elseif key == "Left" then
            traverse_x = screen.workarea.x
        else
            traverse_x = screen.workarea.x + screen.workarea.width
        end
    end

    if choice ~= nil then
        traverse_x = max(regions[choice].x + traverse_radius, min(regions[choice].x + regions[choice].width - traverse_radius, traverse_x))
        traverse_y = max(regions[choice].y + traverse_radius, min(regions[choice].y + regions[choice].height - traverse_radius, traverse_y))
        tablist = nil

        if c and draft_mode then
            local lu = c.machi_lu
            local rd = c.machi_rd

            rd = choice
            if regions[rd].x + regions[rd].width <= regions[lu].x or
                regions[rd].y + regions[rd].height <= regions[lu].y
                then
                lu = nil
            end

            if lu ~= nil and rd ~= nil then
                machi.layout.set_geometry(c, regions[lu], regions[rd], 0, c.border_width)
            elseif lu ~= nil then
                machi.layout.set_geometry(c, regions[lu], nil, 0, c.border_width)
            elseif rd ~= nil then
                c.x = min(c.x, regions[rd].x)
                c.y = min(c.y, regions[rd].y)
                machi.layout.set_geometry(c, nil, regions[rd], 0, c.border_width)
            end
            c.machi_lu = lu
            c.machi_rd = rd

            c:raise()
            api.layout.arrange(screen)
        end
    end
end

return module
