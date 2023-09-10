package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)
require 'rtk'
SimpleSlider = rtk.class('SimpleSlider', rtk.Spacer)
SimpleSlider.register{
    -- Value of the slider from 0.0 to 1.0, initialized in the middle.
    value = rtk.Attribute{default=0.5},
    -- Color of the slider
    color = rtk.Attribute{type='color', default='orange'},

    -- Parent class attribute overrides
    --
    -- Don't let it get too small, also acts as a default width.
    minw = 5,
    -- Override base class height so we default to the full height of parent container
    h = 1.0,
    -- Allow taking focus when clicked
    autofocus = true,
}

function SimpleSlider:initialize(attrs, ...)
    rtk.Spacer.initialize(self, attrs, SimpleSlider.attributes.defaults, ...)
end

function SimpleSlider:set_from_mouse_y(y)
    local h = self.calc.h - (y - self.clienty)
    local value = rtk.clamp(h / self.calc.h, 0, 1)
    self:animate{
        attr = 'value',
        dst = value,
        duration = 0.0070
    }
end


function SimpleSlider:_handle_draw(offx, offy, alpha, event)
    local calc = self.calc
    local x = offx + calc.x
    local y = offy + calc.y
    local h = calc.h * calc.value
    self:setcolor(calc.color)
    gfx.a = 0.2
    gfx.rect(x, y, calc.w, calc.h)
    gfx.a = 1.0
    gfx.rect(x, y + calc.h - h, calc.w, h)
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


-- Добавим переменную для хранения значения первого зажатого слайдера
local first_slider_value = nil

-- Добавляем переменную для хранения "фокусного" слайдера
local focused_slider = nil

-- ... (оставшаяся часть кода)

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




    local win = rtk.Window{w=600, h=400, padding=20}
    local group = win:add(SliderGroup{spacing=1, expand=1})
    for _ = 1, 10 do
        -- Use a 5px hotzone on either side to compensate for the 10px box spacing,
        -- so it allows the user to click inside the spacing and still get a response.
        group:add(SimpleSlider{lhotzone=5, rhotzone=5}, {fillw=true})
    end
    win:open()


