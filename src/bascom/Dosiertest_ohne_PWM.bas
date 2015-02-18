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
Dim F As Bit
Dim G As Byte
Dim H As Byte

Dim Anlauf As Word
Dim Foerder As Word
Dim Menu As Byte

Dim Idle As Word
Dim Menge As Word
Dim Warten As Word
Dim Pwm As Byte
Dim Startm As Word

Dim Wert As Long
Dim Ziel As Long
Dim Mymenge As Long
Dim Durch As Long

Dim Diff As Long
Dim State As Byte
Dim Cnt As Byte







Declare Function Getwaage() As Long
Declare Sub Pumpe(byval X As Byte , Byref Millisec As Word)
Declare Sub Dispcls(byval X As Byte)
Declare Sub Setpwm(byval X As Byte)
Declare Sub Stoppwm()
Declare Sub Selectpump(byval X As Byte)
Declare Sub Stoppumps()
Declare Sub Allesaus()
Declare Sub Dosieren(byval Wieviel As Long , Byval Pumpe As Byte)

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
Lcd "          CoMa 1.0         "                           'Text in Zeile 2

Wait 2
___lcdno = 1


E = 2
Pwm = 150
Menge = 100


Menu:
Call Dispcls(2)

F = 1
Menu = 0
Idle = 0

Do
   If Links = 0 Then
      If Menu > 0 Then Menu = Menu - 1 Else Menu = 2
      F = 1
      Do
         Waitms 10
      Loop Until Links = 1
   End If

   If Rechts = 0 Then
      If Menu < 2 Then Menu = Menu + 1 Else Menu = 0
      F = 1
      Do
         Waitms 10
      Loop Until Rechts = 1
   End If

   If F = 1 Then
      Locate 1 , 1
      If Menu = 0 Then Lcd "Setup                      "
      If Menu = 1 Then Lcd "Dosieren                   "
      If Menu = 2 Then Lcd "Eichen                     "

      F = 0
   End If

   ' Schickes, drehendes Teil...
   Locate 2 , 1
   Idle = Idle + 1
   If Idle = 900 Then Idle = 0
   If Idle = 0 Then Lcd "|"
   If Idle = 100 Then Lcd "/"
   If Idle = 200 Then Lcd "-"
   If Idle = 300 Then Lcd "\"
   If Idle = 400 Then Lcd "|"
   If Idle = 500 Then Lcd "/"
   If Idle = 600 Then Lcd "-"
   If Idle = 700 Then Lcd "\"
   If Idle = 800 Then Lcd "*"

Loop Until Auswahl = 0

Do
   Waitms 10
Loop Until Auswahl = 1

If Menu = 0 Then Goto Dossetup
If Menu = 1 Then Goto Dosdo
If Menu = 2 Then Goto Eichen

Goto Menu





Dossetup:

' Nun kommt die PWM
F = 1
Call Dispcls(2)

Do
   If Rechts = 0 Then
      If Pwm < 255 Then Pwm = Pwm + 1 Else Pwm = 255
      F = 1
      Do
         Waitms 20
      Loop Until Rechts = 1
   End If

   If Links = 0 Then
      If Pwm > 0 Then Pwm = Pwm -1 Else Pwm = 0
      F = 1
      Do
         Waitms 20
      Loop Until Links = 1
   End If

   If F = 1 Then
      Locate 1 , 1
      Lcd "PWM: "
      Lcd Pwm
      Lcd "     "

      F = 0
   End If
Loop Until Auswahl = 0

Do
   Waitms 50
Loop Until Auswahl = 1

' Nun kommt die Mengenauswahl
F = 1
Call Dispcls(2)

Do
   If Rechts = 0 Then
      Menge = Menge + 10
      F = 1
      Do
         Waitms 20
      Loop Until Rechts = 1
   End If

   If Links = 0 Then
      If Menge > 10 Then Menge = Menge -10 Else Menge = 0
      F = 1
      Do
         Waitms 20
      Loop Until Links = 1
   End If

   If F = 1 Then
      Locate 1 , 1
      Lcd "Menge: "
      Lcd Menge
      Lcd "       "

      F = 0
   End If
Loop Until Auswahl = 0

Do
   Waitms 50
Loop Until Auswahl = 1

Goto Menu







Dosdo:

Call Dosieren(100 , 1)
Waitms 1000

Call Dosieren(100 , 2)
Waitms 1000

Call Dosieren(100 , 3)
Waitms 1000

Goto Menu



Eichen:

Do
   Wert = Getwaage()

   Locate 2 , 1
   Lcd "Aktuell: "
   Lcd Wert
   Lcd "         "

Loop Until Auswahl = 0

Do
   Waitms 50
Loop Until Auswahl = 1

Goto Menu




End

Sub Dosieren(wieviel As Long , Pumpe As Byte)
   Cls

   Call Stoppumps()

   Mymenge = Menge * 40
   Mymenge = Mymenge / 100
   State = 1
   Cnt = 0

   Locate 2 , 1
   Lcd "Menge: "
   Lcd Menge
   Lcd ", myMenge: "
   Lcd Mymenge

   Waitms 100

   If Ziel > 1000 Then
      Ziel = 5
   End If

   If Menge > 60 Then
      Compare1a = 50
   Else
      If Menge > 20 Then
         Compare1a = 150
         State = 3
      Else
         Compare1a = 200
         State = 4
      End If
   End If

   Waitms 100

   Call Selectpump(2)


   Wert = Getwaage()
   Ziel = Wert + Mymenge


   Locate 1 , 1
   Lcd "Start: "
   Lcd Wert
   Lcd ", Ziel: "
   Lcd Ziel

   Locate 2 , 1
   Lcd "Aktuell: "
   Lcd Wert
   Lcd "         "

   Do
      Wert = Getwaage()
      Locate 2 , 1
      Lcd "Aktuell: "
      Lcd Wert

      Diff = Ziel - Wert

      If State = 3 Then
         If Diff < 5 Then
            Compare1a = 200
            State = 4
         End If
      End If

      If State = 2 Then
         If Diff < 15 Then
            Compare1a = 150
            State = 3
         End If
      End If

      If State = 1 Then
         If Diff < 25 Then
            Compare1a = 100
            State = 2
         End If
      End If

      If Wert >= Ziel Then
         Cnt = Cnt + 1
      Else
         Cnt = 0
      End If

   Loop Until Cnt > 5

   Call Allesaus
End Sub



Function Getwaage() As Long
   Local Mywert As Long
   Local Mydurch As Long

   For H = 1 To 100
      Mywert = Getadc(1)

      ' ___lcdno = 0
      ' Locate 1 , 1
      ' Lcd "Aktuell RAW: "
      ' Lcd Mywert
      ' Lcd "     "
      ' ___lcdno = 1

      Mydurch = Mydurch + Mywert
      Waitms 1
   Next H

   Mydurch = Mydurch / 100

   Getwaage = Mydurch
End Function



Sub Allesaus()
   Call Stoppwm
   Call Stoppumps
End Sub


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

   ' PWM erstmal aus machen
   Compare1a = 255

   ' PWM langsam auf den gewünschten Wert fahren
   For D = 255 To X Step -1
      Compare1a = D
      Waitms 5
   Next D

End Sub

Sub Stoppwm()
   ' PWM Verhältnis so setzen, dass nix mehr geht
   Compare1a = 255
End Sub