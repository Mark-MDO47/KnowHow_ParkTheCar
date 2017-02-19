// We're including two Libraries, "Ultrasonic.h" and "FastLED.h"
// FastLED.h gives us the ability to addres the WS2812 LEDs
// "Ultrasonic.h" allows us to trigger and read the ultrasonic sensor
#include "Ultrasonic.h"
#include "FastLED.h"

// Mark Olson 2016-09
//
// adapted from TWIT-TV Know How https://twit.tv/shows/know-how/episodes/178
//     major kudos to Fr. Robert Ballecer and Bryan Burnett for their show
//             and for pointing me to the FastLED library
//     major kudos to Daniel Garcia and Mark Kriegsman for the FANTASTIC FastLED library and examples!!!
//
// My buddy Jim and I pretty much re-wrote the code for our own sensibilities
//
// Discovered it REALLY helps to use AREF when using an analog signal; maybe that is needed due to
//    using inexpensive clone Arduino nano
// Also using a software hysteresis. When the potentiometer is found to be in a certain interval
//    then we make it "sticky" by extending that interval a bit on both sides (POT_HYST_DELTA)
//
//
// I am using an Arduino Nano with a USB mini-B connector
//   example: http://www.ebay.com/itm/Nano-V3-0-ATmega328P-5V-16M-CH340-Compatible-to-Arduino-Nano-V3-Without-Cable/201804111413?_trksid=p2141725.c100338.m3726&_trkparms=aid%3D222007%26algo%3DSIC.MBE%26ao%3D1%26asc%3D20150313114020%26meid%3Dea29973f227743f78772d7a22512af53%26pid%3D100338%26rk%3D1%26rkt%3D30%26sd%3D191602576205
//            V3.0 ATmega328P 5V 16M CH340 Compatible to Arduino Nano V3
//            http://www.mouser.com/pdfdocs/Gravitech_Arduino_Nano3_0.pdf
//
// uses 8-LED PIXEL STICK WS2812
//   example: http://www.readytoflyquads.com/rtfpixel-stick-8x-rgb-leds
//            This Programmable LED bar has 8 RGB WS2812 LED's set up in series.  These bars are 70mm long and 9mm wide with two mounting holes 35mm apart.
//
// uses Ultrasonic Module HC-SR04 Distance Measuring Transducer Sensor
//   example: http://www.ebay.com/itm/Ultrasonic-Module-HC-SR04-Distance-Measuring-Transducer-Sensor-for-Arduino-FO-/291548991993?hash=item43e1ac91f9:g:xmYAAOSwZd1VaXBO
//
// uses Uxcell 50K-ohm Trimmer Potentiometer. I used the 3386P-package top-adjustment version
//   example: https://smile.amazon.com/gp/product/B00G9JSCUQ/ref=oh_aui_detailpage_o02_s00?ie=UTF8&psc=1
//
//
// 2017-01 MDO: re-wrote pot hysterisis code, which suffered from two-person split-personality stream-of-consciousness coding syndrome.
//    Using AREF, sampling pot 500 times gives a range of [0,6] (example: values 708 through 713). Hysterisis parameter is set at 4 which
//    will handle this but means that we can only have intervals of 8 since hysterisis < interval size. Thus 128 intervals.
//
// connections:
// 
// Nano pin 5V      LEDstick VCC
// Nano pin GND     LEDstick GND
// Nano pin D-3     LEDstick DIN
//
// Nano pin 5V      SR04 VCC
// Nano pin GND     SR04 GND
// Nano pin D-13    SR04 Trig
// Nano pin D-12    SR04 Echo
//
// Nano pin 5V      Pot VCC (one side)
// Nano pin AREF    Pot same pin as above
// Nano pin GND     Pot GND (other side)
// Nano pin A-1     Pot middle

// Recommendations - of course I ignored these!  ;^)
//    Before connecting the WS2812 to a power source, connect a big capacitor from power to ground. A cap between 100microF and 1000microF should be good. Try to place this cap as close to your WS2812 as possible.
//    Electrolytic Decoupling Capacitors 
//
//    Placing a small-ish resistor between your Arduino's data output and the WS2812's data input will help protect the data pin. A resistor between 220 and 470 O should do nicely. Try to place the resistor as close to the WS2812 as possible.
//
//    Keep Wires Short!

// We are using an 8-LED stick
#define NUM_LEDS 8

// We'll be using Digital Data Pin #3 to control the WS2812 LEDs
#define LED_DATA_PIN 3

// we will use analog pin A1 to read the potentiometer
//   leaves a little space between that and AREF
// BE SURE TO CONNECT THE AREF PIN!!! MAKES READINGS MUCH LESS NOISY
// the potentiometer adjusts the desired car position (fine grain)
#define ANLG_PIN 1

// This tells the ultrasonic library that the trigger pin is on digital 13
// This also tells the ultrasonic library that the echo pin is on digital 12
#define ULTRA_TRIG_PIN 13
#define ULTRA_ECHO_PIN 12


// we use the range value from the Ultrasonic sensor to decide we are in one of
//    ULTRA_REGION_NUM display ranges (or OFF)
//    ranges are mapped to appropriate entry in led_ultra_range_mapping[] array
#define ULTRA_REGION_NUM 7 // number of valid ranges; index = 0 means OFF

// These are the definitions for our software hysteresis
// NOTE FIXME DEPENDS ON POT_RAW_NUM_INTVL BEING A POWER OF 2 AND EXACTLY DIVISIBLE INTO COUNTS
#define POT_RAW_NUM_COUNTS 1024 // so max val is 1023
#define POT_RAW_COUNTS_INTVL 8 // analog counts in each interval
#define POT_RAW_NUM_INTVL (POT_RAW_NUM_COUNTS/POT_RAW_COUNTS_INTVL) // number of intervals
#define POT_HYST_DELTA 4 // size extra size of hysteresis each side in counts; MUST be < (POT_RAW_NUM_COUNTS/POT_RAW_NUM_INTVL)
static int pot_intvl_prev = -99; // no hysterisis first time; this interval will match nothing
#define DEBUG_POT_HYSTERISIS(A) // Serial.print((A)) to debug

// approximate distances
// 50.8 cm or 20 inches min
// 66.04 cm or 26 inches van
// 81.28 cm or 32 inches middle
// 96.52 cm or 38 inches car
// 111.76 cm or 44 inches max
#define POT_DISTANCE_MIN_CM   50.8
#define POT_DISTANCE_MAX_CM  111.76
#define POT_DISTANCE_DELTA_CM ((POT_DISTANCE_MAX_CM-POT_DISTANCE_MIN_CM)/POT_RAW_NUM_INTVL)

// Creates an array with the length set by NUM_LEDS above
// This is the array the library will read to determine how each LED in the strand should be set
CRGB led_display[NUM_LEDS];
CRGB led_ultra_range_mapping[8 * NUM_LEDS] = { \
    CRGB::Black,   CRGB::Black,   CRGB::Black,   CRGB::Black,   CRGB::Black,   CRGB::Black,   CRGB::Black,   CRGB::Black,  \
    CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,  \
    CRGB::Orange,  CRGB::Orange,  CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Orange, \
    CRGB::Orange,  CRGB::Orange,  CRGB::Orange,  CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Green,   CRGB::Orange, \
    CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Orange,  CRGB::Orange,  CRGB::Orange,  CRGB::Red,    \
    CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Orange,  CRGB::Orange,  CRGB::Red,    \
    CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Orange,  CRGB::Red,    \
    CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red,     CRGB::Red};

int blnk_cnt = 0;
int blnk_on = 0;
#define BLNK_CNT_MAX 5

// Now we're going to initialize an instance from the Ultrasonic Sensor library with our pin numbers
// The sensor itself needs four leads: ground, vcc, trigger, and echo
Ultrasonic ultrasonic(ULTRA_TRIG_PIN,ULTRA_ECHO_PIN);

// copy_leds does the copying of the CRGB values
// also takes care of blinking
void copy_leds(int idx, CRGB *from, CRGB *to)
{
  for (int i = 0; i < NUM_LEDS; i += 1)
  {
    to[i] = from[i + NUM_LEDS * idx];
  }

  // do we need to blink the edges
  blnk_cnt += 1;
  blnk_cnt %= BLNK_CNT_MAX;
  if (0 == blnk_cnt) blnk_on ^= 1;
  if ((idx > 2) && (1 == blnk_on))
  {
    to[0] = CRGB::Black;
    to[NUM_LEDS-1] = CRGB::Black;
  }
}

int pot_intvl_with_hysterisis(int pot_read) {
    int pot_intvl = pot_read / POT_RAW_COUNTS_INTVL;
    DEBUG_POT_HYSTERISIS(pot_intvl_prev); DEBUG_POT_HYSTERISIS(" <-- pot_intvl_prev "); DEBUG_POT_HYSTERISIS(pot_intvl); DEBUG_POT_HYSTERISIS(" <-- pot_intvl_raw ");
    // now to check for hysterisis
    if ( (pot_intvl - pot_intvl_prev) == 1) {
        DEBUG_POT_HYSTERISIS((pot_read - POT_HYST_DELTA) / POT_RAW_COUNTS_INTVL ); DEBUG_POT_HYSTERISIS(" <-- hyst check due to +1 ");
        if ( ( (pot_read - POT_HYST_DELTA) / POT_RAW_COUNTS_INTVL )  == pot_intvl_prev) {
            pot_intvl = pot_intvl_prev;
            DEBUG_POT_HYSTERISIS(pot_intvl); DEBUG_POT_HYSTERISIS(" <-- pot_intvl_adjust due to +1 ");
        }
    } else if ( (pot_read - POT_HYST_DELTA) == -1) {
        DEBUG_POT_HYSTERISIS((pot_read - POT_HYST_DELTA) / POT_RAW_COUNTS_INTVL ); DEBUG_POT_HYSTERISIS(" <-- hyst check due to -1 ");
        if ( ( (pot_read + POT_HYST_DELTA) / POT_RAW_COUNTS_INTVL )  == pot_intvl_prev) {
            pot_intvl = pot_intvl_prev;
            DEBUG_POT_HYSTERISIS(pot_intvl); DEBUG_POT_HYSTERISIS(" <-- pot_intvl_adjust due to -1 ");
        }
    }   // end if might need hysterisis adjustment
    pot_intvl_prev = pot_intvl;
    return(pot_intvl);
}   // end Pot_intvl_with_hysterisis()

// with AREF and hysterisis don't need moving average
int pot_desired_distance() {
    int pot_read = analogRead(ANLG_PIN); // This checks the pot connected to Analog Pin - and gives us a value between 0-1024
    DEBUG_POT_HYSTERISIS(pot_read); DEBUG_POT_HYSTERISIS(" <-- analog ");
    // get potentiometer interval number [0,POT_RAW_NUM_INTVL)
    int pot_intvl = pot_intvl_with_hysterisis(pot_read);
    DEBUG_POT_HYSTERISIS(pot_intvl); DEBUG_POT_HYSTERISIS(" <-- intvl ");
    // convert to distance in cm (psuedo-rounded)
    int pot_dist = POT_DISTANCE_MIN_CM +0.5 + pot_intvl * POT_DISTANCE_DELTA_CM;
    Serial.print(pot_dist);
    Serial.print(" <-- dist");
    Serial.print("\n"); // don't use println so can use DEBUG_POT_HYSTERISIS()
    return(pot_dist);
}   // end pot_desired_distance()

// pot_dist is the desired distance
// ultra_distance is the actual distance
// approximate distances
// 50.8 cm or 20 inches min
// 66.04 cm or 26 inches van
// 81.28 cm or 32 inches middle
// 96.52 cm or 38 inches car
// 111.76 cm or 44 inches max

int calc_led_idx(int pot_dist, int ultra_dist) {
   int idx = 0;
   return(idx);  
}
#define POT_DISTANCE_MIN_CM   50.8
#define POT_DISTANCE_MAX_CM  111.76
#define POT_DISTANCE_DELTA_CM ((POT_DISTANCE_MAX_CM-POT_DISTANCE_MIN_CM)/POT_RAW_NUM_INTVL)

// setup()
//   initializes FastLED library for our config
//   initializes serial port
void setup()
{
  FastLED.addLeds<NEOPIXEL,LED_DATA_PIN>(led_display, NUM_LEDS);
  Serial.begin(9600);

  Serial.println("setup");
  
  delay(100);
}

// loop()
//    sorry; gets a little complex here ... ;^)
//
//    we read the potentiometer and calculate its distance setting using hysteresis
//       note: normally the potentiometer only moved during calibration
//    we compare this desired distance with that from LPF
//    If  "no ultrasound bounce" return, special case index into led_ultra_range_mapping[]
//    we calculate what region the LPF range is in
//    the index of that region is the index into led_ultra_range_mapping[] for display
//       so we call copy_leds() with that index
//    copy_leds() takes care of LED blinking using a count based on time
//
void loop() {
  
  static int idx = 0;
  static int range_regions_min[ULTRA_REGION_NUM] = { 42, 32, 27, 17, 12, 7 };
  static int range_regions    [ULTRA_REGION_NUM] = { 42, 32, 27, 17, 12, 7 };
  static int range;
  static int potIntvl = 0; // number calculated from potentiometer using hysteresis; previous at entry
  static int once = 0;

  if (0 == once)
  {
    once = 1;
    Serial.println("loop");
  }

  // this gives us a number of centimeters we want to call good
  int pot_dist = pot_desired_distance();
  
  // the range reading from the Ultrasonic sensor in centimeters
  int ultra_dist=(ultrasonic.Ranging(CM));
  idx = calc_led_idx(pot_dist, ultra_dist);
  //Serial.println(idx);
  // we want [0,ULTRA_REGION_NUM] currently [0-7] (note: enpoint inclusive
  // see what region idx we are in - farthest away is smallest idx; idx=7 is LED OFF


  copy_leds(idx, led_ultra_range_mapping, led_display);
  FastLED.setBrightness(60);
  FastLED.show();
  
  delay(100);
}
