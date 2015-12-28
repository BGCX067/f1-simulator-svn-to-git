with Ada.Calendar; use Ada.Calendar;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Coordinatori; use Coordinatori;
with Settori; use Settori;
with ConfigurazioniAuto; use ConfigurazioniAuto;
with Comunication;

-- YAMI4
with YAMI.Agents;
with YAMI.Agents.Helpers;
with YAMI.Parameters;

with GNATCOLL.Config; use GNATCOLL.Config;


with YAMI.Connection_Event_Handlers;


with ConfigurazioniAuto_Mid;

package Comunicazioni is

   ComunicazioniOk : Boolean := False;


   type Connection_Event_Handler is
        new YAMI.Connection_Event_Handlers.Handler with null record;


      overriding
      procedure Report
        (H : in out Connection_Event_Handler;
         Name : in String;
         Event : in YAMI.Connection_Event_Handlers.Connection_Event);


   Config : Config_Pool;
   Middleware : Comunication.Comunication_Interface;

   Tempo_Comunicazione : Comunication.Tempo_Settore;

   Stato_Iniziale_Comunicazione : Comunication.Stato_Iniziale;

   Dati_Auto_Iniziali : Comunication.Dati_Concorrente;

   Uscita : Boolean;

   Config_Parser : INI_Parser;

   -- Tipo per comunicazione con middleware
   type Comunication_Impl is new Comunication.Command_Interface_Server with null record;

   -- Procedura di avvio del middleware
   task Start is
      entry Termina;
   end Start;


   --     Tempo_Comunicazione : Comunication.Tempo_Settore;


   --definizioni delle dicitura dei metodi ereditati da Comunication.Command_Interface_Server
   overriding procedure Comunica_Aggiornamenti (S : in out Comunication_Impl;
                                                Dati_In : in ConfigurazioniAuto_Mid.Configurazione_Auto_Box);


   overriding procedure Hello(S : in out Comunication_Impl);

   overriding procedure Comunica_Dati_Iniziali (S : in out Comunication_Impl; Dati_In : in Comunication.Dati_Inizio_Gara);

   overriding procedure Avvio(S : in out Comunication_Impl);

   overriding procedure Termina_Comunicazioni(S : in out Comunication_Impl);


   ------------------------------------------------------------------------------------

   -- Funzione di casting da Configurazione Auto a Configurazione Auto per comunicazione Yami
   function To_Configurazione_Yami(Configurazione_Auto : Configurazione) return ConfigurazioniAuto_Mid.Configurazione;

   -- Funzione di casting da Configurazione Auto per comunicazione Yami a Configurazione Auto
   function To_Configurazione(Configurazione_Yami : ConfigurazioniAuto_Mid.Configurazione) return Configurazione;


   -- Questo task si occupa di gestire la comunicazione tra la gara ed il middleware
   protected Comunicazione is

      entry Attiva_Comunicazioni;

      entry Hello;

      -- Comunica il tempo di uscita di un auto da un settore
      entry Comunica_Tempo(Id_Settore : Integer; Id_Auto: Integer; Tempo : Float; Giro: Integer);
      --- Comunica il tempo di uscita dall'attuale settore, nel futuro

      entry Comunica_Tempo_Futuro(Id_Settore : Integer; Id_Auto: Integer; Tempo : Float; Giro: Integer);

      -- Comunica lo stato dell'auto ai box
      entry Comunica_Configurazione(Stato_Auto : Configurazione);

      -- Comunica i dati iniziali della gara
      entry Comunica_Dati_Iniziali_Gara(Nome_Pista : Unbounded_String; Numero_Giri : Integer; Numero_Settori : Integer; Numero_Auto : Integer; Meteo : Integer ; Checkpoints : Coordinatori.VectorDiInteri.Vector);

      -- Comunica i dati di un'auto a inizio gara
      entry Comunica_Dati_Iniziali_Auto(Id_Auto : Integer; Nome_Pilota : Unbounded_String; Nome_Scuderia : Unbounded_String);

      -- Comunica i dati meteo
      entry Comunica_Meteo(Meteo : Integer);

      -- Comunica la fine della gara
      entry Comunica_Fine_Gara(Auto : in Integer);

      entry Comunica_Uscita;

      entry Comunica_Errore(Errore : in String);

   private
      ConnessioniOk : Boolean := False;




   end Comunicazione;

end Comunicazioni;

