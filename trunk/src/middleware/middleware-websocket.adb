with Ada.Characters.Handling;
with Ada.Integer_Text_IO;
with Ada.Text_IO;
with Ada.Directories;

with AWS.Messages;
with AWS.MIME;
with AWS.Templates;
with AWS.Translator;
with Middleware.Webserver;
with GNATCOLL.JSON; use GNATCOLL.JSON;
with Statistiche;
with Logger;



package body Middleware.Websocket is

   use Ada;
   use type AWS.Net.WebSocket.Kind_Type;

   WWW_Root : constant String := "../../web";

   -- Creazione Websocket Monitor
   function Create_Monitor
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class is
   begin
      return Object'(Net.WebSocket.Object
                       (Net.WebSocket.Create (Socket, Request)) with Tipo => Ada.Strings.Unbounded.To_Unbounded_String("Monitor") );
   end Create_Monitor;

   -- Creazione Websocket Box
   function Create_Box
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class is
   begin
      return Object'(Net.WebSocket.Object
                       (Net.WebSocket.Create (Socket, Request)) with Tipo => Ada.Strings.Unbounded.To_Unbounded_String("Box"));
   end Create_Box;

   -- Creazione Websocket Gui
   function Create_GuiSocket
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class is
   begin
      return Object'(Net.WebSocket.Object
                       (Net.WebSocket.Create (Socket, Request)) with Tipo => Ada.Strings.Unbounded.To_Unbounded_String("GuiSocket"));
   end Create_GuiSocket;

   -- Callback alla richiesta di una determinata risorsa (URI)
   function callback (Request : Status.Data) return Response.Data is
      URI      : constant String := Status.URI (Request);
      Filename : constant String := URI (URI'First + 1 .. URI'Last);
      Extension : Unbounded_String := To_Unbounded_String("/");

   begin
      if(URI'Last>3) then
         Extension := To_Unbounded_String(URI (URI'Last - 3 .. URI'Last));
      end if;
      Logger.Traccia(Logger.Middle,String'(URI));
      Logger.Traccia(Logger.Middle,String'(Filename));


      If URI="/" or URI="/index.html" or URI="/index.htm" then
         return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/index.html")));
      elsif URI= "/monitor.html" then
         return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/monitor.html")));
      elsif URI= "/box.html" then
      	 return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/box.html")));
      elsif Extension = ".jpg" then
         if(Ada.Directories.Exists(WWW_Root & URI)) then
            return AWS.Response.File ("image/jpg", WWW_Root & URI);
         else
            return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/404.html")), Status_Code   => AWS.Messages.S404);
         end if;
      elsif Extension = ".png" then
         if(Ada.Directories.Exists(WWW_Root & URI)) then

            return AWS.Response.File ("image/png", WWW_Root & URI);
         else
            return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/404.html")), Status_Code   => AWS.Messages.S404);
         end if;
      end if;
      -- in tutti gli altri casi la pagina nn è presente mostro pagina errore 404
      return Response.Build ("text/html", String'(Templates.Parse (WWW_Root & "/404.html")), Status_Code   => AWS.Messages.S404);
   end callback;

   -- Chiusura websocket
   overriding procedure On_Close (Socket : in out Object; Message : String) is
   begin
      Logger.Traccia(Logger.Middle,"Websocket Close: "
                     & Net.WebSocket.Error_Type'Image (Socket.Error) & ", " & Message);

      if(Socket.Tipo = "Box") then
         Logger.Traccia(Logger.Middle,"Box Chiuso");
         Rimuovi_Associazione(Socket);

      elsif(Socket.Tipo = "Monitor") then
         Logger.Traccia(Logger.Middle,"Monitor Chiuso");
      end if;

   end On_Close;

   -- Ricevuto messaggio da un Websocket
   overriding procedure On_Message
     (Socket : in out Object; Message : String) is
      Tipo: Integer;
      Responce: JSON_Value;
      Conf:ConfigurazioniAuto_Mid.Configurazione_Auto_Box;

      s:Unbounded_String;
      Xml: Dati_Inizio_Gara;
      Socket_Box: Object;
      Concorrenti_Cursor: Auto_Desc_Vectors.Cursor;
      Concorrenti_Tmp:Auto_Desc;
   begin
      Logger.Traccia(Logger.Middle,"Received : " & Message);

      if(Socket.Tipo = "Box") then--messaggi dai box
         Myobj:=Read(Message,"json.errors");
         Logger.Traccia(Logger.Middle,Myobj.Write);

         Tipo:=Get(Myobj,"tipo");
         Logger.Traccia(Logger.Middle,"Tipo: " & Integer'Image(Tipo));

         if(Tipo=0) then--richiesta associazione
            Responce:=Create_Object;
            Responce.Set_Field("tipo",4);

            Socket_Box:=Ottieni_Socket(Get(Myobj,"auto"));
            if(Socket_Box.Tipo/="Box") then--risposta associazione fatta

               Inserisci_Associazione(Get(Myobj,"auto"),Socket);
               Responce.Set_Field("esito",True);
               Socket.Send(Responce.Write);


               --invio configurazione
               Concorrenti_Cursor:= Auto_Desc_Vectors.First(Concorrenti);
               while Auto_Desc_Vectors.Has_Element(Concorrenti_Cursor) loop
                  Concorrenti_Tmp:=Auto_Desc_Vectors.Element(Concorrenti_Cursor);
                  if(Concorrenti_Tmp.Id_Auto=Get(Myobj,"auto") and Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Id_Auto))/=-1) then
                     Responce:=Create_Object;
                     Responce.Set_Field("tipo",5);
                     Responce.Set_Field("auto",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Id_Auto)));
                     Responce.Set_Field("gomme",Concorrenti_Tmp.Configurazione.Gomme);
                     Responce.Set_Field("usuragomme",Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Concorrenti_Tmp.Configurazione.Usura_Gomme)));
                     Responce.Set_Field("gommepitstop",Concorrenti_Tmp.Configurazione.Gomme_Pitstop);
                     Responce.Set_Field("usuragommestop",Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Concorrenti_Tmp.Configurazione.Usura_Gomme_Stop)));
                     Responce.Set_Field("livellobenzina",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Livello_Benzina)));
                     Responce.Set_Field("livellobenzinastop",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Livello_Benzina_Stop)));
                     Responce.Set_Field("livellobenzinapitstop",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Livello_Benzina_Pitstop)));
                     Responce.Set_Field("livellodanni",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Livello_Danni)));
                     Responce.Set_Field("entratabox",Concorrenti_Tmp.Configurazione.Entrata_Box);
                     Responce.Set_Field("potenza",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Potenza)));
                     Responce.Set_Field("bravurapilota",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Concorrenti_Tmp.Configurazione.Bravura_Pilota)));
                     Responce.Set_Field("nomescuderia",Concorrenti_Tmp.Configurazione.Nome_Scuderia);
                     Responce.Set_Field("nomeplota",Concorrenti_Tmp.Configurazione.Nome_Pilota);
                     Socket.Send(Responce.Write);

                     exit;
                  end if;
                  Auto_Desc_Vectors.Next(Concorrenti_Cursor);
               end loop;

               --Invia settori precedenti
               Socket.Send(Invia_Settori_Box(Get(Myobj,"auto")));
            else--risposta gia presente rifiutata

               Responce.Set_Field("esito",False);

               Socket.Send(Responce.Write);
               Logger.Traccia(Logger.Middle,Responce.Write);

            end if;
         elsif (Tipo=1) then
            Conf.Id_Auto:=YAMI.Parameters.YAMI_Integer'Value(Integer'Image(Get(Myobj,"auto")));
            Conf.Gomme_Pitstop:=Get(Myobj,"gomme");
            Conf.Usura_Gomme_Stop:=YAMI.Parameters.YAMI_Integer'Value(Integer'Image(Get(Myobj,"usura_stop")));
            Conf.Livello_Benzina_Stop:=YAMI.Parameters.YAMI_Integer'Value(Integer'Image(Get(Myobj,"livello_stop")));
            Conf.Livello_Benzina_Pitstop:=YAMI.Parameters.YAMI_Integer'Value(Integer'Image(Get(Myobj,"livello_rifornimento")));
            Conf.Entrata_Box:=Get(Myobj,"entrata_obbligatoria");

            if(Coordinatore_Stato) then
               Coordinatore.Comunica_Aggiornamenti(Conf);
            end if;
         end if;

      elsif(Socket.Tipo = "GuiSocket") then--messaggi dalla gui
         Logger.Traccia(Logger.Middle,"Dentro if socketGui");
         Myobj:=Read(Message,"json.errors");
         --Logger.Traccia(Logger.Middle,Myobj.Write);
         Tipo:=Get(Myobj,"tipo");
         if(Tipo=1) then--caricamento file xml
            --resetgara
            --reset dati iniziali
            Dati_Gara.Nome_Pista:=To_Unbounded_String("");
            Dati_Gara.Numero_Giri:=0;
            Dati_Gara.Numero_Settori:=0;
            Dati_Gara.Numero_Auto_Tot:=0;
            Dati_Gara.Meteo:=0;
            Dati_Gara.Fine_Gara:=False;
            Primo_dato:=0;
            Gara_Finita:=False;
            --reset lista concorrenti
            Concorrenti.Clear;
            --reset associazione Box auto
            Associazione_Box_Auto.Clear;
            -- reset database tempi
            Statistiche.Resetta;

            Logger.Traccia(Logger.Middle,"Gara finita? " & Boolean'Image(Gara_Finita));

            s:=Get(Myobj,"pista");

            Logger.Traccia(Logger.Middle,"pista: " & To_String(s));

            Xml.Xml_Data:=s;

            Logger.Traccia(Logger.Middle,"Prima di invio: ");
            if(Coordinatore_Stato) then
               Coordinatore.Comunica_Dati_Iniziali(Xml);
            end if;
            Logger.Traccia(Logger.Middle,"Dopo di invio: ");
         elsif(Tipo=2) then--avvio gara
            if(Coordinatore_Stato) then
               Coordinatore.Avvio;
            end if;
         elsif(Tipo=3) then--termina programma
            if(Coordinatore_Stato) then
               Coordinatore.Termina_Comunicazioni;
            end if;
            Middleware.Foto_Loop.Chiudi;
            Middleware.Stato_Programma.Chiudi_Programma;
         end if;
      end if;

   end On_Message;


   -- Apertura nuovo Websocket
   overriding procedure On_Open (Socket : in out Object; Message : String) is
      tmp: Auto_Desc;
      Laps : Statistiche.Giro_Tempo_Vectors.Vector;
      Lap: Statistiche.Giro_Tempo;
      Laps_Cursor : Statistiche.Giro_Tempo_Vectors.Cursor;

      --per la creazione di array json
      Array_Obj_Json : JSON_Value;
      Array_Json : JSON_Array;

      Array_Obj_Gara : JSON_Value;
      Array_Gara : JSON_Array;

      Tempo_Prec: Float;
      Tot_Giri: Integer:=-1;

      Frame: Middleware.UString.Vector;
      Frame_Messaggio: Unbounded_String;
      Cursor_Frame: Middleware.UString.Cursor;

      Cursor_Check:Statistiche.Integer_Vector.Cursor;

      Checkpoint:Integer;
      Cursor : Auto_Desc_Vectors.Cursor;
      Cursor_Concorrenti : Auto_Desc_Vectors.Cursor;
   begin
      if(Socket.Tipo = "Box") then
         Logger.Traccia(Logger.Middle,"Aperto socket box");

         Cursor := Auto_Desc_Vectors.First(Concorrenti);
         if Auto_Desc_Vectors.Has_Element(Cursor) then
            --reinvio dati iniziali gara
            Myobj:=Create_Object;
            Myobj.Set_Field("tipo",0);
            Myobj.Set_Field("nomepista",Dati_Gara.Nome_Pista);
            Myobj.Set_Field("numerogiri",Dati_Gara.Numero_Giri);
            Myobj.Set_Field("numerosettori",Dati_Gara.Numero_Settori);
            Myobj.Set_Field("numeroautotot",Dati_Gara.Numero_Auto_Tot);
            Myobj.Set_Field("meteo",Dati_Gara.Meteo);

            Array_Json :=Empty_Array;--set checkpoint
            Cursor_Check:=Dati_Gara.Settori_CheckPoint.First;
            while Statistiche.Integer_Vector.Has_Element(Cursor_Check) loop
               Checkpoint:=Statistiche.Integer_Vector.Element(Cursor_Check);
               if(Checkpoint<=Dati_Gara.Numero_Settori) then
               Array_Obj_Json:=Create_Object;
               Array_Obj_Json.Set_Field("settore",Checkpoint);
               Append (Arr => Array_Json,
                       Val => Array_Obj_Json);
               end if;
               Statistiche.Integer_Vector.Next(Cursor_Check);
            end loop;
            Myobj.Set_Field("checkpoint",Array_Json);


            Send(Socket,Myobj.Write);
            Logger.Traccia(Logger.Middle,Myobj.Write);

            --reinvio dati iniziali piloti
            while Auto_Desc_Vectors.Has_Element(Cursor) loop
               tmp:=Auto_Desc_Vectors.Element(Cursor);
               Myobj:=Create_Object;
               Myobj.Set_Field("tipo",1);
               Myobj.Set_Field("auto",tmp.Id_Auto);
               Myobj.Set_Field("nome",tmp.Nome);
               Myobj.Set_Field("scuderia",tmp.Scuderia);
               Send(Socket,Myobj.Write);

               Logger.Traccia(Logger.Middle,Myobj.Write);
               Auto_Desc_Vectors.Next(Cursor);
            end loop;

         end if;
      elsif(Socket.Tipo = "Monitor") then
         Text_IO.Put_Line ("Aperto socket Monitor");

         Cursor := Auto_Desc_Vectors.First(Concorrenti);
         if Auto_Desc_Vectors.Has_Element(Cursor) then
            --reinvio dati iniziali gara
            Myobj:=Create_Object;
            Myobj.Set_Field("tipo",0);
            Myobj.Set_Field("nomepista",Dati_Gara.Nome_Pista);
            Myobj.Set_Field("numerogiri",Dati_Gara.Numero_Giri);
            Myobj.Set_Field("numerosettori",Dati_Gara.Numero_Settori);
            Myobj.Set_Field("numeroautotot",Dati_Gara.Numero_Auto_Tot);
            Myobj.Set_Field("meteo",Dati_Gara.Meteo);

            Array_Json :=Empty_Array;--set checkpoint
            Cursor_Check:=Dati_Gara.Settori_CheckPoint.First;
            while Statistiche.Integer_Vector.Has_Element(Cursor_Check) loop
               Checkpoint:=Statistiche.Integer_Vector.Element(Cursor_Check);
               if(Checkpoint<=Dati_Gara.Numero_Settori) then
               Array_Obj_Json:=Create_Object;
               Array_Obj_Json.Set_Field("settore",Checkpoint);
               Append (Arr => Array_Json,
                       Val => Array_Obj_Json);
               end if;
               Statistiche.Integer_Vector.Next(Cursor_Check);
            end loop;
            Myobj.Set_Field("checkpoint",Array_Json);


            Send(Socket,Myobj.Write);
            Logger.Traccia(Logger.Middle,Myobj.Write);
            Cursor_Concorrenti:=Auto_Desc_Vectors.First(Concorrenti);
            while Auto_Desc_Vectors.Has_Element(Cursor_Concorrenti) loop
               tmp:=Auto_Desc_Vectors.Element(Cursor_Concorrenti);
               Myobj:=Create_Object;
               Myobj.Set_Field("tipo",1);
               Myobj.Set_Field("auto",tmp.Id_Auto);
               Myobj.Set_Field("nome",tmp.Nome);
               Myobj.Set_Field("scuderia",tmp.Scuderia);
               Send(Socket,Myobj.Write);

               Logger.Traccia(Logger.Middle,Myobj.Write);
               Auto_Desc_Vectors.Next(Cursor_Concorrenti);
            end loop;



            --Invio frame completo
            if(Middleware.Stato_Loop_Task=True) then--gara in corso
               Middleware.Foto_Loop.Frame_On_Open(Frame);
               Logger.Traccia(Logger.Middle,"ONPEN FRAME----------------------");
               Cursor_Frame:=Middleware.UString.First(Frame);
               while Middleware.UString.Has_Element(Cursor_Frame) loop
                  Frame_Messaggio:=Middleware.UString.Element(Cursor_Frame);

                  Logger.Traccia(Logger.Middle,To_String(Frame_Messaggio));
                  Send(Socket,To_String(Frame_Messaggio));

                  Middleware.UString.Next(Cursor_Frame);
               end loop;
               Logger.Traccia(Logger.Middle,"ONPEN FRAME SEND----------------------");
            end if;

            if(Dati_Gara.Fine_Gara) then
               Logger.Traccia(Logger.Middle,"Dentro Fine Gara------------------------");

               Array_Gara:=Empty_Array;

               Myobj:=Create_Object;
               Myobj.Set_Field("tipo",10);
               Myobj.Set_Field("numeroautotot",Dati_Gara.Numero_Auto_Tot);
               Myobj.Set_Field("numerogiri",Dati_Gara.Numero_Giri);
               Myobj.Set_Field("numerosettori",Dati_Gara.Numero_Settori);
               while Auto_Desc_Vectors.Has_Element(Cursor) loop
                  tmp:=Auto_Desc_Vectors.Element(Cursor);

                  Array_Obj_Gara:=Create_Object;
                  Array_Obj_Gara.Set_Field("auto",tmp.Id_Auto);
                  Array_Obj_Gara.Set_Field("nome",tmp.Nome);
                  Array_Obj_Gara.Set_Field("scuderia",tmp.Scuderia);

                  Array_Json := Empty_Array;

                  Laps:=Statistiche.Tempi_Giri_Pilota(tmp.Id_Auto);
                  Laps_Cursor:=Statistiche.Giro_Tempo_Vectors.First(Laps);

                  --controllo che ci sia almeno 1 giro
                  if(Statistiche.Giro_Tempo_Vectors.Has_Element(Laps_Cursor)) then

                     --estraggo il primo giro , giro 0 iniziale
                     Lap:=Statistiche.Giro_Tempo_Vectors.Element(Laps_Cursor);
                     Tempo_Prec:=Lap.Tempo;
                     Statistiche.Giro_Tempo_Vectors.Next(Laps_Cursor);
                     --estrazione degli eventuali altri giri
                     Tot_giri:=0;
                     while Statistiche.Giro_Tempo_Vectors.Has_Element(Laps_Cursor) loop
                        Lap:=Statistiche.Giro_Tempo_Vectors.Element(Laps_Cursor);


                        Array_Obj_Json:=Create_Object;
                        Array_Obj_Json.Set_Field("giro",Lap.Giro);

                        if(Lap.giro<=1)then-- il primo giro
                           Array_Obj_Json.Set_Field("tempo",Lap.Tempo);
                        else-- gli altri giri
                           Array_Obj_Json.Set_Field("tempo",Lap.Tempo-Tempo_Prec);
                        end if;
                        Tempo_prec:=Lap.Tempo;

                        if(Lap.Settore=Dati_Gara.Numero_Settori)then --giro senza boxx
                           Array_Obj_Json.Set_Field("sosta",False);
                           Append (Arr => Array_Json,
                                   Val => Array_Obj_Json);
                           Tot_giri:=Tot_giri+1;

                        elsif(Lap.Settore=Dati_Gara.Numero_Settori+1) then --giro con sosta box
                           Array_Obj_Json.Set_Field("sosta",True);
                           Append (Arr => Array_Json,
                                   Val => Array_Obj_Json);
                           Tot_giri:=Tot_giri+1;

                        end if;
                        --Se non rientra nei casi precedenti il giro non è completo e non lo reporto
                        Statistiche.Giro_Tempo_Vectors.Next(Laps_Cursor);
                     end loop;
                     Array_Obj_Gara.Set_Field("giri",Array_Json);
                     Logger.Traccia(Logger.Middle,"prima di appenda arraygara");

                     Append (Arr => Array_Gara,
                             Val => Array_Obj_Gara);
                  end if;
                     Logger.Traccia(Logger.Middle,"id: "& Integer'Image(tmp.Id_Auto));

                  Auto_Desc_Vectors.Next(Cursor);
               end loop;
               Myobj.Set_Field("gara",Array_Gara);

               --stampo a video
               Logger.Traccia(Logger.Middle,Myobj.Write);

               --Invio al monitor
               Send(Socket,Myobj.Write);
            end if;

         end if;

      elsif(Socket.Tipo = "GuiSocket") then

         Logger.Traccia(Logger.Middle,"un Gui Socket è stato aperto");
      end if;

   end On_Open;

   --Errore sul Websocket
   overriding procedure On_Error(Socket : in out Object; Message : String) is
   begin

      Logger.Traccia(Logger.Middle,"Errore websocket: " & Net.WebSocket.Error_Type'Image (Socket.Error) & ", " & Message);

      --Chrome quando chiudi o reloddi un tab nn invoca on_close ma on_errore gestisco questo caso
      if (Message = "Receive : Socket closed by peer") then
         if(Socket.Tipo = "Box") then
            Logger.Traccia(Logger.Middle,"Box Chiuso");

            Rimuovi_Associazione(Socket);

         elsif(Socket.Tipo = "Monitor") then
            Logger.Traccia(Logger.Middle,"Monitor Chiuso");
         end if;
      end if;



   end On_Error;


   -- Invio messaggio al singolo socket
   overriding procedure Send (Socket : in out Object; Message : String) is
   begin
      -- Invio del messaggio
      Net.WebSocket.Object (Socket).Send (Message);
   end Send;

   --inserisce una associazione nell'array se non è gia presente, se c'è gia la rimpiazza
   procedure Inserisci_Associazione(auto:Integer; websocket:Object) is
      Cursor:Box_Auto_Vectors.Cursor;
      Tmp:Box_Auto;
      Rimpiazzo:Box_Auto;
      Rimpiazzato:Boolean:=false;
   begin
      Rimpiazzo.auto:=auto;
      Rimpiazzo.websocket:=websocket;
      Cursor:=Box_Auto_Vectors.First(Associazione_Box_Auto);
      while Box_Auto_Vectors.Has_Element(Cursor) loop
         Tmp:=Box_Auto_Vectors.Element(Cursor);
         if(Tmp.auto=Rimpiazzo.auto) then--rimpiazzo elemento
            Associazione_Box_Auto.Replace_Element(Position => Cursor,
                                                  New_Item => Rimpiazzo);
            Rimpiazzato:=true;
            exit;
         end if;

         Box_Auto_Vectors.Next(Cursor);
      end loop;
      if(Rimpiazzato=false) then--Se l'elemento nn è presente lo inserisco
         Associazione_Box_Auto.Append(Rimpiazzo);
      end if;
   end Inserisci_Associazione;

   --rimuove associazione se presente
   procedure Rimuovi_Associazione(websocket:Object) is
      Cursor:Box_Auto_Vectors.Cursor;
      Tmp:Box_Auto;
   begin
      Cursor:=Box_Auto_Vectors.First(Associazione_Box_Auto);
      while Box_Auto_Vectors.Has_Element(Cursor) loop
         Tmp:=Box_Auto_Vectors.Element(Cursor);
         if(Tmp.websocket=Websocket) then--rimuovo elemento
            Associazione_Box_Auto.Delete(Cursor);
            exit;
         end if;
         Box_Auto_Vectors.Next(Cursor);
      end loop;
   end Rimuovi_Associazione;

   --ottengo un determinato Websocket dall'associazione Box/Websocket
   function Ottieni_Socket(auto:Integer) return Object is
      Risultato:Object;
      Cursor:Box_Auto_Vectors.Cursor;
      Tmp:Box_Auto;
   begin

      Cursor:=Box_Auto_Vectors.First(Associazione_Box_Auto);
      while Box_Auto_Vectors.Has_Element(Cursor) loop
         Tmp:=Box_Auto_Vectors.Element(Cursor);
         if(Tmp.auto=auto) then--rimpiazzo elemento
            Risultato:=Tmp.websocket;
            exit;
         end if;
         Box_Auto_Vectors.Next(Cursor);
      end loop;


      return Risultato;
   end Ottieni_Socket;

   --Verifico che esista un associazione Box/websocket
   function Verifica_Associazione(auto:Integer) return Boolean is
      Risultato:Boolean:=false;
      Cursor:Box_Auto_Vectors.Cursor;
      Tmp:Box_Auto;
   begin
      Cursor:=Box_Auto_Vectors.First(Associazione_Box_Auto);
      while Box_Auto_Vectors.Has_Element(Cursor) loop
         Tmp:=Box_Auto_Vectors.Element(Cursor);
         if(Tmp.auto=auto) then--rimpiazzo elemento
            Risultato:=true;
            exit;
         end if;
         Box_Auto_Vectors.Next(Cursor);
      end loop;

      return Risultato;
   end Verifica_Associazione;

   --Invio a singolo Box
   procedure Invia_Box_Singolo(dati:string) is
      auto: Integer;
      Socket_Box: Object;
   begin

      auto:=Get(Myobj,"auto");
      Socket_Box:=Ottieni_Socket(auto);
      if(Socket_Box.Tipo="Box") then
         Socket_Box.Send(dati);
      end if;


   end Invia_Box_Singolo;

   --Calcola tutti i settore precedenti di una certa auto e ne ritorna il messaggio JSON
   function Invia_Settori_Box(auto:Integer) return String is
      Tempi_Settori: Statistiche.Giro_Tempo_Vectors.Vector;
      Tempi_Settori_Cursor: Statistiche.Giro_Tempo_Vectors.Cursor;
      Tmp: Statistiche.Giro_Tempo;
      Tmp_Succ: Statistiche.Giro_Tempo;

      Tempo_Prec: Float;
      Giro_Prec: Integer;
      Uscita: Boolean:=false;

      --per la creazione di array json
      Array_Obj_Json : JSON_Value;
      Array_Json : JSON_Array;
      Array_Obj_Json_Settore : JSON_Value;
      Array_Json_Settore : JSON_Array;
   begin

      Tempi_Settori:=Statistiche.Tempi_Settori_Pilota(auto);
      Tempi_Settori_Cursor:=Statistiche.Giro_Tempo_Vectors.First(Tempi_Settori);


      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",9);
      while Statistiche.Giro_Tempo_Vectors.Has_Element(Tempi_Settori_Cursor) loop
         Tmp:=Statistiche.Giro_Tempo_Vectors.Element(Tempi_Settori_Cursor);

         if(tmp.Giro=0) then
            Giro_Prec:=Tmp.Giro;
            Tempo_Prec:=Tmp.Tempo;
            Statistiche.Giro_Tempo_Vectors.Next(Tempi_Settori_Cursor);
         else
            Array_Obj_Json:=Create_Object;
            Array_Obj_Json.Set_Field("giro",Tmp.Giro);

            Array_Obj_Json_Settore:=Create_Object;
            Array_Json_Settore:=Empty_Array;
            Array_Obj_Json_Settore.Set_Field("settore",Tmp.Settore);
            Array_Obj_Json_Settore.Set_Field("tempo",Tmp.Tempo-Tempo_Prec);
            Append (Arr => Array_Json_Settore,
                    Val => Array_Obj_Json_Settore);


            Giro_Prec:=Tmp.Giro;
            Tempo_Prec:=Tmp.Tempo;
            Statistiche.Giro_Tempo_Vectors.Next(Tempi_Settori_Cursor);
            Uscita:=false;
            while Statistiche.Giro_Tempo_Vectors.Has_Element(Tempi_Settori_Cursor) and Uscita=false loop
               Tmp_Succ:=Statistiche.Giro_Tempo_Vectors.Element(Tempi_Settori_Cursor);
               if(Tmp_Succ.Giro=Giro_Prec) then
                  Array_Obj_Json_Settore:=Create_Object;
                  Array_Obj_Json_Settore.Set_Field("settore",Tmp_Succ.Settore);
                  Array_Obj_Json_Settore.Set_Field("tempo",Tmp_Succ.Tempo-Tempo_Prec);
                  Append (Arr => Array_Json_Settore,
                          Val => Array_Obj_Json_Settore);

                  Tempo_Prec:=Tmp_Succ.Tempo;

                  Statistiche.Giro_Tempo_Vectors.Next(Tempi_Settori_Cursor);
               else
                  Uscita:=True;
               end if;
            end loop;
            Array_Obj_Json.Set_Field("settori",Array_Json_Settore);
            Append (Arr => Array_Json,
                    Val => Array_Obj_Json);

         end if;
      end loop;
      Myobj.Set_Field("giri",Array_Json);

      Logger.Traccia(Logger.Middle, Myobj.Write);

      return Myobj.Write;
   end Invia_Settori_Box;


end Middleware.Websocket;
