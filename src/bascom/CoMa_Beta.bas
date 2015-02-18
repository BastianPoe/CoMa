' Chip Konstanten
$crystal = 8000000
$regfile = "m168def.dat"


Dim Geschummelt As Byte                                     ' Gibt an, ob ein Waagenfehler bei der Dosierung aufgetreten ist
Dim Menu As Byte                                            ' Bestimmt die aktuelle Position im Menü

Dim Dname As String * 20                                    ' Name des Cocktails
Dim Dmenge As Integer                                       ' Menge der jeweiligen Zutat
Dim Pumpengeschwindigkeitfast(14) As Byte
Dim Pumpengeschwindigkeitslow(14) As Byte
Dim PumpengeschwindigkeitsOffset(14) as Byte
Dim Adcvalues(128) As Long


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

Dim Pumpzeit As Long                                        ' Zählt die Zeit der Änderungen
Dim Alterwaagenwert As Long                                 ' Merkt sich den alten Stand der Waage

Dim Reinigung As Byte                                       ' Bestimmt, ob wir ins Reinigungsprogramm gehen

Dim Mystart As Byte
Dim Myende As Byte


Dim Alterwert As Long
Dim Mymenge As Long
Dim State As Byte
Dim Diff As Long
Dim Ziel As Long
Dim Testmenge As Integer

Dim Pumpe As Byte
Dim Status As Byte
Dim Sc As Byte



' Declare Sub Pumpe(byval X As Byte , Byref Millisec As Word)
Declare Sub Setpwm(byval X As Byte)
Declare Sub Stoppwm()
Declare Sub Selectpump(byval X As Byte)
Declare Sub Stoppumps()
Declare Sub Dosieren(byval Wieviel As Integer , Byval Pumpe As Byte)


Declare Function Sampleadc(byval Startval As Long) As Long
' Declare Function SampleADCMedian() as Long


' Port D
Ddrd = &B11111111

' Port B
Ddrb = &B00011111

Portb.5 = 1
Portb.6 = 1
Portb.7 = 1

' Je größer der Prescaler, desto kleiner die Störungen der Pumpen in der Spannungsversorgung
Config Timer1 = Pwm , Pwm = 8 , Compare A Pwm = Clear Up , Prescale = 256
Config Lcdpin = Pin , E = Portd.1 , E2 = Portd.2 , Rs = Portd.0 , Db4 = Portd.3 , Db5 = Portd.4 , Db6 = Portd.6 , Db7 = Portd.7
Config Lcd = 40 * 4
' Prescaler 128 sollte genug Samples für uns erlauben
Config Adc = Single , Prescaler = 128 , Reference = Internal


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
Rechts Alias Pinb.6
Links Alias Pinb.7
Auswahl Alias Pinb.5

' Ausgänge initialisieren
Strobe = 0
Clock = 0
Datain = 0
Oe = 0

' Pumpengeschwindigkeiten Modus "schnell" setzen
Pumpengeschwindigkeitfast(1) = 44
Pumpengeschwindigkeitfast(2) = 34
Pumpengeschwindigkeitfast(3) = 43
Pumpengeschwindigkeitfast(4) = 39
Pumpengeschwindigkeitfast(5) = 48
Pumpengeschwindigkeitfast(6) = 49
Pumpengeschwindigkeitfast(7) = 28
Pumpengeschwindigkeitfast(8) = 49
Pumpengeschwindigkeitfast(9) = 55
Pumpengeschwindigkeitfast(10) = 44
Pumpengeschwindigkeitfast(11) = 55
Pumpengeschwindigkeitfast(12) = 41

' Pumpengeschwindigkeiten Modus "schnell" setzen
Pumpengeschwindigkeitslow(1) = 128
Pumpengeschwindigkeitslow(2) = 100
Pumpengeschwindigkeitslow(3) = 127
Pumpengeschwindigkeitslow(4) = 117
Pumpengeschwindigkeitslow(5) = 136
Pumpengeschwindigkeitslow(6) = 139
Pumpengeschwindigkeitslow(7) = 76
Pumpengeschwindigkeitslow(8) = 138
Pumpengeschwindigkeitslow(9) = 148
Pumpengeschwindigkeitslow(10) = 128
Pumpengeschwindigkeitslow(11) = 148
Pumpengeschwindigkeitslow(12) = 122

' Pumpenoffset setzen
PumpengeschwindigkeitsOffset(1) = 0
PumpengeschwindigkeitsOffset(2) = 0
PumpengeschwindigkeitsOffset(3) = 0
PumpengeschwindigkeitsOffset(4) = 0
PumpengeschwindigkeitsOffset(5) = 0
PumpengeschwindigkeitsOffset(6) = 0
PumpengeschwindigkeitsOffset(7) = 0
PumpengeschwindigkeitsOffset(8) = 0
PumpengeschwindigkeitsOffset(9) = 0
PumpengeschwindigkeitsOffset(10) = 0
PumpengeschwindigkeitsOffset(11) = 0
PumpengeschwindigkeitsOffset(12) = 30


' ##############################################################################
' ##############################################################################
' Wieviele Cocktails haben wir eigentlich???
' ##############################################################################
' ##############################################################################
Cocktails = 18
' ##############################################################################
' ##############################################################################
' ##############################################################################
' ##############################################################################

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
Waitms 50
Initlcd
Cursor Off
Cls

___lcdno = 1                                                'untere Displayhälfte initialisieren
Waitms 50
Initlcd
Cursor Off
Cls





Start:

If Auswahl = 0 Then
   Reinigung = 1
Else
   Reinigung = 0
End If


___lcdno = 0
Waitms 50
Locate 1 , 1
Lcd "     *** Willkommen ***    "                           'Text in Zeile 1
Locate 2 , 1
Lcd "         CoMa Gamma        "                           'Text in Zeile 2

Wait 1



Eichen:

___lcdno = 1
Waitms 50
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
Leergewicht = Leergewicht + 15

If Reinigung = 1 And Auswahl = 0 Then
   ' Der Benutzer will wohl ins Reinigungsprogramm
   ___lcdno = 1
   Waitms 50

   Locate 1 , 1
   Lcd "Reinigungsprogramm?        "                        'Text in Zeile 2

   Locate 2 , 1
   Lcd "Test       Calib         Ja"

   Do
      Waitms 10
   Loop Until Links = 1 And Rechts = 1 And Auswahl = 1


   Do
      Waitms 10
   Loop Until Links = 0 Or Rechts = 0 Or Auswahl = 0

   If Auswahl = 0 Then
      ' Reinigungsprogramm
      Pumpe = 1
      Status = 0
      Sc = 0
      Changed = 1

      Do
         Waitms 10
      Loop Until Auswahl = 1


      Do
         If Links = 0 And Status = 0 Then
            If Pumpe > 1 Then Pumpe = Pumpe - 1 Else Pumpe = 12
            Changed = 1
            Do
               Waitms 10
            Loop Until Links = 1
         End If

         If Rechts = 0 And Status = 0 Then
            If Pumpe < 12 Then Pumpe = Pumpe + 1 Else Pumpe = 1
            Changed = 1
            Do
               Waitms 10
            Loop Until Rechts = 1
         End If

         If Auswahl = 0 Then
            Do
               Waitms 10
            Loop Until Auswahl = 1

            If Status = 1 Then Status = 0 Else Status = 1
            Changed = 1

            Sc = 1
         End If

         If Changed = 1 Then
            Locate 1 , 1
            Lcd "Pumpe:                     "
            Locate 1 , 7
            Lcd Pumpe

            Locate 2 , 1
            If Status = 0 Then Lcd "-          +          An   "
            If Status = 1 Then Lcd "-          +          Aus  "


            Changed = 0
         End If


         If Sc = 1 Then
            ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
            If Status = 1 Then
               Call Selectpump(pumpe)
               ' Call Setpwm(100)
               Call Setpwm(pumpengeschwindigkeitfast(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
            Elseif Status = 0 Then
               Call Stoppwm()
               Call Stoppumps()
            End If

            Sc = 0
         End If

      Loop
   Elseif Rechts = 0 Then
      ' Kalibrierungsprogramm
      Dim Adcwertalt As Long
      Dim Adcwertneu As Long

      Pumpe = 1
      Status = 0
      Changed = 1

      Do
         Waitms 10
      Loop Until Auswahl = 1


      Do
         If Links = 0 And Status = 0 Then
            If Pumpe > 1 Then Pumpe = Pumpe - 1 Else Pumpe = 12
            Changed = 1
            Do
               Waitms 10
            Loop Until Links = 1
         End If

         If Rechts = 0 And Status = 0 Then
            If Pumpe < 12 Then Pumpe = Pumpe + 1 Else Pumpe = 1
            Changed = 1
            Do
               Waitms 10
            Loop Until Rechts = 1
         End If

         If Auswahl = 0 Then
            Do
               Waitms 10
            Loop Until Auswahl = 1

            ' Den Anfangswert der Waage messen
'(
            Adcdurchschnittswert = 0
            For J = 1 To 512
               Adcwert = Getadc(1)
               Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
               Waitus 200
            Next J
            Adcwertalt = Adcdurchschnittswert / 512
')
            Adcwertalt = Sampleadc(0)

            ' Pumpe ausgewählt und gestartet
            Call Selectpump(pumpe)
            Call Setpwm(pumpengeschwindigkeitfast(pumpe) - PumpengeschwindigkeitsOffset(pumpe))

            ' 10 Sekunden laufen lassen
            For I = 1 To 10 Step 1
               Wait 1
            Next I

            ' Pumpe stoppen
            Call Stoppwm()
            Call Stoppumps()

            ' Und dann mal gucken, wie viel darin gelandet ist
'(
            Adcdurchschnittswert = 0
            For J = 1 To 512
               Adcwert = Getadc(1)
               Adcdurchschnittswert = Adcdurchschnittswert + Adcwert
               Waitus 200
            Next J
            Adcwertneu = Adcdurchschnittswert / 512
')
            Adcwertneu = Sampleadc(0)

            Changed = 1
         End If

         If Changed = 1 Then
            Locate 1 , 1
            Lcd "Pumpe:                     "
            Locate 1 , 7
            Lcd Pumpe

            Locate 1 , 12
            Lcd Adcwertalt
            Locate 1 , 20
            Lcd Adcwertneu

            Locate 2 , 1
            If Status = 0 Then Lcd "-          +          Start"

            Changed = 0
         End If
      Loop


   Elseif Links = 0 Then
      ' Testprogramm
      Testmenge = 100
      Status = 0
      Changed = 1

      Do
         Waitms 10
      Loop Until Auswahl = 1


      Do
         If Links = 0 And Status = 0 Then
            If Testmenge > 20 Then Testmenge = Testmenge - 20
            Changed = 1
            Do
               Waitms 10
            Loop Until Links = 1
         End If

         If Rechts = 0 And Status = 0 Then
            If Testmenge < 1000 Then Testmenge = Testmenge + 20
            Changed = 1
            Do
               Waitms 10
            Loop Until Rechts = 1
         End If

         If Auswahl = 0 Then
            Do
               Waitms 10
            Loop Until Auswahl = 1
            Adcwertalt = Sampleadc(0)

            Call Dosieren(testmenge , 1)

            Adcwertneu = Sampleadc(0)

            Changed = 1
         End If

         If Changed = 1 Then
            Locate 1 , 1
            Lcd "Menge:                     "
            Locate 1 , 7
            Lcd Testmenge

            Locate 1 , 12
            Lcd Adcwertalt
            Locate 1 , 20
            Lcd Adcwertneu

            Locate 2 , 1
            If Status = 0 Then Lcd "-          +          Start"

            Changed = 0
         End If
      Loop



   Else
      Do
         Waitms 10
      Loop Until Links = 1
   End If
End If



Menu = 0

Menulabel:
Changed = 1
Menulimit = Cocktails
' Geschummelt = 0


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

         ___lcdno = 0
         Waitms 50

         Locate 1 , 1
         Lcd "         CoMa Gamma       "                   'Text in Zeile 1

         Locate 2 , 1
         Dname = Lookupstr(menu , Namen)
         Lcd Dname
         Waitms 50

         ___lcdno = 1
         Waitms 50

         Dname = Lookupstr(menu , Kommentare)

         Locate 1 , 1
         Lcd "=>                         "                  'Text in Zeile 2

         Locate 1 , 4
         Lcd Dname

         Locate 2 , 1
         Lcd "Auf        Ab           Los"
      Else
         ___lcdno = 0
         Waitms 50

         Locate 1 , 1
         Lcd "         CoMa Gamma        "                  'Text in Zeile 2

         Locate 2 , 1
         Lcd "                           "                  'Text in Zeile 2

         ___lcdno = 1
         Waitms 50

         Locate 1 , 1
         Lcd "                           "                  'Text in Zeile 2

         Locate 2 , 1
         Lcd "Auf        Ab        Eichen"
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

I = 1                                                       ' Pumpe
For H = Mystart To Myende
   Dmenge = Lookup(h , Mengen)

   If Dmenge > 0 Then
      ___lcdno = 1
      Waitms 50

      Dname = Lookupstr(i , Zutaten)

      Locate 1 , 1
      Lcd "                         ml"

      Locate 1 , 1
      Lcd Dname

      Locate 1 , 21
      Lcd Dmenge

      Locate 2 , 1
      Lcd "                           "                     'Text in Zeile 2

      Call Dosieren(dmenge , I)

   End If
   I = I + 1
Next H


Goto Menulabel

End


Sub Dosieren(wieviel As Integer , Pumpe As Byte)
   Local Pumpversuche as Integer

   If Geschummelt = 1 Then
      Exit Sub
   End If

   ' Erstmal berechnen, wieviele AD-Wandler Ticks wir brauchen
   Mymenge = Wieviel * 90
   Mymenge = Mymenge / 100
   Mymenge = Wieviel

   ' Status initialisieren
   State = 0

   ' Den Anfangswert der Waage messen
   Adcwert = Sampleadc(0)

   Alterwaagenwert = Adcwert + 3
   Pumpzeit = 0

   ' Zielwerte festlegen
   Ziel = Adcwert + Mymenge

   ' Kleine Mengen werden offenbar zu kurz gepumpt, daher rechnen wir gleich mal etwas drauf
   if wieviel < 30 then
      Ziel = Ziel + 3                                          ' Etwas mehr ist besser als zu wenig!
   end if
   Diff = Ziel - Adcwert
   Alterwert = Adcwert


   If Adcwert < Leergewicht Then
      ' Auf der Waage steht weniger, als bei der anfänglichen Kalibrierung

      ___lcdno = 1
      Waitms 50

      Locate 1 , 1
      Lcd "   Bitte Glas aufstellen   "

      Locate 2 , 1
      Lcd "                           "                     'Text in Zeile 2

      Geschummelt = 1

      Wait 1

      Exit Sub
   End If

   ' Pumpe in den Schieberegistern auswählen
   Call Selectpump(pumpe)
   Waitms 50

   ' Den Displayinhalt vorbereiten...
   ___lcdno = 1
   Waitms 50

   Locate 2 , 1
   Lcd "       /         (        )"

   Locate 2 , 1
   Lcd Adcwert

   Locate 2 , 10
   Lcd Ziel

   Locate 2 , 20
   Lcd Diff

   Waitms 200

   If Diff < 25 Then
      ' Wenn nur wenig zu pumpen ist, dann laufen wir langsam los
      ' Call Setpwm(145)
      ' Call Setpwm(90)
      ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
      Call Setpwm(pumpengeschwindigkeitslow(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
   Else
      ' Wenns mehr ist, dann halt schneller
      ' Call Setpwm(100)
      ' Call Setpwm(55)
      ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
      Call Setpwm(pumpengeschwindigkeitfast(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
   End If

   Waitms 200

   Alterwert = 0
   Do
      ' Waage auswerten, um das aktuelle Gewicht zu erhalten
      Adcwert = Sampleadc(adcwert)

      If Adcwert > Alterwaagenwert Then
         Pumpzeit = 0
         Alterwaagenwert = Adcwert + 3
      End If

      Pumpzeit = Pumpzeit + 1

      If Pumpzeit > 200 Then
         Call Stoppwm
         Waitms 20

         ' offenbar ist die Zutat wohl leer
         ___lcdno = 0
         Waitms 50

         Locate 1 , 1
         Lcd "      *** FEHLER ***       "


         Locate 2 , 1
         Lcd "leer:                      "

         Locate 2 , 7
         Dname = Lookupstr(pumpe , Zutaten)
         Lcd Dname

         ___lcdno = 1
         Waitms 50

         Locate 1 , 1
         Lcd "Bitte nachfuellen in      ."

         Locate 1 , 22
         Lcd Pumpe

         Locate 2 , 1
         Lcd "Abbrechen            Weiter"


         Do
            Waitms 100
         Loop Until Auswahl = 0 Or Links = 0

         If Links = 0 Then
            Do
               Waitms 10
            Loop Until Links = 1

            Geschummelt = 1
            Exit Do
         End If

         Do
            Waitms 10
         Loop Until Auswahl = 1

         Pumpzeit = 0

          ___lcdno = 0
         Waitms 50

         Locate 1 , 1
         Lcd "         CoMa Gamma        "                  'Text in Zeile 1

         Locate 2 , 1
         Lcd "                           "                  'Text in Zeile 1


         ___lcdno = 1
         Waitms 50

         Locate 1 , 1
         Lcd "                           "                  'Text in Zeile 1

         If Diff < 25 Then
            ' Wenn nur wenig zu pumpen ist, dann laufen wir langsam los
            ' Call Setpwm(145)
            ' Call Setpwm(90)
            ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
            Call Setpwm(pumpengeschwindigkeitslow(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
         Else
            ' Wenns mehr ist, dann halt schneller
            ' Call Setpwm(100)
            ' Call Setpwm(55)
            ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
            Call Setpwm(pumpengeschwindigkeitfast(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
         End If
      End If


      ' Die verbleibende Differenz zum Zielwert ermitteln
      Diff = Ziel - Adcwert
      Alterwert = Alterwert - 10

      Locate 2 , 1
      Lcd Adcwert

      Locate 2 , 20
      Lcd Diff



      ' Gucken, ob das Glas zufällig leichter geworden ist
      If Adcwert < Alterwert Then
         Call Stoppwm
         Waitms 20

         ___lcdno = 0
         Waitms 50

         Locate 1 , 1
         Lcd "      *** FEHLER ***       "

         Locate 2 , 1
         Lcd " !!! Schummeln is nich !!! "

         ___lcdno = 1
         Waitms 50

         Locate 1 , 1
         Lcd "                           "                  'Text in Zeile 2

         Locate 2 , 1
         Lcd "                           "                  'Text in Zeile 2

         Wait 5


         Locate 2 , 1
         Lcd "Abbrechen            Weiter"

         Do
            Waitms 100
         Loop Until Auswahl = 0 Or Links = 0

         If Links = 0 Then
            Do
               Waitms 10
            Loop Until Links = 1

            Geschummelt = 1
            Exit Do
         End If

         Do
            Waitms 10
        Loop Until Auswahl = 1

        Pumpzeit = 0

        ___lcdno = 0
        Waitms 50

        Locate 1 , 1
        Lcd "         CoMa Gamma        "                   'Text in Zeile 1

        Locate 2 , 1
        Lcd "                           "                   'Text in Zeile 1


        ___lcdno = 1
        Waitms 50

        Locate 1 , 1
        Lcd "                           "                   'Text in Zeile 1

         If Diff < 25 Then
            ' Wenn nur wenig zu pumpen ist, dann laufen wir langsam los
            ' Call Setpwm(145)
            ' Call Setpwm(90)
            ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
            Call Setpwm(pumpengeschwindigkeitslow(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
         Else
            ' Wenns mehr ist, dann halt schneller
            ' Call Setpwm(100)
            ' Call Setpwm(55)
            ' Für jede Pumpe haben wir einen eigenen Geschwindigkeitswert
            Call Setpwm(pumpengeschwindigkeitfast(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
         End If


'         Geschummelt = 1
'         Exit Do

      End If

      Alterwert = Adcwert

      ' Wenn wir uns dem Ziel annähren, dann pumpen wir lieber langsamer
      If State = 0 Then
         ' 40 scheint ein guter Wert zu sein, weil die Pumpen und der Volumenstrom
         ' doch etwas träge ist
         If Diff < 40 Then
            ' Call Setpwm(145)
            Call Setpwm(pumpengeschwindigkeitslow(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
            State = 1
         End If
      End If

   Loop Until Ziel < Adcwert

   ' PWM aus
   Call Stoppwm

   Waitms 500

   ' Hier gucken wir jetzt mal, ob wir nicht doch noch ein klein wenig nachfüllen müssen
   Adcwert = Sampleadc(0)

   Diff = Ziel - Adcwert
   Pumpversuche = 0

   ' Hier nachpumpen, falls die Abweichung doch noch zu groß ist
   ' Die Grenze sind 4 ticks = 1 cl
   while Diff >= 4 AND Pumpversuche < 5
      ___lcdno = 1
      Waitms 50

      Locate 1 , 27
      Lcd "E"

      Call Setpwm(pumpengeschwindigkeitslow(pumpe) - PumpengeschwindigkeitsOffset(pumpe))
      Pumpzeit = 0
      Pumpversuche = Pumpversuche + 1

      Do
         Pumpzeit = Pumpzeit + 1

         ' Waage auswerten, um das aktuelle Gewicht zu erhalten
         Adcwert = Sampleadc(0)

         ' Die verbleibende Differenz zum Zielwert ermitteln
         Diff = Ziel - Adcwert
         Alterwert = Alterwert - 10

         Locate 2 , 1
         Lcd "       /         (        )"

         Locate 2 , 1
         Lcd Adcwert

         Locate 2 , 10
         Lcd Ziel

         Locate 2 , 20
         Lcd Diff

         If Pumpzeit > 200 Then
            Pumpversuche = 5
            Call Stoppwm
            Waitms 20
            Exit Do
         End If

      Loop Until Ziel < Adcwert

      ' PWM aus
      Call Stoppwm
      Waitms 20
   Wend


   ' Pumpe aus
   Call Stoppumps
   Waitms 100
End Sub







Sub Selectpump(x As Byte)
   ___lcdno = 0
   Waitms 50


   Locate 2 , 15
   Lcd "Pump         "

   Locate 2 , 20
   Lcd X

   ___lcdno = 1
   Waitms 50

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

   If X < 10 Then
      X = 10
   End If

   ___lcdno = 0
   Waitms 50


   Locate 2 , 1
   Lcd "PWM           "

   Locate 2 , 5
   Lcd X

   ___lcdno = 1
   Waitms 50

   Oldpwm = Compare1a

   If Oldpwm < X Then                                       ' PWM langsam auf den gewünschten Wert herabsetzen
      For J = Compare1a To X
         Compare1a = J
         Waitms 8
      Next J

   Else                                                     ' PWM langsam auf den gewünschten Wert fahren
      For J = Oldpwm To X Step -1
         Compare1a = J
         Waitms 8
      Next J
   End If

End Sub

Sub Stoppwm()
   ' PWM Verhältnis so setzen, dass nix mehr geht
   Compare1a = 255
End Sub



Function Sampleadc(byval Startval As Long) As Long
'(
   Local Iterator As Integer , Ewma As Long , Adcvalue As Long , Alpha As Long , Base As Long , Bla As Long

   Alpha = 6
   Base = 8

   If Startval > 0 Then
      Ewma = Startval
   Else
      Ewma = 0
   End If

   For Iterator = 1 To 32
      Adcvalue = Sampleadcmedian()

      If Ewma = 0 Then
         Ewma = Adcvalue
      Else
         Ewma = Ewma * 6
         Bla = Adcvalue * 2
         Ewma = Ewma + Bla
      End If
   Next Iterator

   Sampleadc = Ewma / 8
End Function


Function Sampleadcmedian() As Long
')
   Local Iteratora As Integer , Iteratorb As Integer , Idx As Integer , Mymin As Long

   Idx = 0
   Mymin = 65535

   ' Waage auswerten, um das aktuelle Gewicht zu erhalten
   For Iteratora = 1 To 100
      Adcvalues(iteratora) = Getadc(1)
      Waitms 1
   Next Iteratora

   ' Jetzt suchen wir einfach 128 mal das minimum und schon haben wir den median
   For Iteratora = 1 To 50
      Mymin = 65535

      For Iteratorb = 1 To 100
         If Adcvalues(iteratorb) < Mymin Then
            Idx = Iteratorb
            Mymin = Adcvalues(iteratorb)
         End If
      Next Iteratorb

      Adcvalues(idx) = 65535
   Next Iteratora

   Sampleadc = Mymin
End Function



Zutaten:
Data "", "Gin" , "Rum" , "Tequila" , "Wodka" , "Orangenlikoer" , "Pfirsichlikoer" , "Cola" , "Sprite" , "Orangensaft" , "Zitronensaft" , "Cranberry Saft" , "Grenadinensirup"

Namen:
Data "Long Island Icetea         " , "Long Beach Icetea          " , "Long Island Iced Tea       " , "Wodka-O                    " , "Sex on the Beach           " , "Tequila Sunrise            " , "Margarita                  " , "White Lady                 " , "Barcadi Cola               " , "Wodka Sunrise              " , "Tequila Pink               " , "Revolucion                 " , "Mexican Screwdriver        "

Kommentare:
Data "Gin, Rum, Tequila, Cola " , "Gin, Rum Tequila, Sprite" , "Gin, Rum, Tequila, Cranb" , "Wodka, O-Saft           " , "Wodka, O-Saft, Pfirsichl" , "Tequila, Orangensaft    " , "Tequila, Orangenl, Zitro" , "Gin, Orangenl, Citrus   " , "Brauner Rum, Cola       " , "Wodka, Orangensaft      " , "Tequila, Rum, O-Saft    " , "Wodka, Tequila, O-Saft  " , "Tequila, Orangensaft    "

Mengen:
Data 20%, 20%, 20%, 20%, 0%, 20%, 80%, 0%, 30%, 30%, 0%, 0%, 20%, 20%, 20%, 20%, 0%, 0%, 0%, 90%, 30%, 40%, 0%, 0%, 20%, 20%, 20%, 20%, 20%, 0%, 0%, 0%, 30%, 30%, 80%, 0%, 0%, 0%, 0%, 50%, 0%, 0%, 0%, 0%, 190%, 0%, 0%, 0%, 0%, 0%, 0%, 40%, 0%, 20%, 0%, 0%, 120%, 30%, 30%, 0%, 0%, 0%, 50%, 0%, 0%, 0%, 0%, 0%, 160%, 0%, 0%, 30%, 0%, 0%, 50%, 0%, 20%, 0%, 0%, 0%, 0%, 50%, 0%, 0%, 50%, 0%, 0%, 0%, 20%, 0%, 0%, 0%, 0%, 50%, 0%, 0%, 0%, 50%, 0%, 0%, 0%, 0%, 190%, 0%, 0%, 0%, 0%, 0%, 0%, 0%, 0%, 5%, 0%, 0%, 0%, 0%, 16%, 20%, 0%, 20%, 0%, 20%, 40%, 0%, 20%, 0%, 0%, 0%, 90%, 30%, 0%, 40%, 0%, 0%, 40%, 40%, 0%, 0%, 0%, 0%, 160%, 0%, 0%, 0%, 0%, 0%, 40%, 0%, 0%, 0%, 0%, 0%, 200%, 0%, 0%, 0%



'(
Zutaten:
Data "" , "Gin" , "Rum" , "Tequila" , "Wodka" , "Orangenlikoer" , "Pfirsichlikoer" , "Cola" , "Sprite" , "Orangensaft" , "Zitronensaft" , "Cranberry Saft" , "Grenadinensirup"

Namen:
Data "Long Island Icetea         " , "Long Beach Icetea          " , "Long Island Iced Tea       " , "Wodka-O                    " , "Sex on the Beach           " , "Tequila Sunrise            " , "Margarita                  " , "White Lady                 " , "Barcadi Cola               " , "Long Island Icetea (hart)  " , "Long Beach Icetea (hart)   " , "Long Island Iced Tea (hart)" , "Wodka-O (hart)             " , "Sex on the Beach (hart)    " , "Tequila Sunrise (hart)     " , "Margarita (hart)           " , "White Lady (hart)          " , "Barcadi Cola (hart)        "

Kommentare:
Data "Gin, Rum, Tequila, Wodka" , "                        " , "mit Cranberry Saft      " , "Wodka, O-Saft           " , "Wodka, O-Saft, Pfirsichl" , "Tequila, Orangensaft    " , "Tequila, Orangenl, Citru" , "Gin, Orangenl, Citrus   " , "Brauner Rum, Cola       " , "Gin, Rum, Tequila, Wodka" , "                        " , "mit Cranberry Saft      " , "                        " , "Wodka, O-Saft, Pfirsichl" , "Tequila, Orangensaft    " , "Tequila, Orangenl, Citru" , "Gin, Orangenl, Citrus   " , "Brauner Rum, Cola       "

Mengen:
Data 16% , 16% , 16% , 16% , 0% , 16% , 114% , 0% , 23% , 23% , 0% , 0% , 16% , 16% , 16% , 16% , 0% , 0% , 0% , 110% , 26% , 40% , 0% , 0% , 16% , 16% , 16% , 16% , 16% , 0% , 0% , 0% , 23% , 23% , 114% , 0% , 0% , 0% , 0% , 48% , 0% , 0% , 0% , 0% , 192% , 0% , 0% , 0% , 0% , 0% , 0% , 44% , 0% , 20% , 0% , 0% , 121% , 27% , 28% , 0% , 0% , 0% , 44% , 0% , 0% , 0% , 0% , 0% , 168% , 0% , 0% , 28% , 0% , 0% , 48% , 0% , 16% , 0% , 0% , 0% , 0% , 46% , 0% , 0% , 48% , 0% , 0% , 0% , 24% , 0% , 0% , 0% , 0% , 48% , 0% , 0% , 0% , 48% , 0% , 0% , 0% , 0% , 192% , 0% , 0% , 0% , 0% , 0% , 20% , 20% , 20% , 20% , 0% , 20% , 100% , 0% , 20% , 20% , 0% , 0% , 20% , 20% , 20% , 20% , 0% , 0% , 0% , 110% , 20% , 30% , 0% , 0% , 20% , 20% , 20% , 20% , 20% , 0% , 0% , 0% , 20% , 20% , 100% , 0% , 0% , 0% , 0% , 60% , 0% , 0% , 0% , 0% , 180% , 0% , 0% , 0% , 0% , 0% , 0% , 55% , 0% , 25% , 0% , 0% , 110% , 25% , 25% , 0% , 0% , 0% , 55% , 0% , 0% , 0% , 0% , 0% , 160% , 0% , 0% , 25% , 0% , 0% , 60% , 0% , 20% , 0% , 
')




'Zutaten:
'Data "" , "Gin" , "Rum" , "Tequila" , "Wodka" , "Orangenlikoer" , "Pfirsichlikoer" , "Cola" , "gesperrt" , "Orangensaft" , "Zitronensaft" , "Cranberry Saft" , "Grenadinensirup"
'
'Namen:
'Data "Long Island Icetea         " , "Long Beach Icetea          " , "Long Island Iced Tea       " , "Wodka-O                    " , "Sex on the Beach           " , "Tequila Sunrise            " , "Margarita                  " , "White Lady                 " , "Barcadi Cola               "
'
'Kommentare:
'Data "Gin, Rum, Tequila, Wodka" , "Mit Sprite auffuellen   " , "mit Cranberry Saft      " , "Wodka, O-Saft           " , "Wodka, O-Saft, Pfirsichl" , "Tequila, Orangensaft    " , "Tequila, Orangenl, Citru" , "Gin, Orangenl, Citrus   " , "Brauner Rum, Cola       "
'
'Mengen:
'Data 20% , 20% , 20% , 20% , 0% , 20% , 100% , 0% , 20% , 20% , 0% , 0% , 20% , 20% , 20% , 20% , 0% , 0% , 0% , 0% , 20% , 30% , 0% , 0% , 20% , 20% , 20% , 20% , 20% , 0% , 0% , 0% , 20% , 20% , 100% , 0% , 0% , 0% , 0% , 60% , 0% , 0% , 0% , 0% , 180% , 0% , 0% , 0% , 0% , 0% , 0% , 55% , 0% , 25% , 0% , 0% , 110% , 25% , 25% , 0% , 0% , 0% , 55% , 0% , 0% , 0% , 0% , 0% , 160% , 0% , 0% , 25% , 0% , 0% , 60% , 0% , 30% , 0% , 0% , 0% , 0% , 30% , 0% , 0% , 60% , 0% , 0% , 0% , 30% , 0% , 0% , 0% , 0% , 30% , 0% , 0% , 0% , 60% , 0% , 0% , 0% , 0% , 180% , 0% , 0% , 0% , 0% , 0%



'Zutaten:
'Data "" , "Wodka" , "Rum" , "Triple Sec" , "Amaretto" , "Limettensaft" , "Cranberrysaft" , "Pfirsichlikoer" , "gesperrt" , "Kokosmilch und Sahne" , "Ananassaft" , "Maracujasaft" , "Orangensaft"
'
'Namen:
'Data "Sex on the Beach           " , "Cosmopolitan               " , "Wiki Waku Woo              " , "Screwdriver                " , "Leckerli-Cocktail          " , "Los Angeles                " , "WooWoo                     " , "Swimmingpool               " , "Pina Colada                " , "Princess                   " , "Antialkoholiker            "
'
'Kommentare:
'Data "Wodka, Pfirsichlikoer   " , "Wodka, Preiselbeersaft  " , "Wodka, Rum, Amaretto    " , "Wodka, O-Saft           " , "Pfirsichlikoer, Amaretto" , "Wodka, Saefte           " , "Wodka, Rum, Pfirsichliko" , "Wodka, Rum, Saefte      " , "Rum, Sahne, Saefte      " , "Wodka, etc.             " , "Saefte                  "
'
'Mengen:
'Data 40% , 0% , 0% , 0% , 0% , 80% , 40% , 0% , 0% , 0% , 0% , 80% , 30% , 0% , 15% , 0% , 15% , 20% , 0% , 0% , 0% , 0% , 0% , 0% , 15% , 15% , 15% , 20% , 0% , 20% , 0% , 0% , 0% , 0% , 0% , 30% , 40% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 200% , 0% , 20% , 0% , 20% , 15% , 0% , 20% , 0% , 0% , 0% , 20% , 60% , 40% , 0% , 0% , 0% , 15% , 0% , 20% , 0% , 0% , 20% , 20% , 40% , 20% , 20% , 0% , 0% , 20% , 40% , 20% , 0% , 0% , 40% , 0% , 0% , 20% , 20% , 0% , 0% , 0% , 0% , 0% , 0% , 50% , 60% , 0% , 0% , 0% , 50% , 0% , 0% , 0% , 0% , 0% , 0% , 50% , 100% , 0% , 0% , 40% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 30% , 0% , 40% , 40% , 0% , 0% , 0% , 0% , 0% , 30% , 0% , 0% , 0% , 30% , 40% , 50%





'Namen:
'Data "Sex on the Beach           " , "Wodka Energy               " , "Wodka Energy (hart)        " , "Screwdriver                " , "Cuba Libre                 " , "Bacardi Orange             "
'
'Kommentare:
'Data "Wodka, Pfirsichlikoer   " , "Wodka, Energydrink      " , "viel Wodka, Energydrink " , "Wodka, Orangensaft      " , "weisser Rum, Cola       " , "weisser Rum, Orangensaft"
'
'Mengen:
'Data 50% , 0% , 90% , 50% , 0% , 90% , 0% , 0% , 0% , 0% , 0% , 0% , 60% , 220% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 95% , 185% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 80% , 0% , 200% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 60% , 0% , 220% , 0% , 0% , 0% , 0% , 0% , 0% , 0% , 220% , 0% , 60% , 0% , 0% , 0% , 0% , 0% , 0% , 0%
'
'Zutaten:
'Data "" , "Wodka" , "Energydrink" , "Orangensaft" , "Pfirsichlikoer" , "weisser Rum" , "Cranberry Juice" , "Cola" , "" , "" , "" , "" , ""