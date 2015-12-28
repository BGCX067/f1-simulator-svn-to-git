with Ada.Text_IO; --with Ada.Calendar;
USE Ada.Text_IO; --use Ada.Calendar;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Coordinatori; use Coordinatori;
with Settori; use Settori;
with Ada.Calendar.Formatting;

with Comunicazioni; use Comunicazioni;

package body Autos is

   -- Task Auto: il suo comportamento e' quello di entrare nei settori consecutivamente fino al termine della gara
   task body Auto is
      Stato : Configurazione;
      Tempo_Inizio_Gara : time; -- Istante di inizio gara, in formato data

      t : float; -- tempo impiegato fin'ora
      --Risveglio : time; -- tempo assoluto fino al quale dormire zzzzzzzz.....

      -- Giro : Integer; -- Numero di giri effettuati


      Settore_Attuale : Settore_T;
      Id_Settore_Successivo : Integer;
      Gara_Finita : Boolean := False;
      Tipo_Settore_Attuale : Tipi_Settori;
      Termina_Gara : Boolean := False;
   begin


      accept Set_Status (Nuovo_Stato : Configurazione) do
         Stato := Nuovo_Stato;

      end Set_Status;

      -- Una volta avviato il processo e completate tutte le operazioni iniziali, aspetto il via
      select
         accept Parti(Settore_Partenza : Settore_T; Inizio : time) do
         Settore_Attuale := Settore_Partenza; -- Sistemati sull'ultimo settore
         --Giro := 0;
         Tempo_Inizio_Gara := Inizio;

         end Parti;

      or
         accept Termina  do
            Termina_Gara := True;
         end Termina;
           end select;

      if Termina_Gara = False then



      loop
         -- esci dal settore attuale ed entra nel prossimo, ottenendo il tempo di arrivo alla fine del prossimo

         Settore_Attuale.Esci_Dal_Settore(id, Stato, Id_Settore_Successivo,  t);
         --Put_Line(To_String(Stato.Nome_Pilota) & " dovra dormire per " & Float'Image(t));

         -- ho il tempo di uscita, lo comunico già al middleware

         -- Se ho completato i giri, mi fermo
         if(Stato.Numero_Giri = Stato.Numero_Giri_Totali + 1) then
            -- Gara finita
            Coordinatore.Set_Fine_Gara(id);
            Put_Line(To_String(Stato.Nome_Pilota) & " ha finito la gara facendo tutti i giri");
            exit;
         end if;

         -- Se la gara è finita e ho passato il traguardo, mi fermo
         Coordinatore.Get_Fine_Gara(Gara_Finita);
         Settore_Attuale.Get_Tipo_Settore(Tipo_Settore_Attuale);
         if(Gara_Finita and (Tipo_Settore_Attuale=Last or Tipo_Settore_Attuale = Pit_Lane) ) then
            -- Gara finita
            Coordinatore.Set_Fine_Gara(id);
            Put_Line(To_String(Stato.Nome_Pilota) & " ha finito la gara da doppiato");
            exit;
         end if;


         -- Sono uscito dal settore attuale (ed entrato nel successivo). Conosco il tempo di arrivo
         -- alla fine del prossimo settore, e le condizioni dell'auto. Effettuo i controlli per i pitstop

         -- Chiedo al coordinatore se c'è una nuova configurazione arrivatq dai box
         declare Stato_Dai_Box : Configurazione;
         begin


            Coordinatore.Get_Nuovo_Stato(Stato.Id, Stato_Dai_Box);
            if Stato_Dai_Box.Id /= 0 then
               --Stato := Stato_Dai_Box; --singoli campi

               Stato.Gomme_Pitstop := Stato_Dai_Box.Gomme_Pitstop;
               Stato.Usura_Gomme_Stop := Stato_Dai_Box.Usura_Gomme_Stop;
               Stato.Livello_Benzina_Stop := Stato_Dai_Box.Livello_Benzina_Stop ;
               Stato.Livello_Benzina_Pitstop := Stato_Dai_Box.Livello_Benzina_Pitstop;

               Stato.Entrata_Box := Stato_Dai_Box.Entrata_Box;



            end if;


         end;

         -- E' il momento di prenotare la fermata ai box?
         --Put_Line(To_String(Stato.Nome_Pilota) & " benzina: " & Integer'Image(Stato.Livello_Benzina) & " gomme: " & Float'Image(Stato.Usura_Gomme));
         if (Stato.Usura_Gomme >= Stato.Usura_Gomme_Stop or Stato.Livello_Benzina <= Stato.Livello_Benzina_Stop) and Stato.Entrata_Box = False then
            Stato.Entrata_Box := True;
         end if;

         --Put_Line(To_String(Stato.Nome_Pilota) & " chiede al coordinatore il settore da ID");


         -- TODO: Al momento ignoro cosa mi ritorna la procedura qui sopra, e chiedo al coordinatore di darmi il prossimo settore
         Coordinatore.Get_Settore_Da_Id(Id_Settore_Successivo,  Settore_Attuale );

         -- Put_Line(To_String(Stato.Nome_Pilota) & " ha ottenuto il settore da ID");


         -- esegui operazioni varie, routines, leggi box, cambia strategia, comunica ai box...

         -- calcola degrado gomme e livello benzina
         -- controlla condizioni atmosferiche, e nel caso cambia strategia
         -- setta o meno il flag di fermata ai box
         -- in caso positivo, comunica la fermata ai box
         -- se entra nell'ultimo settore, contatta i box per sapere se bisogna rientrare

         --Put_Line("Auto con id " & Positive'Image(id) & " in corsa" );

         -- Prove di accesso al Coordinatore
         -- Coordinatore.Get_Settore_Successivo(20, Settore_Successivo);
         -- Put_Line(Positive'Image(Settore_Successivo));

         -- dormi fino all'arrivo alla fine del settore

         --Put_Line(To_String(Stato.Nome_Pilota) & " comunica lo stato al coordinator");

         -- comunica il tuo stato al coordinator
         Comunicazione.Comunica_Configurazione(Stato);

         --Put_Line(To_String(Stato.Nome_Pilota) & " ha comunicato lo stato al coordinator");

         -- Ricevo il nuovo stato dal coordinator in caso di cambiamento dai box
         --TODO Non dovrebbe piu servire questo
         --           select
         --           accept Set_Nuovo_Status (Nuovo_Stato : Configurazione) do
         --              Stato.Gomme_Pitstop := Nuovo_Stato.Gomme_Pitstop;
         --              Stato.Usura_Gomme_Stop := Nuovo_Stato.Usura_Gomme_Stop;
         --              Stato.Livello_Benzina_Stop := Nuovo_Stato.Livello_Benzina_Stop;
         --                 Stato.Livello_Benzina_Pitstop := Nuovo_Stato.Livello_Benzina_Pitstop;
         --                 Stato.Entrata_Box := Nuovo_Stato.Entrata_Box;
         --                 Put_Line(To_String(Stato.Nome_Pilota) &  " ha ricevuto nuovo stato dai box");
         --
         --
         --           end Set_Nuovo_Status;
         --           or
         --                delay 1.0;
         --           end select;
         --Put_Line(To_String(Stato.Nome_Pilota) & " pronto allo sleep");

         --Put_Line(Integer'Image(Stato.Numero_Giri) & " su " & Integer'Image(Stato.Numero_Giri_Totali));
         delay until Tempo_Inizio_Gara + To_Time_Span(duration(t));



      end loop;

         end if;
      -- Non basta.. bisogna liberare il settore successivo anche! TODO:
      --Put_Line(To_String(Stato.Nome_Pilota) & " libera il settore" );
      Settore_Attuale.Libera_Settore(id);
      --Put_Line(To_String(Stato.Nome_Pilota) & " ha finito la gara" );

      --delay 5.0;
   end Auto;



end Autos;
