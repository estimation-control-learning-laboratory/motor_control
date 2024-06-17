#define enA 9
#define in1 6
#define in2 7
#define button 4

// int rotDirection = 0;
// int pressed = false;

void setup() {
  pinMode(enA, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  // pinMode(button, INPUT);
  // Set initial rotation direction
  // digitalWrite(in1, LOW);
  // digitalWrite(in2, HIGH);
  pinMode(LED_BUILTIN, OUTPUT);
  
}

void loop() {
  // int potValue = analogRead(A0); // Read potentiometer value
  // int pwmOutput = map(800, 0, 1023, 0 , 255); // Map the potentiometer value from 0 to 255
  // analogWrite(enA, 200); // Send PWM signal to L298N Enable pin
  analogWrite(enA, 255);

  // Read button - Debounce
  // if (digitalRead(button) == true) {
  //   pressed = !pressed;
  // }
  // while (digitalRead(button) == true);
  // delay(20);

  // If button is pressed - change rotation direction
  // if (pressed == true  & rotDirection == 0) {
    digitalWrite(in1, HIGH);
    digitalWrite(in2, LOW);
    digitalWrite(LED_BUILTIN, HIGH);
    // rotDirection = 1;
    delay(2000);
  // }
  // If button is pressed - change rotation direction
  // if (pressed == false & rotDirection == 1) {
    digitalWrite(in1, LOW);
    digitalWrite(in2, HIGH);
    digitalWrite(LED_BUILTIN, LOW);
    // // rotDirection = 0;
    delay(2000);
  // }
}