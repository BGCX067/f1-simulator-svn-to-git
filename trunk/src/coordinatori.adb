with Ada.Text_IO; 	 use Ada.Text_IO;
with Ada.Text_IO.Text_Streams; use Ada.Text_IO.Text_Streams;
with Ada.Real_Time;	 use Ada.Real_Time;
with Ada.Calendar.Formatting; use Ada.Calendar.Formatting;

with Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO; use Ada.Text_IO.Unbounded_IO;

-- XML
with Input_Sources.File; use Input_Sources.File;
with Sax.Readers;        use Sax.Readers;
with DOM.Readers;        use DOM.Readers;
with DOM.Core;           use DOM.Core;
with DOM.Core.Documents; use DOM.Core.Documents;
with DOM.Core.Nodes;     use DOM.Core.Nodes;
with DOM.Core.Attrs;     use DOM.Core.Attrs;

with Ada.Containers.Vectors; use Ada.Containers;

-- Settori ed auto
with Settori; use Settori;
with Autos; use Autos;
with ConfigurazioniAuto; use ConfigurazioniAuto;

-- Comunicazione
with Comunicazioni; use Comunicazioni;

with Ada.Numerics.Float_Random;
use Ada.Numerics.Float_Random;

--eccezioni
with Ada.Exceptions;

package body Coordinatori is



   package SU renames Ada.Strings.Unbounded; -- Rinomino Ada.Strings.Unbounded per comodità

   procedure Finalize(Tlw : in out Task_Last_Wishes) is
   begin
      Put("Sto morendo");
   end Finalize;

   task body Coordinatore is




      --------------------------------------------------------------------------------------
      -- Finchè il caricamento da xml non sarà operativo, uso delle variabili provvisorie --
      --------------------------------------------------------------------------------------

      -- Variabili per la lettura dal file xml
      Input  : File_Input;
      Output : File_Type;
      Reader : Tree_Reader;
      Doc    : Document;
      List   : Node_List;
      Lista_Corsie: Node_List;
      N      : Node;
      A      : Attr;

      -- End variabili per la lettura dal file xml

      Numero_Auto : Integer := 12; -- Numero delle auto partecipanti
      Numero_Settori : Integer := 30; -- Numero dei settori nella pista (esclusi box)

      Concorrenti : Array_Auto; -- Array delle auto nella competizione
      Settori_Pista : Array_Settori; -- Array dei settori della pista
      -- Settori_Box : Array_Settori; -- Array dei settori della corsia dei box (corsia di accesso e box)

      Nuove_Configurazioni : Array_Configurazioni; -- Array delle nuove configurazioni arrivate dai box

      Corsie_Settore : access Array_Corsie; -- Array delle corsie di un settore

      Nome_Pista : SU.Unbounded_String; -- Nome del tracciato

      Meteo : Integer; -- Tempo atmosferico TODO: Decidere i valori

      Numero_Giri : Integer; -- Numero di giri totali da effettuare


      Settori_Checkpoint : VectorDiInteri.Vector;

      Configurazione_Auto : Configurazione; -- Setup di un auto

      Inizio : time; -- L'istante di inizio gara, in formato data

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

      Gara_Finita : Boolean := False;
      Tutti_Finiti : Boolean := False;
      Numero_Auto_Finite : Integer;
      Stringa_Xml : SU.Unbounded_String;

      g : Generator;
      randomNumber : Float;

      Termina : Boolean := False;

      -- Eccezioni
      Comando_Errato : exception;

      Errore_Comunicazione : Boolean;


   begin
      -- Eccezioni

      Put_Line("Coordinatore avviato");
      -- Contatto il middleware

      Comunicazione.Hello;
      Errore_Comunicazione := False;




      Put_Line("Middleware contattato");
      -- Inizio attivazione gara
      loop
         -- Reinizializzare/pulire tutte le variabili
         Gara_Finita := False;
         Tutti_Finiti := False;
         Numero_Auto_Finite := 0;


         Put_Line("In attesa di nuova gara o terminazione");
         select

            accept Get_Dati_Iniziali(Dati : in Unbounded_String) do
               Put_Line("Ricevuti i dati della gara");
               Stringa_Xml := Dati;
               --Put_Line(To_String(Stringa_Xml));
            end;

         or
            accept Termina_Tutto do
               Termina := True;
            end Termina_Tutto;
         end select;


         if Termina = True then
            exit;
         end if;


         -- Lettura da xml --
         Create(File=>Output, Name=>"circuit.xml");

         Unbounded_IO.Put_Line(Output,Stringa_Xml);
         Close(Output);

         Set_Public_Id (Input, "Configuration file");
         Open ("circuit.xml", Input);
         -- Ignorable_Whitespace(Reader,Ch => " ");

         Set_Feature (Reader, Validation_Feature, False);
         Set_Feature (Reader, Namespace_Feature, False);

         Parse (Reader, Input);
         Close (Input);

         -- Ottieni l'albero del documento xml
         Doc := Get_Tree (Reader);

         -- Lettura delle info del circuito
         List := Get_Elements_By_Tag_Name (Doc, "circuit");
         N := Item (List, 0);
         Numero_Giri := Integer'Value(Value(Get_Named_Item(Attributes (N), "laps")));
         Nome_Pista := SU.To_Unbounded_String(Value(Get_Named_Item(Attributes (N), "name")));
         Meteo := Integer'Value(Value(Get_Named_Item(Attributes (N), "weather")));

         -- Lettura della lista dei settori
         List := Get_Elements_By_Tag_Name (Doc, "sector");
         Numero_Settori := Length (List);

         for I in 1 .. Length (List) loop

            N := Item (List, I - 1);
            A := Get_Named_Item (Attributes (N), "type");
            Settori_Pista(I) := new Settore(I);
            Settori_Pista(I).Set_Tipo_Settore(Tipi_Settori'Value( Value(A)));

            Settori_Pista(I).Set_Checkpoint( Boolean'Value(Value(Get_Named_Item (Attributes (N), "checkpoint"))) );

            if  Boolean'Value(Value(Get_Named_Item (Attributes (N), "checkpoint"))) = True then
               Settori_Checkpoint.append(I);
            end if;


            -- Crea le corsie all'interno del settore
            Lista_Corsie := DOM.Core.Nodes.Child_Nodes(N);

            Corsie_Settore := new Array_Corsie (1 .. Length (Lista_Corsie));
            for J in 1 .. Length (Lista_Corsie) loop

               -- Escludo i "nodi vuoti" causati da spazi ed invii nel file xml TODO
               if(Node_Type(Item(Lista_Corsie, J-1)) /= Text_Node) then
                  --Put_Line ("Corsia");
                  Corsie_Settore(J) := new Corsia;
                  Corsie_Settore(J).Set_Valori_Corsia(Float'Value(Value(Get_Named_Item (Attributes (Item(Lista_Corsie, J-1)), "length"))),Float'Value(Value(Get_Named_Item (Attributes (Item(Lista_Corsie, J-1)), "grip"))),Float'Value(Value(Get_Named_Item (Attributes (Item(Lista_Corsie, J-1)), "max_exit_speed"))),Float'Value(Value(Get_Named_Item (Attributes (Item(Lista_Corsie, J-1)), "max_speed"))));

               end if;
            end loop;

            Settori_Pista(I).Aggiungi_Corsie(Corsie_Settore);


         end loop;

         -- Crea il settore di accesso ai box ed il settore box
         -- Li inserisco nell'array Settori_Pista nelle ultime 2 posizioni

         -- Settore pitlane
         List := Get_Elements_By_Tag_Name(Doc, "pitlane");
         Settori_Pista(Numero_Settori+1) := new Settore(Numero_Settori + 1);
         Settori_Pista(Numero_Settori+1).Set_Tipo_Settore(Tipi_Settori'Value("Pit_Lane"));
         Settori_Pista(Numero_Settori+1).Set_Checkpoint(True);
         Settori_Checkpoint.append(Numero_Settori+1);


         -- Creo una corsia nella pitlane
         Corsie_Settore := new Array_Corsie (1 .. 1);
         Corsie_Settore(1) := new Corsia;
         Corsie_Settore(1).Set_Valori_Corsia(Float'Value(Value(Get_Named_Item (Attributes (Item(List, 0)), "length"))),1.0,80.0,80.0);
         -- Aggiungo la corsia alla pitlane
         Settori_Pista(Numero_Settori+1).Aggiungi_Corsie(Corsie_Settore);

         -- Ora creo il settore contenente i box veri e propri
         Settori_Pista(Numero_Settori + 2) := new Settore(Numero_Settori + 2);
         Settori_Pista(Numero_Settori + 2).Set_Tipo_Settore(Tipi_Settori'Value("Box"));




         -- Carica le info sulle auto

         List := Get_Elements_By_Tag_Name (Doc, "car");
         Numero_Auto := Length (List);

         -- Ora che ho il numero di auto, prima di inviare le info di ogni comunica al middleware le info sulla gara. TODO
         Comunicazione.Comunica_Dati_Iniziali_Gara(Nome_Pista, Numero_Giri, Numero_Settori, Numero_Auto, Meteo, Settori_Checkpoint);


         for I in 1 .. Length (List) loop

            N := Item (List, I - 1);
            --A := Get_Named_Item (Attributes (N), "power");

            -- TODO: Carico la configurazione di ogni auto dal file
            Configurazione_Auto.Id := I;
            Configurazione_Auto.Nome_Pilota := SU.To_Unbounded_String( Value(Get_Named_Item (Attributes (N), "pilot")) );
            Configurazione_Auto.Nome_Scuderia := SU.To_Unbounded_String( Value(Get_Named_Item (Attributes (N), "team")) );
            Configurazione_Auto.Gomme := Gomma'Value( Value(Get_Named_Item (Attributes (N), "tyres")) );
            Configurazione_Auto.Gomme_Pitstop := Gomma'Value( Value(Get_Named_Item (Attributes (N), "tyres")) );
            Configurazione_Auto.Usura_Gomme_Stop := Float'Value(Value(Get_Named_Item (Attributes (N), "tyres_stop")));
            Configurazione_Auto.Livello_Benzina := Integer'Value(Value(Get_Named_Item (Attributes (N), "gasoline")));
            Configurazione_Auto.Potenza := Integer'Value(Value(Get_Named_Item (Attributes (N), "power")));
            Configurazione_Auto.Livello_Benzina_Pitstop := Integer'Value(Value(Get_Named_Item (Attributes (N), "gasoline_at_pitstop")));
            Configurazione_Auto.Livello_Benzina_Stop := Integer'Value(Value(Get_Named_Item (Attributes (N), "gasoline_stop")));

            Configurazione_Auto.Usura_Gomme := 0.0;
            Configurazione_Auto.Velocita_Attuale := 0.0;

            Configurazione_Auto.Livello_Danni := 0;

            Configurazione_Auto.Numero_Giri := 0; -- Giro in cui si trova l'auto
            Configurazione_Auto.Numero_Giri_Totali := Numero_Giri; -- Giri totali da eseguire

            Concorrenti(I):= new Auto(I); -- Crea l'i-esima auto
            Concorrenti(I).Set_Status(Configurazione_Auto); -- Carica la configurazione iniziale

            -- Comunico i dati del pilota al Middleware
            Comunicazione.Comunica_Dati_Iniziali_Auto(I,Configurazione_Auto.Nome_Pilota,Configurazione_Auto.Nome_Scuderia);
         end loop;


         Free (List);

         Free (Reader);


         -- Fine lettura da xml --



         -- Operazioni preliminari varie


         -- Posiziona le auto sulla griglia di partenza
         Settori_Pista(Numero_Settori).Partenza(Numero_Auto);

         -- Gara iniziata
         -- TODO: Aggiungere una entry per rimanere in attesa dell'evento inizio gara
         Put_Line("In attesa dello start");

         select
            accept Avvio do
            null;
            end Avvio;
         or
            accept Termina_Tutto  do
               Termina := True;
               Put_Line("Coordinatore termina");
            end Termina_Tutto;
         end select;

         if Termina = True then
            for I in Integer range 1 .. Numero_Auto loop
            Concorrenti(I).Termina;
         end loop;
            exit;
         end if;

         Put_Line("Partenza!");


         -- Imposta il tempo di inizio della gara
         Inizio := Clock;
         -- Fai partire i task auto
         for I in Integer range 1 .. Numero_Auto loop
            Concorrenti(I).Parti( Settori_Pista(Numero_Settori), Inizio );
         end loop;


         loop
            select
               accept Get_Settore_Successivo (Settore_Attuale : Integer ; Settore_Successivo : out Settore_T ) do
                  if Settore_Attuale = Numero_Settori + 1 then
                     -- Sono in corsia box, voglio il settore box
                     Settore_Successivo := Settori_Pista(Numero_Settori + 2);
                  else
                     if Settore_Attuale = Numero_Settori + 2 then
                        -- Sono ai box, voglio il secondo settore
                        Settore_Successivo := Settori_Pista(2);
                     else
                        -- Voglio il settore successivo in pista
                        Settore_Successivo := Settori_Pista( (Settore_Attuale) mod Numero_Settori + 1);
                     end if;
                  end if;
               end Get_Settore_Successivo;
            or
               accept Get_Corsia_Box(Settore_Successivo : out Settore_T) do
                  Settore_Successivo := Settori_Pista(Numero_Settori + 1);
                  --Put_Line("*************CHIEDONO CORSIA BOX********");
               end Get_Corsia_Box;

            or
               accept Get_Settore_Da_Id(Id_Settore : Integer; Settore_Successivo : out Settore_T) do
                  Settore_Successivo := Settori_Pista(Id_Settore);
               end Get_Settore_Da_Id;

            or
               accept Comunica_Aggiornamento(Stato : in Configurazione) do
                  --Put_Line("TODO - Devo aggiornare lo stato dell'auto " & Integer'Image(Stato.Id));
                  Nuove_Configurazioni(Stato.Id) := Stato;


               end Comunica_Aggiornamento;

            or
               accept Get_Nuovo_Stato (Auto: in Integer; Stato : out Configurazione) do

                  Stato := Nuove_Configurazioni(Auto);
                  Nuove_Configurazioni(Auto).Id := 0; -- Imposto a 0 l'Id in modo da capire che lo stato è gia stato comunicato

               end Get_Nuovo_Stato;
            or
               accept Set_Fine_Gara(Auto: in Integer) do
                  Comunicazione.Comunica_Fine_Gara(Auto);
                  if Gara_Finita = False then
                     Gara_Finita := True;
                  end if;
                  Numero_Auto_Finite := Numero_Auto_Finite + 1;
                  if Numero_Auto_Finite = Numero_Auto then
                     Tutti_Finiti := True;
                  end if;


               end Set_Fine_Gara;
            or
               accept Get_Fine_Gara(Status : out Boolean) do
                  Status := Gara_Finita;

               end Get_Fine_Gara;

            or
               accept Get_Meteo(m : out Tempo_Atmosferico) do
                  m := Tempo_Atmosferico'Val(Meteo);
               end Get_Meteo;

            or
               accept Errore_Comunicazioni do
                  Errore_Comunicazione := True;
                  Put_Line("Ricevuto errore di comunicazione");

               end Errore_Comunicazioni;

            or

               terminate;

            end select;

            -- Invio il meteo (sempre quello) TODO

            reset(g);
            randomNumber := random(g);
            if randomNumber < 0.001 then
               reset(g);
               randomNumber := random(g);
               if randomNumber < 0.2 then
                  Comunicazione.Comunica_Meteo(1);
               elsif randomNumber < 0.4 then
                  Comunicazione.Comunica_Meteo(2);
               elsif randomNumber < 0.6 then
                  Comunicazione.Comunica_Meteo(3);
               elsif randomNumber < 0.8 then
                  Comunicazione.Comunica_Meteo(4);
               end if;
            end if;



            if Tutti_Finiti then
               exit;
            end if;

            if Errore_Comunicazione = True then
            null;
           -- exit;
            end if;

           -- Put_Line("Coordinatore loop");
         end loop;

         -- Fine gara
         if Errore_Comunicazione = True then
            null;
            exit;
         end if;
         --Comunicazione.Comunica_Uscita;
         --exit;
      end loop;

      --Comunicazione.Comunica_Uscita;
      select
         Comunicazioni.Start.Termina;
      or
         delay 1.0;
      end select;


      Put_Line("Coordinatore pronto a terminare");
   exception
      when E : others =>
         Put_Line("Errore. La gara viene chiusa");
         --Ada.Text_IO.Put_Line(Ada.Exceptions.Exception_Message (E));
         --Put_Line(".....");
         Comunicazione.Comunica_Errore("Errore di lettura file xml");
         Comunicazioni.Start.Termina;

   end Coordinatore;


end Coordinatori;
