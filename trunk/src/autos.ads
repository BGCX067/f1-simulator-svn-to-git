-- Questo package raccoglie le auto e tutti gli aspetti collegati

with Ada.Strings.Unbounded;
--with Ada.Calendar; use Ada.Calendar;
with Ada.Real_Time; use Ada.Real_Time;
with Settori; use Settori;
with ConfigurazioniAuto; use ConfigurazioniAuto;

package Autos is

   package SU renames Ada.Strings.Unbounded; -- Rinomino Ada.Strings.Unbounded per comodità


   -- Task Auto
   task type Auto(id : Integer) is
      entry Parti(Settore_Partenza : Settore_T; Inizio : time);
      entry Set_Status(Nuovo_Stato : Configurazione);
      --entry Set_Nuovo_Status(Nuovo_Stato : Configurazione); -- Stato dai box
      entry Termina;
   end Auto;

   -- Array di Auto
   type Array_Auto is array (1 .. 12) of access Auto;

end Autos;
