wifi.setmode(wifi.STATION);
wifi.sta.config("James","gaic7721");
NbTopsFan = 0;

gpio.mode(2, gpio.INPUT);
gpio.mode(1, gpio.OUTPUT); 

function rpm()
  NbTopsFan = NbTopsFan + 1;
end 

function enInt()
  gpio.mode(3,gpio.INT);
  gpio.trig(3,"up", rpm);
end

function disInt()
  gpio.mode(3,gpio.INPUT);
end

function delay_us(micro_secs)
   local timestart = tmr.now();
   while(tmr.now() - timestart < micro_secs) do
     tmr.wdclr();
   end
end

function read_usonic()
   local pulse_start = 0;
   local pulse_end = 0;
   gpio.write(1, gpio.LOW);
   delay_us(5);
   gpio.write(1, gpio.HIGH);
   delay_us(10);
   gpio.write(1, gpio.LOW);
   while(gpio.read(2) == 0) do
     tmr.wdclr();
     pulse_start = tmr.now();
   end
   while(gpio.read(2) == 1) do
      tmr.wdclr();
      pulse_end = tmr.now();
   end
   print(((pulse_end-pulse_start)/58).."cm");
   return ((pulse_end-pulse_start)/58);
end

function FlowRate()
  NbTopsFan = 0;
  enInt();
  delay_us(1000*1000);
  disInt();
  NbTopsFan = NbTopsFan*60/7.5;
  print(NbTopsFan.."l/h");
  return(NbTopsFan);
end

function postThingSpeak(Flowrate, Depth)
    connout = net.createConnection(net.TCP,0)

    connout:on("receive", function(connout, payloadout)
       if(string.find(payloadout, "Status: 200 OK") ~=nil) then
          print("Posted OK");
       end
    end)

    connout:on("connection", function(connect, payloadout)
        print("Posting....");

        connout:send("GET /update?api_key=DAVSJDLY1K64OLSD&field1=%d"..(Depth)
        .."&field2=%d"..(Flowrate)
        .." HTTP/1.1\r\n"
        .."Host: api.thingspeak.com\r\n"
        .."Connection: close\r\n"
        .."Accept: */*\r\n"
        .."User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
        .."\r\n")
    end)

    connout:on("disconnection", function(connout, payloadout)
       connout:close();
       collectgarbage();
    end)

    connout:connect(80,'api.thingspeak.com')
end

tmr.alarm(1,60000, 1, function() postThingSpeak(FlowRate(), read_usonic()) end);
