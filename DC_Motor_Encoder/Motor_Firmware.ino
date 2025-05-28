#define ENCA 2 // YELLOW
#define ENCB 3 // WHITE
#define PWM 5  // Purple/Green
#define IN2 6  // Red
#define IN1 7  // Yellow/Orange

volatile int encoderPos = 0;
volatile unsigned long lastTime = 0;
volatile int lastEncoderPos = 0;

float omega = 0;
float radians = 0;
const int encoderPulsesPerRev = 256;
const float gearRatio = 38.0;
const unsigned long interval = 200; 

#define FILTER_SIZE 5
float omegaBuffer[FILTER_SIZE] = {0};
int omegaIndex = 0;

void setup() {
  Serial.begin(9600);

  pinMode(ENCA, INPUT);
  pinMode(ENCB, INPUT);
  pinMode(PWM, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(ENCA), readEncoder, CHANGE);
  lastTime = millis();

  setMotor(0, 0); 
}

void loop() {
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    int commaIndex = command.indexOf(',');
    if (commaIndex > 0) {
      int dir = command.substring(0, commaIndex).toInt();
      int pwmVal = command.substring(commaIndex + 1).toInt();

      int minPWM = 30;
      int effectivePWM = (pwmVal > 0) ? max(pwmVal, minPWM) : pwmVal;
      setMotor(dir, abs(effectivePWM));
    }
  }

  calculateSpeed();
  delay(10);  
}

void setMotor(int dir, int pwmVal) {
  analogWrite(PWM, pwmVal);
  if (dir == -1) {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
  } else if (dir == 1) {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
  } else {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
  }
}

void readEncoder() {
  int a = digitalRead(ENCA);
  int b = digitalRead(ENCB);
  if (a == b) {
    encoderPos++;
  } else {
    encoderPos--;
  }
}

void calculateSpeed() {
  unsigned long currentTime = millis();
  if (currentTime - lastTime >= interval) {
    int deltaPos = encoderPos - lastEncoderPos;
    float motorRevs = deltaPos / (float)encoderPulsesPerRev;
    radians = (motorRevs / gearRatio) * 2.0 * PI;
    omega = radians / ((currentTime - lastTime) / 1000.0);  

    omegaBuffer[omegaIndex] = omega;
    omegaIndex = (omegaIndex + 1) % FILTER_SIZE;

    float omegaAvg = 0;
    for (int i = 0; i < FILTER_SIZE; i++) {
      omegaAvg += omegaBuffer[i];
    }
    omegaAvg /= FILTER_SIZE;

    Serial.println(omegaAvg);

    lastEncoderPos = encoderPos;
    lastTime = currentTime;
  }
}
