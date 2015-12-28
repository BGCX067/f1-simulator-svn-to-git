with Ada.Streams;

with AWS.Net.Log;
with AWS.Response;
with AWS.Status;

with AWS.Net.WebSocket;

package Middleware.Websocket is

   use Ada.Streams;
   use AWS;


   function callback (Request : Status.Data) return Response.Data;


   type Object is new AWS.Net.WebSocket.Object with private;

   function Create_Monitor
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class;

   function Create_Box
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class;

   function Create_GuiSocket
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class;


   overriding procedure On_Message (Socket : in out Object; Message : String);
   --  Messaggio ricevuto dal server

   overriding procedure On_Open (Socket : in out Object; Message : String);
   --  E' stato aperto un websocket

   overriding procedure On_Close (Socket : in out Object; Message : String);
   --  è stato chiuso un websocket

   overriding procedure Send (Socket : in out Object; Message : String);
   --  Invia un messaggio

   overriding procedure On_Error(Socket : in out Object; Message : String);
   -- sull'errore

   procedure Invia_Box_Singolo(dati:string);
   function Ottieni_Socket(auto:Integer) return Object;

private
   procedure Inserisci_Associazione(auto:Integer; websocket:Object);
   procedure Rimuovi_Associazione(websocket:Object);
   function Verifica_Associazione(auto:Integer) return Boolean;
   type Object is new Net.WebSocket.Object with record
      Tipo: Unbounded_String ;
   end record;

   function Invia_Settori_Box(auto:Integer) return String;

   type Box_Auto is record
      auto:Integer;
      websocket: Object;
   end record;
   package Box_Auto_Vectors is new Vectors(Natural, Box_Auto);

   Associazione_Box_Auto: Box_Auto_Vectors.Vector;


end Middleware.Websocket;
