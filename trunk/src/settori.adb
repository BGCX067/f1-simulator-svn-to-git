with Ada.Text_IO;with Ada.Real_Time;
USE Ada.Text_IO; use Ada.Real_Time;
with Ada.Calendar;
with Ada.Numerics.Float_Random;
use Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;

with Coordinatori; use Coordinatori;
with Comunicazioni; use Comunicazioni;
with ConfigurazioniAuto; use ConfigurazioniAuto;
with Ada.Calendar.Formatting;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Settori is

   -- Tabelle prestazioni e degrado dei pneumatici in base alle condizioni atfmosferiche
   Performance_Gomme : Tabella_Performance :=
   -- Morbida, Media, Dura, Rain
     (( 1.0, 0.9, 0.8, 0.3 ), 	-- Sole
      ( 0.9, 0.8, 0.6, 0.4 ), 	-- Parziale
      ( 0.8, 0.7, 0.5, 0.5 ), 	-- Nuvoloso
      ( 0.4, 0.3, 0.3, 0.7 )); 	-- Pioggia

   Degrado_Gomme : Tabella_Performance :=
   -- Morbida, Media, Dura, Rain
     (( 0.6, 0.5, 0.4, 0.8 ), 	-- Sole
      ( 0.4, 0.3, 0.2, 0.7 ), 	-- Parziale
      ( 0.3, 0.2, 0.1, 0.5 ), 	-- Nuvoloso
      ( 0.2, 0.2, 0.2, 0.1 )); 	-- Pioggia

   protected body Corsia is

      entry Calcola_Tempo_Attraversamento(Stato_Auto : in out Configurazione; Tempo_Entrata : float; Tempo_Uscita: Out float)
        when true is

         Tempo_Impiegato : Float;
         Performance : Float;
         Accelerazione : Float;
         Meteo : Tempo_Atmosferico;
         Tempo_Velocita_Max : Float; -- Tempo necessario per raggiungere la velocita max
         Metri_Velocita_Max : Float; -- Metri necessari per raggiungere la velocità max permessa nella corsia
         Spazio_Rimanente : Float ; -- Spazio rimanente da percorrere una volta raggiunta la velocità max
         Tempo_Rimanente : Float; -- Tempo necessario per percorrere lo Spazio Rimanente
         g : Generator;
         randomNumber : Float;
         livelloDanni:Integer;
      begin
         -- TODO: Calcola il tempo di attraversamento in base alle caratteristiche di auto e corsia

         Coordinatore.Get_Meteo(Meteo);
         performance := Performance_Gomme(Stato_Auto.Gomme,Meteo);

         -- Calcolo i possibili danni
         reset(g);
         randomNumber := random(g);
         randomNumber := (randomNumber * randomNumber);
         --Put_Line("RANDOM: " & Float'Image(randomNumber));
         if randomNumber > 0.3 then

            reset(g);
            livelloDanni := Integer(random(g)*100.0);
            if livelloDanni > Stato_Auto.Livello_Danni then
               Stato_Auto.Livello_Danni := livelloDanni;
               if Stato_Auto.Livello_Danni > 50 then

                  Stato_Auto.Entrata_Box := True;
               end if;

               --Put_Line("Auto con livello danni" & Integer'Image(Stato_Auto.Livello_Danni));
            end if;


         end if;

         -- Calcolo il coefficiente di accelerazione in base a gomme
         Accelerazione := 7.7 * ((100.0 - Stato_Auto.Usura_Gomme)/100.0)*0.6 + 7.7 * ((100.0 - Stato_Auto.Usura_Gomme)/100.0)*0.4* performance -1.0 + Float(Grip)/100.0 - 1.0 + Float(Stato_Auto.Potenza)/100.0;
         Accelerazione := Accelerazione * (1.0 - Float(Stato_Auto.Livello_Danni)/100.0);
         if Accelerazione < 2.0 then
            Accelerazione := 2.0;
         end if;

         -- Put_Line("Accelerazione: " & Float'Image(Accelerazione));
         -- Calcolo del tempo necessario per raggiungere la velocità max della corsia
         if Stato_Auto.Velocita_Attuale >= Corsia.Velocita_Max_Percorrenza then
            -- Moto uniforme (l'auto è già alla velocita max, e la faccio "frenare" bruscamente)
            Tempo_Velocita_Max := 0.0;
         else
            -- Moto uniformemente accelerato
            Tempo_Velocita_Max := (Corsia.Velocita_Max_Percorrenza - Stato_Auto.Velocita_Attuale) / 3.6 / Accelerazione;
         end if;

         --put_line(Float'Image(Tempo_Velocita_Max));
         -- Calcolo i metri necessari per raggiungere la velocità max permessa nella corsia
         Metri_Velocita_Max := 0.5 * Accelerazione * Tempo_Velocita_Max * Tempo_Velocita_Max + Stato_Auto.Velocita_Attuale * Tempo_Velocita_Max;

         -- Calcolo se raggiungerei la velocità max prima della fine della corsia
         --put_line(Float'Image(Metri_Velocita_Max) & " " & Float'Image(Corsia.Lunghezza));
         if Metri_Velocita_Max <= Corsia.Lunghezza then
            --    ___________
            --   /
            --  /
            -- /
            Spazio_Rimanente := Corsia.Lunghezza - Metri_Velocita_Max;
            Tempo_Rimanente := Spazio_Rimanente / Corsia.Velocita_Max_Percorrenza;

            Tempo_Impiegato := Tempo_Velocita_Max + Tempo_Rimanente;
            --Put_Line("Devo limitare velocita");

            Stato_Auto.Velocita_Attuale := Corsia.Velocita_Max_Percorrenza	; -- L'auto uscirebbe con la velocità massima della corsia
         else
            --    /
            --   /
            --  /
            -- /

            Tempo_Impiegato := (- Stato_Auto.Velocita_Attuale - sqrt( (Stato_Auto.Velocita_Attuale) ** 2 + 2.0 * Accelerazione * Corsia.Lunghezza )) / Accelerazione;

            if Tempo_Impiegato <= 0.0 then
               Tempo_Impiegato := (- Stato_Auto.Velocita_Attuale + sqrt( (Stato_Auto.Velocita_Attuale) ** 2 + 2.0 * Accelerazione * Corsia.Lunghezza )) / Accelerazione;

               -- put_line("Tempo impiegato per " & To_String(Stato_Auto.Nome_Pilota) & ": " & Float'Image(Tempo_Impiegato));

            end if;

            --Tempo_Impiegato := ((Corsia.Lunghezza) * 5.0 )/ Float(Stato_Auto.Potenza);

            Stato_Auto.Velocita_Attuale := Accelerazione * Tempo_Impiegato + Stato_Auto.Velocita_Attuale; -- L'auto uscirebbe con la sua velocità



         end if;

         -- Settare la velocita di uscita TODO
         if Stato_Auto.Velocita_Attuale > Corsia.Velocita_Max_Uscita then
            Stato_Auto.Velocita_Attuale := Corsia.Velocita_Max_Uscita; -- frenata improvvisa
         end if;

         --TODO: Fix per DEBUG
         --Tempo_Impiegato := 1.0;
         Tempo_Uscita := Tempo_Entrata + Tempo_Impiegato;
         -- Se il tempo di attraversamento è inferiore al tempo di liberazione, devo alzarlo
         if Tempo_Uscita < Tempo_Liberazione + 1.0 then
            -- L'auto deve accodarsi
            Tempo_Uscita := Tempo_Liberazione + 1.0; -- TODO: metto 1 sec. Sarà da calcolare in base a velocità di uscita dell'auto davanti
         end if;

         -- Put_Line("Tempo uscita per " & To_String(Stato_Auto.Nome_Pilota) & ": " & Float'Image(Tempo_Uscita));

         -- TODO: Cambio lo stato dell'auto in seguito alla percorrenza della corsia
         Stato_Auto.Usura_Gomme := Stato_Auto.Usura_Gomme + Degrado_Gomme(Stato_Auto.Gomme,Meteo);
         Stato_Auto.Livello_Benzina := Stato_Auto.Livello_Benzina - 1;

         --Stato_Auto


      end Calcola_Tempo_Attraversamento;

      -- Entra effettivamente nella corsia. Il tempo e lo stato sono già stati calcolati dalla funzione Calcola_Tempo_Attraversamento
      entry Entra_Nella_corsia(Tempo_Uscita: float) when true is
      begin
         --Put_Line("Aggiorno tempo di liberazione corsia");
         Tempo_Liberazione := Tempo_Uscita;
         -- Velocita_Uscita TODO
      end Entra_Nella_Corsia;


      entry Set_Valori_Corsia(Nuova_Lunghezza : Float; Nuovo_Grip : Float; Nuova_Velocita_Max_Uscita : Float; Nuova_Velocita_Max_Percorrenza : Float) when true is
      begin
         Lunghezza := Nuova_Lunghezza;
         Grip := Nuovo_Grip;
         Velocita_Max_Uscita := Nuova_Velocita_Max_Uscita;
         Velocita_Max_Percorrenza := Nuova_Velocita_Max_Percorrenza;
      end;


      procedure Set_Tempo_Liberazione is
      begin
         Tempo_Liberazione := 0.0;

      end Set_Tempo_Liberazione;

   end Corsia;


   -- Definizione della funzione di ordinamento per i record Tempo_Arrivo
   function "<" (L, R : Tempo_Arrivo) return Boolean is
   begin
      -- Nel caso i tempi siano uguali, considera minore quello con Id Auto minore
      if L.Tempo = R.Tempo then
         return L.Id < R.Id;
      end if;

      return L.Tempo < R.Tempo;
   end "<";




   -- Body di Settore
   protected body Settore is

      entry Set_Tipo_Settore(Tipo : Tipi_Settori) when true is
      begin
         Tipo_Settore := Tipo;
      end Set_Tipo_Settore;

      entry Set_Checkpoint(Check : Boolean) when true is
      begin
         Checkpoint := Check;
      end Set_Checkpoint;


      entry Aggiungi_Corsie(Nuove_Corsie : access Array_Corsie) when true is
      begin
         Corsie := Nuove_Corsie;
         for I in Integer range 1 .. Corsie'Length loop
            Corsie(I).Set_Tempo_Liberazione;
         end loop;

      end Aggiungi_Corsie;



      -- Posiziona tutte le auto nell'array di uscita dall'ultimo settore in ordine di partenza
      entry Partenza(Numero_Concorrenti : in Integer)
        when true is
         --Istante_Partenza : Ada.Calendar.Time;
         Istante_Partenza_Float : Float;
      begin
         -- Posizionamento sulla griglia
         --Istante_Partenza := Clock; -- La gara è partita
         Istante_Partenza_Float := 0.0;
         for I in Integer range 1 .. Numero_Concorrenti loop
            -- Metti ogni auto in uscita dall'ultimo settore con scarti di un secondo TODO

            Ordine_Uscita.Insert( ( (Id => I,    Tempo => Istante_Partenza_Float )) );

            Istante_Partenza_Float := Istante_Partenza_Float + 1.0;
            Put ("*");
         end loop;

         Put_Line ("Auto posizionate sulla griglia di partenza");

      end Partenza;


      procedure Entra_Nel_Settore(Id_Auto: in Integer; Stato_Auto : in out Configurazione; Tempo_Entrata : in float; Tempo_Uscita: out float) is
         -- Variabili di comodo usate per il calcolo di tempo e stato nelle varie corsie
         Tempo_Uscita_Provvisorio : float;
         Stato_Auto_Iniziale : Configurazione;
         Stato_Auto_Provvisorio : Configurazione;

         Corsia_Scelta : Integer;
      begin

         if Tipo_Settore = Tipi_Settori'Value("Box") then
            -- Sono il settore Box. Non scelgo corsie, ma rifornisco l'auto e calcolo il tempo di uscita in base al tempo di rifornimento
            -- TODO: Metto 10 secondi standard per ora
            Tempo_Uscita := Tempo_Entrata + 10.0 + Float(Stato_Auto.Livello_Danni/10) + Float(Stato_Auto.Livello_Benzina_Pitstop - Stato_Auto.Livello_Benzina)/10.0;
            --Put_Line("Rifornimento time " & Float'Image(Float(Stato_Auto.Livello_Danni/10) + Float(Stato_Auto.Livello_Benzina_Pitstop - Stato_Auto_Provvisorio.Livello_Benzina)/10.0));
            --Put_Line("Rifornimento per " & To_String(Stato_Auto.Nome_Pilota));
            Stato_Auto.Livello_Benzina := Stato_Auto.Livello_Benzina_Pitstop; -- Metto tanta benzina quanta specificata
            Stato_Auto.Gomme := Stato_Auto.Gomme_Pitstop; -- Monto il tipo di gomme selezionato
            Stato_Auto.Usura_Gomme := 0.0; -- Le gomme sono nuove
            Stato_Auto.Entrata_Box := False; -- Resetto la decisione di fermarsi ai box
            Stato_Auto.Livello_Danni:= 0; -- Riparo i danni
            -- TODO: Calcolo il tempo necessario per il rifornimento + percorrenza ultimo tratto

            Put_Line("Rifornimento per " & To_String(Stato_Auto.Nome_Pilota));

         else

            -- Scelta della corsia normalmente
            -- Calcola il tempo che impiegherebbe l'auto su ogni corsia, e salva il tempo migliore con il relativo stato
            for I in Integer range 1 .. Corsie'Length loop

               Stato_Auto_Iniziale := Stato_Auto;
               Corsie(I).Calcola_Tempo_Attraversamento(Stato_Auto_Iniziale,Tempo_Entrata,Tempo_Uscita_Provvisorio);
               if I=1 or Tempo_Uscita_Provvisorio < Tempo_Uscita then
                  Tempo_Uscita := Tempo_Uscita_Provvisorio;
                  Corsia_Scelta := I;

                  Stato_Auto_Provvisorio := Stato_Auto_Iniziale;
               end if;
            end loop;

            --Put_Line("Auto " & Positive'Image(Id_Auto) & " entra in settore " & Positive'Image(Id) & " in corsia " & Positive'Image(Corsia_Scelta));
            -- Imposto lo stato finale dell'auto
            Stato_Auto := Stato_Auto_Provvisorio;


            -- Ho l'indice della corsia scelta. Effettuo l'entrata vera e propria per impostarne il tempo di uscita
            Corsie(Corsia_Scelta).Entra_Nella_Corsia(Tempo_Uscita);
         end if;

         -- Posizionamento nell'array di uscita
         Ordine_Uscita.Insert  ( (Id => Id_auto,    Tempo => Tempo_Uscita )) ;
         -- Comunico gia il tempo di uscita al middleware per dargli un'idea del progesso dell'auto
         Comunicazione.Comunica_Tempo_Futuro(Id, Id_Auto, Tempo_Uscita, Stato_Auto.Numero_Giri);

      end Entra_Nel_Settore;


      entry Esci_Dal_Settore(Id_Auto: in Integer; Stato_Auto: in out Configurazione; Prossimo_Settore: out Integer; Tempo_Uscita : out float)
        when true is
         Settore_Successivo_T : Settore_T;
      begin

         --delay 2.0; -- slowdown factor
         --Put_Line("Auto con Id "  & Positive'Image(Id_Auto) & " vuole uscire dal settore " & Positive'Image(Id) & " - candidata ad uscire: "  & Positive'Image(Ordine_Uscita.First_Element.Id));

         if Ordine_Uscita.First_Element.Id = Id_Auto then
            -- E' proprio quest'auto che deve uscire


            Put_Line(To_String(Stato_Auto.Nome_Pilota) & " esce dal settore " & Positive'Image(Id) );
            Comunicazione.Comunica_Tempo(Id, Id_Auto, Ordine_Uscita.First_Element.Tempo, Stato_Auto.Numero_Giri);
            -- L'auto ora deve entrare nel settore successivo

            -- Nel caso questo settore sia il penultimo, devo controllare che l'auto non debba entrare ai box, in qual caso la faccio entrare nel settore corsia box




            if Tipo_Settore = Tipi_Settori'Value("Second_Last") and Stato_Auto.Entrata_Box = True then
               -- L'auto deve entrare in PitLane
               Coordinatore.Get_Corsia_Box(Settore_Successivo_T); -- Ottieni il settore "Corsia box"
               --Coordinatore.Get_Settore_Successivo(Id, Settore_Successivo_T);
               --    Settore_Successivo_T
            else
               if Tipo_Settore = Tipi_Settori'Value("Pit_Lane") then
                  --Put_Line("CORSIA BOX");
                  -- Entro nel box TODO:
                  Coordinatore.Get_Settore_Successivo(Id, Settore_Successivo_T); -- Ottieni il prossimo settore

               else
                  -- Entro nel settore successivo normalmente
                  Coordinatore.Get_Settore_Successivo(Id, Settore_Successivo_T); -- Ottieni il prossimo settore

               end if;


            end if;


            --Put_Line ("Auto " & Positive'Image(Id_Auto) & " ottiene il settore successivo");

            -- Controllo se l'auto finisce un giro, in caso incremento il contatore giri
            if Tipo_Settore = Tipi_Settori'Value("Last") or Tipo_Settore = Tipi_Settori'Value("Pit_Lane") then
               Stato_Auto.Numero_Giri := Stato_Auto.Numero_Giri + 1;
               -- Controllo anche se finisce la gara TODO:
               if Stato_Auto.Numero_Giri = Stato_Auto.Numero_Giri_Totali then
                  -- Ultimo settore della gara. Mi accodoGara finita. Lo comunico al coordinatore? TODO
                  null;
                  --Coordinatore.Set_Fine_Gara(Id_Auto);
                  --else
                  --Put_Line("Il tempo di entrata dell'auto " & Positive'Image(Id_Auto) & ": " & Float'Image(Ordine_Uscita.First_Element.Tempo));
               end if;

               Settore_Successivo_T.Entra_Nel_Settore(Id_Auto, Stato_Auto, Ordine_Uscita.First_Element.Tempo, Tempo_Uscita); -- Entra nel prossimo settore ottenendo il tempo
               --end if;
            else
               Settore_Successivo_T.Entra_Nel_Settore(Id_Auto, Stato_Auto, Ordine_Uscita.First_Element.Tempo, Tempo_Uscita); -- Entra nel prossimo settore ottenendo il tempo
            end if;

            -- Put_Line("Rimuovo " & Positive'Image(Ordine_Uscita.First_Element.Id) & " dalla coda del settore " & Positive'Image(Id));
            -- Rimuovo l'auto dall'array delle uscite
            Ordine_Uscita.Delete_First;

            Prossimo_Settore := Settore_Successivo_T.Id;



            Guardia := True; -- Apri la guardia
         else
            --Put_Line("---------------Devi riaccodarti");
            requeue Esci_Dal_Settore_Requeue;
         end if;

      end Esci_Dal_Settore;

      entry Esci_Dal_Settore_Requeue(Id_Auto: in Integer; Stato_Auto: in out Configurazione; Prossimo_Settore: out Integer; Tempo_Uscita : out float)
        when Guardia = True is
      begin
         if Esci_Dal_Settore_Requeue'Count = 0 then
            Guardia := False;
         end if;

         requeue Esci_Dal_Settore;
      end Esci_Dal_Settore_Requeue;

      entry Libera_Settore(Id_Auto: in Integer)
        when True is
      begin
         null;
      end Libera_Settore;

      procedure Get_Tipo_Settore(Tipo : out Tipi_Settori) is
      begin
         Tipo := Tipo_Settore;
      end Get_Tipo_Settore;


   end Settore;

end Settori;
