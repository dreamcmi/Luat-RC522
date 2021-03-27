--- 模块功能：rc522-demo
-- @module rc522·
-- @author Wendal & Darren
-- @release 2021.03.26

PROJECT = "air302_rc522_demo"
VERSION = "1.0.0"

local sys = require "sys"
local RC522 = require "RC522"

--------------------------------------------------------
--  Converts a table of numbers into a HEX string
--  将数字表转换为十六进制字符串
local function appendHex(t)
  strT = ""
  for i,v in ipairs(t) do
    strT = strT.." 0x"..string.format("%X", t[i])
  end
  return strT
end

---------------------------------------------------
-- Initialise the RC522

sys.taskInit(function()
  sys.wait(3000)
  RC522.setup()
  sys.wait(100)
  log.info("=================================================")
  log.info("Ver","RC522 Firmware Version: 0x"..string.format("%X", RC522.getFirmwareVersion()))

  while true do
    sys.wait(1000)
    isTagNear, cardType = RC522.request()
    
    if isTagNear == true then
      err, serialNo = RC522.anticoll()
      log.info("","Tag Found: "..appendHex(serialNo).."  of type: "..appendHex(cardType))

      -- Selecting a tag, and the rest afterwards is only required if you want to read or write data to the card
    
      err, sak = RC522.select_tag(serialNo)
      if err == false then
        log.info("","Tag selected successfully.  SAK: 0x"..string.format("%X", sak))
    
    
        for i = 0,63 do
          err = RC522.card_auth(auth_a, i, keyA, serialNo)     --  Auth the "A" key.  If this fails you can also auth the "B" key
          if err then 
            log.info("","ERROR Authenticating block "..i)
          else
            -- Write data to card, enable if you need it
            --if (i == 2) then   -- write to block 2
            --  err = RC522.writeTag(i, { 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 })
            --  if err then print("ERROR Writing to the Tag") end
            --end
    
            -- Read card data
            if not (i % 4 == 3) then   --  Don't bother to read the Sector Trailers 
              err, tagData = RC522.readTag(i)
              if not err then log.info("","READ Block "..i..": "..appendHex(tagData)) end
            end
          end
        end
    
        
      else
        log.info("ERROR Selecting tag")
    
      end
      log.info(" ")
    
      -- halt tag and get ready to read another.
      buf = {}
      buf[1] = 0x50  --MF1_HALT
      buf[2] = 0
      crc = RC522.calculate_crc(buf)
      table.insert(buf, crc[1])
      table.insert(buf, crc[2])
      err, back_data, back_length = RC522.card_write(mode_transrec, buf)
      RC522.clear_bitmask(0x08, 0x08)    -- Turn off encryption

    else 
      log.info("NO TAG FOUND")
    end
  end
end)

-- 结尾总是这一句哦
sys.run()