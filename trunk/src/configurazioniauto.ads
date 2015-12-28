with Ada.Strings.Unbounded;
with Comunication;
with ConfigurazioniAuto_Mid;

package ConfigurazioniAuto is

   package SU renames Ada.Strings.Unbounded; -- Rinomino Ada.Strings.Unbounded per comodità

   -- Gomme utilizzabili dalle auto
   type Gomma is (Soft, Medium, Hard, Rain);

   -- Tempo atmosferico
   type Tempo_Atmosferico is (Sole, Parziale, Nuvoloso, Pioggia);

   -- Elementi che caratterizzano lo stato di un'auto
   type Configurazione is record
      Id : Integer; -- Id dell'auto
      Gomme : Gomma; -- Tipo di gomme montate
      Usura_Gomme : Float; -- Livello di usura gomme

      Gomme_Pitstop : Gomma; -- Tipo di gomme da montare al prossimo pitstop
      Usura_Gomme_Stop : Float; -- Livello di usura oltre il quale effettuare una sostituzione

      Livello_Benzina : Integer; -- Livello di benzina nel serbatoio
      Livello_Benzina_Stop : Integer; -- Livello sotto il quale occorre effettuare il rifornimento
      Livello_Benzina_Pitstop : Integer; -- Livello fino al quale rifornire al prossimo pitstop

      Livello_Danni : Integer; -- Numero che rappresenta il livello dei danni subiti

      Entrata_Box : Boolean; -- Indica se l'auto ha pianificato uno stop

      Potenza : Integer; -- Rappresenta la potenza dell'auto
      Bravura_Pilota : Integer; -- Rappresenta l'infallibilità del pilota

      Nome_Scuderia : SU.Unbounded_String;
      Nome_Pilota : SU.Unbounded_String;


      Numero_Giri : Integer; -- Numero di giri effettuati

      Numero_Giri_Totali : Integer; -- Numero di giri della pista

      Velocita_Attuale : Float; -- Velocità attuale dell'auto

   end record;


    -- Array di Configurazioni
   type Array_Configurazioni is array (1 .. 12) of  Configurazione;

   type Tabella_Performance is array(Gomma, Tempo_Atmosferico) of Float;

end ConfigurazioniAuto;
