<script>

/*
*
* All'apertura della pagina il websocket viene aperto.
* Vengono ricevuto dal webserver il messaggio che la pagina Ã¨ stata aperta (Funzione onopen)
* All'apertura della pagina viene inviata dal webserver la lista dei piloti (Messaggi di tipo 2)
* Viene visualizzata nel monitor del box la tabella, dei piloti ancora liberi, dopo aver ricevuto i dati di tutti i piloti.
*
*/


  /*
  *
  * Questa variabile permette di far scorrere la pagina iniziale (selezione del pilota) se e solo se
  * la selezione va a buon fine, ovvero viene confermato che il pilota Ã¨ stato prenotato correttamente.
  * In caso contrario la variabile resta a false e si rimane nella pagina dei selezione dei piloti.
  * Viene visualizzato anche un messaggio di errore
  */
        var status_selezione_pilota=false;
        var idPilotaSelezionato = -1;

      //****************************************************************************
      //DATI GLOBALI
      var nome_pista;
      var info_meteo;
      var num_piloti;
      var num_giri;
      var num_settori;
      var entrata_box;
      var uscita_box;
      var contatorePiloti = 0;
      //log
      var log;
      //array di info piloti
      idAutoArray = new Array();
      nomePilotaArray = new Array();
      scuderiaPilotaArray = new Array();
      //matrice delle posizioni della gara iniziale / precedente ad un tempo ricevuto
      var griglia=new Array();
      
      /*
      Pila di messaggi di tipo 1
      Uso una pila per salvare tutti i messaggi di tipo 1 ricevuti.
      */       
      var pila_messaggi = new Array();
     
      //dati per la timeline
      grigliaDatiPiloti = new Array();
      grigliaSoste = new Array();
      
      //grigliaIncidenti = new Array();
      
      //matrice per i tempi del pilota
      tempiPilota = new Array();
      tempiGiroPilota = new Array();
      //temp per il calcolo del settore unico
      var precedente = 0;
           
      //****************************************************************************
      //INIZIO FUNZIONI UTENTI
     
      //inizio funzione setValoriIniziali
      function setValoriIniziali (nomePista, infoMeteoIniziale, numPiloti, numGiri,numSettori)
      {
        nome_pista=nomePista;
        info_meteo=infoMeteoIniziale;
        num_piloti=parseInt(numPiloti);
        num_giri=parseInt(numGiri);
        num_settori=parseInt(numSettori);
        entrata_box=parseInt(num_settori);
        entrata_box=entrata_box + 1;
        uscita_box = parseInt(num_settori);
        uscita_box = uscita_box + 2;
        //document.getElementById("nome_pista").innerHTML=nome_pista;
        //document.getElementById("info_meteo").innerHTML=info_meteo;
        //document.getElementById("num_piloti").innerHTML=num_piloti;
        //document.getElementById("num_giri").innerHTML=num_giri;
        for (var i=0; i<num_piloti; i++)
                griglia.push(new Array("","","","","","",""));
        //matrice per i tempi
        for(var i=0; i<num_giri;i++)
        {
          tempiPilota[i] = new Array();
          for(var j=0; j<num_settori+2;j++)
            tempiPilota[i][j]=0;
        }    
        for(var i=0; i<num_giri;i++)
          tempiGiroPilota[i] = 0;
        
        
        i=0;     
        for (var i=0; i<num_giri; i++)
        {
          grigliaSoste[i]=0;       
        }
        
        /*
        i=0;
        for (var i=0; i<num_giri; i++)
        {
          grigliaIncidenti[i]=-1;       
        }
        */
      }
      //fine funzione setValoriIniziali
      

  /*
    Funzione che serve per aggiungere un pilota
    1) Aggiungo un pilota e i suoi dati nei vari array
    2) Stampo la tabella quando ho recuperato tutti i piloti    
  */
    function aggiungiPilota(auto, nome, scuderia)
    {
    if(parseInt(contatorePiloti) < parseInt(num_piloti))
        {
          idAutoArray.push(parseInt(auto));
            nomePilotaArray.push(nome);
            scuderiaPilotaArray.push(scuderia);
            contatorePiloti++;     
        }
        if(parseInt(contatorePiloti)==parseInt(num_piloti))
        {
        
            document.getElementById('tableSmart').style.visibility = 'visible';
            setTable(contatorePiloti);
         }            
      }
      //fine funzione aggiungiPilota
      
     //inizio funzione setTable
      function setTable(num_piloti)
      {
          var numPiloti = parseInt(num_piloti);
          var indice = 0;
          
          for (var i = 0; i < numPiloti; i++)
          {
            indice = indice+1;
            var tag_id = "id"+indice;
            var tag_nome = "nome"+indice;                              
            document.getElementById(tag_id).innerHTML = idAutoArray[i];                                                  
            document.getElementById(tag_nome).innerHTML = nomePilotaArray[i];
            info = infoPilota(idAutoArray[i]);
          }
          //document.getElementById("tabellaPiloti").innerHTML = tabella;
          //inizializzaGriglia();
          
          // Rendo invisibili i piloti di troppo nella tabella
      for(var i=num_piloti+1;i<9;i++){
        document.getElementById('trid'+i).style.visibility = 'hidden';          
      }
      }
      //fine funzione setTable
      
    //inizio funzione infoPilota
  function infoPilota(idPilota)
    {
      return new Array(griglia[idPilota-1][5],griglia[idPilota-1][4],griglia[idPilota-1][6]);        
  }
    //fine funzione infoPilota            
 
      function inizializzaGrigliaPiloti()
      {
                       
          var i=0;
          for (i=0; i<num_piloti; i++)
          {
              grigliaDatiPiloti[i] = new Array(); //una matrice per ogni pilota
              var j=0;
              for(j=0;j<num_giri;j++)
              {
                  //per ogni pilota per ogni giro un array
                  grigliaDatiPiloti[i][j]=new Array();
                  var k=0;
                  //aggiunta dei due settori che formano i box
                  for (k=0; k<num_settori+2; k++)
                  {
                      grigliaDatiPiloti[i][j][k] = new Array();
                  }
              }
          }
      }      
            
 //****************************************************************************
                       
                       
      //INIZIO FUNZIONI WEBSOCKET PREDEFINITE
      function startWebSocket()
      {
         ws = new WebSocket("ws://" + window.location.hostname + ":8080/box");
         ws.onopen = function(evt) { onOpen(evt) };
         ws.onclose = function(evt) { onClose(evt) };
         ws.onmessage = function(evt) { onMessage(evt) };
         ws.onerror = function(evt) { onError(evt) };
      }
     
      function onOpen(evt)
      {  
         //insertLog("Websocket avviato");
      }
     
      function onClose(evt)
      {
         //insertLog("Websocket chiuso fine trasmissioni");
      }
     
      function onError(evt)
      {
         //alert("Errore");
      }  
     
      function doSend(id)
      {
        var msg={
            tipo: 0,
            auto: parseInt(id),
            };
            ws.send(JSON.stringify(msg));
            idPilotaSelezionato=parseInt(id);
      }  
      
      /*
      * Invio nuove configurazioni dal box
      *
      */
      function doSendSettingFromBox()
      {
        //var auto = document.getElementById('auto').value;
        var auto = parseInt(idPilotaSelezionato);
        var gomme = document.getElementById('gommepitstop_set').value;
        var usura_stop = document.getElementById('usuragommestop_set').value;
        var livello_stop = document.getElementById('livellobenzinastop_set').value;
        var livello_rifornimento = document.getElementById('livellobenzinapitstop_set').value;
        var entrata_obbligatoria = false;
    
        if( document.getElementById("entratabox_set").checked == true)    
         entrata_obbligatoria = true;
    
            var msg={
          tipo: 1,
          //auto: parseInt(auto),
          auto: idPilotaSelezionato,
          gomme: gomme,
          usura_stop: parseInt(usura_stop),
          livello_stop: parseInt(livello_stop),
          livello_rifornimento: parseInt(livello_rifornimento),
          entrata_obbligatoria: entrata_obbligatoria,
        };
        ws.send(JSON.stringify(msg));
      }        
      
      
     
      function onMessage(evt)
      {
         //recupero il valore del messaggio
         var msg = JSON.parse(evt.data);
         //controllo il valore del tipo
         if (msg.tipo=="0")
         {
             //informazioni iniziali del circuito (nomepista, numerogiri, numerosettori, numeroautotot, meteo)
             setValoriIniziali(msg.nomepista,msg.meteo,parseInt(msg.numeroautotot),parseInt(msg.numerogiri),parseInt(msg.numerosettori));
         }

         if(msg.tipo=="1")
         {
            //popola tabella iniziale piloti in ordine di id macchina
            aggiungiPilota(parseInt(msg.auto), msg.nome, msg.scuderia);
         }

         if(msg.tipo=="2")
         {
          //controllo del meteo
          aggiornaMeteo(msg.meteo);
         }
         
         if(msg.tipo=="4")
            {
                document.getElementById("resp").innerHTML="risp arrivata";
                if(msg.esito)
                {
                  status_selezione_pilota = true; 
                  pilotaScelto = idPilotaSelezionato;         
                  document.getElementById("resp").innerHTML="Loading...";
                }
                else
                {
                  document.getElementById("resp").innerHTML="Il pilota selezionato e' gia' stato prenotato";
                  idPilotaSelezionato=-1;
                }
            }


        if(msg.tipo=="5")
        {
            //alert(msg.auto);
          document.getElementById('auto').value = msg.auto; 
          document.getElementById('gomme').value = msg.gomme; 
          document.getElementById('usuragomme').value = msg.usuragomme;
          document.getElementById('gommepitstop').value = msg.gommepitstop;
          document.getElementById('usuragommestop').value = msg.usuragommestop;
          document.getElementById('livellobenzina').value = msg.livellobenzina;
          document.getElementById('livellobenzinastop').value = msg.livellobenzinastop;
          document.getElementById('livellobenzinapitstop').value = msg.livellobenzinapitstop;
          document.getElementById('livellodanni').value = msg.livellodanni;
          document.getElementById('entratabox').value = msg.entratabox;
          document.getElementById('potenza').value = msg.potenza;
          document.getElementById('bravurapilota').value = msg.bravurapilota;
          document.getElementById('nomescuderia').value = msg.nomescuderia;
          document.getElementById('nomepilota').value = msg.nomeplota;
      
          $( "#slider-usuragomme" ).slider({
            range: "min",
            value: parseInt(msg.usuragomme),
            min: 0,
            max: max_usuragomme,
          });
      
          $( "#slider-livellobenzina" ).slider({
            range: "min",
            value: parseInt(msg.livellobenzina),
            min: 0,
            max: max_livellobenzina,
          });     

        }



        if(msg.tipo=="6") //messaggio di tempo, costruisco una tabella per la gara
         {        
            //alert("tempi"); 
            //popola tabella iniziale piloti in ordine di id macchina
            //alert("ricevuto 6");
            if(contatorePiloti == num_piloti)
            {
                // Aggiungo il messaggio alla pila                
                pila_messaggi.push(msg);
                pilotaScelto=parseInt(msg.auto);
                
                var tempoSettore = (parseFloat(msg.tempo)).toPrecision(8) - precedente;
                precedente = (parseFloat(msg.tempo)).toPrecision(8);
                inserisciTempoPilota(parseInt(msg.giro),parseInt(msg.settore),parseFloat(tempoSettore).toPrecision(8));
                //soste
                if(msg.settore==num_settori+1)
                  inserisciSosta(msg.giro);
                stampaStatistichePilota();
             }
          }

        //fine gara
        if(msg.tipo=="7")
        {
          document.getElementById("fine_gara").innerHTML("Gara finita!");
        }


        if(msg.tipo=="9")
        {
          for(var g=0; g<num_giri;g++)
            for(var s=0; s<num_settori;s++)
            {
              inserisciTempoPilota(parseInt(msg.giri[g].giro),parseInt(msg.giri[g].settori[s].settore),parseFloat(msg.giri[g].settori[s].tempo).toPrecision(8));
            }
           
           stampaStatistichePilota();
        }

        

          
      }
  
      function inserisciSosta(giro)
      {
          grigliaSoste[giro-1] = 1;
      }
      
    //FINE FUNZIONI WEBSOCKET PREDEFINITE
    //****************************************************************************
      
      function inizializzaGrigliaPiloti()
      {
                       
          var i=0;
          for (i=0; i<num_piloti; i++)
          {
              grigliaDatiPiloti[i] = new Array(); //una matrice per ogni pilota
         
            var j=0;
              for(j=0;j<num_giri;j++)
              {
                  //per ogni pilota per ogni giro un array
                  grigliaDatiPiloti[i][j]=new Array();
                  var k=0;
                  //aggiunta dei due settori che formano i box
                  for (k=0; k<num_settori+2; k++)
                  {
                      grigliaDatiPiloti[i][j][k] = new Array();
                  }
              }
          }
      }
 
       function inserisciTempoPilota(giro, settore, tempo)
       {
          tempiPilota[giro-1][settore-1]=tempo;
          tempiGiroPilota[giro-1] = parseFloat(tempiGiroPilota[giro-1]) + parseFloat(tempo);
       }
       
       
  // Avvio il websocket e resto in attesa per ricevere messaggi     
  function start()
    {
    startWebSocket();
  }
  
  
  function stampaStatistichePilota()
  {
  
    // Altezza dinamica della pagina in proporzione ai giri  (by Dario production ma corretto da Diego production)
    document.getElementById('pagina_2').style.height = (800+num_giri*30)+'px';
  
    var tabellaInfo = "Timeline del pilota: <b>" + nomePilotaArray[pilotaScelto-1] + " </b> della scuderia: <b>" +scuderiaPilotaArray[pilotaScelto-1] + "</b>";
    
    //intestazione
    tabellaInfo += "<table border='0' width='1000px' style='padding:4px;'> <tr> <th> N. Giro </th> ";
    for (var i=0; i<num_settori; i++)
    {
       tabellaInfo += " <th> Settore " + (i+1) + " </th> ";
    }
    
    //tabellaInfo += "<th>Tempo del giro</th> <th> Sosta </th> <th> Incidenti/Uscite </th> </tr> ";
    tabellaInfo += "<th>Tempo del giro</th> <th> Sosta </th> </tr> ";
    
    //calcolo il settore migliore tra i giri...
    settoriMigliori = new Array();
    for(var k=0; k<num_settori+2; k++)
      settoriMigliori[k]=0;
    
    //settori migliori
    for(var k=0; k<num_settori+2; k++)
      settoriMigliori[k]=tempiPilota[0][k];
    
    for(var g=1; g<num_giri; g++)
      for(var s=0; s<num_settori+2; s++)
        if(tempiPilota[g][s]<settoriMigliori[s] && tempiPilota[g][s]!=0)
          settoriMigliori[s]=tempiPilota[g][s];
    
    var giroVeloce = tempiGiroPilota[0];
    for(var l=1; l<num_giri; l++)
      if(tempiGiroPilota[l]<giroVeloce && tempiGiroPilota[l]!=0)
        giroVeloce=tempiGiroPilota[l];
    
      
    for (var i=0; i<num_giri; i++)
    {
        //colonna dei giri
        tabellaInfo += "<tr> <td align='center' style='background:#e5e5e5;'> " + (i+1) + " </td> ";
        
    var colore = "#e5e5e5;";
    var colore_michele_palloso = "#B5B5B5";
    var colore_michele_palloso_tantooo = "#C9C9C9";
                
        for(var j=0; j<num_settori; j++)
        {
          var primosettore = 0;
          var ultimosettore = 0;
          if(j==0) //primo settore e settore di uscita dai box (1 , +2)
          {
            if(tempiPilota[i][0]!=0)
            {
              primosettore = tempiPilota[i][0];
              if(primosettore==settoriMigliori[0])
                tabellaInfo += "<td align='center' style='background:"+colore+"'> <b> " + stampaTempo(parseFloat(primosettore).toPrecision(8),false) + " </b></td>";
              else
                tabellaInfo += "<td align='center' style='background:"+colore+"'> " + stampaTempo(parseFloat(primosettore).toPrecision(8),false) + " </td>";
            }
            else 
            {
              primosettore = tempiPilota[i][num_settori+1];
              if(primosettore==settoriMigliori[num_settori+1])
                tabellaInfo += "<td align='center' style='background:"+colore+"'> <b> " + stampaTempo(parseFloat(primosettore).toPrecision(8),false) + " </b></td>";
              else
                tabellaInfo += "<td align='center' style='background:"+colore+"'> " + stampaTempo(parseFloat(primosettore).toPrecision(8),false) + " </td>";
            }        
          }
          
          if(j==num_settori-1) //ultimo settore e penultimo settore (n,n+1)
          {
             if(tempiPilota[i][num_settori-1]!=0)
             {
              ultimosettore=tempiPilota[i][num_settori-1]; 
              if(ultimosettore==settoriMigliori[num_settori-1])
                tabellaInfo += "<td align='center' style='background:"+colore+"'> <b> " + stampaTempo(parseFloat(ultimosettore).toPrecision(8),false) + " </b></td>";
              else
                tabellaInfo += "<td align='center' style='background:"+colore+"'> " + stampaTempo(parseFloat(ultimosettore).toPrecision(8),false) + " </td>";
             }
             else 
             {
              ultimosettore = tempiPilota[i][num_settori];
              if(primosettore==settoriMigliori[num_settori])
                tabellaInfo += "<td align='center' style='background:"+colore+"'> <b> " + stampaTempo(parseFloat(ultimosettore).toPrecision(8),false) + " </b></td>";
              else
                tabellaInfo += "<td align='center' style='background:"+colore+"'> " + stampaTempo(parseFloat(ultimosettore).toPrecision(8),false) + " </td>";
             }
          }
          else
          {
            if(j!=0 && j!=num_settori-1)
              if(tempiPilota[i][j]==settoriMigliori[j])
                tabellaInfo += "<td align='center' style='background:"+colore+"'> <b> " + stampaTempo(parseFloat(tempiPilota[i][j]).toPrecision(8),false) + " </b> </td>";
              else
                tabellaInfo += "<td align='center' style='background:"+colore+"'>" +  stampaTempo(parseFloat(tempiPilota[i][j]).toPrecision(8),false) + "</td>";
          }
        }
        
        colore = colore_michele_palloso;
        
        // Colonna della somma dei tempi settore (tempo giro)
        if(tempiGiroPilota[i]==giroVeloce )
          tabellaInfo += "<td align='center' style='background:"+colore+"'> <b>"+ stampaTempo(parseFloat(tempiGiroPilota[i]).toPrecision(8),false) +"</b> </td>";
        else
          tabellaInfo += "<td align='center' style='background:"+colore+"'> "+ stampaTempo(parseFloat(tempiGiroPilota[i]).toPrecision(8),false) +" </td>";

        
        if(grigliaSoste[i]==1)
            tabellaInfo += "<td align='center' style='background:#e5e5e5;'> <b>SI</b> </td> ";
        else
            tabellaInfo += "<td align='center' style='background:#e5e5e5;'> NO </td> ";
        
        //if(grigliaIncidenti[i]==0 || grigliaIncidenti[i]==1)
        //    tabellaInfo += "<td align='center' style='background:#e5e5e5;'> <b>SI</b> </td>";
        //else
        //    tabellaInfo += "<td align='center' style='background:#e5e5e5;'> NO </td> ";
            
        tabellaInfo += "</tr>";
     }
     
     tabellaInfo += "</table>";
     document.getElementById("timelinePilota").innerHTML = tabellaInfo; 
  }
  
  function stampaTempo(tempo, withH)
  {

        if(tempo!=0)
        {
          var splitted = (tempo.toString()).split(".");
          var sec_num = parseInt(splitted[0], 10); // don't forget the second parm
          var hours   = Math.floor(sec_num / 3600);
          var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
          var seconds = sec_num - (hours * 3600) - (minutes * 60);

          if (hours   < 10) {hours   = "0"+hours;}
          if (minutes < 10) {minutes = "0"+minutes;}
          if (seconds < 10) {seconds = "0"+seconds;}
          var time = "";
          if(withH==true)
            time    = hours + "h  " + minutes + "\'  " + seconds + "\'\' " + splitted[1];
          else
            time    = minutes + "\'  " + seconds + "\'\' " + splitted[1][0]+splitted[1][1]+splitted[1][2];
          return time;      
        }
        else
          return "0";
      }
  

</script>