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
Dim Geschummelt As Bit

Dim Globalh As Word
Dim Globalwert As Long


Dim Mystart As Byte
Dim Myende As Byte

Dim Anlauf As Word
Dim Foerder As Word
Dim Menu As Byte

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

Wait 1
___lcdno = 1
Locate 1 , 1
Lcd "                           "                           'Text in Zeile 1
Locate 2 , 1
Lcd "   initialisiere Waage     "                           'Text in Zeile 2



' leergewicht messen
Globaldurchschnittswert = 0
Globalh = 0
For Globalh = 1 To 256
   Globalwert = Getadc(1)
   Globaldurchschnittswert = Globaldurchschnittswert + Globalwert
   Waitus 200
Next Globalh
Leergewicht = Globaldurchschnittswert / 256

Wait 1
Locate 2 , 1
Lcd "   Gewicht: "                                          'Text in Zeile 2
Lcd Leergewicht
Lcd "             "                                         'Text in Zeile 2
Wait 1
Leergewicht = Leergewicht + 20


E = 2
Pwm = 100
Menge = 100


Menu:
Call Dispcls(2)

F = 1
Menu = 0
Idle = 0


' Startmenü

Do
   If Links = 0 Then
      If Menu > 0 Then Menu = Menu - 1 Else Menu = 4
      F = 1
      Do
         Waitms 10
      Loop Until Links = 1
   End If

   If Rechts = 0 Then
      If Menu < 4 Then Menu = Menu + 1 Else Menu = 0
      F = 1
      Do
         Waitms 10
      Loop Until Rechts = 1
   End If

   If F = 1 Then
      Locate 2 , 1
      If Menu = 0 Then Lcd "Auf        Ab         Setup"
      If Menu = 1 Then Lcd "Auf        Ab      Dosieren"
      If Menu = 2 Then Lcd "Auf        Ab        Eichen"
      If Menu = 3 Then Lcd "Auf        Ab        Listen"
      If Menu = 4 Then Lcd "Auf        Ab      Lauflicht"

      F = 0
   End If



Loop Until Auswahl = 0





Do
   Waitms 10
Loop Until Auswahl = 1

If Menu = 0 Then Goto Dossetup
If Menu = 1 Then Goto Dosdo
If Menu = 2 Then Goto Eichen
If Menu = 3 Then Goto Listen
If Menu = 4 Then Goto Lauflicht

Goto Menu



Lauflicht:
   Call Dispcls(2)

   Locate 2 , 1
   Lcd "Pumpen werden nacheinander angefahren... "

   For G = 1 To 12
      Locate 2 , 1
      Lcd "Pumpe "

      Locate 2 , 7
      Lcd G


      Call Selectpump(g)
      Waitms 500

      Call Stoppumps


   Next G

   Call Dispcls(2)

Goto Menu





Listen:
Call Dispcls(2)


G = 0
Do
   Dname = Lookupstr(g , Namen)
   Call Dispcls(2)

   Locate 1 , 1
   Lcd Dname

   Mystart = G * 12
   Myende = G + 1
   Myende = Myende * 12
   Myende = Myende - 1

   A = 1
   For E = Mystart To Myende
      Dmenge = Lookup(e , Zutaten)
      Locate 2 , 1
      Lcd "          "

      Locate 2 , 1
      Lcd Dmenge
      Waitms 500

      If Dmenge > 0 Then
         Call Dosieren(dmenge , A)
         Geschummelt = 0
      End If

      A = A + 1
   Next E


   Waitms 500

   G = G + 1
Loop Until G > 2



' Tastendruck abwarten
Do
   Waitms 50
Loop Until Auswahl = 0
Do
   Waitms 50
Loop Until Auswahl = 1

Goto Menu







Dossetup:

' Nun kommt die PWM
F = 1
Call Dispcls(2)

Do
   If Rechts = 0 Then
      If Pwm < 255 Then Pwm = Pwm + 5 Else Pwm = 255
      F = 1
      Do
         Waitms 20
      Loop Until Rechts = 1
   End If

   If Links = 0 Then
      If Pwm > 0 Then Pwm = Pwm - 5 Else Pwm = 0
      F = 1
      Do
         Waitms 20
      Loop Until Links = 1
   End If

   If F = 1 Then
      Locate 1 , 1
      Lcd "PWM: "
      Locate 1 , 5
      Lcd Pwm
      Lcd "  "
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
      Locate 1 , 7
      Lcd Menge
      Lcd "  "
      F = 0
   End If
Loop Until Auswahl = 0

Do
   Waitms 50
Loop Until Auswahl = 1

Goto Menu







Dosdo:
Geschummelt = 0
   Locate 2 , 1
   Lcd " Cocktail wird angefertigt! "

   Call Dosieren(menge , 1)
   Call Dosieren(menge , 2)
   Call Dosieren(menge , 3)
   Wait 1
   Call Dispcls(2)

Goto Menu







Eichen:

Locate 1 , 1
Lcd " Speichere Leergewicht     "
                                                           ' leergewicht messen
Globaldurchschnittswert = 0
Globalh = 0
For Globalh = 1 To 256
   Globalwert = Getadc(1)
   Globaldurchschnittswert = Globaldurchschnittswert + Globalwert
   Waitus 200
Next Globalh
Leergewicht = Globaldurchschnittswert / 256


Locate 2 , 1
Lcd "   Gewicht: "
Lcd Leergewicht
Lcd "              "

Leergewicht = Leergewicht + 20

Wait 1


Goto Menu




End


Namen:
Data "Cuba Libre" , "Wodka Energy" , "Reinigung"


Zutaten:
Data 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 4% , 26% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 4% , 26% , 0% , 0% , 5% , 0% , 5% , 0% , 5% , 0% , 5% , 0% , 5% , 0% , 5% , 0%
' Data 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 4 , 26 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 4 , 26 , 0 , 0 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5



Sub Dosieren(wieviel As Integer , Pumpe As Byte)
   Local Alterwert As Long
   Local Mymenge As Long
   Local State As Byte
   Local Diff As Long
   Local H As Word
   Local Durchschnittswert As Long
   Local Wert As Long
   Local Ziel As Long

   Cls
If Geschummelt = 1 Then Exit Sub
'menge = menge in millilitern
'mymenge = menge in ad-wandlerschritten
'glasgewicht = glasgewicht in ad-wandlerschritten
'ziel = gewollte menge in ad-wandlerschritten
'pwm = max pwm für pumpengeschwindigkeit


   Mymenge = Wieviel * 40
   Mymenge = Mymenge / 100
   State = 0
   Diff = 0

   H = 0
   Durchschnittswert = 0

   For H = 1 To 512
      Wert = Getadc(1)
      Durchschnittswert = Durchschnittswert + Wert
      Waitus 200
   Next H

   Durchschnittswert = Durchschnittswert / 512
   Ziel = Durchschnittswert + Mymenge
   Diff = Ziel - Durchschnittswert
   Alterwert = Durchschnittswert


   If Durchschnittswert < Leergewicht Then
           Geschummelt = 1
           Locate 1 , 1
           Lcd "   Bitte Glas aufstellen   "
           Wait 1
           Lcd "                           "
           Exit Sub
   End If


   Waitms 50
   Call Selectpump(pumpe)
   Waitms 50


   If Diff < 16 Then Call Setpwm(185) Else Call Setpwm(pwm)


   For H = 1 To 256
      Wert = Getadc(1)
      Durchschnittswert = Durchschnittswert + Wert
      Waitus 200
   Next H
   Durchschnittswert = Durchschnittswert / 256

   If Alterwert > Durchschnittswert Then
     ___lcdno = 0
        Locate 1 , 1
        Lcd " Schummeln is nich !!!     "
        Locate 2 , 1
        Lcd "                           "
        Geschummelt = 1
        Call Stoppwm
        Waitms 20
        Call Stoppumps
        Wait 1

        Exit Sub
   End If



   Alterwert = 0
   Do


   Durchschnittswert = 0
   H = 0
   For H = 1 To 256
      Wert = Getadc(1)
      Durchschnittswert = Durchschnittswert + Wert
      Waitus 200
   Next H
   Durchschnittswert = Durchschnittswert / 256
   Diff = Ziel - Durchschnittswert
   Alterwert = Alterwert - 10

   If Durchschnittswert < Alterwert Then
        ___lcdno = 0
        Locate 1 , 1
        Lcd " Schummeln is nich !!!     "
        Locate 2 , 1
        Lcd "                           "
        Geschummelt = 1
        Exit Do
   End If
   Alterwert = Durchschnittswert


   If State = 0 Then
      If Diff < 20 Then
         Call Setpwm(185)
         State = 1
      End If
   End If


   Loop Until Ziel < Durchschnittswert

   Call Stoppwm
   Waitms 20
   Call Stoppumps

   Waitms 100

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







