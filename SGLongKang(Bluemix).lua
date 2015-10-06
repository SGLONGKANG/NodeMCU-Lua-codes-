mqttState = 0

topic = "iot-2/evt/status/fmt/json"

function enInt()
  gpio.mode(3,gpio.INT)
  gpio.trig(3,"up", rpm)
end

function disInt()
  gpio.mode(3,gpio.INPUT)
end

function delay_us(micro_secs)
  local timestart = tmr.now()
  while(tmr.now() - timestart < micro_secs) do
    tmr.wdclr()
  end
end

function FlowRate()
  local NbTopsFan = 0
  enInt()
  delay_us(1000*1000)
  disInt()
  NbTopsFan = NbTopsFan*60/7.5
  print(NbTopsFan)
  return(NbTopsFan)
end

function mqtt_do()
  if mqttState < 5 then
  mqttState = wifi.sta.status() 
  wifi.setmode(wifi.STATION)
  wifi.sta.config("G3_1367","bryangoh")
  wifi.sta.connect()
  
  elseif mqttState == 5 then
  print("Starting to connect...")
  m = mqtt.Client("d:quickstart:esp8266:18fe349e543f",120,"","")
  m:on("offline", function(conn) 
  print ("Checking IoTF server...") 
  mqttState = 0 end)
  m:connect('quickstart.messaging.internetofthings.ibmcloud.com',1883, 0, 
  function(conn)
  print("Connected to quickstart.messaging.internetofthings.ibmcloud.com:1883")
  mqttState = 20 end)

  elseif mqttState == 20 then
  mqttState = 25
    
  m:publish(topic ,'{"d": {"FlowRate":'..FlowRate()..'}}', 0, 0,
  function(conn)
  print("Sent message")
  mqttState = 20 end)

  else print("Waiting...")
  mqttState = mqttState - 1 
  end
  
end
tmr.alarm(2, 10000, 1, function() mqtt_do() end) 