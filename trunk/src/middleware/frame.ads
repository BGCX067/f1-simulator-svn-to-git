
with Ada.Containers.Vectors; use Ada.Containers;

--Tipo e metodi per la gestione dei tempi vettura da visualizzare sul monitor
package Frame is

   type Frame_Type is record
      Auto:Integer;
      Settore:Integer;
      Giro:Integer;
      Tempo_Entrata:float;
      Tempo_Uscita:float;
      Fine_Gara:Boolean;
   end record;
   package Frame_Vectors is new Vectors(Natural, Frame_Type);

   procedure Inserisci_Frame(Self:in out Frame_Vectors.Vector;Auto:Integer;Settore:Integer;Giro:Integer;Tempo_Entrata:float;Tempo_Uscita:float;Fine_Gara:Boolean);
   function Esiste_Frame(Self:Frame_Vectors.Vector;Auto:Integer;Settore:Integer;Giro:Integer;Fine_Gara:Boolean) return Boolean;

   function Cambio_Giro(Self:Frame_Vectors.Vector;Auto:Integer;Giro:Integer) return Boolean;
   function Ottieni_Frame(Self:Frame_Vectors.Vector;Auto:Integer) return Frame_Type;

end Frame;
