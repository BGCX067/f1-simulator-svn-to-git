
with GNATCOLL.Traces; use GNATCOLL.Traces;

Package Logger is



   type Log_Tipo is (Middle, Coord);

   procedure Traccia(Tipo: Log_Tipo; Messaggio: String);
private
   Mid  : constant Trace_Handle:= Create ("Middle");
   C  : constant Trace_Handle:= Create ("Coord");
end Logger;
