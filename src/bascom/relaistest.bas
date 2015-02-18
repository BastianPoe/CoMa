

$crystal = 8000000
$regfile = "m8def.dat"
Dim A As Byte
Dim B As Byte
Dim C As Byte
Dim D As Byte
Dim Prozent As Word
Dim Millisec As Word
Dim ___lcdno As Bit

Declare Sub Pumpe(byval X As Byte , Byref Millisec As Word)

Ddrd = &B11111111
Ddrb = &B11111000

Portb.5 = 1
Portb.6 = 1
Portb.7 = 1

Config Timer1 = Pwm , Pwm = 8 , Compare A Pwm = Clear Up , Prescale = 8
Config Lcdpin = Pin , E = Portd.1 , E2 = Portd.2 , Rs = Portd.0 , Db4 = Portd.3 , Db5 = Portd.4 , Db6 = Portd.6 , Db7 = Portd.7
Config Lcd = 40 * 4

Compare1a = 255

Oe Alias Portb.0
Strobe Alias Portb.2
Clock Alias Portb.3
Datain Alias Portb.4

Strobe = 0
Clock = 0
Datain = 0
Oe = 0

For A = 0 To 15
   Datain = 0
   Clock = 0
   Waitms 1
   Clock = 1
   Waitms 1
   Clock = 0
Next A
Strobe = 0
Waitms 1
Strobe = 1
Waitms 1
Strobe = 0

Oe = 1
Millisec = 500

___lcdno = 0                                                'ober Displayhälfte initialisieren
Initlcd
Cursor Off

___lcdno = 1                                                'untere Displayhälfte initialisieren
Initlcd
Cursor Off
Cls

___lcdno = 0
Locate 1 , 1
Lcd "     *** Willkommen ***    "                           'Text in Zeile 1

Locate 2 , 1
Lcd "          CoMa 1.0         "                           'Text in Zeile 2


Do
If Pinb.5 = 0 Then Goto Start                               'Eingang Schalten gegen Masse
If Pinb.6 = 0 Then Goto Start                               'Eingang Schalten gegen Masse
If Pinb.7 = 0 Then Goto Start                               'Eingang Schalten gegen Masse
Loop


Start:

___lcdno = 1
Locate 1 , 1
Lcd "Aktiviere Pumpe: "                                     'Text in Zeile 3

Locate 2 , 1
Lcd "                           "                           'Text in Zeile 2

Waitms 500







'Hauptprogramm ;-)


Do
For C = 1 To 16
Locate 1 , 17
Lcd C                                                       'Text in Zeile 3
Call Pumpe(c , Millisec)
Next C

Wait 2

Locate 1 , 17
Lcd "0 "                                                    'Text in Zeile 3

Loop

End



Sub Pumpe(x As Byte , Millisec As Word)



'Pumpe X auswählen

   For A = X To 15
      Datain = 0
      Clock = 0
      Waitms 1
      Clock = 1
      Waitms 1
      Clock = 0
   Next A

   Datain = 1
   Clock = 0
   Waitms 1
   Clock = 1
   Waitms 1
   Clock = 0

   For A = 2 To X
      Datain = 0
      Clock = 0
      Waitms 1
      Clock = 1
      Waitms 1
      Clock = 0
   Next A

   Strobe = 0
   Waitms 1
   Strobe = 1
   Waitms 1
   Strobe = 0


If X = 2 Then

Wait 1
Locate 2 , 1
Lcd "Leistung Pumpe:              "

For D = 255 To 0 Step -1

Prozent = 255 - D
Prozent = Prozent * 100
Prozent = Prozent / 255

Locate 2 , 16
Lcd Prozent
Locate 2 , 19
Lcd "%"

Compare1a = D
Waitms 20

Next D

Wait 2

Locate 2 , 1
Lcd "Pumpe gestoppt             "
Compare1a = 255
Wait 2

End If





   Waitms Millisec

'Alle pumpen abschalten

For A = 0 To 15
   Datain = 0
   Clock = 0
   Waitms 1
   Clock = 1
   Waitms 1
Next A

Clock = 0

Strobe = 0
Waitms 1
Strobe = 1
Waitms 1
Strobe = 0

Waitms 200

End Sub


'do



'Loop


End