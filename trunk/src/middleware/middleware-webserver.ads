with AWS.Config.Set;
with AWS.Default;
with AWS.Net.Log;
with AWS.Net.WebSocket.Registry.Control;
with AWS.Server;
with AWS.Status;
with AWS.Templates;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Middleware.Websocket;
package Middleware.Webserver is

   use AWS;
   use AWS.Config;
   use type AWS.Net.Socket_Access;

   procedure Start;
   procedure Stop;
   procedure Invia_Monitor(dati:String);
   procedure Invia_Box(dati:String);
   procedure Invia_Box_Singolo(dati:string);
   procedure Invia_Gui(dati:string);
private
   -- Contiene tutti i Monitor
   Monitor : Net.WebSocket.Registry.Recipient := Net.WebSocket.Registry.Create (URI => "/monitor");
   -- Contiene tutti i Box
   Box : Net.WebSocket.Registry.Recipient := Net.WebSocket.Registry.Create (URI => "/box");
   -- Contenitore gui
   Gui : Net.WebSocket.Registry.Recipient := Net.WebSocket.Registry.Create (URI => "/gui");

   --Connessione e configurazione WebServer
   WS     : Server.HTTP;
   Config : AWS.Config.Object;
end Middleware.Webserver;
