
package body Frame is
   --inserisco in self il relativo frame, se c'è gia un frame con in Auto lo rimpiazzo
   procedure Inserisci_Frame(Self:in out Frame_Vectors.Vector;Auto:Integer;Settore:Integer;Giro:Integer;Tempo_Entrata:float;Tempo_Uscita:float;Fine_Gara:Boolean) is
      Cursor:Frame_Vectors.Cursor;
      Tmp:Frame_Type;
      Tmp_Inserimento:Frame_Type;
      Inserito:Boolean:=false;
   begin
      Tmp_Inserimento.Auto:=Auto;
      Tmp_Inserimento.Settore:=Settore;
      Tmp_Inserimento.Giro:=Giro;
      Tmp_Inserimento.Tempo_Entrata:=Tempo_Entrata;
      Tmp_Inserimento.Tempo_Uscita:=Tempo_Uscita;
      Tmp_Inserimento.Fine_Gara:=Fine_Gara;

      Cursor:=Frame_Vectors.First(Self);
      while(Frame_Vectors.Has_Element(Cursor))loop
         Tmp:=Frame_Vectors.Element(Cursor);
         if(Tmp.Auto=Tmp_Inserimento.Auto)then
            Self.Replace_Element(Position => Cursor,
                                 New_Item => Tmp_Inserimento);
            Inserito:=true;
            exit;
         end if;
         Frame_Vectors.Next(Cursor);
      end loop;
      if(Inserito=false)then
         Self.Append(Tmp_Inserimento);
      end if;

   end Inserisci_Frame;

   --Ottiene la specifica riga all'interno del vettore
   function Ottieni_Frame(Self:Frame_Vectors.Vector;Auto:Integer) return Frame_Type is
      Cursor:Frame_Vectors.Cursor;
      Tmp:Frame_Type;
      Risultato: Frame_Type;
   begin
      Risultato.Auto:=-1;
      Cursor:=Frame_Vectors.First(Self);
      while(Frame_Vectors.Has_Element(Cursor) and Risultato.Auto=-1)loop
         Tmp:=Frame_Vectors.Element(Cursor);
         if(Tmp.Auto=Auto)then
            Risultato:=Tmp;
            exit;
         end if;
         Frame_Vectors.Next(Cursor);
      end loop;

      return Risultato;
   end Ottieni_Frame;


   --Verifica che i dati di un certo pilota siano quelli indicati
   function Esiste_Frame(Self:Frame_Vectors.Vector;Auto:Integer;Settore:Integer;Giro:Integer;Fine_Gara:Boolean) return Boolean is
      Risutato:Boolean:=false;
      Cursor:Frame_Vectors.Cursor;
      Tmp:Frame_Type;
   begin

      Cursor:=Frame_Vectors.First(Self);
      while(Frame_Vectors.Has_Element(Cursor))loop
         Tmp:=Frame_Vectors.Element(Cursor);
         if(Tmp.Auto=Auto and Tmp.Settore=Settore and Tmp.Giro=giro and Tmp.Fine_Gara=Fine_Gara)then
            Risutato:=true;
            exit;
         end if;
         Frame_Vectors.Next(Cursor);
      end loop;

      return Risutato;
   end Esiste_Frame;

   --Verifica se per un determinato pilota il giro è cambiato rispetto al frame
   function Cambio_Giro(Self:Frame_Vectors.Vector;Auto:Integer;Giro:Integer) return Boolean is
      Risutato:Boolean:=false;
      Cursor:Frame_Vectors.Cursor;
      Tmp:Frame_Type;
   begin

      Cursor:=Frame_Vectors.First(Self);
      while(Frame_Vectors.Has_Element(Cursor))loop
         Tmp:=Frame_Vectors.Element(Cursor);
         if (Tmp.Auto=Auto) then
            if(Tmp.Giro/=giro) then
               Risutato:=true;
            end if;
            exit;
         end if;
         Frame_Vectors.Next(Cursor);
      end loop;

      return Risutato;

   end Cambio_Giro;
end Frame;
