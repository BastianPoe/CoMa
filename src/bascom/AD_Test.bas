' Chip Konstanten
$crystal = 8000000
$regfile = "m8def.dat"

Dim ___lcdno As Bit
Dim Wert As Word
Dim Durch As Long
Dim H As Word


Config Lcdpin = Pin , E = Portd.1 , E2 = Portd.2 , Rs = Portd.0 , Db4 = Portd.3 , Db5 = Portd.4 , Db6 = Portd.6 , Db7 = Portd.7
Config Lcd = 40 * 4
Config Adc = Single , Prescaler = Auto , Reference = Internal
' Config Adc = Single , Prescaler = Auto , Reference = Avcc

' ADC anmachen
' Start Adc


' Config Adc = Single , Prescaler = Auto
'Now give power to the chip
Start Adc



___lcdno = 0                                                'ober Displayhälfte initialisieren
Initlcd
Cursor Off
Cls

___lcdno = 1                                                'untere Displayhälfte initialisieren
Initlcd
Cursor Off
Cls


Wert = 0

' A/D Wandler einlesen und ausgeben
Do
   ___lcdno = 0

   For H = 1 To 128
      Wert = Getadc(1)
      Durch = Durch + Wert
   Next H

   Durch = Durch / 128

   Locate 1 , 1
   Lcd "Wert:  "
   Lcd Durch
   Lcd "      "

Loop