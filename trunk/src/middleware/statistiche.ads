
with GNATCOLL.SQL;          use GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;     use GNATCOLL.SQL.Exec;
with GNATCOLL.SQL.Sqlite;
with GNATCOLL.SQL.Inspect;  use GNATCOLL.SQL.Inspect;
with GNATCOLL.SQL.Sessions; use GNATCOLL.SQL.Sessions;
with GNATCOLL.VFS;          use GNATCOLL.VFS;
with Ada.Containers.Vectors; use Ada.Containers;

-- Gestione dei tempi piloti nel database utilizzando SQLite
package Statistiche is

   type Giro_Tempo is record
      Giro: Integer;
      Settore: Integer;
      Tempo: Float;
   end record;
   package Giro_Tempo_Vectors is new Vectors(Natural, Giro_Tempo);

   type AGSTempo is record
      Giro: Integer;
      Settore: Integer;
      Auto: Integer;
      Tempo: Float;
   end record;
   package AGSTempo_Vectors is new Vectors(Natural, AGSTempo);
   package Integer_Vector is new Vectors(Natural, Integer);

   --risorsa protetta che serializza l'accesso al database
   Protected type DB_Connessione  is
      entry Execute(Q :  SQL_Query);
      entry Query(Q :  SQL_Query; R : in out Forward_Cursor);
      entry Connetti;
      entry Stop;
   private
      DB_Descr : GNATCOLL.SQL.Exec.Database_Description;
      DB : Database_Connection;
   end DB_Connessione;
   Connessione: DB_Connessione;

   procedure InsertTempo(giro:Integer;auto:Integer;settore:Integer;tempo:Float);
   function Tempo_Settore(giro:Integer;auto:Integer;settore:Integer) return Float;
   function Tempi_Giri_Pilota(auto:Integer;tempogara:float:=-1.0) return Giro_Tempo_Vectors.Vector;
   function Tempi_Settori_Pilota(auto:Integer) return Giro_Tempo_Vectors.Vector;
   function Tempo_Fine_Gara return float;
   function Tempo_Settori_Check(auto:Integer;giros:Integer;girof:Integer;tempogara:Float;settori_check:Integer_Vector.Vector) return Giro_Tempo_Vectors.Vector;
   function Tempo_Giro_Pilota(giro:Integer;auto:Integer) return Giro_Tempo;
   function Tempo_Fine_Gara_Pilota(auto:Integer) return float;
   function Tempi_Settore_Istantanea_Uscita(tempogara:Float) return AGSTempo_Vectors.Vector;
   function Tempi_Settore_Istantanea_Entrata(tempogara:Float) return AGSTempo_Vectors.Vector;
   procedure Resetta;
   procedure Stop;


end Statistiche;
