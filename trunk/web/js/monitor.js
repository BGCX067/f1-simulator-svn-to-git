<script type="text/javascript">
    var status_selezione_pilota = false;

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
    var griglia = new Array();
    // Pila di messaggi di tipo 1
    var pila_messaggi = new Array();

    //dati per la timeline
    grigliaDatiPiloti = new Array();
    grigliaSoste = new Array();
    giriMigliori = new Array();
    
    //grigliaIncidenti = new Array();

    var primo;
    var arrivatiTutti;
    
    // Variabili globali per i checkpoint
    var numero_checkpoint; // Numero checkpoint
    var checkpoint; // Array dei checkpoint. Indica quali settori sono checkpoint
    var pilecheckpoint;	// Tabella per tempi dei checkpoint. Ogni riga è un checkpoint a cui aggiungo i tempi delle auto

    contatoreTempoMessaggio9 = -1;

    var matriceMessaggio9 = new Array();

    //****************************************************************************
    //INIZIO FUNZIONI UTENTI

    //inizio funzione setValoriIniziali
    function setValoriIniziali(nomePista, infoMeteoIniziale, numPiloti, numGiri, numSettori, checkp) {
    
    	    	
        nome_pista = nomePista;
        info_meteo = infoMeteoIniziale;
        num_piloti = parseInt(numPiloti);
        num_giri = parseInt(numGiri);
        num_settori = parseInt(numSettori);
        entrata_box = parseInt(num_settori);
        entrata_box = entrata_box + 1;
        uscita_box = parseInt(num_settori);
        uscita_box = uscita_box + 2;
            
    	console.log("Funzione di inisializzazione");
    	// ------------------------------------------------
    	// INIZIO Inizializzazione checkpoint
    	    	
    		numero_checkpoint = checkp.length;
    		console.log("Numero checkpoint: "+numero_checkpoint);
    		// Creo array per salvarmi quali settori sono checkpoint
    		checkpoint = new Array();
    		// Creo la tabella checkpoint-tempi
    		pilecheckpoint = new Array();
    		// Popolo array e tabella
    		
    		for(var cp = 0; cp < numero_checkpoint; cp++){
    			checkpoint[cp] = checkp[cp].settore;
    			console.log("\t"+checkpoint[cp]);
    			pilecheckpoint[cp] = new Array();
    			
				for (var i = 0; i < num_piloti; i++){
					var pacchetto_checkpoint = new Array((i+1), 1, 0.0);				
				    pilecheckpoint[cp].push(pacchetto_checkpoint);
				}
            			
    		}
   			console.log(""); 
   			
   					  			   			
   			
    	// FINE Inizializzazione checkpoint    	
    	// ------------------------------------------------

        document.getElementById("nome_pista").innerHTML = nome_pista;        
        document.getElementById("num_piloti").innerHTML = num_piloti;
        document.getElementById("num_giri").innerHTML = num_giri;
        
        aggiornaMeteo(infoMeteoIniziale);

        primo = false;
        arrivatiTutti = 0;

        for (var i = 0; i < num_piloti; i++){
            griglia.push(new Array("", "", "", "", "", "", ""));
        }
            
        var i = 0;
        for (var i = 0; i < num_piloti; i++) {
            giriMigliori[i] = new Array();
            var j = 0;
            for (j = 0; j < num_giri; j++)
                giriMigliori[i][j] = 0;
        }
        i = 0;
        for (var i = 0; i < num_piloti; i++) {
            grigliaSoste[i] = new Array();
            var j = 0;
            for (j = 0; j < num_giri; j++)
                grigliaSoste[i][j] = 0;
        }
        
        /*
        i = 0;
        for (var i = 0; i < num_piloti; i++) {
            grigliaIncidenti[i] = new Array();
            var j = 0;
            for (j = 0; j < num_giri; j++)
                grigliaIncidenti[i][j] = 0;
        }
        */

        
        // Nascondo i piloti fasulli
        for (var i = num_piloti + 1; i < 11; i++) {
            document.getElementById('riga_' + i).style.visibility = 'hidden';
			document.getElementById('tempo'+i).innerHTML = 99999999;
			document.getElementById('posizione'+i).innerHTML = i;
			document.getElementById('id'+i).innerHTML = i;
			document.getElementById('giro'+i).innerHTML = 0;
			document.getElementById('settore'+i).innerHTML = 0;					
        }

        document.getElementById('fieldset_griglia').style.height = (num_piloti * 35) + 'px';

        //inizializzo matrice messaggio 9
        i = 0;
        //l'ultimo valore indica il fine gara, ce ne dovrebbe essere uno in piu per l'eventuale tempo totale e finale?
        for (var i = 0; i < num_piloti; i++) {
            matriceMessaggio9[i] = new Array(i+1,1,1,999999.0,999999.0);           
        }
        
        


    }
    //fine funzione setValoriIniziali

    //funzione che serve per aggiungere un pilota
    function aggiungiPilota(auto, nome, scuderia) {
        if (parseInt(contatorePiloti) < parseInt(num_piloti)) {
            idAutoArray.push(parseInt(auto));
            nomePilotaArray.push(nome);
            scuderiaPilotaArray.push(scuderia);
            contatorePiloti++;
        }
        if (parseInt(contatorePiloti) == parseInt(num_piloti)) {
            document.getElementById('info_complete').style.visibility = 'visible';
            document.getElementById('inizio').style.visibility = 'hidden';
            document.getElementById('tableSmart').style.visibility = 'visible';
            setTable(contatorePiloti);
            //TEST
            inizializzaGrigliaPiloti();
            aggiornaTempiGiri();
        }
    }
    //fine funzione aggiungiPilota

    //Aggiungo il nuovo giro alla matrice giriMigliori
    function aggiornaTempiGiri(idAuto, settore, tempo, giro) {
        if (giro == 1)
            giriMigliori[idAuto - 1][0] = tempo.toPrecision(8);
        else
        if (giro > 1) {
            var giroAttuale = tempo - sommaTempiGiri(idAuto - 1, giro - 2);
            giriMigliori[idAuto - 1][giro - 1] = giroAttuale.toPrecision(8);
        }
    }

    // Calcolo la somma dei tempi del pilota idAuto nei giri che vanno da 0 a fino_a_giro
    function sommaTempiGiri(idAuto, fino_a_giro) {
        var somma = 0;

        for (var i = 0; i <= fino_a_giro; i++) {
            somma += giriMigliori[idAuto][i] * 1;
        }

        return somma;
    }

    //inizio log soste
    function inserisciSosta(idAuto, giro) {
        grigliaSoste[idAuto - 1][giro - 1] = 1;
    }
    //fine log soste

    //inizio funzione aggiornaPosizioniPiloti
    function aggiornaPosizioniPiloti() {
        //creo la griglia
        var grigliaAttuale = new Array();
        for (i = 0; i < num_piloti; i++) {
            grigliaAttuale[i] = new Array();
            // scorro i campi della griglia
            for (j = 0; j < 7; j++) {
                grigliaAttuale[i].push(griglia[i][j]);
            }
        }

        insertionSort(grigliaAttuale, 0, num_piloti);
        stampaGriglia(grigliaAttuale);


        var indice = 1;
        var i = 0;
        for (i = 0; i < num_piloti; i++) {
            var tag_id = "id" + indice;
            var tag_posizione = "posizione" + indice;
            var id_pilota = document.getElementById(tag_id).innerHTML;
            var posizione = getPosizione(id_pilota, grigliaAttuale);
            //alert(indice+" "+id_pilota);
            document.getElementById(tag_posizione).innerHTML = posizione;

            var tag_giro = "giro" + indice;
            var tag_settore = "settore" + indice;
            var tag_tempo = "tempo" + indice;

            info = infoPilota(document.getElementById(tag_id).innerHTML);
            document.getElementById(tag_giro).innerHTML = info[0];
            document.getElementById(tag_settore).innerHTML = info[1];
            document.getElementById(tag_tempo).innerHTML = info[2];

            if (info[1] == num_settori + 1 || info[1] == num_settori + 2) {
                document.getElementById("box" + indice).innerHTML = "*";
            } else {
                document.getElementById("box" + indice).innerHTML = "";
            }

            indice = indice + 1;
        }
        ordinaColonna();

    }
    //fine funzione aggiornaPosizioniPiloti

    //inizio funzione infoPilota
    function infoPilota(idPilota) {
        return new Array(griglia[idPilota - 1][5], griglia[idPilota - 1][4], griglia[idPilota - 1][6]);
    }
    //fine funzione infoPilota

    //inizio funzione getPosizione
    function getPosizione(idAuto, grigliaAttuale) {

        var indice = 1;
        var i = 0;
        for (i = 0; i < num_piloti; i++) {
            if (grigliaAttuale[i][1] == idAuto) {
                return indice;
            }
            indice = indice + 1;
        }
        return indice;
    }
    //fine funzione getPosizione
    
      

    //inizio funzione insertionSort
    function insertionSort(grigliaAttuale, min, max) {
        for (i = 1; i < max; i++) {
            var x = i;
            var j = i - 1;
            for (; j >= min; j--) {
                if (posizionePrima(grigliaAttuale, j, x)) {
                    scambiaRiga(grigliaAttuale, j, x);
                    x = j;
                } else
                    break;
            }
        }
    }
    //fine funzione insertionSort

    // funzione posizionePrima (risponde alla domanda: i è prima di j?)
    function posizionePrima(grigliaAttuale, i, j) {


		
        var settore_i = parseInt(grigliaAttuale[i][4]);
        var settore_j = parseInt(grigliaAttuale[j][4]);
        var giro_i = grigliaAttuale[i][5];
        var giro_j = grigliaAttuale[j][5];
        var percentuale_settore_i = grigliaAttuale[i][6];
        var percentuale_settore_j = grigliaAttuale[j][6];
        var tempo_fine_settore_i = grigliaAttuale[i][7];
        var tempo_fine_settore_j = grigliaAttuale[j][7];                

		var arrivata_j = parseInt(grigliaAttuale[j][8]);
		var arrivata_i = parseInt(grigliaAttuale[i][8]);		
		
        var giro_piu_avanti = false;
        var stesso_giro = false;

        // Correzione problema che al secondo settore dei box (numero elevato) corrisponde il nuovo giro
        // C'era il problema della visualizzazione nei monitor (finto sorpasso)
        // Se mi trovo nel secondo settore dei box, faccio risultare che il giro non Ã¨ ancora completato
        if (settore_j == (num_settori + 2)) {settore_j = 1*1.0;}
        if (settore_i == (num_settori + 2)) {settore_i = 1*1.0;} 
        
        // Controllo se un'auto è già arrivata e se si trova nel primo settore (o nel secondo dei box)
        // In questo caso riduco un po' il settore.
        if(arrivata_j == 1  && settore_j == 1){
        	settore_j = settore_j*1.0;
        	settore_j = settore_j-0.1;        	        	
        }
        
        if(arrivata_i == 1  && settore_i == 1){
        	settore_i = settore_i*1.0;
        	settore_i = settore_i-0.1;
        }    
   

        // Confronto se il giro di j Ã¨ maggiore di i
        if (giro_j > giro_i)
            giro_piu_avanti = true;
        else
        if (giro_j == giro_i)
            stesso_giro = true;



        // considero settore 7 (ultimo prima del traguardo) e 8 (primo dei box) uguali, o viceversa        
        var settore_piu_avanti = false;
        var stesso_settore = false;
                
        if (settore_i == settore_j) {
            stesso_settore = true;
        } else {
            if (settore_j > settore_i) {
                settore_piu_avanti = true;
            }
        }
        
		// confronto le percentuali di avanzamento nel settore
        var percentuale_settore_piu_avanti = false;
        var stessa_percentuale_settore = false;
        
        if (percentuale_settore_i == percentuale_settore_j) {
            stessa_percentuale_settore = true;
        } else {
            if (percentuale_settore_j > percentuale_settore_i) {
                percentuale_settore_piu_avanti = true;
            }
        }   
        
        
		// confronto i tempi di fine settore (per la fine gara)
        var tempo_piu_avanti = false;
        var stesso_tempo = false;
        
        if (tempo_fine_settore_i == tempo_fine_settore_j) {
            stesso_tempo = true;
        } else {
            if (tempo_fine_settore_j > tempo_fine_settore_i) {
                tempo_piu_avanti = true;
            }
        }   
                     
        
        //griglia aggiornata dopo l'arrivo di un tempo, ora devo invertire le posizioni sulla base di "auto"
        if (giro_piu_avanti) {
	        //console.log(grigliaAttuale[j][1]+"->"+grigliaAttuale[i][1]+" A "+"("+giro_j+" "+giro_i+")");
            return true;
        } else
        if (stesso_giro && settore_piu_avanti) {
   	        //console.log(grigliaAttuale[j][1]+"->"+grigliaAttuale[i][1]+" B "+"("+settore_j+" "+settore_i+") ("+arrivata_j+" "+arrivata_i+")");
            return true;
        } else
        if (stesso_giro && stesso_settore && percentuale_settore_piu_avanti) {
	        //console.log(grigliaAttuale[j][1]+"->"+grigliaAttuale[i][1]+" C "+"("+percentuale_settore_j+" "+percentuale_settore_i+") ("+arrivata_j+" "+arrivata_i+")");        
            return true;
        } else 
        if (stesso_giro && stesso_settore && stessa_percentuale_settore && !tempo_piu_avanti) {
 	        //console.log(grigliaAttuale[j][1]+"->"+grigliaAttuale[i][1]+" D "+"("+tempo_fine_settore_i+" "+tempo_fine_settore_j+")");
            return true;
        } else {
            return false;
        }
    }
    //fine funzione posizionePrima

    //inizio funzione scambiaRiga
    function scambiaRiga(griglia, rigaI, rigaJ) {
        var j = 0;
        //passo 1
        temp = new Array();
        for (j = 0; j < 9; j++) temp.push(griglia[rigaI][j]);

        //passo 2
        j = 0;
        for (j = 0; j < 9; j++) griglia[rigaI][j] = griglia[rigaJ][j];

        //passo 3
        j = 0;
        for (j = 0; j < 9; j++) griglia[rigaJ][j] = temp[j];

        griglia[rigaI][0] += 1;
        griglia[rigaJ][0] -= 1;
    }
    //fine funzione scambiaRiga

    //inizio funzione ordinaColonna
    function ordinaColonna() {
        javascript: $('#example1_table').sortTable({
            onCol: 1,
            keepRelationships: true,
            sortType: 'numeric'
        });
    }
    //fine funzione ordinaColonna

    //inizio funzione stampaGriglia
    function stampaGriglia(grigliaTemp) {
        var tabella = "";
        //document.getElementById("griglia").innerHTML = tabella;
        var numPiloti = parseInt(num_piloti);
        tabella = "<table border='1' width='700'> <tr><th>ID_Auto</th> <th>Nome Pilota</th>";
        tabella = tabella + "<th>Scuderia</th> <th>Settore</th> <th>Giro</th> <th>Tempo totale</th> <th>Time Line</th> </tr>";
        for (var i = 0; i < numPiloti; i++) {
            tabella += "<tr>";
            tabella += "<td> " + grigliaTemp[i][1] + " </td>";
            tabella += "<td> " + grigliaTemp[i][2] + " </td>";
            tabella += "<td> " + grigliaTemp[i][3] + " </td>";
            tabella += "<td> " + grigliaTemp[i][4] + " </td>";
            tabella += "<td> " + grigliaTemp[i][5] + " </td>";
            tabella += "<td> " + grigliaTemp[i][6] + " </td>";
            tabella += "<td>";
            tabella += "<input type='radio' onclick='javascript:recuperaTimeLine(" + grigliaTemp[i][1] + ")'";
            tabella += "</td>";
            tabella += "</tr>";
        }

        tabella += "</table>";
        //document.getElementById("griglia").innerHTML = tabella;

    }
    //fine funzione stampaGriglia

    //inizio funzione inizializzaGriglia
    function inizializzaGriglia() {
        //posizioniCambiate, id auto, nome pilota, tempo_ultimo_settore,n_giri,tempotot_gara,totposizioni
        var i = 0;
        for (i = 0; i < parseInt(num_piloti); i++) {
            //creo la griglia
            //posizioni update - idauto - nomePilota - scuderia - tempoultimosettore -
            //numerogiro - tempototalegara - posizioniTotaliGuadagnate
            griglia[i] = new Array(0, idAutoArray[i], nomePilotaArray[i], scuderiaPilotaArray[i], 0, 0, 0);
        }
        stampaGriglia(griglia);
    }
    //fine funzione inizializzaGriglia

    //inizio funzione setTable
    function setTable(num_piloti) {
        var tabella = "";
        var numPiloti = parseInt(num_piloti);
        tabella = "<table border='3' width='300'> <tr><th> Id Auto </th> <th>Nome Pilota</th>";
        tabella = tabella + "<th>Scuderia</th> </tr>";
        var indice = 0;
        for (var i = 0; i < numPiloti; i++) {
            tabella += "<tr>";
            tabella += "<td> " + idAutoArray[i] + " </td>";
            tabella += "<td> " + nomePilotaArray[i] + " </td>";
            tabella += "<td> " + scuderiaPilotaArray[i] + " </td>";
            tabella += "</tr>";
            indice = indice + 1;
            var tag_posizione = "posizione" + indice;
            var tag_id = "id" + indice;
            var tag_nome = "nome" + indice;
            var tag_giro = "giro" + indice;
            var tag_settore = "settore" + indice;
            var tag_tempo = "tempo" + indice;
            document.getElementById(tag_posizione).innerHTML = indice;
            document.getElementById(tag_id).innerHTML = idAutoArray[i];
            document.getElementById(tag_nome).innerHTML = nomePilotaArray[i];
            info = infoPilota(idAutoArray[i]);
            document.getElementById(tag_giro).innerHTML = info[0];
            document.getElementById(tag_settore).innerHTML = info[1]
            document.getElementById(tag_tempo).innerHTML = info[2];
            //document.getElementById(tag_tempo).innerHTML = stampaTempo(info[2], true);
        }
        tabella += "</table>";
        //document.getElementById("tabellaPiloti").innerHTML = tabella;
        inizializzaGriglia();
    }
    //fine funzione setTable

    //inizio funzione aggiornaMeteoexample1_table
    function aggiornaMeteo(infoMeteo) {
        //info_meteo=infoMeteo;
        document.getElementById("info_meteo").innerHTML = info_meteo;
        if (infoMeteo == "0") //sole
        {
            document.getElementById("info_meteo").innerHTML = "soleggiato";
            //document.getElementById("info_complete").style.backgroundImage="url('sole.png')";
            //document.body.style.backgroundImage="url('sole.png')";
        } else
        if (infoMeteo == "1") {
            document.getElementById("info_meteo").innerHTML = "parzialmente nuvoloso";
            //document.body.style.backgroundImage="url('nuvoloso.png')";
            //document.getElementById("info_complete").style.backgroundImage="url('nuvoloso.png')";
        } else
        if (infoMeteo == "2") {
            document.getElementById("info_meteo").innerHTML = "nuvoloso";
            //document.body.style.backgroundImage="url('nuvoloso.png')";
            //document.getElementById("info_complete").style.backgroundImage="url('nuvoloso.png')";
        } else
        if (infoMeteo == "3") {
            document.getElementById("info_meteo").innerHTML = "piovoso";
            //document.body.style.backgroundImage="url('pioggia.png')";
            //document.getElementById("info_complete").style.backgroundImage="url('pioggia.png')";
        }
    }
    //fine funzione aggiornaMeteo

    //inizio funzione start - prima funzione avviata
    function start() {
        //threadVisualizzazione();
        //document.getElementById('info_complete').style.display = 'none';
        //document.getElementById('inizio').style.display = 'block';
        startWebSocket();
    }
    //fine funzione start - prima funzione avviata

    //inizio funzione threadVisualizzazione
    function threadVisualizzazione() {
        setTimeout(function () {
            sistemaGriglia();
            // visualizzo griglia
            threadVisualizzazione();
        }, 1500);
    }
    //fine funzione threadVisualizzazione

    //inizio funzione sistemaGriglia
    function sistemaGriglia() {
        if (pila_messaggi.length > 0) {
            // svuto la coda
            var copia_pila = pila_messaggi;
            pila_messaggi = new Array();
            // Scorro i messaggi della pila
            var i = 0;
            for (i = 0; i < copia_pila.length; i++) {
                //recupero il messaggio
                var msg = new Array(0, copia_pila[i].auto, copia_pila[i].settore, copia_pila[i].giro, copia_pila[i].tempo);
                if (griglia[msg[1] - 1][6] < msg[4]) {
                    griglia[msg[1] - 1][4] = copia_pila[i].settore;
                    griglia[msg[1] - 1][5] = copia_pila[i].giro;
                    griglia[msg[1] - 1][6] = copia_pila[i].tempo;
                }
            }
            aggiornaPosizioniPiloti();
        }
    }
    //fine funzione sistemaGriglia

    //FINE FUNZIONI UTENTI



    // INIZIO FUNZIONI TEMP

    // Funzione per aggiornare la tabella grande del monitor
    // Il tempo Ã¨ il tempo totale traso
    function aggiornaTabellaGrande(msg, tempo, settore) {
        //popola tabella iniziale piloti in ordine di id macchina
        if (contatorePiloti == num_piloti) {
            // Aggiungo il messaggio alla pila
            aggiornaStatistichePilota(msg.auto, msg.settore, msg.tempo, msg.giro);
            //stampaStatistichePilota();
            pila_messaggi.push(msg);

            // Se sono a fine giro (settore 7 o 8) vado a salvare in una seconda matrice il tempo del giro
            if (msg.settore == num_settori || msg.settore == num_settori + 1) {
                // Vado ad inserire il nuovo tempo del giro nella matrice giriveloci
                aggiornaTempiGiri(msg.auto, msg.settore, msg.tempo, msg.giro);
            }

            if (msg.settore == num_settori + 1)
                inserisciSosta(msg.auto, msg.giro);
        }
    }

    // FINE FUNZIONI TEMP


    //INIZIO FUNZIONI WEBSOCKET PREDEFINITE
    function startWebSocket() {



        ws = new WebSocket("ws://" + window.location.hostname + ":8080/monitor");
        ws.onopen = function (evt) {
            onOpen(evt)
        };
        ws.onclose = function (evt) {
            onClose(evt)
        };
        ws.onmessage = function (evt) {
            onMessage(evt)
        };
        ws.onerror = function (evt) {
            onError(evt)
        };
    }

    function onOpen(evt) {
        //Websocket avviato
    }

    function onClose(evt) {
        //Websocket chiuso fine trasmissioni
    }

    function onError(evt) {
        //alert("Errore");
    }

    function doSend(message) {
        ws.send(message);
    }

    function onMessage(evt) {
        // Recupero il valore del messaggio
        var msg = JSON.parse(evt.data);

        // Controllo il valore del tipo
        if (msg.tipo == 0) {
            // Informazioni iniziali del circuito (nomepista, numerogiri,numerosettori,numeroautotot,meteo)
            console.log("RICEVUTI VALORI INIZIALI");
            console.log("Tipo mess: "+msg.tipo);
            console.log("Nome pista: "+msg.nomepista);
            console.log("Numero giri: "+msg.numerogiri);
            console.log("Numero settori: "+msg.numerosettori);
            console.log("Numero auto: "+msg.numeroautotot);
            console.log("Meteo: "+msg.meteo);
            console.log("Numero checkpoint: "+msg.checkpoint.length);
            for(var cp=0;  cp<msg.checkpoint.length; cp++){
            	console.log("\t"+msg.checkpoint[cp].settore);
            }
            console.log("");
            // Funzione di inizializzazione
            setValoriIniziali(msg.nomepista, msg.meteo, parseInt(msg.numeroautotot), parseInt(msg.numerogiri), parseInt(msg.numerosettori), msg.checkpoint);
        }

        //informazioni sulle macchine
        //PER DIEGO EX TIPO 2
        if (msg.tipo == 1) {
        	console.log("MESSAGGIO 1");
            //alert("2 "+nomePilotaArray.indexOf(msg.nome)==-1);
            //if(nomePilotaArray.indexOf(msg.nome)==-1){
            //popola tabella iniziale piloti in ordine di id macchina
            aggiungiPilota(parseInt(msg.auto), msg.nome, msg.scuderia);
            //}
        }

        //controllo del meteo 
        //PER DIEGO EX TIPO 3
        if (msg.tipo == 2) {
            aggiornaMeteo(msg.meteo);
        }

        //gestione dei tempi cambiata in GESTIONE PERCENTUALI 
        //PER DIEGO EX TIPO 9
        if (msg.tipo == 3)
        {
			
			
            document.getElementById('info_complete').style.visibility = 'visible';
            document.getElementById('inizio').style.visibility = 'hidden';
            

            document.getElementById('tempo_gara').innerHTML = parseFloat(msg.tempogara);

            if((parseInt(msg.tempogara) > parseInt(contatoreTempoMessaggio9)))
            {
              
	            console.log("MESSAGGIO 3");
	            
                // recupero il tempo di gara
                contatoreTempoMessaggio9 = msg.tempogara;                  
                                    
                //msg.tempi è la mia matrice
                for (var i = 0; i<msg.tempi.length; i++)
                {
                
                    // Inserisco i valori in matriceMessaggi9
                    matriceMessaggio9[(parseInt(msg.tempi[i].auto))-1][0] = parseInt(msg.tempi[i].auto); // 0 auto
                    matriceMessaggio9[(parseInt(msg.tempi[i].auto))-1][1] = parseInt(msg.tempi[i].settore); // 1 settore
                    matriceMessaggio9[(parseInt(msg.tempi[i].auto))-1][2] = parseInt(msg.tempi[i].giro); // 2 giro
                    matriceMessaggio9[(parseInt(msg.tempi[i].auto))-1][3] = parseFloat(msg.tempi[i].tempoentrata); // 3 tempo entrata
                    matriceMessaggio9[(parseInt(msg.tempi[i].auto))-1][4] = parseFloat(msg.tempi[i].tempouscita); // 4 tempo uscita
                    // 5 auto arrivata
                    // 6 percentuale settore
                }  
                     
                /**for (var i = 0; i<matriceMessaggio9.length; i++)
                {
	                console.log(
	                	matriceMessaggio9[i][0]+" "+
	                	matriceMessaggio9[i][1]+" "+
	                	matriceMessaggio9[i][2]+" "+
	                	matriceMessaggio9[i][3]+" "+
	                	matriceMessaggio9[i][4]);
                }                
                console.log("");
                */
            }
            
            if(parseInt(contatorePiloti) == parseInt(num_piloti)){
            
            // Inizializzo grigliaAttuale
            var grigliaAttuale = new Array();
            
            var indice = 0; 
            //console.log("GRIGLIA ATTUALE");                       
            for (var p = 0; p < num_piloti; p++) 
            {

                // Creo la riga della griglia attuale
                grigliaAttuale[p] = new Array();

                    var intervallo = (parseFloat(matriceMessaggio9[p][4]) - parseFloat(matriceMessaggio9[p][3]));
                    var tempo_nel_settore = ((parseFloat(msg.tempogara)-parseFloat(matriceMessaggio9[p][3])));                  
                    var percentualeSettore = tempo_nel_settore*100.0/intervallo;
                    
                    if(intervallo==0.00)
                    	percentualeSettore = parseFloat(0.00);
                    	
                    if(matriceMessaggio9[p][5]==1 && (matriceMessaggio9[p][1]==(num_settori+2) || matriceMessaggio9[p][1]==1)){
                        percentualeSettore = parseFloat(100.00);
                    }                   

                    matriceMessaggio9[p][6] =  percentualeSettore;
                                            
                    // Popolo la griglia attuale con cui farò l'ordinamento dei piloti
                    grigliaAttuale[p] = new Array(
                        "", // 0 non arrivata
                        matriceMessaggio9[p][0], // 1 id auto
                        nomePilotaArray[p], // 2 nome pilota
                        scuderiaPilotaArray[p], // 3 scuderia pilota
                        matriceMessaggio9[p][1], // 4 settore
                        matriceMessaggio9[p][2], // 5 giro
                        matriceMessaggio9[p][6], // 6 percentuale settore
                        parseFloat(matriceMessaggio9[p][3]), // 7 tempo uscita
                        parseInt(0) // 8 non arrivata
                        ); 
                        
                        
                        
                    // Se l'auto è arrivata setto il primo campo a 1
                    // In fase di ordinamento controllo se l'auto è arrivata e se è al settore 9 o 1.
                    // In tal caso pongo a 100% la precentuale-settore e diminuisco il settore di un po' (0,9 = 1; 8,9 = 9).
                    if(matriceMessaggio9[p][5]==1){
                        grigliaAttuale[p][8] = 1;
                    }                                    
                    
                    if(parseInt(matriceMessaggio9[p][5])==1){
                        console.log("");
                        console.log("####################################");
                        console.log("#### ARRIVATO A FINE GARA "+ matriceMessaggio9[p][0] + " "+matriceMessaggio9[p][4]);
                        console.log("####################################");
                        console.log("");                        
                    }
                    
                    
                    /*	grigliaAttuale[p][1]+" "+
                    	grigliaAttuale[p][2]+" "+
                    	grigliaAttuale[p][3]+" "+
                    	grigliaAttuale[p][4]+" "+
                    	grigliaAttuale[p][5]+" "+
                    	grigliaAttuale[p][6]+" "+
                    	grigliaAttuale[p][7]+" "+
                    	grigliaAttuale[p][8] );
                    	*/
                    
                    
            }
            //console.log("");

            // Ordinamento di grigliaAttuale
            insertionSort(grigliaAttuale, 0, num_piloti);

            for (var j = 0; j < grigliaAttuale.length; j++) {

                indice = indice + 1;
                var tag_posizione = "posizione" + indice;
                var tag_id = "id" + indice;
                var tag_nome = "nome" + indice;
                var tag_giro = "giro" + indice;
                var tag_settore = "settore" + indice;
                var tag_tempo = "tempo" + indice;
                var tag_gap = "gap" + indice;
                
                var tag_posizione = "posizione" + indice;
                var id_pilota = document.getElementById(tag_id).innerHTML;

                var posizione = getPosizione(parseInt(id_pilota), grigliaAttuale);

                document.getElementById(tag_posizione).innerHTML = posizione; 
  
  				/*
		            console.log(tag_id+" ("+document.getElementById(tag_giro).innerHTML +" "+ document.getElementById(tag_settore).innerHTML+") "+ 
		                j+" "+nomePilotaArray[parseInt(id_pilota)-1]+" "+parseInt(id_pilota)+" ("+matriceMessaggio9[parseInt(id_pilota)-1][2]+" "+matriceMessaggio9[parseInt(id_pilota)-1][1]+" "+matriceMessaggio9[parseInt(id_pilota)-1][6]+" "+matriceMessaggio9[parseInt(id_pilota)-1][3]+") ");
		          */                     
              
		            // Se mi arriva un messaggio (4 9) giro 4, secondo settore box -> in realtà sono al (4 1)
				    if(matriceMessaggio9[parseInt(id_pilota)-1][1] == (num_settori+2)){             
				        document.getElementById(tag_settore).innerHTML = 1;
				    }
				    else{
				    	document.getElementById(tag_settore).innerHTML = matriceMessaggio9[(parseInt(id_pilota))-1][1];                    
				    }

		            document.getElementById(tag_giro).innerHTML = matriceMessaggio9[(parseInt(id_pilota))-1][2];
                    
                    var num = new Number(parseFloat(matriceMessaggio9[parseInt(id_pilota)-1][6]));
                    var new_number = Math.round(num).toFixed(2);
                    var sep = ((new_number).toString()).split(".");
		            document.getElementById(tag_tempo).innerHTML = sep[0] + " %";
		            


		            // Se l'auto è ai box allora visualizzo l'asterisco
		            if (matriceMessaggio9[parseInt(id_pilota)-1][1] == num_settori + 1 || matriceMessaggio9[parseInt(id_pilota)-1][1] == num_settori + 2) {
		              document.getElementById("box" + indice).innerHTML = "*";
		            } else {
		              document.getElementById("box" + indice).innerHTML = "";
		            }
		            
				    //-------------------------------------- 
				    // INIZIO calcolo il gap dal precedente
		
				    var gap;
				    // Se sono primo il mio gap è 0
				    // altrimenti cerco il tempo più alto dell'auto nelle pile		
				    var mia_posizione = parseInt(posizione); 
				    var mio_settore = matriceMessaggio9[parseInt(id_pilota)-1][1];
				    var id_auto_davanti;
				    var setore_auto_davanti;
				       
				    if(parseInt(mia_posizione) == 1){
						gap=0;
						console.log("Posizione: di "+nomePilotaArray[parseInt(id_pilota-1)]+": "+mia_posizione+" - Gap: "+ gap);
						document.getElementById(tag_gap).innerHTML = gap.toString();			
								
						//document.getElementById(tag_gap).innerHTML = stampaTempo(gap.toString(),false);						
		            }else{
		            	var tempo_maggiore = -1.0;
		            	var index_checkpoint = -1;
		            	var tempo_maggiore_auto_davanti = -1.0;
		            	var giro_auto = -1;
		            	var giro_auto_davanti = -1;
		            	// Scorro le pile dei checkpoint		            	
				        for(var cp=0; cp < numero_checkpoint; cp++){
				        	// Scorro i tempi
				        	//console.log("cp:\t"+cp)
				        	for(var t=0; t < pilecheckpoint[cp].length; t++){
				        		// Seleziono il tempo maggiore
				        		//console.log("t:\t\t"+t+"-> auto:"+parseFloat(pilecheckpoint[cp][t][0])+" tempo:"+parseFloat(pilecheckpoint[cp][t][2]));
				        		if (parseFloat(pilecheckpoint[cp][t][2]) > tempo_maggiore && 
				        			parseInt(pilecheckpoint[cp][t][0]) == parseInt(id_pilota)){
				        			tempo_maggiore = parseFloat(pilecheckpoint[cp][t][2]);
				        			index_checkpoint = cp;
				        			giro_auto = pilecheckpoint[cp][t][1];
				        		}
				        	}	            							
				        }
				       	//console.log("Tempo maggiore: "+tempo_maggiore+" - Checkpoint: "+index_checkpoint);
						// Trovo l'auto che precede
						//id_auto_davanti =  grigliaAttuale[posizione-2][1];
						id_auto_davanti =  grigliaAttuale[0][1];
						//console.log("Auto che precede: "+nomePilotaArray[parseInt(id_auto_davanti)-1]);
						// Trovo il tempo più vecchio dell'auto che precede, nello stesso checkpoint

						
						for(var t=0; t<pilecheckpoint[index_checkpoint].length; t++){
							if(	parseFloat(tempo_maggiore_auto_davanti) < parseFloat(pilecheckpoint[index_checkpoint][t][2]) && 
								parseInt(pilecheckpoint[index_checkpoint][t][0]) == parseInt(id_auto_davanti) &&
								parseFloat(tempo_maggiore_auto_davanti)<parseFloat(tempo_maggiore)){
								tempo_maggiore_auto_davanti = pilecheckpoint[index_checkpoint][t][2];
								giro_auto_davanti = pilecheckpoint[index_checkpoint][t][1];								
							}						
						}
						gap = tempo_maggiore - tempo_maggiore_auto_davanti;
						console.log("Posizione: di "+nomePilotaArray[parseInt(id_pilota)-1]+": (posizione:"+mia_posizione+" tempo: "+tempo_maggiore+") - Gap: (al checkpoint "+index_checkpoint+") "+ gap + " dall'auto "+ nomePilotaArray[parseInt(id_auto_davanti)-1] +" (posizione: " + (posizione-1) + " tempo: "+tempo_maggiore_auto_davanti+")");					

						var differenza_giri = parseInt(giro_auto_davanti) - parseInt(giro_auto);
					

						//console.log("mia_posizione: "+mia_posizione+" "+id_auto_davanti);
						settore_auto_davanti =  matriceMessaggio9[parseInt(id_auto_davanti)-1][1];
					
						// Controllo se è doppiato
						var doppiato = false;
 						if(mio_settore == (num_settori+2)){             
				    	    mio_settore = 1;
				   		}
 						if(settore_auto_davanti == (num_settori+2)){             
				    	    settore_auto_davanti = 1;
				   		}
 						if(mio_settore == (num_settori+1)){             
				    	    mio_settore = num_settori;
				   		}
 						if(settore_auto_davanti == (num_settori+1)){             
				    	    settore_auto_davanti = num_settori;
				   		}				   						   								
					
						//console.log("### "+parseInt(giro_auto_davanti) +" "+ parseInt(giro_auto)+ " "+parseInt(settore_auto_davanti)+" "+parseInt(mio_settore));
						if(differenza_giri > 1){
							doppiato = true;
						}else{
							if(differenza_giri == 1){
								if(parseInt(settore_auto_davanti) >= parseInt(mio_settore))
									doppiato= true;
							}
					
						}
					
						if(doppiato){
							document.getElementById(tag_gap).innerHTML = "+ "+differenza_giri+" Lap";
						}else{
							if(tempo_maggiore==0){
								// Se non è ancora passato a nessun checkpoint
								document.getElementById(tag_gap).innerHTML = "Ricalcolo..";
							}else{
								
								if(gap>0){
										//document.getElementById(tag_gap).innerHTML = stampaTempo(gap.toString(),false);
										var result = gap.toFixed(3);
										document.getElementById(tag_gap).innerHTML = result.toString();
									}
								else{
										document.getElementById(tag_gap).innerHTML = "Ricalcolo..";
										console.log("!!!--- "+gap+" "+mio_settore+" "+ settore_auto_davanti+" "+id_pilota+" "+id_auto_davanti);
									}
							}
						}						
					}

            }
            
			for(var cp=0; cp < numero_checkpoint; cp++){
				// Scorro i tempi
				console.log("cp:\t"+cp)
				for(var t=0; t < pilecheckpoint[cp].length; t++){
	        		// Seleziono il tempo maggiore
	        		console.log("t:\t\t"+t+"-> auto:"+parseFloat(pilecheckpoint[cp][t][0])+" tempo:"+parseFloat(pilecheckpoint[cp][t][2]));
	        	}	            							
	        }            
            
            console.log("");            
                       

          // Funzione jquery che ordina la tabella
          ordinaColonna();
          
          }
        }

        //statistiche giri piloti
        //PER DIEGO EX TIPO 5
        if (msg.tipo == 4) {
           //statistiche aggiornamento piloti
            //giriMigliori Ã¨ la matrice da aggiornare...
            for (var g = 0; g < num_giri; g++) {
                giriMigliori[msg.auto - 1][g] = parseFloat(msg.giri[g].tempo).toPrecision(8); //aggiorno i tempi su giro per le statistiche del pilota...
                if (msg.giri[g].sosta == true)
                    inserisciSosta(msg.auto, msg.giri[g].giro);
            }

        }

        //comunicazione fine giro pilota
        //PER DIEGO EX TIPO 10 (creato da poco)
        if (msg.tipo == 6)
        {
            
            if(msg.giro==1)
                giriMigliori[msg.auto - 1][msg.giro-1] = parseFloat(msg.tempo).toPrecision(8);
            else
                if(msg.giro>1)
                    giriMigliori[msg.auto - 1][msg.giro-1] = (parseFloat(msg.tempo).toPrecision(8)) - (parseFloat(giriMigliori[msg.auto - 1][msg.giro-2]).toPrecision(8));
        }

        //fine gara pilota
        if (msg.tipo == 7) {
            settaFineGaraAuto(parseInt(msg.auto));

        }


        //MESSAGGIO TIPO 8 E 9 ATTUALMENTE NON PRESENTI (buco per eventuali altri messaggi)


        
        // Messaggio inviato solo se mi collego a gara terminata         
        if (msg.tipo == 10) {
            
            document.getElementById('info_complete').style.visibility = 'visible';
            document.getElementById('inizio').style.visibility = 'hidden';
            document.getElementById("tempovspercentuale").innerHTML = "Tempo";

            // inizializzazione
            var numero_giri = msg.numerogiri;
            var numero_piloti = msg.numeroautotot;
            var numero_settori = msg.numerosettori;
            var grigliaAttuale = new Array();

            var indice = 0;
            grigliaAttuale = new Array();
            for (var p = 0; p < numero_piloti; p++) {

                grigliaAttuale[p] = new Array();
                var tempo = 0;
                for (var giri = 0; giri < msg.gara[p].giri.length; giri++) {

                    tempo = tempo + msg.gara[p].giri[giri].tempo * 1;
                }

                grigliaAttuale[p] = new Array(
                        "", // 0 non arrivata
                        msg.gara[p].auto, // 1 id auto
                        msg.gara[p].nome, // 2 nome pilota
                        msg.gara[p].scuderi, // 3 scuderia pilota
                        numero_settori, // 4 settore
                         msg.gara[p].giri.length, // 5 giro
                        100, // 6 percentuale settore
                        parseFloat(tempo), // 7 tempo uscita
                        parseInt(0) // 8 non arrivata
                        );

            }

            insertionSort(grigliaAttuale, 0, num_piloti);



            for (var j = 0; j < numero_piloti; j++) {

                indice = indice + 1;
                var tag_posizione = "posizione" + indice;
                var tag_id = "id" + indice;
                var tag_nome = "nome" + indice;
                var tag_giro = "giro" + indice;
                var tag_settore = "settore" + indice;
                var tag_tempo = "tempo" + indice;
                document.getElementById(tag_posizione).innerHTML = indice;
                document.getElementById(tag_id).innerHTML = grigliaAttuale[j][1];
                document.getElementById(tag_nome).innerHTML = grigliaAttuale[j][2];
                document.getElementById(tag_giro).innerHTML = grigliaAttuale[j][5];
                document.getElementById(tag_settore).innerHTML = grigliaAttuale[j][4];
                if (grigliaAttuale[j][5] == numero_giri)
                    if (j == 0)
                        document.getElementById(tag_tempo).innerHTML = stampaTempo(grigliaAttuale[j][7], true);
                    else
                        document.getElementById(tag_tempo).innerHTML = stampaTempo(grigliaAttuale[j][7], true) + " + " + stampaTempo(grigliaAttuale[j][7] - grigliaAttuale[0][7], false);
                    else
                if (numero_giri - grigliaAttuale[j][5] == 1)
                    document.getElementById(tag_tempo).innerHTML = stampaTempo(grigliaAttuale[j][7], true) + " +" + (numero_giri - grigliaAttuale[j][5]) * 1 + " lap";
                else
                    document.getElementById(tag_tempo).innerHTML = stampaTempo(grigliaAttuale[j][7], true) + " +" + (numero_giri - grigliaAttuale[j][5]) * 1 + " laps";


                //setto giri piloti
                for (var g = 0; g < grigliaAttuale[j][5]; g++) {
                    giriMigliori[j][g] = msg.gara[(grigliaAttuale[j][1]) - 1].giri[g].tempo;
                }


            }

        }

        //messaggio gestione checkpoint
        if(msg.tipo == 11)
        {
			// ### SEZIONE CHECKPOINT - POPOLO TABELLA
		                                      
            // Scorro i checkpoint e popolo la tabella dei checkpoint
			for(var ckpoint = 0; ckpoint < msg.giri.length; ckpoint++){
				var pacchetto_checkpoint = new Array(msg.auto, msg.giri[ckpoint].giro, msg.giri[ckpoint].tempo);

                	// Ritorna l'indice del settore nell'array dei checkpoint
                	var index_settore = checkpoint.indexOf(msg.giri[ckpoint].settore);
                	//console.log("Il settore ha indice: "+index_settore);
                	// Aggiungo il pacchetto nella pila se non è presente
                	if(!checkpointPresente(pacchetto_checkpoint[0], pacchetto_checkpoint[1] , pacchetto_checkpoint[2], msg.giri[ckpoint].settore)){
                		pilecheckpoint[index_settore].push(pacchetto_checkpoint);
                	}                	
            }
            // ### FINE SEZIONE CHECKPOINT - POPOLO TABELLA
 
        }

    }
    //FINE FUNZIONI WEBSOCKET PREDEFINITE
    //****************************************************************************


	function checkpointPresente(auto, giro, tempo, settore){
		var index_settore = checkpoint.indexOf(settore);

		for(var t =0; t < pilecheckpoint[index_settore].length; t++){
			if(
				pilecheckpoint[index_settore][t][0] == auto &&
				pilecheckpoint[index_settore][t][1] == giro &&
				pilecheckpoint[index_settore][t][2] == tempo
			){
				return true;				
			}
		}
		return false;
	}

    function settaFineGaraAuto(idAuto) {
			
        matriceMessaggio9[idAuto-1][5]= 1; //il pilota e' arrivato a fine gara

        if (primo == false) {

            //document.getElementById("fine_gara").innerHTML += "<br /> Il pilota " + nomePilotaArray[idAuto - 1] + " ha terminato la gara ed e' arrivato primo!";
            primo = true;
            arrivatiTutti = arrivatiTutti + 1;

        } else {

            //document.getElementById("fine_gara").innerHTML += "<br /> Il pilota " + nomePilotaArray[idAuto - 1] + " ha terminato la gara.";
            arrivatiTutti = arrivatiTutti + 1;
        }
    }

    //FUNZIONI DI DI TIMELINE

    function inizializzaGrigliaPiloti() {

        var i = 0;
        for (i = 0; i < num_piloti; i++) {
            grigliaDatiPiloti[i] = new Array(); //una matrice per ogni pilota
            var j = 0;
            for (j = 0; j < num_giri; j++) {
                //per ogni pilota per ogni giro un array
                grigliaDatiPiloti[i][j] = new Array();
                var k = 0;
                //aggiunta dei due settori che formano i box
                for (k = 0; k < num_settori + 2; k++) {
                    grigliaDatiPiloti[i][j][k] = new Array();
                }
            }
        }
    }

    function aggiornaStatistichePilota(idAuto, settore, tempoSettore, giro) {
        grigliaDatiPiloti[idAuto - 1][giro - 1][settore - 1] = tempoSettore;
    }

    function recuperaTimeLine(idPilota) {
        return grigliaDatiPiloti[idPilota - 1];
    }

    function stampaStatistichePilota(idPilota) {

        // Altezza dinamica della pagina in proporzione ai giri (by Dario production ma corretto da Diego production)
        document.getElementById('pagina_2').style.height = (900 + num_giri * 35) + 'px';

        var nome = "Timeline del pilota: <b>" + nomePilotaArray[idPilota - 1] + " </b> della scuderia: <b>" + scuderiaPilotaArray[idPilota - 1] + "</b>";
        document.getElementById("infoPilota").innerHTML = nome;

        //tabellaInfo = "<table border='1' width='400px'> <tr> <th> N. Giro </th> <th>Tempo del giro</th> <th> Sosta </th> <th> Incidenti/Uscite </th>";
        tabellaInfo = "<table border='1' width='400px'> <tr> <th> N. Giro </th> <th>Tempo del giro</th> <th> Sosta </th>";
        var i = 0;
        var migliore = giriMigliori[idPilota - 1][0];

        //cerco il giro migliore fino a quel momento
        for (i = 1; i < num_giri; i++) {
            if (giriMigliori[idPilota - 1][i] < migliore && giriMigliori[idPilota - 1][i] != 0)
                migliore = giriMigliori[idPilota - 1][i];
        }

        i = 0;
        for (i = 0; i < num_giri; i++) {
            tabellaInfo += "<tr> <td align='center'> " + (i + 1) + " </td> ";

            if (giriMigliori[idPilota - 1][i] == migliore && giriMigliori[idPilota - 1][i] != 0)
            //tabellaInfo += "<td align='center'> <b> " + giriMigliori[idPilota-1][i].toString().toHHMMSS() + "</b> </td>";
                tabellaInfo += "<td align='center'> <b> " + stampaTempo(giriMigliori[idPilota - 1][i], false) + "</b> </td>";
            else
            //tabellaInfo += "<td align='center'> " + giriMigliori[idPilota-1][i].toString().toHHMMSS() + " </td>";
                tabellaInfo += "<td align='center'> " + stampaTempo(giriMigliori[idPilota - 1][i], false) + " </td>";

            if (grigliaSoste[idPilota - 1][i] == 1)
                tabellaInfo += "<td align='center'> <b>SI</b> </td> ";
            else
                tabellaInfo += "<td align='center'> NO </td> ";

            //if (grigliaIncidenti[idPilota - 1][i] == 1)
            //    tabellaInfo += "<td align='center'> <b>SI</b> </td>";
            //else
            //    tabellaInfo += "<td align='center'> NO </td> ";

            tabellaInfo += "</tr>";
        }
        tabellaInfo += "</table>";

        document.getElementById("pannello").innerHTML = tabellaInfo;
    }

    function stampaTempo(tempo, withH) {

        //console.log("ricevuto tempo " + tempo);

        if (tempo != 0) {
            var splitted = (tempo.toString()).split(".");
            var sec_num = parseInt(splitted[0], 10); // don't forget the second parm
            var hours = Math.floor(sec_num / 3600);
            var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
            var seconds = sec_num - (hours * 3600) - (minutes * 60);

            if (hours < 10) {
                hours = "0" + hours;
            }
            if (minutes < 10) {
                minutes = "0" + minutes;
            }
            if (seconds < 10) {
                seconds = "0" + seconds;
            }
            var time = "";
            if (withH == true)
                time = hours + "h  " + minutes + "\'  " + seconds + "\'\' " + splitted[1][0] + splitted[1][1] + splitted[1][2];
            else
                time = minutes + "\'  " + seconds + "\'\' " + splitted[1][0] + splitted[1][1] + splitted[1][2];
            return time;
        } else
            return "0";
    }
</script>
