with GNATCOLL.SQL;          use GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;     use GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Sqlite;
with GNATCOLL.SQL.Inspect;  use GNATCOLL.SQL.Inspect;
with GNATCOLL.SQL.Sessions; use GNATCOLL.SQL.Sessions;
with GNATCOLL.VFS;          use GNATCOLL.VFS;
with Database;              use Database;
with Ada.Text_IO;
with Ada.Containers.Vectors; use Ada.Containers;
with Logger;

package body Statistiche is

   --Inserimento tempo pilota
   procedure InsertTempo(giro:Integer;auto:Integer;settore:Integer;tempo:Float) is
      Q :  SQL_Query;
   begin
       Q := SQL_Insert
        ((Tempi.giro = giro )
         &(Tempi.settore= settore)
         &(Tempi.auto= auto)
         &(Tempi.tempo= tempo));

      Connessione.Execute(Q);

   end InsertTempo;

   --Ottiene il tempo di un auto in un determinato giro e settore
   function Tempo_Settore(giro:Integer;auto:Integer;settore:Integer) return Float is
      Q :  SQL_Query;
      R  : Forward_Cursor;
      Tempo:Float:=-1.0;
   begin
      --select Tempo
      --from Tempi
      --where Tempi.giro=giro and Tempi.auto=Auto and Tempi.settore=settore
      Q := SQL_Select
        (Fields => Tempi.tempo,
         From   => Tempi,
         Where => Tempi.giro = giro and Tempi.auto=auto and Tempi.settore=settore);
      Connessione.Query(Q,R);

      while R.Has_Row loop
         Tempo:=R.Float_Value (0);
         R.Next;
      end loop;
      return Tempo;
   end Tempo_Settore;

   --Ottiene il tempo piu alto tra tutti i dati salvati
   function Tempo_Fine_Gara return float is
      tmp:float:=-1.0;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select max(tempo)
      --from tempi
      Q := SQL_Select
        (Fields => Apply(Func_Max,Tempi.tempo),
         From   => Tempi);
      Connessione.Query(Q,R);
      if R.Has_Row then
         tmp:=R.Float_Value(0);
      end if;
      return tmp;

   end Tempo_Fine_Gara;

   --Tempo di un determinato pilota in un determianto giro
   function Tempo_Giro_Pilota(giro:Integer;auto:Integer) return Giro_Tempo is
      tmp:Giro_Tempo;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select max(tempo)
      --from tempi
      --where auto=auto
      Q := SQL_Select
        (Fields => Apply(Func_Max,Tempi.tempo) & Tempi.giro & Tempi.Settore,
         From   => Tempi,
         Where => Tempi.auto=auto and Tempi.giro=giro,
         Group_By => Tempi.giro);
      Connessione.Query(Q,R);
      if R.Has_Row then
         tmp.Tempo:=R.Float_Value(0);
         tmp.Giro:=R.Integer_Value(1);
         tmp.Settore:=R.Integer_Value(2);
      end if;
      return tmp;

   end Tempo_Giro_Pilota;

   --Ottieni il massimo tempo di un pilota
   function Tempo_Fine_Gara_Pilota(auto:Integer) return float is
      tmp:float:=-1.0;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select max(tempo)
      --from tempi
      --where auto=auto
      Q := SQL_Select
        (Fields => Apply(Func_Max,Tempi.tempo),
         From   => Tempi,
         Where => Tempi.auto=auto);
      Connessione.Query(Q,R);
      if R.Has_Row then
         tmp:=R.Float_Value(0);
      end if;
      return tmp;

   end Tempo_Fine_Gara_Pilota;

   --Ottiene tutti i tempi giro di un pilota fino a un certo tempogara
   function Tempi_Giri_Pilota(auto:Integer;tempogara:float:=-1.0) return Giro_Tempo_Vectors.Vector is
      laps : Giro_Tempo_Vectors.Vector;
      tmp: Giro_Tempo;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select giro, settore, max(tempo)
      --from tempi
      --where auto =auto
      --group by giro
      --order by giro asc
      Q := SQL_Select
        (Fields => Tempi.giro & Tempi.settore & Apply(Func_Max,Tempi.tempo),
         From   => Tempi,
         Where => Tempi.auto=auto,
         Group_By => Tempi.giro,
         Order_By => Asc (Tempi.giro));

      if (tempogara>0.0)then
      	Q:=Q.Where_And(Where => Tempi.Tempo<=tempogara);
      end if;

      Connessione.Query(Q,R);
      while R.Has_Row loop
         tmp.Giro:=R.Integer_Value(0);
         tmp.Settore:=R.Integer_Value(1);
         tmp.Tempo:=R.Float_Value(2);
         laps.Append(tmp);
         R.Next;
      end loop;
      return laps;
   end Tempi_Giri_Pilota;

   --Tempi di tutti i settori di un pilota
   function Tempi_Settori_Pilota(auto:Integer) return Giro_Tempo_Vectors.Vector is
      Tempi_Settore : Giro_Tempo_Vectors.Vector;
      Tmp: Giro_Tempo;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select giro, settore, tempo
      --from tempi
      --where auto =auto
      --order by tempo asc
      Q := SQL_Select
        (Fields => Tempi.giro & Tempi.settore & Tempi.tempo,
         From   => Tempi,
         Where => Tempi.auto=auto,
         Order_By => Asc (Tempi.tempo));


      Connessione.Query(Q,R);
      while R.Has_Row loop
         Tmp.Giro:=R.Integer_Value(0);
         Tmp.Settore:=R.Integer_Value(1);
         Tmp.Tempo:=R.Float_Value(2);
         Tempi_Settore.Append(Tmp);
         R.Next;
      end loop;
      return Tempi_Settore;
   end Tempi_Settori_Pilota;

   --Ottiene per ogni pilota il tempo giro settore appena precedente al tempo gara
   function Tempi_Settore_Istantanea_Entrata(tempogara:Float) return AGSTempo_Vectors.Vector is
      Tempi_Giro: AGSTempo_Vectors.Vector;
      tmp: AGSTempo;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select giro, settore, auto, MAx(tempo)
      --from tempi t
      --where tempo<=tempogara
      --group by  auto

      Q := SQL_Select
        (Fields => Tempi.giro & Tempi.settore & Tempi.auto & Apply(Func_Max,Tempi.tempo),
         From   => Tempi,
         Where => Tempi.Tempo<=tempogara,
         Group_By => Tempi.auto);
      Connessione.Query(Q,R);
      while R.Has_Row loop
         tmp.Giro:=R.Integer_Value(0);
         tmp.Settore:=R.Integer_Value(1);
         tmp.Auto:=R.Integer_Value(2);
         tmp.Tempo:=R.Float_Value(3);
         Tempi_Giro.Append(tmp);
         R.Next;
      end loop;

      return Tempi_Giro;
   end Tempi_Settore_Istantanea_Entrata;


   --Ottiene per ogni pilota il tempo giro settore appena successivo al tempo gara
   function Tempi_Settore_Istantanea_Uscita(tempogara:Float) return AGSTempo_Vectors.Vector is
      Tempi_Giro: AGSTempo_Vectors.Vector;
      tmp: AGSTempo;
      Q :  SQL_Query;
      R  : Forward_Cursor;
   begin
      --select giro, settore, auto, MIN(tempo)
      --from tempi t
      --where tempo>=tempogara
      --group by  auto

      Q := SQL_Select
        (Fields => Tempi.giro & Tempi.settore & Tempi.auto & Apply(Func_Min,Tempi.tempo),
         From   => Tempi,
         Where => Tempi.Tempo>tempogara,
         Group_By => Tempi.auto);
      Connessione.Query(Q,R);
      while R.Has_Row loop
         tmp.Giro:=R.Integer_Value(0);
         tmp.Settore:=R.Integer_Value(1);
         tmp.Auto:=R.Integer_Value(2);
         tmp.Tempo:=R.Float_Value(3);
         Tempi_Giro.Append(tmp);
         R.Next;

      end loop;

      return Tempi_Giro;
   end Tempi_Settore_Istantanea_Uscita;

   --Ottiene i tempi dei checkpoint di un auto in un certo intervallo di giri(giros,girof) entro un certo limite di tempogara
   function Tempo_Settori_Check(auto:Integer;giros:Integer;girof:Integer;tempogara:Float;settori_check:Integer_Vector.Vector) return Giro_Tempo_Vectors.Vector is
      Risultato: Giro_Tempo_Vectors.Vector;
      Q :  SQL_Query;
      Crit_Or:SQL_Criteria:=No_Criteria;
      R  : Forward_Cursor;
      Integer_Cursor: Integer_Vector.Cursor;
      Set_Check:Integer;
      tmp: Giro_Tempo;
   begin
      --select giro, settore, tempo
      --from tempi t
      --where tempi.auto>=auto
      --and tempi.giro>giros and tempi.giro<girof
      --and settore=set1 or settore =set2

      Q := SQL_Select
        (Fields => Tempi.giro & Tempi.settore & Tempi.tempo,
         From   => Tempi,
         Where => Tempi.auto=auto and Tempi.Giro>=giros and Tempi.Giro<=girof and Tempi.Tempo<=tempogara);

      Integer_Cursor:=Integer_Vector.First(settori_check);
      while Integer_Vector.Has_Element(Integer_Cursor) loop
         Set_Check:=Integer_Vector.Element(Integer_Cursor);

         --Q.Where_And(Where => Tempi.Settore=1);
         Crit_Or:=Crit_Or or Tempi.Settore=Set_Check;

         Integer_Vector.Next(Integer_Cursor);
      end loop;
      Q:=Q.Where_And(Crit_Or);

      Connessione.Query(Q,R);
      while R.Has_Row loop
         tmp.Giro:=R.Integer_Value(0);
         tmp.Settore:=R.Integer_Value(1);
         tmp.Tempo:=R.Float_Value(2);
         Risultato.Append(tmp);
         R.Next;
         --Logger.Traccia(Logger.Middle,"G S T: "& Integer'Image(tmp.Giro) & " " & Integer'Image(tmp.Settore) & " " & Float'Image(tmp.Tempo));
      end loop;

      return Risultato;
   end Tempo_Settori_Check;

   --Chiudo la connessione al db
   procedure Stop is
   begin
      Connessione.Stop;
   end Stop;

   --Cancella il contenuto del db
   procedure Resetta is
      Q :  SQL_Query;
   begin
      Q:= SQL_Delete
        (From  => Tempi);
      Connessione.Execute(Q);
   end Resetta;


   Protected body DB_Connessione  is
      entry Execute(Q :  SQL_Query) when true is
      begin
         Execute (DB, Q);
         DB.Commit;
      end Execute;

      --esegue la query Q e restituisce il risultato R
      entry Query(Q :  SQL_Query; R : in out Forward_Cursor) when true is
      begin
         R.Fetch (DB, Q);
      end Query;

      --Connessione al Database
      entry Connetti when true is
      begin
         DB_Descr := GNATCOLL.SQL.Sqlite.Setup ("prova.db");
         DB := DB_Descr.Build_Connection;
      end Connetti;

      --Chiude il database
      entry Stop when true is
      begin
         Free (DB);
         Free (DB_Descr);
      end Stop;
   end DB_Connessione;

begin
   Connessione.Connetti;

   --cancello tutto il db
   Resetta;


end Statistiche;
