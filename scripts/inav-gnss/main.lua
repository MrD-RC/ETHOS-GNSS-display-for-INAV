-- Mr D's Simple script to display the satellite count when connected to INAV. 
-- It will automaticlly switch between CRSF and SmartPort telemetry sensors. 
-- SmartPort having the advantage of changing the colour of the text based on 
-- the fix. Red for no fix. Orange for fixed, and green for fixed and home fix.
local environment = system.getVersion()

local function create()
    local isCRSF = true
    local oldINAVSensor = false
    -- First, try to get the sats from a CRSF based telemetry
    local sensor = system.getSource("GPS Sats")

    if sensor == nil then
        -- Not CRSF. So try SmartPort, using the new INAV ID "GNSS - 0x0480"
        isCRSF = false
        sensor = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0480})

        if sensor == nil then
            -- No luck, try the old INAV ID "Tmp2 - 0x0410"
            sensor = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0410})
            oldINAVSensor = true
        end
    end

    local sensorLinked = sensor:state()

    return {sats = sensor, isCRSF = isCRSF, oldINAVSensor = oldINAVSensor, value = nil}
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    
    if widget.sensor == nil then
        lcd.font(FONT_L)
    local textW, textH = lcd.getTextSize("")
        lcd.drawText(w/2, (h - textH)/2, "No GNSS Sensor found", CENTERED)
    else
        lcd.font(FONT_XL)
        local textW, textH = lcd.getTextSize("")

        if widget.isCRSF then
            local sats = tonumber(widget.value)
            if sats > 5 then
                lcd.color(lcd.RGB(0xff, 0xa5, 0x00));
            else
                lcd.color(lcd.RGB(0xff, 0x00, 0x00));
            end
            
            if widget.sensor:state() == false then
                lcd.color(lcd.RGB(0x99, 0x99, 0x99));
            end

            lcd.drawText(w/2, (h - textH)/2, "Sats: " .. sats, CENTERED)
        else
            local sats = 0;
            if string.len(widget.value) > 1 then
                if string.len(widget.value) < 2 then
                    lcd.color(lcd.RGB(0xff, 0x00, 0x00));
                    sats = tonumber(widget.value)
                else
                    sats = tonumber(string.sub(widget.value, 3))
                    if tonumber(string.sub(widget.value, 1, 1)) > 0 then
                        if tonumber(string.sub(widget.value, 1, 1)) > 1 then
                            lcd.color(lcd.RGB(0x00, 0xff, 0x00));
                        else
                            lcd.color(lcd.RGB(0xff, 0xa5, 0x00));
                        end
                    else
                        lcd.color(lcd.RGB(0xff, 0x00, 0x00));
                    end
                end
            else
                lcd.color(lcd.RGB(0xff, 0x00, 0x00));
            end

            if widget.sensor:state() == false then
                lcd.color(lcd.RGB(0x99, 0x99, 0x99));
            end

            lcd.drawText(w/2, (h - textH)/2, "Sats: " .. sats, CENTERED)
        end
    end
end

local function wakeup(widget)
	-- this is the main loop that ethos calls every couple of ms
    if widget.sensor == nil then
        widget.isCRSF = true
        widget.oldINAVSensor = false
        -- First, try to get the sats from a CRSF based telemetry
        widget.sensor = system.getSource("GPS Sats")

        if widget.sensor == nil then
            -- Not CRSF. So try SmartPort, using the new INAV ID "GNSS - 0x0480"
            widget.isCRSF = false
            widget.sensor = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0480})

            if widget.sensor == nil then
                -- No luck, try the old INAV ID "Tmp2 - 0x0410"
                widget.sensor = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0x0410})
                widget.oldINAVSensor = true
            end
        end
    end

    local newVal = nil

    if widget.sensor ~= nil then
        newVal = widget.sensor:stringValue()

        if widget.oldINAVSensor then
            newVal = widget.sensor:rawValue()
        end
    end

    if widget.value ~= newVal then
        widget.value = newVal
        lcd.invalidate()
    end
end

local function init()
    system.registerWidget (
        {
            key = "mrdgnss",
            name = "INAV GNSS Widget",
            create = create,
            paint = paint,
            wakeup = wakeup,
            persistent = false,
            title = OFF,
        }
    )
end

return {init = init}