' Chip Konstanten
$crystal = 8000000
$regfile = "m8def.dat"


Dim A As Byte
Dim B As Byte
Dim C As Byte
Dim D As Byte
Dim Prozent As Word
Dim Millisec As Word
Dim ___lcdno As Bit
Dim E As Byte
Dim Sc As Byte
Dim F As Bit
Dim G As Byte
Dim Geschummelt As Bit

Dim Globalh As Word
Dim Globalwert As Long


Dim Mystart As Byte
Dim Myende As Byte

Dim Anlauf As Word
Dim Foerder As Word
Dim Pumpe As Byte
Dim Status As Byte

Dim Idle As Word
Dim Menge As Integer
Dim Warten As Word
Dim Pwm As Byte
Dim Startm As Word

Dim Leergewicht As Long
Dim Glasgewicht As Long

Dim Dname As String * 20
Dim Dmenge As Integer



Dim Globaldurchschnittswert As Long






Declare Sub Pumpe(byval X As Byte , Byref Millisec As Word)
Declare Sub Dispcls(byval X As Byte)
Declare Sub Setpwm(byval X As Byte)
Declare Sub Stoppwm()
Declare Sub Selectpump(byval X As Byte)
Declare Sub Stoppumps()
Declare Sub Dosieren(byval Wieviel As Integer , Byval Pumpe As Byte)

' Port D
Ddrd = &B11111111

' Port B
Ddrb = &B00011111

Portb.5 = 1
Portb.6 = 1
Portb.7 = 1

Config Timer1 = Pwm , Pwm = 8 , Compare A Pwm = Clear Up , Prescale = 8
Config Lcdpin = Pin , E = Portd.1 , E2 = Portd.2 , Rs = Portd.0 , Db4 = Portd.3 , Db5 = Portd.4 , Db6 = Portd.6 , Db7 = Portd.7
Config Lcd = 40 * 4
Config Adc = Single , Prescaler = Auto , Reference = Internal


' ADC anmachen
Start Adc

' PWM ausmachen
Compare1a = 255

' Pins für die Schieberegister
Oe Alias Portb.0
Strobe Alias Portb.2
Clock Alias Portb.3
Datain Alias Portb.4

' Pins für die Taster
Rechts Alias Pinb.7
Links Alias Pinb.6
Auswahl Alias Pinb.5

' Ausgänge initialisieren
Strobe = 0
Clock = 0
Datain = 0
Oe = 0

' Alle Schieberegister auf 0 setzen
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
Cls

___lcdno = 1                                                'untere Displayhälfte initialisieren
Initlcd
Cursor Off
Cls





Start:

___lcdno = 0
Locate 1 , 1
Lcd "     *** Willkommen ***    "                           'Text in Zeile 1
Locate 2 , 1
Lcd "          CoMa 0.9         "                           'Text in Zeile 2

Call Dispcls(2)

Wait 1

F = 1
Idle = 0
Pumpe = 1
Status = 0
Sc = 0


' Startmenü

Do
   If Links = 0 And Status = 0 Then
      If Pumpe > 1 Then Pumpe = Pumpe - 1 Else Pumpe = 12
      F = 1
      Do
         Waitms 10
      Loop Until Links = 1
   End If

   If Rechts = 0 And Status = 0 Then
      If Pumpe < 12 Then Pumpe = Pumpe + 1 Else Pumpe = 1
      F = 1
      Do
         Waitms 10
      Loop Until Rechts = 1
   End If

   If Auswahl = 0 Then
      Do
         Waitms 10
      Loop Until Auswahl = 1

      If Status = 1 Then Status = 0 Else Status = 1
      F = 1

      Sc = 1
   End If

   If F = 1 Then
      Call Dispcls(2)

      Locate 1 , 1
      Lcd "Pumpe: "
      Locate 1 , 7
      Lcd Pumpe

      Locate 2 , 1
      If Status = 0 Then Lcd "-          +          An"
      If Status = 1 Then Lcd "-          +          Aus"


      F = 0
   End If


   If Sc = 1 Then
      If Status = 1 Then
         Call Selectpump(pumpe)
         Call Setpwm(100)
      Elseif Status = 0 Then
         Call Stoppwm()
         Call Stoppumps()
      End If

      Sc = 0
   End If

Loop





End




Sub Dispcls(x As Byte)
   If X = 1 Then
      ' obere Displayhälfte löschen
      ___lcdno = 0
      Locate 1 , 1
      Lcd "                           "
      Locate 2 , 1
      Lcd "                           "
   End If

   If X = 2 Then
      ' untere Displayhälfte löschen
      ___lcdno = 1
      Locate 1 , 1
      Lcd "                           "
      Locate 2 , 1
      Lcd "                           "
   End If

   If X = 0 Then
      ' beide Displayhälften löschen
      ___lcdno = 0
      Locate 1 , 1
      Lcd "                           "
      Locate 2 , 1
      Lcd "                           "

      ___lcdno = 1
      Locate 1 , 1
      Lcd "                           "
      Locate 2 , 1
      Lcd "                           "
   End If
End Sub


Sub Selectpump(x As Byte)
   'Pumpe X auswählen
   For A = 15 To 1 Step -1
      If A = X Then
         Datain = 1
      Else
         Datain = 0
      End If

      Waitms 1
      Clock = 0
      Waitms 1
      Clock = 1
      Waitms 1
      Clock = 0
   Next A

   Datain = 0
   Strobe = 0
   Waitms 1
   Strobe = 1
   Waitms 1
   Strobe = 0
End Sub


Sub Stoppumps()
   ' Die Schieberegister mit 0en füllen, so dass keine Pumpe mehr läuft
   For A = 0 To 15
      Datain = 0
      Clock = 0
      Waitms 1
      Clock = 1
      Waitms 1
   Next A

   Clock = 0

   ' Stroben, um die Daten an die Ausgänge zu legen
   Strobe = 0
   Waitms 1
   Strobe = 1
   Waitms 1
   Strobe = 0
End Sub




Sub Setpwm(x As Byte)
   Local Oldpwm As Byte
   Oldpwm = Compare1a


   If Oldpwm < X Then                                       ' PWM langsam auf den gewünschten Wert herabsetzen
      For D = Pwm To X
         Compare1a = D
         Waitms 5
      Next D

   Else                                                     ' PWM langsam auf den gewünschten Wert fahren
      For D = Oldpwm To X Step -1
         Compare1a = D
         Waitms 5
      Next D
   End If


End Sub

Sub Stoppwm()
   ' PWM Verhältnis so setzen, dass nix mehr geht
   Compare1a = 255
End Sub







