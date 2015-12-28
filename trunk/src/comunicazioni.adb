with Ada.Text_IO; use Ada.Text_IO;
with Calendar.Formatting; use Calendar.Formatting;
with ConfigurazioniAuto; use ConfigurazioniAuto;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings; use Ada.Strings;

-- YAMI4
with YAMI.Agents;
with YAMI.Agents.Helpers;
with YAMI.Parameters;

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with GNATCOLL.Config; use GNATCOLL.Config;

with Comunication;

with Coordinatori; use Coordinatori;


package body Comunicazioni is
   Termina : Boolean := False;

   procedure Report
     (H : in out Connection_Event_Handler;
      Name : in String;
      Event : in YAMI.Connection_Event_Handlers.Connection_Event) is
   begin
      case Event is
         when YAMI.Connection_Event_Handlers.New_Incoming_Connection =>
            null;
            --Logger.Traccia(Logger.Middle,"incoming");
         when YAMI.Connection_Event_Handlers.New_Outgoing_Connection =>
            null;
            --Logger.Traccia(Logger.Middle,"outgoiing");
         when YAMI.Connection_Event_Handlers.Connection_Closed =>
            Put_Line("Comunicazioni interrotte");
            --Logger.Traccia(Logger.Middle,"close");
            ComunicazioniOk := False;

            select
               Coordinatore.Termina_Tutto;
            or
               delay 1.0;
            end select;

            select
            Coordinatore.Errore_Comunicazioni;
            or
               delay 1.0;
            end select;

             select
            Start.Termina;
            or
               delay 1.0;
            end select;





      end case;
   end Report;

   overriding procedure Hello(S : in out Comunication_Impl) is
   begin
      null;
   end Hello;

   overriding procedure Comunica_Aggiornamenti (S : in out Comunication_Impl;
                                                Dati_In : in ConfigurazioniAuto_Mid.Configurazione_Auto_Box) is
      Stato : Configurazione;
   begin

      -- Converto da Yami a Configurazione auto
      Stato.Id := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Id_Auto));
      Stato.Gomme_Pitstop := Gomma'Value(To_String(Dati_In.Gomme_Pitstop));
      Stato.Usura_Gomme_Stop := Float'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Usura_Gomme_Stop));
      Stato.Livello_Benzina_Stop := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Benzina_Stop));
      Stato.Livello_Benzina_Pitstop := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Benzina_Pitstop));

      Stato.Entrata_Box := Dati_In.Entrata_Box;
      -- comunico al coordinatore il tutto

      Coordinatore.Comunica_Aggiornamento(Stato);


   end Comunica_Aggiornamenti;

   overriding procedure Comunica_Dati_Iniziali (S : in out Comunication_Impl;
                                                Dati_In : in Comunication.Dati_Inizio_Gara) is
   begin
      -- Put_Line("Chiamato da middleware");
      Coordinatore.Get_Dati_Iniziali(Dati_In.Xml_Data);
     -- Put_Line("Dati iniziali ricevuti");
   end Comunica_Dati_Iniziali;

   overriding procedure Avvio(S : in out Comunication_Impl) is
   begin
      Coordinatore.Avvio;
   end Avvio;

   overriding procedure Termina_Comunicazioni(S : in out Comunication_Impl) is
   begin
      Coordinatore.Termina_Tutto;
      select
         Start.Termina;
      or
         delay 1.0;
      end select;

   end Termina_Comunicazioni;

   --Config_Parser : INI_Parser;

   --------------------
       task body Start is



     	My_Server : aliased Comunication_Impl;
	Server_Address : constant String := "tcp://127.0.0.1:12344";

      Resolved_Server_Address_Last : Natural;
   Client_Agent : YAMI.Agents.Agent :=YAMI.Agents.Make_Agent;


   begin





      --Client_Agent :=YAMI.Agents.Make_Agent;
      Uscita := False;
      Put_Line("Gestore delle comunicazioni avviato");

      Open (Config_Parser, "coordinatorconfig");
      Fill (Config, Config_Parser);

	--Server_Address := Config.Get ("Connection.coorserv");
      --Put_Line(Config.Get ("Connection.midserver"));

      -- Avvio comunicazione middleware
      Middleware.Initialize_Comunication_Interface(Client_Agent, Config.Get ("Connection.midserver"), "comunication");

      --Put_Line("Abilito le comunicazioni");

      Comunicazione.Attiva_Comunicazioni;



      declare
Server_Agent : YAMI.Agents.Agent := YAMI.Agents.Make_Agent;
        Resolved_Server_Address :String (1 .. YAMI.Agents.Max_Target_Length);
 Server_Event_Handler : aliased Connection_Event_Handler;
      begin
	--Put_Line("Provo ad avviarmi");

         Server_Agent.Add_Listener
           (Config.Get ("Connection.coorserv"),
            Resolved_Server_Address,
            Resolved_Server_Address_Last);

         Server_Agent.Register_Connection_Event_Monitor
           (Server_Event_Handler'Unchecked_Access);

         Put_Line
           ("La gara e' in ascolto in: " &
              Resolved_Server_Address(1 .. Resolved_Server_Address_Last));

         -- registrazione dell'oggetto remoto usato dal client
         Server_Agent.Register_Object("comunicationIn", My_Server'Unchecked_Access);


         -- in attesa di client


            accept Termina  do

         	--YAMI.Agents.Helpers.Finalize_Agent(Client_Agent);

              -- Client_Agent.Close_connection(Resolved_Server_Address);
               -- 	Client_Agent.Remove_Listener(Resolved_Server_Address);

               --Server_Agent.Close_connection(Resolved_Server_Address);
               --Server_Agent.Remove_Listener(Resolved_Server_Address);
               --YAMI.Agents.Helpers.Finalize_Agent(Server_Agent);

               --Put_Line("Comunicatore chiude le comunicazioni con il middleware");
               --YAMI.Agents.Helpers.Finalize_Agent(Server_Agent);

              -- exit;
               null;

            end Termina;


         Put_Line("Chiudo il server");
      end;



   exception
      when E : others =>
         Put_Line("Termino tutte le comunicazioni");
         --Ada.Text_IO.Put_Line(Ada.Exceptions.Exception_Message (E));

   end Start;


                           ---------------------

   function To_Configurazione_Yami(Configurazione_Auto : Configurazione) return ConfigurazioniAuto_Mid.Configurazione is

      Conversione : ConfigurazioniAuto_Mid.Configurazione;
   begin
      Conversione.Id_Auto := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Id);
      Conversione.Gomme := To_Unbounded_String(Gomma'Image(Configurazione_Auto.Gomme));
      Conversione.Usura_Gomme := YAMI.Parameters.YAMI_Long_Float(Configurazione_Auto.Usura_Gomme);
      Conversione.Gomme_Pitstop := To_Unbounded_String(Gomma'Image(Configurazione_Auto.Gomme_Pitstop));
      Conversione.Usura_Gomme_Stop := YAMI.Parameters.YAMI_Long_Float(Configurazione_Auto.Usura_Gomme_Stop);
      Conversione.Livello_Benzina := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Livello_Benzina);
      Conversione.Livello_Benzina_Stop := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Livello_Benzina_Stop);
      Conversione.Livello_Benzina_Pitstop := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Livello_Benzina_Pitstop);
      Conversione.Livello_Danni := YAMI.Parameters.YAMI_Integer'Val  (Configurazione_Auto.Livello_Danni);
      Conversione.Entrata_Box := Configurazione_Auto.Entrata_Box;
      Conversione.Potenza := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Potenza);
      Conversione.Bravura_Pilota := YAMI.Parameters.YAMI_Integer'Val(Configurazione_Auto.Bravura_Pilota);
      Conversione.Nome_Pilota := Configurazione_Auto.Nome_Pilota;
      Conversione.Nome_Scuderia := Configurazione_Auto.Nome_Scuderia;

      return Conversione;
      end To_Configurazione_Yami;



function To_Configurazione(Configurazione_Yami : ConfigurazioniAuto_Mid.Configurazione) return Configurazione is

      Conversione : Configurazione;
   begin
      Conversione.Id := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Id_Auto));
      Conversione.Gomme := Gomma'Value(To_String(Configurazione_Yami.Gomme));
      Conversione.Usura_Gomme := Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Configurazione_Yami.Usura_Gomme));
      Conversione.Gomme_Pitstop := Gomma'Value(To_String(Configurazione_Yami.Gomme_Pitstop));
      Conversione.Usura_Gomme_Stop := Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Configurazione_Yami.Usura_Gomme_Stop));
      Conversione.Livello_Benzina := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Livello_Benzina));
      Conversione.Livello_Benzina_Stop := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Livello_Benzina_Stop));
      Conversione.Livello_Benzina_Pitstop := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Livello_Benzina_Pitstop));
      Conversione.Livello_Danni := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Livello_Danni));
      Conversione.Entrata_Box := Configurazione_Yami.Entrata_Box;
      Conversione.Potenza := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Potenza));
      Conversione.Bravura_Pilota := Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Configurazione_Yami.Bravura_Pilota));
      Conversione.Nome_Pilota := Configurazione_Yami.Nome_Pilota;
      Conversione.Nome_Scuderia := Configurazione_Yami.Nome_Scuderia;

      return Conversione;
      end To_Configurazione;


   protected body Comunicazione is

      --ComunicazioniOk := True;

      --------------------------------------------------------------------------------------
      -- Configurazione del middleware --
      --------------------------------------------------------------------------------------

      --Server_Address : String; -- Server in input (es tcp://127.0.0.1:1234)

      entry Attiva_Comunicazioni when true is
      begin
         ConnessioniOk:=true;
      end Attiva_Comunicazioni;



      entry Hello when ConnessioniOk is
      begin
         --Put_Line("Faccio per contattare i middleware");

         Middleware.Hello;
         ComunicazioniOk := True;
         Put_Line("Hello effettuata");
           end Hello;


            entry Comunica_Tempo(Id_Settore : Integer; Id_Auto: Integer; Tempo : Float; Giro: Integer) when ConnessioniOk is
         begin

               --Put_Line("Settore " & Positive'Image(Id_Settore) & " auto " & Positive'Image(Id_Auto) & " in " &  Ada.Calendar.Formatting.Image(Tempo) );

               Tempo_Comunicazione.Id_Auto := YAMI.Parameters.YAMI_Integer'Val(Id_Auto);
               Tempo_Comunicazione.Id_Settore := YAMI.Parameters.YAMI_Integer'Val(Id_Settore);
               Tempo_Comunicazione.Giro := YAMI.Parameters.YAMI_Integer'Val(Giro);
               Tempo_Comunicazione.Tempo := YAMI.Parameters.YAMI_Long_Float(Tempo);

         -- Invia il tempo al middleware
         if ComunicazioniOk = True then
            Middleware.Comunica_Tempo(Tempo_Comunicazione);
            end if;

            end Comunica_Tempo;


            entry Comunica_Tempo_Futuro(Id_Settore : Integer; Id_Auto: Integer; Tempo : Float; Giro: Integer) when ConnessioniOk is
         begin

               --Put_Line("Settore " & Positive'Image(Id_Settore) & " auto " & Positive'Image(Id_Auto) & " in " &  Ada.Calendar.Formatting.Image(Tempo) );

               Tempo_Comunicazione.Id_Auto := YAMI.Parameters.YAMI_Integer'Val(Id_Auto);
               Tempo_Comunicazione.Id_Settore := YAMI.Parameters.YAMI_Integer'Val(Id_Settore);
               Tempo_Comunicazione.Giro := YAMI.Parameters.YAMI_Integer'Val(Giro);
               Tempo_Comunicazione.Tempo := YAMI.Parameters.YAMI_Long_Float(Tempo);

         -- Invia il tempo al middleware
         if ComunicazioniOk = True then
               Middleware.Comunica_Tempo_Futuro(Tempo_Comunicazione);
         end if;

            end Comunica_Tempo_Futuro;


      entry Comunica_Configurazione(Stato_Auto : Configurazione) when ConnessioniOk is
         begin
               -- Invia la configurazione al middleware. Prima la converto in Configurazione per il middleware
if ComunicazioniOk = True then
               Middleware.Comunica_Stato_Auto(To_Configurazione_Yami(Stato_Auto));
end if;
            end Comunica_Configurazione;

            entry Comunica_Dati_Iniziali_Gara(Nome_Pista : Unbounded_String; Numero_Giri : Integer; Numero_Settori : Integer; Numero_Auto : Integer;  Meteo : Integer ; Checkpoints : Coordinatori.VectorDiInteri.Vector) when ConnessioniOk is
         type arrayDiInteri is array(1 .. 10) of Integer;
         SettoriCheckpoint : arrayDiInteri;
         ArrayIndex : Natural := 1;
         StringaArray : Unbounded_String := To_Unbounded_String("");
      begin

               Stato_Iniziale_Comunicazione.Nome_Pista := Nome_Pista;
               Stato_Iniziale_Comunicazione.Numero_Giri := YAMI.Parameters.YAMI_Integer'Val(Numero_Giri);
               Stato_Iniziale_Comunicazione.Numero_Settori := YAMI.Parameters.YAMI_Integer'Val(Numero_Settori);
               Stato_Iniziale_Comunicazione.Numero_Auto_Tot := YAMI.Parameters.YAMI_Integer'Val(Numero_Auto);
         Stato_Iniziale_Comunicazione.Meteo:= YAMI.Parameters.YAMI_Integer'Val(Meteo);


         for K in Checkpoints.First_Index .. Checkpoints.Last_Index loop
            SettoriCheckpoint(ArrayIndex) := Checkpoints.Element (K);
            ArrayIndex := ArrayIndex + 1;
            if StringaArray = To_Unbounded_String("") then
            StringaArray := To_Unbounded_String(Integer'Image(Checkpoints.Element(K)));

            else

               StringaArray := StringaArray & "," & To_Unbounded_String(Integer'Image(Checkpoints.Element(K)));
            end if;

            end loop;

         Stato_Iniziale_Comunicazione.Checkpoint := StringaArray;
if ComunicazioniOk = True then
               Middleware.Comunica_Stato_Iniziale(Stato_Iniziale_Comunicazione);
         end if;
         end Comunica_Dati_Iniziali_Gara;


            entry Comunica_Dati_Iniziali_Auto(Id_Auto : Integer; Nome_Pilota : Unbounded_String; Nome_Scuderia : Unbounded_String) when ConnessioniOk is
         begin
               Dati_Auto_Iniziali.Id_Auto := YAMI.Parameters.YAMI_Integer'Val(Id_Auto);
               Dati_Auto_Iniziali.Nome := Nome_Pilota;
               Dati_Auto_Iniziali.Scuderia := Nome_Scuderia;
if ComunicazioniOk = True then
               Middleware.Comunica_Dati_Concorrente(Dati_Auto_Iniziali);
end if;
            end Comunica_Dati_Iniziali_Auto;


            entry Comunica_Meteo (Meteo : Integer) when ConnessioniOk is
         begin
               declare
                  Cambio_Meteo : Comunication.Dati_Meteo;
               begin

               Cambio_Meteo.Meteo := YAMI.Parameters.YAMI_Integer'Val(Meteo);
            if ComunicazioniOk = True then
               Middleware.Comunica_Cambio_Meteo(Cambio_Meteo);

            end if;
         end;

            end Comunica_Meteo;

            entry Comunica_Fine_Gara(Auto : in Integer) when ConnessioniOk is

      begin
               -- Comunica la fine della gara al middleware
               declare
                  dati : Comunication.Dati_Fine_Gara;
               begin
                  dati.Id_Auto := YAMI.Parameters.YAMI_Integer'Val(Auto);
            if ComunicazioniOk = True then
               Middleware.Comunica_Fine_Gara(dati);
end if;
               end;

            end Comunica_Fine_Gara;


            entry Comunica_Uscita when ConnessioniOk is
         begin
               Uscita := True;

         --Put_Line("Chiesta l'uscita dal comunicatore");

          select
            Start.Termina;
            or
               delay 1.0;
            end select;
         --Start.Termina;

            end Comunica_Uscita;

      entry Comunica_Errore(Errore : in String) when True is
         Dati : Comunication.Dati_Errore;
      begin

         Dati.Messaggio := To_Unbounded_String(Errore);

         if ComunicazioniOk = True then

            Middleware.Comunica_Errori(Dati);
         end if;

         end Comunica_Errore;



   end Comunicazione;



end Comunicazioni;
