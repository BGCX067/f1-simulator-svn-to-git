
package body Logger is


   procedure Traccia(Tipo: Log_Tipo; Messaggio: String) is
   begin

      case Tipo is
      when Middle =>
         Trace (Mid, Messaggio);
      when Coord =>
         Trace (C, Messaggio);
      end case;
   end Traccia;


begin
   --leggo il file di configurazione
   Parse_Config_File;   --  parses default ./.gnatdebug

end Logger;
