package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)
require 'rtk'
main_line_color = "#55666f"
SimpleSlider = rtk.class('SimpleSlider', rtk.Spacer)
SimpleSlider.register{
    value = rtk.Attribute{default=0.5}, --середина
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


function adjustBrightness(color, amount)
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
        
        -- Отрисовка полосы середины
        gfx.a = 0.4
        gfx.rect(x, y + half_h, calc.w, 1)
    
        if calc.value >= 0.5 then  -- Изменил условие с "> 0.4" на ">= 0.5"
            draw_y = y + half_h - draw_h
        else
            draw_y = y + half_h
        end
    end
    
    local adjustedColor = adjustBrightness(calc.color, calc.value - 0.5)
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

    -- Устанавливаем параметры шрифта
    gfx.setfont(1, self.font, self.fontsize)

    -- Вычисляем размеры текста
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


SliderGroup = rtk.class('SliderGroup', rtk.HBox)



function SimpleSlider:_handle_mousedown(event)
    local ok = rtk.Spacer._handle_mousedown(self, event)
    if ok == false then
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
    local duration = 0.3  -- Время анимации в секундах

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
                local newValue = i % 2 == 0 and even_value or odd_value
                updateConsoleMessage(slider)
                slider:animate{
                    attr = 'value',
                    dst = newValue,
                    duration = duration
                }
            end
        end
        return  -- Выходим из функции, так как 'wave' уже обработан
    end
    for i, child in ipairs(self.children) do
        local slider = child[1]
        if rtk.isa(slider, SimpleSlider) then
            local newValue  -- переменная для нового значения
            if mode == 'random' then
                newValue = 0.1 + 0.8 * math.random()
            elseif mode == 'ascending' then
                newValue = 0.1 + (0.8 * (i - 1) / (total_sliders - 1))
            elseif mode == 'descending' then
                newValue = 0.1 + (0.8 * (total_sliders - i) / (total_sliders - 1))

            elseif mode == 'up_from_current' then
                if i == current_slider_idx then
                    newValue = 0.9
                elseif i < current_slider_idx then
                    newValue = 0.1 + (0.8 * (i - 1) / (current_slider_idx - 1))
                else
                    newValue = 0.1 + (0.8 * (total_sliders - i) / (total_sliders - current_slider_idx))
                end
            elseif mode == 'down_from_current' then
                if i == current_slider_idx then
                    newValue = 0.1
                elseif i > current_slider_idx then
                    newValue = 0.1 + (0.8 * (i - current_slider_idx) / (total_sliders - current_slider_idx))
                else
                    newValue = 0.1 + (0.8 * (current_slider_idx - i) / (current_slider_idx - 1))
                end
            end
            
            -- Применяем анимацию
            slider:animate{
                attr = 'value',
                dst = newValue,
                duration = duration
            }
        end
    end
end
function updateConsoleMessage(slider)
    -- Найти текущую вкладку и порядковый номер слайдера
    local tabName = "Unknown Tab"  -- Получить текущую вкладку
    local sliderIndex = "Unknown Index"  -- Получить порядковый номер слайдера
    local sliderType = "Unknown Type"  -- Получить тип слайдера

    -- Здесь должен быть код, который определяет tabName, sliderIndex и sliderType

    -- Используем getDisplayValue для получения текущего значения
    local displayValue = slider:getDisplayValue()
    
    -- Вывести сообщение в консоль
    reaper.ShowConsoleMsg(string.format("Вкладка: %s\nНомер: %s\nТип: %s\nЗначение: %s\n", 
                                       tabName, sliderIndex, sliderType, displayValue))
end


local first_slider_value = nil

local focused_slider = nil


function SliderGroup:_handle_dragstart(event, x, y, t)
    first_slider_value = nil
    focused_slider = nil  -- Сброс фокуса при начале нового перетаскивания
    local draggable, droppable = rtk.HBox._handle_dragmousemove(self, event)
    if draggable ~= nil then
        return draggable, droppable
    end
    return {lastx=x, lasty=y}, false
end

function SliderGroup:_handle_dragmousemove(event, arg)
    local ok = rtk.HBox._handle_dragmousemove(self, event)
    if ok == false or event.simulated then
        return ok
    end

    local x0 = math.min(arg.lastx, event.x)
    local x1 = math.max(arg.lastx, event.x)

    for i = 1, #self.children do
        local child = self.children[i][1]
        if child.clientx >= x1 then
            break
        elseif child.clientx + child.calc.w > x0 and rtk.isa(child, SimpleSlider) then
            if event.ctrl and not focused_slider then
                focused_slider = child  -- Установим фокус на этом слайдере
            end

            if event.shift then
                if first_slider_value == nil then
                    first_slider_value = child.value
                end
                child:attr('value', first_slider_value)
            elseif focused_slider then
                focused_slider:set_from_mouse_y(event.y)  -- Изменяем только фокусный слайдер
            else
                child:set_from_mouse_y(event.y)
            end
        end
    end
    arg.lastx = event.x
    arg.lasty = event.y
end


function SimpleSlider:_handle_mousewheel(event)
    local _, _, _, wheel_y = tostring(event):find("wheel=(%d+.?%d*),(-?%d+.?%d*)")
    local delta = tonumber(wheel_y)
    
    -- Считаем шаг, если не задан
    local step = self.step or ((tonumber(self.max) - tonumber(self.min)) / 100)
    local new_val = self.value + (delta > 0 and -step or step)
    
    -- Убеждаемся, что новое значение входит в допустимый диапазон
    new_val = math.max(tonumber(self.min), math.min(tonumber(self.max), new_val))

    -- Обновляем значение
    self:attr('value', new_val)
    
    return true
end

function SimpleSlider:getDisplayValue()
    local calc = self.calc
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
    return text_to_display
end


bg_all="#262422"

base_w = 35
base_w_slider=58
spacing_1 = base_w/base_w
base_w_for_chord_tabs=60
big_w_for_chord_tabs = base_w_for_chord_tabs + 20
base_h_for_chord_tabs=25
base_color = "#3a3a3a"
pressed_color_tabs = "#08737f"
--[[
velocity_color_slider
octave_color_slider
gate_color_slider
ratchet_color_slider
rate_color_slider


]]

local win = rtk.Window{bg="#1a1a1a",w=450, h=340}
local lastCreatedButtonNumber = 0

local hibox_buttons_browser=win:add(rtk.HBox{})
local chord_add = hibox_buttons_browser:add(rtk.Button{"+"})
local line_add = win:add(rtk.Button{y=200,"plus"})

local buttonCount = 1
local boxes = {} -- Сюда будем складывать все созданные VBox'ы
local container_advanced_3
local index_strip = 8

local function createNewBox()
   
    container_advanced_3=win:add(rtk.HBox{padding=20})
    local vbox = container_advanced_3:add(rtk.VBox{x=15,w=base_w, h=200, padding=25})
    local sliderGroups = {}
    local buttonNames = {'velocity', 'octave', 'gate', 'ratchet', 'rate'}
    
    
    local slider_and_buttons_modes=container_advanced_3:add(rtk.VBox{})
    local container_advanced_vb=slider_and_buttons_modes:add(rtk.HBox{})
    local slider_container_win=slider_and_buttons_modes:add(rtk.HBox{})
    
    -- Функция для создания слайдера
    local function createSlider(group, params, sliderIndex, sliderType, chordIndex)
        local slider = group:add(SimpleSlider(params), {fillw=true})
        slider.onmouseup = function(self, event, arg, x, y, z)
            -- Получаем реальное значение слайдера через вашу функцию getDisplayValue
            local displayValue = self:getDisplayValue()
    
            -- Используем reaper для вывода информации в консоль
            local msg = string.format("Вкладка Chord %d:\n%d. %s %s\n", chordIndex, sliderIndex, sliderType, displayValue)
            reaper.ShowConsoleMsg(msg)
        end
    end
    
    local function toggleGroups(activeIndex)
        for i, group in ipairs(sliderGroups) do
            if i == activeIndex then
                group:show()
            else
                group:hide()
            end
        end
    end
    local isProgrammaticChange = false
    local slider_mode_win = slider_container_win:add(rtk.Slider{value=20,step=20, ticks=5,tracksize=4,thumbsize=1,thumbcolor='transparent',z=-5,w=base_w_slider*5,y=192})
    
    
    for i, name in ipairs(buttonNames) do
        local sliderGroup = vbox:add(SliderGroup{spacing=spacing_1, expand=2})
        sliderGroup:hide()
        table.insert(sliderGroups, sliderGroup)
        
        local button = container_advanced_vb:add(rtk.Button{z=5, halign='center', spacing=2, padding=2, w=base_w_slider, label=name, y=190})
        
        
        -- Добавлено: перемещение слайдера при прокрутке колеса мыши
        button.onmousewheel = function(self, event)
            local _, _, _, wheel_y = tostring(event):find("wheel=(%d+.?%d*),(-?%d+.?%d*)")
            wheel_y = tonumber(wheel_y)
            local c_val = (wheel_y > 0) and slider_mode_win.value - slider_mode_win.step or slider_mode_win.value + slider_mode_win.step
        
            if c_val > slider_mode_win.max then
                c_val = slider_mode_win.min
            elseif c_val < slider_mode_win.min then
                c_val = slider_mode_win.max
            end
        
            slider_mode_win:attr('value', c_val)
            return true
        end
        
        button.onclick = (function(idx)
            return function()
                isProgrammaticChange = true
                slider_mode_win:attr('value', idx * 20)
                toggleGroups(idx)
                isProgrammaticChange = false
                slider_mode_win:focus()
            end
        end)(i)
    end
    
    
    
    slider_mode_win.onchange = function(self, event)
        if isProgrammaticChange then return end
        isProgrammaticChange = true
    
        local value = math.floor(self.value / 20 + 0.5) * 20
    
        -- Проверяем, не равно ли значение 0
        if value == 0 then
            value = 20
        end
    
        self:attr('value', value)
        local index = value / 20
        toggleGroups(index)
    
        isProgrammaticChange = false
    end
    
    slider_mode_win.onmousewheel = function(self, event)
        local _, _, _, wheel_y = tostring(event):find("wheel=(%d+.?%d*),(-?%d+.?%d*)")
        wheel_y = tonumber(wheel_y)
        local c_val = (wheel_y > 0) and self.value - self.step or self.value + self.step
    
        if c_val > self.max then
            c_val = self.min
        elseif c_val < self.min then
            c_val = self.max
        end
    
        -- Проверяем, не равно ли значение 0
        if c_val == 0 then
            c_val = 20
        end
    
        self:attr('value', c_val)
        return true
    end
    
    
    
    
    
    
    
    sliderGroups[1]:show()
    
    -- Создание слайдеров
    for i = 1, index_strip do
        createSlider(sliderGroups[1], {w=base_w,
        lhotzone=5,
        font='Times',
        min=1,
        max=127,
        value=0.79,
        valign='down',
        text_color="#ffffff",
        halign='left',
        w=base_w,
        lhotzone=5,
        rhotzone=5},i, "velocity",lastCreatedButtonNumber)  -- параметры для velocity
        createSlider(sliderGroups[2], {color='#fafa6e',
        w=base_w,
        lhotzone=5,
        font='Times',
        min=-5,
        max=5,
        value=0.5,
         target='center',
        valign='down',
        text_color="#ffffff",
        halign='left',
        w=base_w,
        lhotzone=5,
        rhotzone=5},i, "octave",lastCreatedButtonNumber) -- параметры для octave
        createSlider(sliderGroups[3], {color='#2a4858',
        w=base_w,
        lhotzone=5,
        font='Times',
        min={1, "%"},
        max={100, "%"},
        value=0.5,
        valign='down',
        text_color="#ffffff",
        halign='left',
        w=base_w,
        lhotzone=5},i, "gate",lastCreatedButtonNumber)  -- параметры для gate
        createSlider(sliderGroups[4], {color='#7E7A3E',
        w=base_w,
        lhotzone=5,
        font='Times',
        min=0, 
        max=10,
        value=0.05,
        valign='down',
        text_color="#ffffff",
        halign='left',
        w=base_w,
        lhotzone=5,
        rhotzone=5},i, "ratchet",lastCreatedButtonNumber)  -- параметры для ratchet
        createSlider(sliderGroups[5], {color='#009a86',
        w=base_w,
        lhotzone=5,
        font='Times',
        min=1, 
        max=12,
        ticklabels={"1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16",  "1/24", "1/32", "1/48", "1/64"},
        value=0.5,
        valign='down',
        text_color="#ffffff",
        halign='left',
        w=base_w,
        lhotzone=5,
        rhotzone=5},i, "rate",lastCreatedButtonNumber)  -- параметры для rate
    end
    return container_advanced_3
end


line_add.onclick = function()

end

local nextButtonIndex = 1  -- Следующий индекс для кнопки
local buttons = {}  -- Список для хранения всех кнопок
local currentButtonCount = 0


chord_add.onclick = function()
    -- Скрыть все существующие боксы
    for _, box in pairs(boxes) do
        box:hide()
    end
    
    lastCreatedButtonNumber = lastCreatedButtonNumber + 1
    currentButtonCount = currentButtonCount + 1
    local newBox = createNewBox()
    boxes[lastCreatedButtonNumber] = newBox
    
    local newButton = hibox_buttons_browser:add(rtk.Button{color=base_color, gradient=2, halign='center', spacing=4, padding=2, h=base_h_for_chord_tabs, w=base_w_for_chord_tabs, label="Chord " .. lastCreatedButtonNumber})
    table.insert(buttons, newButton)  -- Добавляем новую кнопку в список

    newBox:show()
    
    newButton.onclick = function(self, event)
        if event.button == rtk.mouse.BUTTON_RIGHT then
            local menu2 = rtk.NativeMenu()
            menu2:set({
                {"Delete", id='delete'}
            })
            menu2:open_at_mouse():done(function(item)
                if item and item.id == 'delete' then
                    hibox_buttons_browser:remove(newButton)
                    win:remove(newBox)
                    
                    for i, btn in ipairs(buttons) do
                        if btn == newButton then
                            table.remove(buttons, i)
                            table.remove(boxes, i)
                            break
                        end
                    end

                    currentButtonCount = currentButtonCount - 1

                    -- Обновляем названия оставшихся кнопок
                    for i, btn in ipairs(buttons) do
                        btn:attr('label', "Chord " .. i)
                    end
                end
            end)
            
        elseif event.button == rtk.mouse.BUTTON_LEFT then
              for _, box in pairs(boxes) do
                  box:hide()
              end
              for _, btn in pairs(buttons) do
                  btn:animate{'color', dst=base_color, duration=0.1}
                  btn:animate{'w', dst=base_w_for_chord_tabs, duration=0.3, easing="out-back"}
                  btn:animate{'h', dst=base_h_for_chord_tabs, duration=0.3, easing="out-back"}
                  btn:attr('gradient', 2)
              end
              
              -- Показать только что созданный бокс и применить к нему анимацию
              newBox:show()
              newButton:animate{'color', dst=pressed_color_tabs, duration=0.1}
              newButton:attr('gradient', 3)
              newButton:animate{'w', dst=base_w_for_chord_tabs+20, duration=0.3, easing="out-quart"}
              newButton:animate{'h', dst=base_h_for_chord_tabs+7, duration=0.3, easing="out-bounce"}
              
          end
          
          nextButtonIndex = nextButtonIndex + 1 
        end
              for _, box in pairs(boxes) do
                  box:hide()
              end
              for _, btn in pairs(buttons) do
                  btn:animate{'color', dst=base_color, duration=0.1}
                  btn:animate{'w', dst=base_w_for_chord_tabs, duration=0.3, easing="out-back"}
                  btn:animate{'h', dst=base_h_for_chord_tabs, duration=0.3, easing="out-back"}
                  btn:attr('gradient', 2)
              end
              
              -- Показать только что созданный бокс и применить к нему анимацию
              newBox:show()
              newButton:animate{'color', dst=pressed_color_tabs, duration=0.1}
              newButton:attr('gradient', 3)
              newButton:animate{'w', dst=base_w_for_chord_tabs+20, duration=0.3, easing="out-quart"}
              newButton:animate{'h', dst=base_h_for_chord_tabs+7, duration=0.3, easing="out-bounce"}
end


--[[
    slider_group_w = SimpleSlider.w
    slider_h_group:add(CircleWidget2{bg="#363a3b",ref='circle', w=base_w, h=40, borderFraction=0/11})
    color_slider="#A0522D"
    local button1 = buttonGroup:add(rtk.Button{
    color=thumb_color_first,
    gradient=0,
    halign='center',
    w=base_w,
    label='0'},
    {fillw=true})
    
    
    
    local dragging = false
    local prevX, prevY = nil, nil
    local dragAccumulatorX = 0
    local dragAccumulatorY = 0
    local dragThreshold = 25  -- порог для изменения значения
    local currentValue = 0  -- Предположительно начальное значение
    
    
    button1.onmouseenter = function(self, event)
      button1:attr("cursor", rtk.mouse.cursors.REAPER_POINTER_LEFTRIGHT)
    end
    button1.onmouseleave = function(self, event)
      button1:attr("cursor", rtk.mouse.cursors.UNDEFINED )
    end
    button1.ondragstart = function(self, event, x, y, t)
        dragging = true
        prevX, prevY = x, y
        button1:attr("cursor", rtk.mouse.cursors.REAPER_MARKER_HORIZ)
        return true
    end
    button1.onmouseup = function(self, event)
     button1.onmouseleave = function(self, event)
       button1:attr("cursor", rtk.mouse.cursors.UNDEFINED )
     end
     button1:attr("cursor", rtk.mouse.cursors.UNDEFINED )
    end
     
    button1.ondragend = function(self, event, dragarg)
        dragging = false
        prevX, prevY = nil, nil
        button1:attr("cursor", rtk.mouse.cursors.UNDEFINED)
    

    end
    
    button1.onmousewheel = function(self, event)
        local _, _, _, wheel_y = tostring(event):find("wheel=(%d+.?%d*),(-?%d+.?%d*)")
        wheel_y = tonumber(wheel_y)
        currentValue = wheel_y > 0 and currentValue - 1 or currentValue + 1
        currentValue = math.max(-4, math.min(4, currentValue))
        button1:attr('label', tostring(currentValue))
    
        return true
    end
    
    button1.ondragmousemove = function(self, event, dragarg)
        if dragging and prevX and prevY then
            local deltaX = event.x - prevX
            
            dragAccumulatorX = dragAccumulatorX + deltaX
    
            if math.abs(dragAccumulatorX) > dragThreshold then
                if deltaX > 0 then
                    currentValue = currentValue + 1  -- Изменено здесь
                elseif deltaX < 0 then
                    currentValue = currentValue - 1  -- Изменено здесь
                end
    
                dragAccumulatorX = 0
                
                currentValue = math.max(-4, math.min(4, currentValue))
                button1:attr('label', tostring(currentValue))
                prevX, prevY = event.x, event.y
            end
        end
    end
    
    
    thumb_color_first = '#4E5557'
    thumb_color_second = '##55666f'
    
    
    
    local currentValue_2 = 0
    CircleWidget2 = rtk.class('CircleWidget2', rtk.Spacer)
    CircleWidget2.register{
        radius = rtk.Attribute{default=33},
        borderFraction = rtk.Attribute{default=1},
        color = rtk.Attribute{type='color', default='red'},
        borderColor = rtk.Attribute{type='color', default='gray'},
        borderwidth = rtk.Attribute{default=5},
        currentValue_2 = rtk.Attribute{default=0},  -- Добавляем атрибут currentValue
    }
    
    function CircleWidget2:initialize(attrs, ...)
        rtk.Spacer.initialize(self, attrs, CircleWidget2.attributes.defaults, ...)
        self.alpha2 = 0.07
        self.currentRadius = 0
        self.currentValue_2 = 0  -- Добавьте это для каждого индивидуального кноба
    end
    
    
    function makeDarker(color, amount)
            local r, g, b = color:match("#(%x%x)(%x%x)(%x%x)")
            r = math.floor(math.max(0, tonumber(r, 16) * (1 - amount)))
            g = math.floor(math.max(0, tonumber(g, 16) * (1 - amount)))
            b = math.floor(math.max(0, tonumber(b, 16) * (1 - amount)))
            return string.format("#%02x%02x%02x", r, g, b)
    end
    currentLabelText = ""
    
    function CircleWidget2:_handle_draw(offx, offy, alpha, event)
        local calc = self.calc
        local x = offx + calc.x + calc.w / 2
        local y = offy + calc.y + calc.h / 2
        local knobRadius = calc.radius + self.currentRadius
    
        local startAngle = 90
        local labels = {"0","1/2", "1/3", "1/4", "1/6", "1/8", "1/12", "1/16",  "1/24", "1/32", "1/48", "1/64"}
        local stepAngle = 360 / #labels
        local borderAngle = startAngle + 360 * (self.currentValue_2 / (#labels - 1))
        local thickness = 12
        local alpha2 = 0.07
        local lineLengths = {5}
        local lineCount = #lineLengths
        local totalLines = #labels
        local lineAngleStep = 360 / totalLines
        for i = 1, totalLines do
            local isNearestLabel = math.abs(i - 1 - self.currentValue_2) < 0.5
            if isNearestLabel then
                self:setcolor('#f3f3f3')
            else
                self:setcolor('#1a1a1a')
            end
            bl = 15
            local angle = math.rad(startAngle + lineAngleStep * (i - 1))
            local lineLength = lineLengths[(i - 1) % lineCount + 1]
            local x1 = x + (knobRadius - bl) * math.cos(angle)  -- было - 8
            local y1 = y + 1 + (knobRadius - bl) * math.sin(angle)  -- было - 8
            local x2 = x + (knobRadius - bl - lineLength ) * math.cos(angle)  -- было - 1 - lineLength
            local y2 = y + 1 + (knobRadius - bl - lineLength ) * math.sin(angle)  -- было - 1 - lineLength
    
            gfx.line(x1, y1, x2, y2, 2)
        end
        
        
        for i = 1, 9 do
            local alpha = alpha2 * (10 - i)
            gfx.set(0, 0, 0, alpha)
            gfx.circle(x - 1, y + 4, knobRadius - calc.borderwidth - 25 + i, 15, true)
        end
    
        local outerRadius = math.floor(knobRadius - calc.borderwidth - 12)
        local steps = 20
        local stepSize = outerRadius / steps
        local color = thumb_color_first
        
        for i = steps, 1, -1 do
            self:setcolor(color)
            gfx.circle(x, y, stepSize * i, 290, true)
            color = makeDarker(color, -0.03)
        end
        
        local markerAngle = math.rad(startAngle + stepAngle * self.currentValue_2)
        local markerDistance = knobRadius - 35
        local markerX = x + markerDistance * math.cos(markerAngle)
        local markerY = y + markerDistance * math.sin(markerAngle)
        markerX = math.floor(markerX + 0.5)
        markerY = math.floor(markerY + 0.5)
        bl = 3
        color = makeDarker(color, 0.065)
        self:setcolor(color)
        gfx.circle(markerX, markerY, 10, bl, true)
    
        local markerAngle = math.rad(startAngle + stepAngle * self.currentValue_2)
        local markerDistance = knobRadius - 25
        local markerX = x + markerDistance * math.cos(markerAngle)
        local markerY = y + markerDistance * math.sin(markerAngle)
        markerX = math.floor(markerX + 0.5)
        markerY = math.floor(markerY + 0.5)
        bl = 3
        color = makeDarker(color, 0.6)
        self:setcolor(color)
        gfx.circle(markerX, markerY, 4, bl, true)
    
        local innerRadius = math.floor((knobRadius - calc.borderwidth - 12) * 0.75)
        local steps = 10
        local stepSize = innerRadius / steps
        local color = thumb_color_second
        
        for i = steps, 1, -1 do
            self:setcolor(color)
            gfx.circle(x, y, stepSize * i, 290, true)
            color = makeDarker(color, 0.0001)
        end
        
        local roundedValue = math.round(self.currentValue_2)
        local labelText = labels[roundedValue + 1]
        
        
        self:setcolor('#FFFFFF')  -- Измените на нужный вам цвет
        gfx.setfont(1, "Gadget", 15)
        gfx.x = x - gfx.measurestr(labelText) / 2
        gfx.y = y + 21
        gfx.drawstr(labelText)
    
    
    end
    
    
        
    
    local dragging = false
    local prevY = nil
    local sensitivity = 0.07  -- уменьшено для большей чувствительности
    CircleWidget2.currentValue_2 = 0
    
    CircleWidget2.ondragstart = function(self, event, x, y, t)
        dragging = true
        prevY = y
        self.alpha2 = 0.02
        
    
        return true
    end
    
    CircleWidget2.ondragend = function(self, event, dragarg)
        self:attr('cursor', nil)
        dragging = false
        prevY = nil
        self.alpha2 = 0.07
    
    end
    
    local lerpSpeed = 0.01
    local lastNearestLabel = nil
    
    
    
    
    CircleWidget2.ondragmousemove = function(self, event, dragarg)
        if dragging and prevY then
            local delta = event.y - prevY
            self.currentValue_2 = self.currentValue_2 - delta * sensitivity
            self.currentValue_2 = math.max(0, math.min(11, self.currentValue_2))  -- 11 - максимальное значение
    
            local nearestLabel = math.floor(self.currentValue_2)
            if self.currentValue_2 - nearestLabel >= 0.5 then
                nearestLabel = nearestLabel + 1
            end
    
            if lastNearestLabel and math.abs(nearestLabel - lastNearestLabel) > 1 then
                nearestLabel = lastNearestLabel + math.sign(nearestLabel - lastNearestLabel)
            end
    
            lastNearestLabel = nearestLabel
    
            local threshold = 0.01
    
            if math.abs(self.currentValue_2 - nearestLabel) < threshold then
                self.currentValue_2 = nearestLabel
            else
                self.currentValue_2 = self.currentValue_2 * (1 - lerpSpeed) + nearestLabel * lerpSpeed
            end
    
            local borderFraction = self.currentValue_2 / 11  -- 11 - максимальное значение
            self:attr('borderFraction', borderFraction)
    
            prevY = event.y
        end
    end
    
    CircleWidget2.onmousewheel = function(self, event)
        local _, _, _, wheel_y = tostring(event):find("wheel=(%d+.?%d*),(-?%d+.?%d*)")
        wheel_y = tonumber(wheel_y)
        
        local step = 1  -- Шаг изменения. Можешь изменить, если нужно
        local nearestLabel = math.floor(self.currentValue_2)  -- Добавлено self.
    
        if wheel_y > 0 then
            nearestLabel = nearestLabel - step
        else
            nearestLabel = nearestLabel + step
        end
    
        nearestLabel = math.max(0, math.min(11, nearestLabel))  -- 11 - максимальное значение
        self.lastNearestLabel = nearestLabel  -- Добавлено self.
        
        self.currentValue_2 = nearestLabel  -- Перемещаемся к ближайшей метке. Добавлено self.
        local borderFraction = self.currentValue_2 / 11  -- 11 - максимальное значение. Добавлено self.
        self:attr('borderFraction', borderFraction)
    
        return true
    end
    
    
    
    function math.sign(x)
        return x > 0 and 1 or x < 0 and -1 or 0
    end
    
]]

win:open()


