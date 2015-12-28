with YAMI.Agents;
with YAMI.Agents.Helpers;

with YAMI.Parameters;

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Middleware.Webserver;
with Statistiche;use Statistiche;
with Frame;

with Logger;

with Ada.Real_Time; use Ada.Real_Time;
with Logger;
with GNATCOLL.JSON; use GNATCOLL.JSON;

with Ada.Calendar.Formatting; use Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones; use Ada.Calendar.Time_Zones;


package body Middleware is



   procedure Report
     (H : in out Connection_Event_Handler;
      Name : in String;
      Event : in YAMI.Connection_Event_Handlers.Connection_Event) is
   begin
      case Event is
         when YAMI.Connection_Event_Handlers.New_Incoming_Connection =>
            Logger.Traccia(Logger.Middle,"incoming");
            Coordinatore_Stato:=True;
         when YAMI.Connection_Event_Handlers.New_Outgoing_Connection =>
            Logger.Traccia(Logger.Middle,"outgoiing");
         when YAMI.Connection_Event_Handlers.Connection_Closed =>
            Logger.Traccia(Logger.Middle,"close");
            Coordinatore_Stato:=False;
            if(Stato_Loop_Task=true) then -- se gara in corso la fermo
               Foto_Loop.Fine_Gara(0.1);
            end if;
      end case;
   end Report;

   task body Foto_Loop is

      Tempo_Gara: Time;
      Tempo_Inizio: Time;

      Tmp_Uscita:AGSTempo;
      Tmp_Entrata:AGSTempo;
      Tempi_Uscita: AGSTempo_Vectors.Vector;
      Tempi_Uscita_Cursor: AGSTempo_Vectors.Cursor;
      Tempi_Entrata: AGSTempo_Vectors.Vector;
      Tempi_Entrata_Cursor: AGSTempo_Vectors.Cursor;

      Myobj: JSON_Value;
      Array_Obj_Giri : JSON_Value;
      Array_Giri : JSON_Array;
      Myobj_Open: JSON_Value;
      Array_Obj_Giri_Open : JSON_Value;
      Array_Giri_Open : JSON_Array;

      Tempo_Chiusura:float:=-1.0;
      Chiusura:Boolean:=false;

      Concorrenti_Cursor: Auto_Desc_Vectors.Cursor;
      Tmp_Conc: Auto_Desc;

      Fine_Gara_Pilota:Boolean;
      Frame_Precedente : Frame.Frame_Vectors.Vector;
      Tempo_Gara_Frame:Float;

      Frame_Precedente_Cursor_Open: Frame.Frame_Vectors.Cursor;
      Tmp_Open:  Frame.Frame_Type;

      --tempo di avanzamento tra 2 frame
      Tempo_Frame:Float:=-1.0;

      --Tempo su giro di 1 pilota
      Tempo_Giro: Statistiche.Giro_Tempo;
      Myobj_Giro: JSON_Value;--messaggio completamento giro di 1 pilota

      --
      Frame_Auto:Frame.Frame_Type;
      Giro_Gap: Integer;
      Settore_Gap: Integer;
      Giri_Check:Statistiche.Giro_Tempo_Vectors.Vector;
      Giri_Check_Cursor:Statistiche.Giro_Tempo_Vectors.Cursor;
      Giro_Singolo:Statistiche.Giro_Tempo;
      Myobj_Gap: JSON_Value;
      Array_Obj_Gap : JSON_Value;
      Array_Gap : JSON_Array;

      --reinvio dati fino al tempogara corrente
      Cursor_Auto_Desc:Middleware.Auto_Desc_Vectors.Cursor;
      Tmp_Auto_Desc: Auto_Desc;
      Laps : Statistiche.Giro_Tempo_Vectors.Vector;
      Lap: Statistiche.Giro_Tempo;
      Laps_Cursor : Statistiche.Giro_Tempo_Vectors.Cursor;
      Array_Json : JSON_Array;
      Array_Obj_Json : JSON_Value;
      Tempo_Prec: Float;
      Tot_Giri: Integer:=-1;
   begin
      loop
         select
            accept Avvia  do
               Myobj:=Create_Object;
               Myobj.Set_Field("tipo",5);
               Middleware.Invia_Gui(Myobj.Write);
            end Avvia;
         or
            accept Chiudi  do
               Chiusura:=true;
            end Chiudi;
         end select;

         if(Chiusura=True)then
            exit;
         end if;

         Tempo_Frame:=Float'Value(Config.Get ("Generale.tempoframe"));

         Frame_Precedente.Clear;
         Tempo_Gara:=Clock;
         Tempo_Inizio:=Tempo_Gara;
         loop
            Stato_Loop_Task:=true;
            Tempo_Gara_Frame:=Float(To_Duration(Tempo_Gara-Tempo_Inizio));
            Tempi_Uscita:=Tempi_Settore_Istantanea_Uscita(Tempo_Gara_Frame);
            Tempi_Entrata:=Tempi_Settore_Istantanea_Entrata(Tempo_Gara_Frame);


            Myobj:=Create_Object;
            Myobj.Set_Field("tipo",3);
            Myobj.Set_Field("tempogara",Tempo_Gara_Frame);

            Array_Giri:=Empty_Array;
            Tempi_Uscita_Cursor:= AGSTempo_Vectors.First(Tempi_Uscita);
            while(AGSTempo_Vectors.Has_Element(Tempi_Uscita_Cursor)) loop
               Tmp_Uscita:=AGSTempo_Vectors.Element(Tempi_Uscita_Cursor);


               Tempi_Entrata_Cursor:=AGSTempo_Vectors.First(Tempi_Entrata);
               while(AGSTempo_Vectors.Has_Element(Tempi_Entrata_Cursor))loop
                  Tmp_Entrata:=AGSTempo_Vectors.Element(Tempi_Entrata_Cursor);
                  If(Tmp_Entrata.Auto=Tmp_Uscita.Auto)then
                     exit;
                  end if;
                  AGSTempo_Vectors.Next(Tempi_Entrata_Cursor);

               end loop;
               If(Tmp_Entrata.Auto=Tmp_Uscita.Auto)then
                  Array_Obj_Giri:=Create_Object;
                  Array_Obj_Giri.Set_Field("auto",Tmp_Uscita.Auto);
                  Array_Obj_Giri.Set_Field("settore",Tmp_Uscita.Settore);
                  Array_Obj_Giri.Set_Field("giro",Tmp_Uscita.Giro);
                  Array_Obj_Giri.Set_Field("tempoentrata",Tmp_Entrata.Tempo);
                  Array_Obj_Giri.Set_Field("tempouscita",Tmp_Uscita.Tempo);

                  Fine_Gara_Pilota:=false;
                  Concorrenti_Cursor:=Auto_Desc_Vectors.First(Concorrenti);
                  while(Auto_Desc_Vectors.Has_Element(Concorrenti_Cursor)) loop
                     Tmp_Conc:=Auto_Desc_Vectors.Element(Concorrenti_Cursor);
                     if(Tmp_Uscita.Auto=Tmp_Conc.Id_Auto and Tmp_Conc.Fine_Gara=true and Tmp_Conc.Tempo_Fine<=Tmp_Uscita.Tempo) then
                        Fine_Gara_Pilota:=true;
                        exit;
                     end if;
                     Auto_Desc_Vectors.Next(Concorrenti_Cursor);
                  end loop;

                  Array_Obj_Giri.Set_Field("finegara",Fine_Gara_Pilota);

                  --solo se è diverso dalla riga gia mandata lo appendo all'invio
                  if(Frame.Esiste_Frame(Frame_Precedente,Tmp_Uscita.Auto,Tmp_Uscita.Settore,Tmp_Uscita.Giro,Fine_Gara_Pilota)=false) then
                     Frame_Auto:=Frame.Ottieni_Frame(Frame_Precedente,Tmp_Uscita.Auto);

                     Giro_Gap:=Frame_Auto.Giro;
                     Settore_Gap:=Frame_Auto.Settore;

                     Giri_Check:=Statistiche.Tempo_Settori_Check(Tmp_Uscita.Auto,Giro_Gap,Tmp_Uscita.Giro,Tempo_Gara_Frame,Dati_Gara.Settori_CheckPoint);
                     Giri_Check_Cursor:=Statistiche.Giro_Tempo_Vectors.First(Giri_Check);
                     if Statistiche.Giro_Tempo_Vectors.Has_Element(Giri_Check_Cursor) then--se c'è almeno un elemento creo l'oggetto
                        Myobj_Gap:=Create_Object;
                        Myobj_Gap.Set_Field("tipo",11);
                        Myobj_Gap.Set_Field("auto",Tmp_Uscita.Auto);

                        Array_Gap:=Empty_Array;
                        while Statistiche.Giro_Tempo_Vectors.Has_Element(Giri_Check_Cursor) loop
                           Giro_Singolo:=Statistiche.Giro_Tempo_Vectors.Element(Giri_Check_Cursor);
                           Array_Obj_Gap:=Create_Object;
                           Array_Obj_Gap.Set_Field("giro",Giro_Singolo.Giro);
                           if(Giro_Singolo.Settore=Dati_Gara.Numero_Settori+1) then
                              Array_Obj_Gap.Set_Field("settore",Dati_Gara.Numero_Settori);
                           elsif (Giro_Singolo.Settore=Dati_Gara.Numero_Settori+2) then
                              Array_Obj_Gap.Set_Field("settore",1);
                           else
                              Array_Obj_Gap.Set_Field("settore",Giro_Singolo.Settore);
                           end if;
                           Array_Obj_Gap.Set_Field("tempo",Giro_Singolo.Tempo);
                           Append (Arr => Array_Gap,
                                   Val => Array_Obj_Gap);


                           Statistiche.Giro_Tempo_Vectors.Next(Giri_Check_Cursor);
                        end loop;
                        Myobj_Gap.Set_Field("giri",Array_Gap);
                        Logger.Traccia(Logger.Middle,Myobj_Gap.Write);
                        Middleware.Invia_Monitor(Myobj_Gap.Write);



                     end if;







                     --controllo se ho completato un giro
                     if(Frame.Cambio_Giro(Frame_Precedente,Tmp_Uscita.Auto,Tmp_Uscita.Giro))then
                        --il giro è cambiato devo inviare il tempo Tmp_Uscita.Giro Tmp_Uscita.Auto
                        Tempo_Giro:=Statistiche.Tempo_Giro_Pilota(Tmp_Uscita.Giro-1,Tmp_Uscita.Auto);
                        Myobj_Giro:=Create_Object;

                        Myobj_Giro.Set_Field("tipo",6);
                        Myobj_Giro.Set_Field("auto",Tmp_Uscita.Auto);
                        Myobj_Giro.Set_Field("giro",Tmp_Uscita.Giro-1);
                        Myobj_Giro.Set_Field("tempo",Tempo_Giro.Tempo);
                        if Tempo_Giro.Settore>Dati_Gara.Numero_Settori then-- se si è entrato ai box
                           Myobj_Giro.Set_Field("sosta",True);
                        else-- altrimenti è un giro normale
                           Myobj_Giro.Set_Field("sosta",False);
                        end if;

                        Logger.Traccia(Logger.Middle,Myobj_Giro.Write);
                        Middleware.Invia_Monitor(Myobj_Giro.Write);

                     end if;

                     Frame.Inserisci_Frame(Frame_Precedente,Tmp_Uscita.Auto,
                                           Tmp_Uscita.Settore,Tmp_Uscita.Giro,
                                           Tmp_Entrata.Tempo,Tmp_Uscita.Tempo,
                                           Fine_Gara_Pilota);
                     Append (Arr => Array_Giri,
                             Val => Array_Obj_Giri);

                  end if;


               end if;


               AGSTempo_Vectors.Next(Tempi_Uscita_Cursor);

            end loop;
            Myobj.Set_Field("tempi",Array_Giri);

            --Logger.Traccia(Logger.Middle,Myobj.Write);

            Middleware.Invia_Monitor(Myobj.Write);



            select
               accept Frame_On_Open (Frame_Open : out Middleware.UString.Vector) do
                  Myobj_Open:=Create_Object;
                  Myobj_Open.Set_Field("tipo",3);
                  Myobj_Open.Set_Field("tempogara",Tempo_Gara_Frame);

                  Array_Giri_Open:=Empty_Array;
                  Frame_Precedente_Cursor_Open:=Frame.Frame_Vectors.First(Frame_Precedente);
                  while(Frame.Frame_Vectors.Has_Element(Frame_Precedente_Cursor_Open))loop
                     Tmp_Open:=Frame.Frame_Vectors.Element(Frame_Precedente_Cursor_Open);
                     Array_Obj_Giri_Open:=Create_Object;
                     Array_Obj_Giri_Open.Set_Field("auto",Tmp_Open.Auto);
                     Array_Obj_Giri_Open.Set_Field("settore",Tmp_Open.Settore);
                     Array_Obj_Giri_Open.Set_Field("giro",Tmp_Open.Giro);
                     Array_Obj_Giri_Open.Set_Field("tempoentrata",Tmp_Open.Tempo_Entrata);
                     Array_Obj_Giri_Open.Set_Field("tempouscita",Tmp_Open.Tempo_Uscita);

                     Fine_Gara_Pilota:=false;
                     Concorrenti_Cursor:=Auto_Desc_Vectors.First(Concorrenti);
                     while(Auto_Desc_Vectors.Has_Element(Concorrenti_Cursor)) loop
                        Tmp_Conc:=Auto_Desc_Vectors.Element(Concorrenti_Cursor);
                        if(Tmp_Open.Auto=Tmp_Conc.Id_Auto and Tmp_Conc.Fine_Gara=true and Tmp_Conc.Tempo_Fine<=Tmp_Open.Tempo_Uscita) then
                           Fine_Gara_Pilota:=true;
                           exit;
                        end if;
                        Auto_Desc_Vectors.Next(Concorrenti_Cursor);
                     end loop;

                     Array_Obj_Giri_Open.Set_Field("finegara",Fine_Gara_Pilota);
                     Append (Arr => Array_Giri_Open,
                             Val => Array_Obj_Giri_Open);
                     Frame.Frame_Vectors.Next(Frame_Precedente_Cursor_Open);
                  end loop;
                  Myobj_Open.Set_Field("tempi",Array_Giri_Open);

                  Frame_Open.append(To_Unbounded_String(Myobj_Open.Write));

                  --reinvio dati gara fino a questo istante
                  --reinvio dati iniziali piloti
                  Cursor_Auto_Desc:=Auto_Desc_Vectors.First(Middleware.Concorrenti);
                  while Auto_Desc_Vectors.Has_Element(Cursor_Auto_Desc) loop
                     Tmp_Auto_Desc:=Auto_Desc_Vectors.Element(Cursor_Auto_Desc);

                     Auto_Desc_Vectors.Next(Cursor_Auto_Desc);
                     Logger.Traccia(Logger.Middle,"Dopo next Cursor");

                     --tempi totali giri per ogni pilota
                     Laps:=Statistiche.Tempi_Giri_Pilota(Tmp_Auto_Desc.Id_Auto,Tempo_Gara_Frame);
                     Laps_Cursor:=Statistiche.Giro_Tempo_Vectors.First(Laps);

                     --controllo che ci sia almeno 1 giro
                     if(Statistiche.Giro_Tempo_Vectors.Has_Element(Laps_Cursor)) then

                        Myobj:=Create_Object;
                        Myobj.Set_Field("tipo",4);
                        Myobj.Set_Field("auto",Tmp_Auto_Desc.Id_Auto);
                        Array_Json := Empty_Array;
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

                        if(Tot_giri>0)then--se ho almeno 1 giro completo invio
                           Myobj.Set_Field("giri",Array_Json);

                           --stampo a video
                           Logger.Traccia(Logger.Middle,Myobj.Write);

                           --Invio al monitor
                           Frame_Open.append(To_Unbounded_String(Myobj.Write));
                        end if;
                     end if;



                     --reinvio fine gara se il pilota ha finito la gara
                     if(Tmp_Auto_Desc.Fine_Gara)then
                        Myobj:=Create_Object;
                        Myobj.Set_Field("tipo",7);
                        Myobj.Set_Field("auto",Tmp_Auto_Desc.Id_Auto);
                        Logger.Traccia(Logger.Middle,Myobj.Write);

                        Frame_Open.append(To_Unbounded_String(Myobj.Write));

                     end if;
                  end loop;







               end Frame_On_Open;
            or
               accept Fine_Gara(tempofinale:float)  do
                  Tempo_Chiusura:=tempofinale;
                  Logger.Traccia(Logger.Middle,"Sono dentro Fine_GARA FOTO LOOP");
               end Fine_Gara;
            or
                 delay 0.0;
            end select;
		--Logger.Traccia(Logger.Middle,"Tempo di arrestarsi: " & Boolean'Image(Tempo_Chiusura>0.0 and To_Time_Span(Duration(Tempo_Chiusura))<Tempo_Gara-Tempo_Inizio));
            if(Tempo_Chiusura>0.0 and To_Time_Span(Duration(Tempo_Chiusura))<Tempo_Gara-Tempo_Inizio) then
               exit;
            end if;
            Tempo_Gara:=Tempo_Gara+To_Time_Span(Duration(Tempo_Frame));


            delay until Tempo_Gara;


         end loop;
         Stato_Loop_Task:=false;
         Logger.Traccia(Logger.Middle,"Fine Gara FOTO LOOP");
         Myobj:=Create_Object;
         Myobj.Set_Field("tipo",6);
         Middleware.Invia_Gui(Myobj.Write);
      end loop;
      Logger.Traccia(Logger.Middle,"Fine task FOTO LOOP");
   end Foto_Loop;





   --Implementazione dei metodi ereditati da Comunication.Comunication_Interface_Server
   overriding procedure Comunica_Stato_Auto (S : in out Comunication_Impl;
                                             Dati_In : in ConfigurazioniAuto_Mid.Configurazione) is
      Concorrenti_Cursor: Auto_Desc_Vectors.Cursor;
      Concorrenti_Tmp:Auto_Desc;
   begin
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",5);
      Myobj.Set_Field("auto",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Id_Auto)));
      Myobj.Set_Field("gomme",Dati_In.Gomme);
      Myobj.Set_Field("usuragomme",Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Dati_In.Usura_Gomme)));
      Myobj.Set_Field("gommepitstop",Dati_In.Gomme_Pitstop);
      Myobj.Set_Field("usuragommestop",Float'Value(YAMI.Parameters.YAMI_Long_Float'Image(Dati_In.Usura_Gomme_Stop)));
      Myobj.Set_Field("livellobenzina",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Benzina)));
      Myobj.Set_Field("livellobenzinastop",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Benzina_Stop)));
      Myobj.Set_Field("livellobenzinapitstop",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Benzina_Pitstop)));
      Myobj.Set_Field("livellodanni",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Livello_Danni)));
      Myobj.Set_Field("entratabox",Dati_In.Entrata_Box);
      Myobj.Set_Field("potenza",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Potenza)));
      Myobj.Set_Field("bravurapilota",Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Bravura_Pilota)));
      Myobj.Set_Field("nomescuderia",Dati_In.Nome_Scuderia);
      Myobj.Set_Field("nomeplota",Dati_In.Nome_Pilota);


      Middleware.Webserver.Invia_Box_Singolo(Myobj.Write);

      --salvo l'ultima configurazione per il pilota
      Concorrenti_Cursor:= Auto_Desc_Vectors.First(Concorrenti);
      while Auto_Desc_Vectors.Has_Element(Concorrenti_Cursor) loop
         Concorrenti_Tmp:=Auto_Desc_Vectors.Element(Concorrenti_Cursor);
         if(Concorrenti_Tmp.Id_Auto=Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Id_Auto))) then
            Concorrenti_Tmp.Configurazione:=Dati_In;
            Concorrenti.Replace_Element(Position => Concorrenti_Cursor,New_Item => Concorrenti_Tmp);
            exit;
         end if;
         Auto_Desc_Vectors.Next(Concorrenti_Cursor);
      end loop;

   end Comunica_Stato_Auto;

   overriding procedure Comunica_Tempo (S : in out Comunication_Impl;
                                        Dati_In : in Comunication.Tempo_Settore) is
      Auto: Integer;
      Settore: Integer;
      Settore_Precedente: Integer;
      Giro: Integer;
      Giro_Precedente: Integer;
      Tempo: Float;
      Tempo_Settore: Float := -1.0;
      Tempo_Precedente: Float;
   begin
      --conversione dati
      Auto:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto));
      Settore:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Settore));
      Giro:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Giro));
      Tempo:=Float'Value(YAMI.Parameters.YAMI_Long_Float'Image (Dati_In.Tempo));


      --ottengo dati database
      if(Giro=0)then
         Tempo_Settore:= Tempo; --il tempo del settore è il tempo totale
      elsif(Settore = Dati_Gara.Numero_Settori+1) then --settore entrata box
         Settore_Precedente:= Settore-2;
         Tempo_Precedente:=Statistiche.Tempo_Settore(Giro,Auto,Settore_Precedente);
         Tempo_Settore:=Tempo-Tempo_Precedente;
      else
         Settore_Precedente:=Settore-1;
         if(Settore_Precedente<1) then
            Giro_Precedente:=Giro-1;
            Settore_Precedente:=Dati_Gara.Numero_Settori;

            Tempo_Precedente:=Statistiche.Tempo_Settore(Giro_Precedente,Auto,Settore_Precedente);
            if(Tempo_Precedente = -1.0) then --se il dato nn c'è allora il settore prec era ai box
               Settore_Precedente:= Dati_Gara.Numero_Settori+2;
               Tempo_Precedente:=Statistiche.Tempo_Settore(Giro_Precedente,Auto,Settore_Precedente);
            end if;
            Tempo_Settore:=Tempo-Tempo_Precedente;
         else
            Tempo_Precedente:=Statistiche.Tempo_Settore(Giro,Auto,Settore_Precedente);
            Tempo_Settore:=Tempo-Tempo_Precedente;
         end if;
      end if;




      --JSON
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",6);
      Myobj.Set_Field("auto",Auto);
      Myobj.Set_Field("settore",Settore);
      Myobj.Set_Field("giro",Giro);
      Myobj.Set_Field("tempo",Tempo);
      Myobj.Set_Field("temposettore",Tempo_Settore);

      -- invio a webserver
      --Middleware.Webserver.Invia_Monitor(Myobj.Write);
      Middleware.Webserver.Invia_Box_Singolo(Myobj.Write);

      --salvo solo i giri 0, per i giri >0 salvo il tempo futuro
      if(Giro=0) then
         Primo_dato:=Primo_dato+1;
         Statistiche.InsertTempo(Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Giro)),
                                         Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto)),
                                         Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Settore)),
                                         Float'Value(YAMI.Parameters.YAMI_Long_Float'Image (Dati_In.Tempo))
                                        );
         if(Primo_dato=Dati_Gara.Numero_Auto_Tot) then
            Foto_Loop.Avvia;--avvio task fotografia gara
         end if;
      end if;

   end Comunica_Tempo;

   overriding procedure Comunica_Tempo_Futuro (S : in out Comunication_Impl;
                                               Dati_In : in Comunication.Tempo_Settore) is
   begin
      --Salvataggio tempi nel DB
      Statistiche.InsertTempo(Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Giro)),
                                      Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto)),
                                      Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Settore)),
                                      Float'Value(YAMI.Parameters.YAMI_Long_Float'Image (Dati_In.Tempo))
                                     );


   end Comunica_Tempo_Futuro;

   overriding procedure Comunica_Stato_Iniziale (S : in out Comunication_Impl;
                                        Dati_In : in Comunication.Stato_Iniziale) is
      Indice_Inizio: Integer;
      Indice_Fine: Integer;
      Lunghezza:Integer;
      Token: Unbounded_String;
      Array_Obj_Check : JSON_Value;
      Array_Check : JSON_Array;
      Checkpoint: Integer;
   begin
      --JSON
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",0);
      Myobj.Set_Field("nomepista",Dati_In.Nome_Pista);
      Myobj.Set_Field("numerogiri",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Numero_Giri)));
      Myobj.Set_Field("numerosettori",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Numero_Settori)));
      Myobj.Set_Field("numeroautotot",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Numero_Auto_Tot)));
      Myobj.Set_Field("meteo",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Meteo)));

       --salvo i dati iniziali
      Dati_Gara.Nome_Pista:=Dati_In.Nome_Pista;
      Dati_Gara.Numero_Giri:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Numero_Giri));
      Dati_Gara.Numero_Settori:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Numero_Settori));
      Dati_Gara.Numero_Auto_Tot:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Numero_Auto_Tot));
      Dati_Gara.Meteo:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image(Dati_In.Meteo));



      Logger.Traccia(Logger.Middle,"CHECK: " &To_String(Dati_In.Checkpoint));

      Array_Check:=Empty_Array;

      Indice_Inizio:=1;
      Indice_Fine:=Index(Dati_In.Checkpoint,",");
      Token:=Dati_In.Checkpoint;
      Lunghezza:=To_String(Dati_In.Checkpoint)'last;
      while Indice_Fine/=0 loop
         Checkpoint:=Integer'Value(Slice(Token,Indice_Inizio,Indice_Fine-1));
         Dati_Gara.Settori_CheckPoint.Append(Checkpoint);
         Array_Obj_Check:=Create_Object;
         if(Checkpoint<=Dati_Gara.Numero_Settori) then
            Array_Obj_Check.Set_Field("settore",Integer'Value(Slice(Token,Indice_Inizio,Indice_Fine-1)) );
            Append(Arr => Array_Check,
                   Val => Array_Obj_Check);
         end if;
         Logger.Traccia(Logger.Middle,"Loop Tocken: " & Integer'Image(Integer'Value(Slice(Token,Indice_Inizio,Indice_Fine-1))));
         Indice_Inizio:=Indice_Fine+1;

         Token:=To_Unbounded_String(Slice(Token,Indice_Inizio,Lunghezza));
         Lunghezza:=To_String(Token)'last;
         Indice_Fine:=Index(Token,",");
         Indice_Inizio:=1;
      --   Logger.Traccia(Logger.Middle,"Valori L - IF: " & Integer'Image(Lunghezza) & " - "& Integer'Image(Indice_Fine));

      end loop;
      Checkpoint:=Integer'Value(To_String(Token));
      Dati_Gara.Settori_CheckPoint.Append(Checkpoint);--aggiungo l'ultimo numero settore
      if(Checkpoint<=Dati_Gara.Numero_Settori) then
         Array_Obj_Check:=Create_Object;
         Array_Obj_Check.Set_Field("settore",Integer'Value(To_String(Token)) );
         Append (Arr => Array_Check,
                 Val => Array_Obj_Check);
      end if;

      Myobj.Set_Field("checkpoint",Array_Check);


      Logger.Traccia(Logger.Middle,"Ho caricato "& Dati_Gara.Settori_CheckPoint.Length'Img & " checkpoint.");


      --stampo su console
      Logger.Traccia(Logger.Middle,Myobj.Write);
      -- invio a webserver
      Middleware.Webserver.Invia_Monitor(Myobj.Write);
      Middleware.Webserver.Invia_Box(Myobj.Write);

      --questo messaggio arriva solo quando viene caricata la pista per cui notifico la gui
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",4);
      Middleware.Invia_Gui(Myobj.Write);

   end Comunica_Stato_Iniziale;

   procedure Invia_Gui(dati:String)is
   begin
      Webserver.Invia_Gui(dati);
   end Invia_Gui;

   procedure Invia_Monitor(dati:String) is
   begin
      Webserver.Invia_Monitor(dati);
   end Invia_Monitor;

   overriding procedure Comunica_Dati_Concorrente(S : in out Comunication_Impl;
                                                  Dati_In: in Dati_Concorrente) is
   begin
      --JSON
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",1);
      Myobj.Set_Field("auto",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto)));
      Myobj.Set_Field("nome",Dati_In.Nome);
      Myobj.Set_Field("scuderia",Dati_In.Scuderia);

      --salvo lista concorrenti
      Append_Concorrenti(Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto)),Dati_In.Nome,Dati_In.Scuderia);

      --stampo su console
      Logger.Traccia(Logger.Middle,Myobj.Write);

      -- invio a webserver
      Middleware.Webserver.Invia_Monitor(Myobj.Write);
      Middleware.Webserver.Invia_Box(Myobj.Write);
   end Comunica_Dati_Concorrente;

   overriding procedure Comunica_Cambio_Meteo(S : in out Comunication_Impl;
                                              Dati_In: in Dati_Meteo) is
   begin
        --JSON
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",2);
      Myobj.Set_Field("meteo",Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Meteo)));
      --stampo su console

      -- invio a webserver
      Logger.Traccia(Logger.Middle,Myobj.Write);

      Middleware.Webserver.Invia_Monitor(Myobj.Write);

   end Comunica_Cambio_Meteo;

   overriding procedure Hello(S : in out Comunication_Impl) is

   begin
      Coordinatore.Hello;
   end Hello;

   overriding procedure Comunica_Errori(S : in out Comunication_Impl;
                                        Dati_In: in Dati_Errore) is
   begin
      --Segnalo alla gui che c'è stato un errore di caricamento
      Logger.Traccia(Logger.Middle,To_String(Dati_In.Messaggio));
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",4);
      Middleware.Invia_Gui(Myobj.Write);
   end Comunica_Errori;

   overriding procedure Comunica_Fine_Gara(S : in out Comunication_Impl;
                                           Dati_In: in Dati_Fine_Gara) is
      Cursor_Piloti : Auto_Desc_Vectors.Cursor;
      Id_Auto: Integer;
      Tmp: Auto_Desc;
      Fine_Gara: Integer:= 0;


      tmp_finegara: float:=-1.0;
   begin
      Id_Auto:=Integer'Value(YAMI.Parameters.YAMI_Integer'Image (Dati_In.Id_Auto));
      Logger.Traccia(Logger.Middle,"Fine Gara: " & Integer'Image(Id_Auto));
      Myobj:=Create_Object;
      Myobj.Set_Field("tipo",7);
      Myobj.Set_Field("auto",Id_Auto);

      Cursor_Piloti:=Auto_Desc_Vectors.First(Concorrenti);
      while Auto_Desc_Vectors.Has_Element(Cursor_Piloti) loop
         Tmp:=Auto_Desc_Vectors.Element(Cursor_Piloti);
         if(Tmp.Fine_Gara)then
         	Fine_Gara:=Fine_Gara+1;
         end if;
         if(Tmp.Id_Auto=Id_Auto)then
            Tmp.Fine_Gara:=true;
            Tmp.Tempo_Fine:=Statistiche.Tempo_Fine_Gara_Pilota(Tmp.Id_Auto);
            Fine_Gara:=Fine_Gara+1;
            Concorrenti.Replace_Element(Position => Cursor_Piloti,New_Item => Tmp);
         end if;
         Auto_Desc_Vectors.Next(Cursor_Piloti);
      end loop;

      Logger.Traccia(Logger.Middle,"Finegara:  " & Integer'Image(Fine_Gara));
      if(Fine_Gara=Dati_Gara.Numero_Auto_Tot)then
         Dati_Gara.Fine_Gara:=true;

         --do tempo di fine al loop
         tmp_finegara:=Statistiche.Tempo_Fine_Gara;
         Logger.Traccia(Logger.Middle,"Comunico FineGara prima: " & Float'Image(tmp_finegara));
         Foto_Loop.Fine_Gara(tmp_finegara);
         Logger.Traccia(Logger.Middle,"Comunico FineGara dopo");
      end if;
      --stampo su console
      Logger.Traccia(Logger.Middle,Myobj.Write);


      --invio a tutti i monitor
      Middleware.Webserver.Invia_Monitor(Myobj.Write);

   end Comunica_Fine_Gara;



   procedure Start is

      My_Server : aliased Comunication_Impl;
      Config_Parser : INI_Parser;
   begin


      --lettura dati configurazione
      Open (Config_Parser, "midconfig");
      Fill (Config, Config_Parser);

      Logger.Traccia(Logger.Middle,"Stampo Config File");
      Logger.Traccia(Logger.Middle,"midserver: " & Config.Get ("Comunicazione.midserver"));
      Logger.Traccia(Logger.Middle,"coorserv: " & Config.Get ("Comunicazione.coorserv"));
      Logger.Traccia(Logger.Middle,"webserverHost: " & Config.Get ("Comunicazione.webserverHost"));
      Logger.Traccia(Logger.Middle,"webserverPort: " & Config.Get ("Comunicazione.webserverPort"));


      declare
         Server_Event_Handler : aliased Connection_Event_Handler;
         Server_Agent :  YAMI.Agents.Agent := YAMI.Agents.Make_Agent;


         Resolved_Server_Address :String (1 .. YAMI.Agents.Max_Target_Length);
         Resolved_Server_Address_Last : Natural;
         Client_Address : String:= Config.Get ("Comunicazione.coorserv"); -- Server in input (es tcp://127.0.0.1:1234)
         Client_Agent : YAMI.Agents.Agent :=YAMI.Agents.Make_Agent;
      begin
         --imposto interfaccia di monitor eventi connessione
         Server_Agent.Register_Connection_Event_Monitor
           (Server_Event_Handler'Unchecked_Access);
         Server_Agent.Add_Listener
           (Config.Get ("Comunicazione.midserver"),
            Resolved_Server_Address,
            Resolved_Server_Address_Last);

         Ada.Text_IO.Put_Line
           ("Il middleware e' in ascolto in: " &
              Resolved_Server_Address(1 .. Resolved_Server_Address_Last));

         -- registrazione dell'oggetto remoto usato dal client
         Server_Agent.Register_Object("comunication", My_Server'Unchecked_Access);


         Coordinatore.Initialize_Command_Interface(Client_Agent, Client_Address, "comunicationIn");

         -- avvio webserver
         Middleware.Webserver.Start;


         -- in attesa di client
         Stato_Programma.Attesa_Chiudi_Programma;

         Middleware.Webserver.Stop;
         Logger.Traccia(Logger.Middle,"Chiuso webserver");


         Logger.Traccia(Logger.Middle,"Chiusi gli agent");

         --libero risorse db
         Statistiche.Stop;
      exception
         when E : others =>
            Ada.Text_IO.Put_Line("exp dentro");

            Ada.Text_IO.Put_Line
              (Ada.Exceptions.Exception_Message (E));
      end;



   exception
      when E : others =>
         Ada.Text_IO.Put_Line
           (Ada.Exceptions.Exception_Message (E));
         Ada.Text_IO.Put_Line("exp fuori");

   end Start;

   --risorsa protetta che forza l'attesa per la chiusura del programma
   protected body Chiudere is
      entry Attesa_Chiudi_Programma when Chiusura = true is
      begin
         null;
      end Attesa_Chiudi_Programma;

      entry Chiudi_Programma when true is
      begin
         Chiusura:=true;
      end Chiudi_Programma;
   end Chiudere;


   --aggiungo concorenti al vettore Concorrenti
   procedure Append_Concorrenti(Id_Auto : Integer;Nome : Unbounded_String;Scuderia: Unbounded_String)is
      tmp: Auto_Desc;
   begin

      tmp.Id_Auto:=Id_Auto;
      tmp.Nome:=Nome;
      tmp.Scuderia:=Scuderia;

      tmp.Configurazione.Id_Auto:=YAMI.Parameters.YAMI_Integer'Val(-1);

      Concorrenti.Append(tmp);


   end Append_Concorrenti;

end Middleware;
