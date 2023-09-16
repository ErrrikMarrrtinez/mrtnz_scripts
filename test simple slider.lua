package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)
require 'rtk'

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
main_line_color = "#55666f"
SimpleSlider = rtk.class('SimpleSlider', rtk.Spacer)
SimpleSlider.register{
    value = rtk.Attribute{default=0.5}, 
    color = rtk.Attribute{type='color', default=main_line_color},
    minw = 5,
    h = 1.0,
    autofocus = true,
    min = rtk.Attribute{default=0},
    max = rtk.Attribute{default=1},
    ticklabels = rtk.Attribute{default=nil},
    text_color = rtk.Attribute{type='color', default='#ffffff'},
    align = rtk.Attribute{default='center'},
    valign = rtk.Attribute{default='top'},
    font = rtk.Attribute{default='arial'},
    fontsize = rtk.Attribute{default=18},
    target = rtk.Attribute{default='top'},
}

function SimpleSlider:initialize(attrs, ...)
    rtk.Spacer.initialize(self, attrs, SimpleSlider.attributes.defaults, ...)
end

rtk.add_image_search_path('../../MrtnzScripts/NotePast/images', 'dark')

function SimpleSlider:set_from_mouse_y(y)
    local h = self.calc.h - (y - self.clienty)
    local value = rtk.clamp(h / self.calc.h, 0, 1)
    self:animate{
        attr = 'value',
        dst = value,
        duration = 0.0070
    }
end
function adjust_brightness(color, amount)
    local r, g, b = color:match("#(%x%x)(%x%x)(%x%x)")
    r = math.floor(math.min(255, math.max(0, tonumber(r, 16) * (1 + amount))))
    g = math.floor(math.min(255, math.max(0, tonumber(g, 16) * (1 + amount))))
    b = math.floor(math.min(255, math.max(0, tonumber(b, 16) * (1 + amount))))
    return string.format("#%02x%02x%02x", r, g, b)
end

function SimpleSlider:_handle_draw(offx, offy, alpha, event)
    local calc = self.calc
    local x = offx + calc.x
    local y = offy + calc.y
    local h = calc.h * calc.value
    
    self:setcolor(calc.color)
    gfx.a = 0.2
    gfx.rect(x, y, calc.w, calc.h)
    
    if self.target == 'top' then
        draw_h = h
        draw_y = y + calc.h - h
    elseif self.target == 'down' then
        draw_h = h
        draw_y = y
    elseif self.target == 'center' then
        local half_h = calc.h / 2
        draw_h = math.abs(h - half_h)
        
        gfx.a = 0.4
        gfx.rect(x, y + half_h, calc.w, 1)
    
        if calc.value >= 0.5 then
            draw_y = y + half_h - draw_h
        else
            draw_y = y + half_h
        end
    end
    
    local adjustedColor = adjust_brightness(calc.color, calc.value - 0.5)
    self:setcolor(adjustedColor)
    gfx.a = 1.0
    gfx.rect(x, draw_y, calc.w, draw_h)
    
    local fmt = type(self.min) == "table" and "%d%%" or "%d"
    local text_to_display
    if self.ticklabels then
        local index = math.floor(calc.value * (#self.ticklabels - 1) + 0.5) + 1
        text_to_display = self.ticklabels[index]
    elseif type(self.min) == "table" and type(self.max) == "table" then
        text_to_display = string.format("%d%%", math.floor(calc.value * 100))
    else
        local min = type(self.min) == "table" and self.min[1] or self.min
        local max = type(self.max) == "table" and self.max[1] or self.max
        text_to_display = string.format("%d", math.floor(min + calc.value * (max - min)))
    end
    gfx.setfont(1, self.font, self.fontsize)

    local str_w, str_h = gfx.measurestr(text_to_display)
    
    if self.align == 'left' then
        gfx.x = x
    elseif self.align == 'center' then
        gfx.x = x + (calc.w - str_w) / 2
    else
        gfx.x = x + calc.w - str_w
    end

    if self.valign == 'top' then
        gfx.y = y
    else
        gfx.y = y + calc.h - str_h
    end
    
    self:setcolor(self.text_color)
    gfx.drawstr(text_to_display)
end


-- В функции SimpleSlider:getDisplayValue()
function SimpleSlider:getDisplayValue()
    local calc = self.calc
    local text_to_display
    if self.ticklabels then
        local index = math.floor(calc.value * (#self.ticklabels - 1) + 0.5) + 1
        text_to_display = self.ticklabels[index]
    elseif type(self.min) == "table" and type(self.max) == "table" then
        text_to_display = string.format("%d", math.floor(calc.value * 100))
    else
        local min = type(self.min) == "table" and self.min[1] or self.min
        local max = type(self.max) == "table" and self.max[1] or self.max
        text_to_display = string.format("%d", math.floor(min + calc.value * (max - min)))
    end

    -- Для rate: преобразуем доли в число и умножаем на 480*8
    if self.name == "rate" then
        local fractions = {["1/2"]=0.5, ["1/3"]=1/3, ["1/4"]=0.25, ["1/6"]=1/6, ["1/8"]=0.125, ["1/12"]=1/12, ["1/16"]=1/16, ["1/24"]=1/24, ["1/32"]=1/32, ["1/48"]=1/48, ["1/64"]=1/64}
        local fraction_value = fractions[text_to_display]
        if fraction_value then
            text_to_display = tostring(math.floor(fraction_value * 480 * 8))
        end
    end

    return text_to_display or "No Value!"
end



--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

SliderGroup = rtk.class('SliderGroup', rtk.HBox)
local step_grid = {}


function SimpleSlider:_handle_mousedown(event)
    
    local ok = rtk.Spacer._handle_mousedown(self, event)
    if ok == false then
    all_info_sliders(self)
        return ok
    end
    
    if event.button == rtk.mouse.BUTTON_RIGHT then
        local menu2 = rtk.NativeMenu()
        menu2:set({
            {"Random", id='random'},
            {"Ascending", id='ascending'},
            {"Descending", id='descending'},
            {"Wave", id='wave'},
            {"Up from Current", id='up_from_current'},
            {"Down from Current", id='down_from_current'}
        })
        menu2:open_at_mouse():done(function(item)
            if not item then
                return
            end
            self.parent:apply_mode(self, item.id)
        end)
    else
        self:set_from_mouse_y(event.y)
        
    end
    
end

function SliderGroup:apply_mode(current_slider, mode)
    local total_sliders = #self.children
    local current_slider_idx
    local duration = 0.3 

    for i, child in ipairs(self.children) do
        if child[1] == current_slider then
            current_slider_idx = i
            break
        end
    end
    if mode == 'wave' then
        local even_value = 0.1 + 0.8 * math.random()
        local odd_value = even_value + 0.3
        if odd_value > 0.9 then
            odd_value = even_value - 0.3
        end
        for i, child in ipairs(self.children) do
            local slider = child[1]
            if rtk.isa(slider, SimpleSlider) then
                local new_value = i % 2 == 0 and even_value or odd_value
                slider:animate{
                    attr = 'value',
                    dst = new_value,
                    duration = duration
                }
            end
        end
        all_info_sliders(self, children, event, x, y, t)
        return
    end
    for i, child in ipairs(self.children) do
        local slider = child[1]
        if rtk.isa(slider, SimpleSlider) then
            local new_value
            if mode == 'random' then
                new_value = 0.1 + 0.8 * math.random()
            elseif mode == 'ascending' then
                new_value = 0.1 + (0.8 * (i - 1) / (total_sliders - 1))
            elseif mode == 'descending' then
                new_value = 0.1 + (0.8 * (total_sliders - i) / (total_sliders - 1))
            elseif mode == 'up_from_current' then
                if i == current_slider_idx then
                    new_value = 0.9
                elseif i < current_slider_idx then
                    new_value = 0.1 + (0.8 * (i - 1) / (current_slider_idx - 1))
                else
                    new_value = 0.1 + (0.8 * (total_sliders - i) / (total_sliders - current_slider_idx))
                end
            elseif mode == 'down_from_current' then
                if i == current_slider_idx then
                    new_value = 0.1
                elseif i > current_slider_idx then
                    new_value = 0.1 + (0.8 * (i - current_slider_idx) / (total_sliders - current_slider_idx))
                else
                    new_value = 0.1 + (0.8 * (current_slider_idx - i) / (current_slider_idx - 1))
                end
                
            end
            all_info_sliders(self, children, event, x, y, t)
            slider:animate{
                attr = 'value',
                dst = new_value,
                duration = duration
            }
        end
    end
    all_info_sliders(self, children, event, x, y, t)
    
end
local first_slider_value = nil
local focused_slider = nil

function SliderGroup:_handle_mousedown(event, x, y, t)
    all_info_sliders(self, event, x, y, t)
end
function SliderGroup:_handle_dragstart(event, x, y, t)
    first_slider_value = nil
    focused_slider = nil
    local draggable, droppable = rtk.HBox._handle_dragmousemove(self, event)
    if draggable ~= nil then
        return draggable, droppable
    end
    return {lastx=x, lasty=y}, false
end


--[[flag_mouse = false
function SliderGroup:_handle_mousedown(event, x, y, t)
    flag_mouse=true
end]]




local last_created_button_number = 0
local buttonCount = 1
local boxes = {}
local container_advanced_3
local index_strip = 8
local next_button_index = 1 
local buttons = {}  
local boxes = {}

-- Глобальная переменная-флаг для управления режимом defer
local on_deferred = true



function all_info_sliders(self, children, event, x, y, t)
    -- Определите, в каком аккорде мы находимся
    local chord_index = active_chord_index
    
    -- Если аккорда еще нет в step_grid, добавим его
    if not step_grid[chord_index] then
        step_grid[chord_index] = {mode = "down"}
    end
    
    for i = 1, #self.children do
        local child = self.children[i][1]
        if rtk.isa(child, SimpleSlider) then
            local step = child.slider_index
    
            -- Создадим слот для данного шага, если его еще нет
            if not step_grid[chord_index][step] then
                step_grid[chord_index][step] = {
                    step = step,
                    grid_step = 480,   -- Значение по умолчанию для grid_step
                    velocity = 100,    -- Значение по умолчанию для velocity
                    octave = 0,        -- Значение по умолчанию для octave
                    ratchet = 0,       -- Значение по умолчанию для ratchet
                    length = 0         -- Значение по умолчанию для length
                }
            end
    
            -- Записываем значения в step_grid
            if child.name == "rate" then
                step_grid[chord_index][step].grid_step = child:getDisplayValue()
            elseif child.name == "velocity" then
                step_grid[chord_index][step].velocity = child:getDisplayValue()
            elseif child.name == "octave" then
                step_grid[chord_index][step].octave = child:getDisplayValue()
            elseif child.name == "ratchet" then
                step_grid[chord_index][step].ratchet = child:getDisplayValue()
            elseif child.name == "gate" then
                step_grid[chord_index][step].length = child:getDisplayValue()
            end
        end
    end

    -- Проверяем значение переменной-флага перед вызовом reaper.defer
    if on_deferred then
        reaper.defer(function() all_info_sliders(self, children, event, x, y, t) end)
    end
end


function SliderGroup:_handle_dragend(event, x, y, t)
    all_info_sliders(self, event, x, y, t)
end


local function print_slider_info()
    local msg = "Step Grid Info:\n"
    for chord_idx, chord_data in ipairs(step_grid) do
        msg = msg .. "Chord " .. chord_idx .. " (Mode: " .. chord_data.mode .. ")\n"
        for step, step_data in ipairs(chord_data) do
            if type(step_data) == "table" then
                msg = msg .. "  Step " .. step .. ": "
                for k, v in pairs(step_data) do
                    if k ~= "step" then
                        msg = msg .. k .. "=" .. tostring(v) .. ", "
                    end
                end
                msg = msg:sub(1, -3)
                msg = msg .. "\n"
            end
        end
    end
    reaper.ShowConsoleMsg(msg)
end




function SliderGroup:_handle_mouseup(event, x, y, t)
    all_info_sliders(self, event, x, y, t)
end


function SliderGroup:_handle_dragmousemove(event, arg)
    local ok = rtk.HBox._handle_dragmousemove(self, event)
    if ok == false or event.simulated then
        return ok
    end
    --show_info(self, event, arg, x, y, t)
    local x0 = math.min(arg.lastx, event.x)
    local x1 = math.max(arg.lastx, event.x)

    for i = 1, #self.children do
        local child = self.children[i][1]
        if child.clientx >= x1 then
            break
        elseif child.clientx + child.calc.w > x0 and rtk.isa(child, SimpleSlider) then
            if event.ctrl and not focused_slider then
                focused_slider = child
            end

            if event.shift then
                if first_slider_value == nil then
                    first_slider_value = child.value
                end
                child:attr('value', first_slider_value)
            elseif focused_slider then
                focused_slider:set_from_mouse_y(event.y)
            else
                child:set_from_mouse_y(event.y)
            end
        end
    end
    arg.lastx = event.x
    arg.lasty = event.y
    all_info_sliders(self, event, x, y, t)
end
    

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--local step_grid = {}
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
bg_all="#262422"

base_w = 35
base_w_slider=58
spacing_1 = base_w/base_w
base_w_for_chord_tabs=60
big_w_for_chord_tabs = base_w_for_chord_tabs + 20
base_h_for_chord_tabs=25
base_color = "#3a3a3a"
pressed_color_tabs = "#08737f"


local win = rtk.Window{bg="#1a1a1a",w=450, h=340}







local hibox_buttons_browser=win:add(rtk.HBox{})

local function create_new_box()

    local container_advanced_3 = all_advanced_mode_container:add(rtk.HBox{padding=20})
    local vbox = container_advanced_3:add(rtk.VBox{x=15, w=base_w, h=200, padding=25})
    local slider_groups = {}
    
    local button_names = {'velocity', 'octave', 'gate', 'ratchet', 'rate'}
    
    local slider_and_buttons_modes = container_advanced_3:add(rtk.VBox{})
    local container_advanced_vb = slider_and_buttons_modes:add(rtk.HBox{})
    local slider_container_win = slider_and_buttons_modes:add(rtk.HBox{})
    
    local slider_params = {
        velocity = {min=1, max=127, value=0.79},
        octave = {color='#fafa6e', min=-5, max=5, value=0.5},
        gate = {color='#2a4858', min={1, "%"}, max={100, "%"}, value=0.5},
        ratchet = {color='#7E7A3E', min=0, max=10, value=0.05},
        rate = {color='#009a86', min=1, max=12, ticklabels={"1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64"}, value=0.5}
    }
    local function create_slider(group, params, name, chord_number, slider_type)
        params.w = base_w
        params.lhotzone = 5
        params.font = 'Times'
        params.valign = 'down'
        params.text_color = "#ffffff"
        params.halign = 'left'
        params.rhotzone = 5
        params.name = name  -- Добавьте поле name
        local slider_line_v = group:add(SimpleSlider(params), {fillw=true})
        return slider_line_v
    end
    
    --[[
    local function create_slider(group, params, name, chord_number, slider_type)
        params.w = base_w
        params.lhotzone = 5
        params.font = 'Times'
        params.valign = 'down'
        params.text_color = "#ffffff"
        params.halign = 'left'
        params.rhotzone = 5
        local slider_line_v = group:add(SimpleSlider(params), {fillw=true})
        
        slider_line_v.onclick=function(self, event)
                local displayValue = slider_line_v:getDisplayValue()
               reaper.ShowConsoleMsg(slider_line_v. )
           end
           return  slider_line_v
    end]]
    
    
    
    local function toggle_groups(active_index)
        for i, group in ipairs(slider_groups) do
            if i == active_index then
                group:show()
            else
                group:hide()
            end
        end
    end

    local is_programmatic_change = false
    local slider_mode_win = slider_container_win:add(rtk.Slider{
        value=20,
        step=20,
        ticks=5,
        tracksize=4,
        thumbsize=1,
        thumbcolor='transparent',
        z=-5, w=base_w_slider*5,
        y=192
    })

    for i, name in ipairs(button_names) do
        local slider_group = vbox:add(SliderGroup{spacing=spacing_1, expand=2})
        
        
        
        slider_group:hide()
        table.insert(slider_groups, slider_group)

        local buttons_type = container_advanced_vb:add(rtk.Button{
            halign='center',
            spacing=2, 
            padding=2,
            w=base_w_slider, 
            label=name, 
            y=190
        })

        buttons_type.onclick = (function(idx)
            return function()
                is_programmatic_change = true
                slider_mode_win:attr('value', idx * 20)
                toggle_groups(idx)
                is_programmatic_change = false
                slider_mode_win:focus()
            end
        end)(i)

        for j = 1, index_strip do
            local slider = create_slider(slider_group, slider_params[name], name)
            slider.chord_index = last_created_button_number
            slider.slider_index = j   -- Сохраняем порядковый номер слайдера
        end
        
    end

    slider_mode_win.onchange = function(self, event)
        if is_programmatic_change then return end
        is_programmatic_change = true
        local value = math.floor(self.value / 20 + 0.5) * 20
        if value == 0 then value = 20 end
        self:attr('value', value)
        toggle_groups(value / 20)
        is_programmatic_change = false
    end
    
    slider_groups[1]:show()
    return container_advanced_3, slider_groups, button_names
end

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local chord_add = hibox_buttons_browser:add(rtk.Button{"+"})
local function animate_button(btn, color, w, h, gradient)
    btn:animate{'color', dst=color, duration=0.1}
    btn:animate{'w', dst=w, duration=0.3, easing="out-back"}
    btn:animate{'h', dst=h, duration=0.3, easing="out-back"}
    btn:attr('gradient', gradient)
end

local function hide_all_boxes_and_reset_buttons()
    for _, box in pairs(boxes) do
        box:hide()
    end
    for _, btn in pairs(buttons) do
        animate_button(btn, base_color, base_w_for_chord_tabs, base_h_for_chord_tabs, 2)
    end
end

local function update_labels()
    for i, btn in ipairs(buttons) do
        btn:attr('label', "Chord " .. i)
    end
end

local function create_new_button_and_box(last_created_button_number)
    local new_box, slider_groups, button_names = create_new_box()
    new_box.slider_groups = slider_groups
    new_box.button_names = button_names
    boxes[last_created_button_number] = new_box
    local new_button = hibox_buttons_browser:add(rtk.Button{
        color=base_color,
        gradient=2,
        halign='center',
        spacing=4,
        padding=2,
        h=base_h_for_chord_tabs,
        w=base_w_for_chord_tabs,
        label="Chord " .. last_created_button_number
    })
    table.insert(buttons, new_button)
    new_box:show()

    new_button.onclick = function(self, event)
        
        local handle_right_click = function()
            
            local menu2 = rtk.NativeMenu()
            menu2:set({{"Delete", id='delete'}})
            menu2:open_at_mouse():done(function(item)
                if item and item.id == 'delete' then
                    hibox_buttons_browser:remove(new_button)
                    win:remove(new_box)
                    for i, btn in ipairs(buttons) do
                        if btn == new_button then
                            table.remove(buttons, i)
                            table.remove(boxes, i)
                            break
                        end
                    end
                    update_labels()
                end
            end)
        end

        local handle_left_click = function()
            hide_all_boxes_and_reset_buttons()
            new_box:show()
            animate_button(new_button, pressed_color_tabs, base_w_for_chord_tabs+20, base_h_for_chord_tabs+7, 3)
        end

        if event.button == rtk.mouse.BUTTON_RIGHT then
            handle_right_click()
        elseif event.button == rtk.mouse.BUTTON_LEFT then
            handle_left_click()
        end
        next_button_index = next_button_index + 1
        active_chord_index = last_created_button_number
    end
    animate_button(new_button, pressed_color_tabs, base_w_for_chord_tabs+20, base_h_for_chord_tabs+7, 3)
    update_labels()
    active_chord_index = last_created_button_number
end
chord_add.onclick = function()
    hide_all_boxes_and_reset_buttons()
    local last_created_button_number = #buttons + 1
    create_new_button_and_box(last_created_button_number)
end

--[[
local function collect_slider_info()
    local step_grid = {}
    for _, box in ipairs(boxes) do
        local chord_data = {mode = "down"} 
        for group_idx, slider_group in ipairs(box.slider_groups) do
            local group_name = box.button_names[group_idx]
            for step, slider in ipairs(slider_group.children) do
                if not chord_data[step] then
                    chord_data[step] = {step = step}
                end
                local value = "No Value!"
                if slider and slider.getDisplayValue then
                    value = slider:getDisplayValue()
                end
                chord_data[step][group_name] = value
            end
        end
        table.insert(step_grid, chord_data)
    end
    return step_grid
end

local function print_slider_info()
    local step_grid = collect_slider_info()
    local msg = "Step Grid Info:\n"
    for chord_idx, chord_data in ipairs(step_grid) do
        msg = msg .. "Chord " .. chord_idx .. " (Mode: " .. chord_data.mode .. ")\n"
        for step, step_data in ipairs(chord_data) do
            msg = msg .. "  Step " .. step .. ": "
            for k, v in pairs(step_data) do
                if k ~= "step" then
                    msg = msg .. k .. "=" .. tostring(v) .. ", "
                end
            end
            msg = msg:sub(1, -3) 
            msg = msg .. "\n"
        end
    end
    reaper.ShowConsoleMsg(msg)
end]]



local baaaatooon=win:add(rtk.Button{y=300,"x"})

baaaatooon.onclick = function()
    print_slider_info()
end

win:open()


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

