
#include "Wire.h"
#include "MPR121.h"

MPR121 touch;

#define POT_IN  A1
#define LED_CLK 12
#define LED_DAT 13

void setup() {
  pinMode(LED_CLK, OUTPUT);
  pinMode(LED_DAT, OUTPUT);
  Serial.begin(9600);
  Wire.begin();
  delay(100);
  touch.initialize();
//  if (touch.testConnection()) {
//    Serial.println("connection successful");
//  } else {
//    Serial.println("connection failed");
//  }
  sendColor(255, 0, 0);
  delay(333);
  sendColor(0, 255, 0);
  delay(333);
  sendColor(0, 0, 255);
  delay(333);
  /*sendColor(127, 0, 0);
  delay(1000);
  sendColor(0, 127, 0);
  delay(1000);
  sendColor(0, 0, 127);
  delay(1000);
  */
}

bool prev_stat[4] = { false };
uint8_t update_touch() {
  for (int i = 0; i < 4; i++) {
    bool touch_stat = touch.getTouchStatus(i);
    if (touch_stat != prev_stat[i]) {
      prev_stat[i] = touch_stat;
    }
  }
  uint8_t result = 0;
  for (int i = 0; i < 4; i++) {
    if (prev_stat[i]) {
      result += 1 << i;
    } 
  }
  return result;
}

void sendZeros()
{
  for (int i = 0; i < 3; i++) {
    shiftOut(LED_DAT, LED_CLK, MSBFIRST, 0);
  }
}

void sendCalib(uint8_t r, uint8_t g, uint8_t b) {
  // Flag bit is two '1'.
  // Calibration bits B7',B6';G7',G6' and R7',R6' are inverse codes 
  // of B7,B6;G7,G6 and R7,R6.
//  Serial.println("calibration: ");
//  Serial.print("r: ");
//  Serial.print(r, BIN);
//  Serial.print(", g: ");
//  Serial.print(g, BIN);
//  Serial.print(", b: ");
//  Serial.println(b, BIN);
  uint8_t all_flags = 0xC0; // flag bits
//  Serial.print("all_flags: ");
//  Serial.println(all_flags, BIN);
  uint8_t not_r = ~r;
//  Serial.print("not_r: ");
//  Serial.println(not_r, BIN);
  uint8_t r_flags = ((not_r >> 6) << 4);
//  Serial.print("r_flags: ");
//  Serial.println(r_flags, BIN);
  uint8_t not_g = ~g;
//  Serial.print("not_g: ");
//  Serial.println(not_g, BIN);  
  uint8_t g_flags = ((not_g >> 6) << 2);
//  Serial.print("g_flags: ");
//  Serial.println(g_flags, BIN);
  uint8_t not_b = ~b;
//  Serial.print("not_b: ");
//  Serial.println(not_b, BIN);
  uint8_t b_flags = ((not_b >> 6) << 0);
//  Serial.print("b_flags: ");
//  Serial.println(b_flags, BIN);
  uint8_t c = all_flags | b_flags | g_flags | r_flags;
//  Serial.print("c: ");
//  Serial.println(c, BIN);
//  Serial.println("-----------");
  shiftOut(LED_DAT, LED_CLK, MSBFIRST, c);  
}

void sendColor(uint8_t r, uint8_t g, uint8_t b) {
  sendZeros();
  sendCalib(r, g, b);
  shiftOut(LED_DAT, LED_CLK, MSBFIRST, b);
  shiftOut(LED_DAT, LED_CLK, MSBFIRST, g);
  shiftOut(LED_DAT, LED_CLK, MSBFIRST, r);
  sendZeros();
}

bool serialReadLine(char* buf, uint8_t len, bool block = false){
  int pos = 0;
  int inByte;
#define cr 13
#define lf 10
  if (!block && !Serial.available()) {
     return false;
  }
  inByte = Serial.read();

  if (inByte > 0 && inByte != cr && inByte != lf) { //If we see data (inByte > 0) and that data isn't a carriage return
    delay(100); //Allow serial data time to collect (I think. All I know is it doesn't work without this.)

    while (inByte != cr && inByte != lf && Serial.available() > 0 && pos < len + 1){ // As long as EOL not found and there's more to read, keep reading
      buf[pos] = inByte; // Save the data in a character array
      pos++; //Increment position in array
      if (inByte > 0) Serial.println(inByte, HEX); // Debug line that prints the charcodes one per line for everything recieved over serial
      inByte = Serial.read(); // Read next byte
    }

    if (inByte == cr || inByte == lf) //If we terminated properly
    {
      buf[pos] = 0; //Null terminate the serialReadString (Overwrites last position char (terminating char) with 0
      Serial.print("read line: ");
      Serial.println(buf);
      return true;
    } else {
      Serial.println("failed to terminate properly");
      return false;
    }
  }
  return false; 
}

String serialReadString(){
  char buf[50] = { 0 };
  if (serialReadLine(buf, 50, false)) {
    return String(buf);
  } else {
    return String("");
  }
}

uint8_t prev_analog = 0;
const uint8_t hysteresis = 5;
uint8_t prev_touch_stat = 0;

//#define BUFSIZE 16
//char cmdBuf[BUFSIZE] = { 0 };

uint8_t strToHex(String s) {
  char buf[3] = { 0 };
  s.toCharArray(buf, 3); 
  uint8_t v = strtol(buf, NULL, 16);
  Serial.print("converted string: '");
  Serial.print(s);
  Serial.print("' to: ");
  Serial.print(v, DEC);
  Serial.print(" (");
  Serial.print(v, HEX);
  Serial.println(")");
  return v;
}
void loop() {
  uint8_t touch_stat = update_touch();
  delay(100);

  if (touch_stat != prev_touch_stat) {
    Serial.print("T");
    Serial.println(touch_stat, HEX);
    prev_touch_stat = touch_stat;
  }

  static uint8_t prev_volume = 0;
  uint16_t rawAnalog = analogRead(POT_IN);
  uint8_t volume = map(rawAnalog, 0, 1023, 0, 100);
  if (volume != prev_volume) {
    Serial.print("A");
    Serial.println(volume, DEC);
    prev_volume = volume;
  }

  String cmd = serialReadString();
  if (cmd == "LEDOn") {
    Serial.println("LED ON");
  } else if (cmd == "LEDOff") {
    Serial.println("LED OFF");
  } else if (cmd[0] == 'L' && cmd.length() == 7) {
    uint8_t r = strToHex(cmd.substring(1,3));
    Serial.print("r: ");
    Serial.println(r, HEX);
    uint8_t g = strToHex(cmd.substring(3,5));
    Serial.print("g: ");
    Serial.println(g, HEX);
    uint8_t b = strToHex(cmd.substring(5,7));
    Serial.print("b: ");
    Serial.println(b, HEX);
    sendColor(r, g, b);
  }

}
