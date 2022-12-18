// ESP32 Touch Test
// teo2017012.01
// Just test touch pin - Touch0 is T0 which is on GPIO 4.

void setup() {
  Serial.begin(115200);
  delay(1000); // give me time to bring up serial monitor
  printf("\n ESP32 Touch Test\n");

}

void loop() {

  // Touch0, T0, is on GPIO4
  Serial.println(touchRead(T2));  // get value using T0

  Serial.println(touchRead(2));   // get value using GPIO 4

  Serial.println("");
  delay(1000);
}
