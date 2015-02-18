' Chip Konstanten
$crystal = 8000000
$regfile = "m8def.dat"


Dim Geschummelt As Bit                                      ' Gibt an, ob ein Waagenfehler bei der Dosierung aufgetreten ist
Dim Menu As Byte                                            ' Bestimmt die aktuelle Position im Menü

Dim Dname As String * 20                                    ' Name des Cocktails
Dim Dmenge As Integer                                       ' Menge der jeweiligen Zutat

Dim G As Byte                                               ' Schleifenvariable für fors
Dim H As Byte                                               ' Schleifenvariable für fors
Dim I As Byte                                               ' Schleifenvariable für fors

Dim J As Word                                               ' Schleifen bla

Dim Adcdurchschnittswert As Long                            ' Durchschnittswert für den AD Wandler
Dim Adcwert As Long                                         ' Momentanwert des ADC

Dim Leergewicht As Long                                     ' Globales Leergewicht der Waage

Dim Changed As Byte                                         ' Menü neuzeichnen

Dim Cocktails As Byte                                       ' Gibt die Nummer der verfügbaren Cocktails
Dim Menulimit As Byte                                       ' Wieviele Einträge hat das Menü?

Dim ___lcdno As Bit                                         ' Bestimmt die Hälfte des LCDs


Dim Mystart As Byte
Dim Myende As Byte


Dim Alterwert As Long
Dim Mymenge As Long
Dim State As Byte
Dim Diff As Long
Dim Ziel As Long



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

' Wieviele Cocktails haben wir eigentlich???
Cocktails = 3

' Alle Schieberegister auf 0 setzen
For H = 0 To 15
   Datain = 0
   Clock = 0
   Waitms 1
   Clock = 1
   Waitms 1
   Clock = 0
Next H
Strobe = 0
Waitms 1
Strobe = 1
Waitms 1
Strobe = 0

Oe = 1

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
Lcd "         CoMa 0.99         "                           'Text in Zeile 2

Wait 1
___lcdno = 1
Locate 1 , 1
Lcd "   initialisiere Waage     "                           'Text in Zeile 1
Locate 2 , 1
Lcd "                           "                           'Text in Zeile 2


' leergewicht messen
Adcdurchschnittswert = 0
For H = 1 To 255
   Adcwert = Getadc(1)
   Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
   Waitus 200
Next H
Leergewicht = Adcdurchschnittswert / 255

Locate 2 , 1
Lcd "   Gewicht: "                                          'Text in Zeile 2
Lcd Leergewicht
Lcd "             "                                         'Text in Zeile 2
Wait 1
Leergewicht = Leergewicht + 20


Menu:
Changed = 1
Menu = 0
Menulimit = Cocktails


' Startmenü
Do
   If Links = 0 Then
      If Menu > 0 Then Menu = Menu - 1 Else Menu = Menulimit
      Changed = 1
      Do
         Waitms 10
      Loop Until Links = 1
   End If

   If Rechts = 0 Then
      If Menu < Menulimit Then Menu = Menu + 1 Else Menu = 0
      Changed = 1
      Do
         Waitms 10
      Loop Until Rechts = 1
   End If

   If Changed = 1 Then
      If Menu >= 0 And Menu < Cocktails Then
         ' Jetzt müssen wir wohl dosieren
         Call Dispcls(1)
         Waitms 50

         Locate 1 , 1
         Lcd "         CoMa 0.99         "                           'Text in Zeile 2

         Locate 2 , 1
         Dname = Lookupstr(menu , Namen)
         Lcd Dname

         Waitms 50
         Call Dispcls(2)
         Locate 1 , 1
         Lcd "=> "

         Dname = Lookupstr(menu , Kommentare)
         Locate 1 , 4
         Lcd Dname

         Locate 2 , 1
         Lcd "Auf        Ab      Dosieren"
      Else
         Call Dispcls(1)
         Locate 1 , 1
         Lcd "         CoMa 0.99         "                           'Text in Zeile 2

         Call Dispcls(2)
         Locate 2 , 1
         If Menu = Cocktails Then Lcd "Auf        Ab        Eichen"
      End If

      Changed = 0
   End If



Loop Until Auswahl = 0

Do
   Waitms 10
Loop Until Auswahl = 1


If Menu = Cocktails Then Goto Eichen


' Hier gehts ans Dosieren
Mystart = Menu * 12
Myende = Menu + 1
Myende = Myende * 12
Myende = Myende - 1
Geschummelt = 0

I = 1
For H = Mystart To Myende
   Dmenge = Lookup(h , Zutaten)

   If Dmenge > 0 Then
      Locate 2 , 1
      Lcd "                           "                     'Text in Zeile 2

      Locate 2 , 1
      Lcd "Zutat "
      Locate 2 , 7
      Lcd H

      Locate 2 , 9
      Lcd ", Menge "
      Locate 2 , 17
      Lcd Dmenge

      Call Dosieren(dmenge , I)
   End If
   I = I + 1
Next H


Goto Menu



Eichen:

Locate 1 , 1
Lcd " Speichere Leergewicht     "
                                                           ' leergewicht messen
Adcdurchschnittswert = 0
For H = 1 To 255
   Adcwert = Getadc(1)
   Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
   Waitus 200
Next H
Leergewicht = Adcdurchschnittswert / 255


Locate 2 , 1
Lcd "   Gewicht: "
Lcd Leergewicht
Lcd "              "

Leergewicht = Leergewicht + 20

Wait 1


Goto Menu




End


Sub Dosieren(wieviel As Integer , Pumpe As Byte)
   If Geschummelt = 1 Then
      Exit Sub
   End If

   ' Erstmal berechnen, wieviele AD-Wandler Ticks wir brauchen
   Mymenge = Wieviel * 40
   Mymenge = Mymenge / 100

   ' Status initialisieren
   State = 0

   ' Den Anfangswert der Waage messen
   Adcdurchschnittswert = 0
   For J = 1 To 512
      Adcwert = Getadc(1)
      Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
      Waitus 200
   Next J
   Adcwert = Adcdurchschnittswert / 512


   ' Zielwerte festlegen
   Ziel = Adcwert + Mymenge
   Diff = Ziel - Adcwert
   Alterwert = Adcwert


   If Adcwert < Leergewicht Then
      ' Auf der Waage steht weniger, als bei der anfänglichen Kalibrierung
      Call Dispcls(2)
      Geschummelt = 1

      Locate 1 , 1
      Lcd "   Bitte Glas aufstellen   "
      Wait 1

      Exit Sub
   End If


   ' Pumpe in den Schieberegistern auswählen
   Call Selectpump(pumpe)
   Waitms 50


   If Diff < 16 Then
      ' Wenn nur wenig zu pumpen ist, dann laufen wir langsam los
      Call Setpwm(185)
   Else
      ' Wenns mehr ist, dann halt schneller
      Call Setpwm(100)
   End If


   ' Durchschnittswert = 0
   ' For H = 1 To 256
   '    Wert = Getadc(1)
   '    Durchschnittswert = Durchschnittswert + Wert
   '    Waitus 200
   ' Next H
   ' Durchschnittswert = Durchschnittswert / 256
   '
   '
   ' If Alterwert > Durchschnittswert Then
   '    Call Dispcls(2)
   '
   '    Locate 1 , 1
   '    Lcd " Schummeln is nich !!!     "
   '
   '    Geschummelt = 1
   '
   '    Geschummelt = 1
   '    Call Stoppwm
   '    Waitms 20
   '    Call Stoppumps
   '    Wait 1
   '
   '    Exit Sub
   ' End If



   Alterwert = 0
   Do
      ' Waage auswerten, um das aktuelle Gewicht zu erhalten
      Adcdurchschnittswert = 0
      For J = 1 To 255
         Adcwert = Getadc(1)
         Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
         Waitus 200
      Next J
      Adcwert = Adcdurchschnittswert / 255

      ' Die verbleibende Differenz zum Zielwert ermitteln
      Diff = Ziel - Adcwert
      Alterwert = Alterwert - 10

      Locate 1 , 1
      Lcd "                           "
      Locate 2 , 1
      Lcd "                           "

      Locate 1 , 1
      Lcd "AD-Wert: "
      Locate 1 , 9
      Lcd Adcwert
      Locate 1 , 15
      Lcd Leergewicht

      Locate 2 , 1
      Lcd "Ziel:"
      Locate 2 , 6
      Lcd Ziel
      Locate 2 , 15
      Lcd Diff



      ' Gucken, ob das Glas zufällig leichter geworden ist
      If Adcwert < Alterwert Then
         Call Dispcls(2)

         Locate 1 , 1
         Lcd " Schummeln is nich !!!     "

         Geschummelt = 1
         Exit Do
      End If

      Alterwert = Adcwert

      ' Wenn wir uns dem Ziel annähren, dann pumpen wir lieber langsamer
      If State = 0 Then
         If Diff < 20 Then
            Call Setpwm(185)
            State = 1
         End If
      End If

   Loop Until Ziel < Adcwert

   ' PWM aus
   Call Stoppwm
   Waitms 20

   ' Pumpe aus
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
   For J = 15 To 1 Step -1
      If J = X Then
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
   Next J

   Datain = 0
   Strobe = 0
   Waitms 1
   Strobe = 1
   Waitms 1
   Strobe = 0
End Sub


Sub Stoppumps()
   ' Die Schieberegister mit 0en füllen, so dass keine Pumpe mehr läuft
   For J = 0 To 15
      Datain = 0
      Clock = 0
      Waitms 1
      Clock = 1
      Waitms 1
   Next J

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
      For J = Compare1a To X
         Compare1a = J
         Waitms 5
      Next J

   Else                                                     ' PWM langsam auf den gewünschten Wert fahren
      For J = Oldpwm To X Step -1
         Compare1a = J
         Waitms 5
      Next J
   End If


End Sub

Sub Stoppwm()
   ' PWM Verhältnis so setzen, dass nix mehr geht
   Compare1a = 255
End Sub







Namen:
Data "Sex on the Beach" , "Wodka Energy" , "Wodka Orange"


Kommentare:
Data "Wodka, Pfirsichlikoer" , "Wodka, Energydrink" , "Wodka, Orangensaft"

Zutaten:
Data 40% , 0% , 100% , 40% , 80% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 40% , 220% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 40% , 0% , 220% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0%
