with Ada.Real_Time;	 use Ada.Real_Time;

with Settori; use Settori;
with ConfigurazioniAuto; use ConfigurazioniAuto;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Finalization; use Ada;

with Ada.Containers.Vectors; use Ada.Containers;

package Coordinatori is

   package VectorDiInteri is new Vectors(Natural, Integer);

   type Task_Last_Wishes is new Finalization.Limited_Controlled
   with record
      Message : Integer := 0;
   end record;


   task Coordinatore is

      -- TODO: Forse le seguenti si possono mettere come funzioni o procedure
      entry Get_Dati_Iniziali(Dati : in SU.Unbounded_String);
      -- Ritorna il settore successivo nell'array dei settori
      entry Get_Settore_Successivo(Settore_Attuale : Integer; Settore_Successivo : out Settore_T);
      entry Get_Corsia_Box(Settore_Successivo : out Settore_T);
      entry Get_Settore_Da_Id(Id_Settore : Integer; Settore_Successivo : out Settore_T);
      entry Comunica_Aggiornamento(Stato : in Configurazione);
      entry Get_Nuovo_Stato(Auto: in Integer; Stato : out Configurazione);
      entry Set_Fine_Gara(Auto : in Integer);
      entry Get_Fine_Gara(Status : out Boolean);
      entry Get_Meteo(m : out Tempo_Atmosferico);
      entry Avvio;
      entry Termina_Tutto;
      entry Errore_Comunicazioni;
   end Coordinatore;

   overriding procedure Finalize(Tlw : in out Task_Last_Wishes);



end Coordinatori;

