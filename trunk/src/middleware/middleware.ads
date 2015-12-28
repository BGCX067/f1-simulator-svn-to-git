
with Comunication;	use Comunication;
with ConfigurazioniAuto_Mid; use ConfigurazioniAuto_Mid;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON; use GNATCOLL.JSON;
with Ada.Containers.Vectors; use Ada.Containers;

with YAMI.Agents;
with YAMI.Parameters;
with Ada.Command_Line;
with GNATCOLL.Config; use GNATCOLL.Config;
with Statistiche;

with YAMI.Connection_Event_Handlers;


-- Package che definisce il middleware del progetto
package Middleware is

   --gestione eventi di connessione
   type Connection_Event_Handler is
     new YAMI.Connection_Event_Handlers.Handler with null record;

   overriding
   procedure Report
     (H : in out Connection_Event_Handler;
      Name : in String;
      Event : in YAMI.Connection_Event_Handlers.Connection_Event);



   package UString is new Vectors(Natural, Unbounded_String);

   -- Interfaccia di comunicazione
   type Comunication_Impl is
     new Comunication.Comunication_Interface_Server  with private;



   -- Procedura di avvio del middleware
   procedure Start;


   Coordinatore : Comunication.Command_Interface;
   Coordinatore_Stato: Boolean;

   --JSON
   Myobj: JSON_Value;


   -- Risorsa Proterra per attendere chiusura prog
   protected type Chiudere is
      entry Attesa_Chiudi_Programma;
      entry Chiudi_Programma;
   private
      Chiusura: Boolean := False;
   end Chiudere;
   Stato_Programma: Chiudere;


   --dati iniziali
   type Dati_Iniziali_Gara is record
      Nome_Pista: Unbounded_String;
      Numero_Giri: Integer;
      Numero_Settori: Integer;
      Numero_Auto_Tot: Integer;
      Meteo: Integer;
      Fine_Gara: Boolean:=False;
      Settori_CheckPoint:Statistiche.Integer_Vector.Vector;
   end record;
   Dati_Gara: Dati_Iniziali_Gara;

   type Auto_Desc is record
      Id_Auto : Integer;
      Nome : Unbounded_String;
      Scuderia: Unbounded_String;
      Fine_Gara: Boolean:=false;
      Tempo_Fine: Float:=-1.0;
      Configurazione:ConfigurazioniAuto_Mid.Configurazione;
   end record;
   package Auto_Desc_Vectors is new Vectors(Natural, Auto_Desc);
   Concorrenti : Auto_Desc_Vectors.Vector;

   --stato della gara
   Gara_Finita:Boolean:=false;

   procedure Invia_Gui(dati:String);
   procedure Invia_Monitor(dati:String);

   Primo_dato:Integer:= 0;
   --configurazione generali
   Config : Config_Pool;


   --true quando la gara è in corso false quando è in attessa di avvio
   Stato_Loop_Task: Boolean:=false;


   task Foto_Loop is
      entry Avvia;
      entry Fine_Gara(tempofinale:float);
      entry Chiudi;
      entry Frame_On_Open(Frame_Open: out Middleware.UString.Vector);

   end Foto_Loop;

private
   type Comunication_Impl is new Comunication.Comunication_Interface_Server with null record;


   procedure Append_Concorrenti(Id_Auto : Integer;Nome : Unbounded_String;Scuderia: Unbounded_String);

   --definizioni delle dicitura dei metodi ereditati da Comunication.Comunication_Interface_Server
   overriding procedure Comunica_Stato_Auto (S : in out Comunication_Impl;
                                             Dati_In : in ConfigurazioniAuto_Mid.Configurazione);

   overriding procedure Comunica_Tempo (S : in out Comunication_Impl;
                                        Dati_In : in Comunication.Tempo_Settore);

   overriding procedure Comunica_Tempo_Futuro (S : in out Comunication_Impl;
                                        Dati_In : in Comunication.Tempo_Settore);


   overriding procedure Comunica_Stato_Iniziale (S : in out Comunication_Impl;
                                        Dati_In : in Comunication.Stato_Iniziale);

   overriding procedure Comunica_Dati_Concorrente(S : in out Comunication_Impl;
                                                  Dati_In: in Dati_Concorrente);

   overriding procedure Comunica_Cambio_Meteo(S : in out Comunication_Impl;
                                              Dati_In: in Dati_Meteo);

   overriding procedure Comunica_Fine_Gara(S : in out Comunication_Impl;
                                          Dati_In: in Dati_Fine_Gara);

   overriding procedure Hello(S : in out Comunication_Impl);

   overriding procedure Comunica_Errori(S : in out Comunication_Impl;
                                        Dati_In: in Dati_Errore);



end Middleware;
