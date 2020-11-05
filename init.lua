-- Initial File
print("Night Light")

-- light pin
pin_light = 1

-- link the btn_wifi pin to GND for a short time to trigger the btn_wifi_fn()
btn_wifi = 2

-- link the btn_wifi pin to GND for a short time to trigger the btn_wifi_fn()
btn_time = 3

-- light duration
light_from = 17
light_to = 7

gpio.mode(pin_light, gpio.OUTPUT)
gpio.mode(btn_wifi, gpio.INPUT)
gpio.mode(btn_time, gpio.INPUT)

function light()
    now = rtctime.get()
    print(now)
    sec = now % 86400
    minute = math.floor(sec / 60)
    hour = math.floor(minute / 60) + time_offset
    print("now: " , tostring(hour), ":", tostring(minute % 60))
    if hour > light_from or hour < light_to then
        gpio.write(pin_light, gpio.HIGH)
    else
        gpio.write(pin_light, gpio.LOW)
    end
    if now ~= 0 then
        print('saving time: ' .. tostring(now))
        file.putcontents('time.now', now)
    end
end

-- CN time offset
time_offset = 8

-- sync time
function sync_time()
    -- sync time
    print("sync time...")
    server_list = {"cn.pool.ntp.org", "CN.NTP.ORG.CN"}
    sntp.sync(server_list, 
        function(sec, usec, server, info)
            print('sync', sec, usec, server)
            file.putcontents('time.now', sec)
        end,
        function()
            print('failed to sync time!')
            print('try to read local time')
            if file.exists('time.now') then 
                local t = file.getcontents('time.now')
                rtctime.set(t)
                print('using local time: ' .. tostring(t))
            end
        end)
end

-- enduser setup
function eus()
    print("initializing...")
    wifi.sta.autoconnect(0)
    enduser_setup.start(
      function()
        print("Connected to WiFi as:" .. wifi.sta.getip())
        wifi.sta.autoconnect(1)
        init()
      end,
      function(err, str)
        print("enduser_setup: Err #" .. err .. ": " .. str)
      end,
      print -- Lua print function can serve as the debug callback
    )
end

-- register btn_wifi
print("registering btn_wifi")
gpio.write(btn_wifi, gpio.HIGH)
function btn_wifi_fn()
    gpio.trig(btn_wifi)
    local time = tmr.create()
    time:alarm(2000, tmr.ALARM_SINGLE, function()
        gpio.trig(btn_wifi, 'up', btn_wifi_fn)
    end)
    print("wifi btn clicked")
    eus()
end
gpio.trig(btn_wifi, 'up', btn_wifi_fn)

-- register btn_time
print("registering btn_time")
gpio.write(btn_time, gpio.HIGH)
function btn_time_fn()
    gpio.trig(btn_time)
    local time = tmr.create()
    time:alarm(2000, tmr.ALARM_SINGLE, function()
        gpio.trig(btn_time, 'up', btn_time_fn)
    end)
    print("time btn clicked")
    sync_time()
end
gpio.trig(btn_time, 'up', btn_time_fn)

-- global tmr
night_light = tmr.create()
night_light:alarm(1000, tmr.ALARM_AUTO, function()
    light()
end)

-- initial function
function init()
    
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("connected")
    sync_time()
    init()
end)

sync_time()
