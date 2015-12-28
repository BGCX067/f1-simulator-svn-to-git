
with Middleware.Websocket;
with Ada.Text_IO;
package body Middleware.Webserver is

   -- avvio webserver
   procedure Start is
   begin
      AWS.Config.Set.Reuse_Address (Config, True);
      AWS.Config.Set.Server_Host (Config,Middleware.Config.Get ("Comunicazione.webserverHost"));
      AWS.Config.Set.Server_Port (Config,Middleware.Config.Get_Integer ("Comunicazione.webserverPort"));

      Ada.Text_IO.Put_Line
        ("Webserver su:" & Middleware.Config.Get ("Comunicazione.webserverHost") & ":" & Middleware.Config.Get("Comunicazione.webserverPort"));

      Server.Start
        (WS,
         Config   => Config,
         Callback => Websocket.callback'Access);

      Net.WebSocket.Registry.Control.Start;
      Net.WebSocket.Registry.Register ("/monitor", Websocket.Create_Monitor'Access);
      Net.WebSocket.Registry.Register ("/box", Websocket.Create_Box'Access);
      Net.WebSocket.Registry.Register ("/gui", Websocket.Create_GuiSocket'Access);
   end Start;

   -- Terminazione Webserver
   procedure Stop is
   begin
      Server.Shutdown(WS);
   end Stop;

   -- invio messaggio a tutti i monitor
   procedure Invia_Monitor(dati:String) is
   begin
       Net.WebSocket.Registry.Send (Monitor,dati);
   end Invia_Monitor;

   -- invio messaggio a tutte le Gui
   procedure Invia_Gui(dati:string) is
   begin
      Net.WebSocket.Registry.Send (Gui,dati);
   end Invia_Gui;

   -- invio messaggio a tutti i box
   procedure Invia_Box(dati:String)is
   begin
       Net.WebSocket.Registry.Send (Box,dati);
   end Invia_Box;

   -- invio messaggio a tutti un determinato box
   procedure Invia_Box_Singolo(dati:string) is
   begin
      Middleware.Websocket.Invia_Box_Singolo(dati);
   end Invia_Box_Singolo;






end Middleware.Webserver;
