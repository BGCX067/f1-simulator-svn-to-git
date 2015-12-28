package f1;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_10;
import org.java_websocket.handshake.ServerHandshake;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;


public class websocket extends WebSocketClient{
    private Start guiParent;
    
    public websocket( URI serverUri , Draft draft, Start gui) {
		super( serverUri, draft );
                guiParent=gui;
	}

	public websocket( URI serverURI ) {
		super( serverURI );
	}

	@Override
	public void onOpen( ServerHandshake handshakedata ) {
		//System.out.println( "opened connection" );
                guiParent.SetStato("Stato: Connesso");
		// if you pan to refuse connection based on ip or httpfields overload: onWebsocketHandshakeReceivedAsClient
	}

	@Override
	public void onMessage( String message ) {
	try {
            //System.out.println( "received: " + message );
                JSONObject json;
        
            json = (JSONObject)new JSONParser().parse(message);
       
            Integer tipo=((Long)json.get("tipo")).intValue();
            if (tipo==4) {
                guiParent.SetStato("Stato: Gara in corso");

            }else if (tipo==5) {
                guiParent.SetStato("Stato: Gara in corso");

            }else if (tipo==6) {
                guiParent.cambiaStatoGara(Start.StatoGara.ATTESA_CARICAMENTO);

            }   
                    
	
            } catch (ParseException ex) {
                Logger.getLogger(websocket.class.getName()).log(Level.SEVERE, null, ex);
            }// send( "you said: " + message );
	}

	@Override
	public void onClose( int code, String reason, boolean remote ) {
		// The codecodes are documented in class org.java_websocket.framing.CloseFrame
		//System.out.println( "Connection closed by " + ( remote ? "remote peer" : "us" ) );
	        guiParent.SetStato("Stato: Connection closed by " + ( remote ? "remote peer" : "us"));
            if(!guiParent.chiusura)
                guiParent.dispose();
        }

	@Override
	public void onError( Exception ex ) {
		ex.printStackTrace();
		// if the error is fatal then onClose will be called additionally
	}


}