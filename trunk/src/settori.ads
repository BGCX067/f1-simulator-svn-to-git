with ConfigurazioniAuto; use ConfigurazioniAuto;
with Ada.Calendar; use Ada.Calendar;
with Ada.Containers.Ordered_Sets; -- Per ordinare array
--with Ada.Numerics.Discrete_Random; -- Per random

package Settori is

   -- Tipi possibili di settori
   type Tipi_Settori is (Normal, First, Last, Second_Last, Pit_Lane, Box);

   --subtype Tempi_Random is Integer range 1 .. 10;
   --package Random_Time is new Ada.Numerics.Discrete_Random(Tempi_Random);
   --use Random_Time;
   -- Risorsa protetta che rappresenta una corsia di un settore
   protected type Corsia is
      -- Ritorna il tempo di attraversamento impiegato dall'auto nel caso prenda la corsia
      entry Calcola_Tempo_Attraversamento(Stato_Auto : in out Configurazione; Tempo_Entrata : float; Tempo_Uscita: Out float);
      entry Entra_Nella_Corsia(Tempo_Uscita : float);

      -- Procedura che imposta il tempo di liberazione al clock attuale (per inizializzare)
      procedure Set_Tempo_Liberazione;

      -- Entry per settaggio dei valori della corsia
      entry Set_Valori_Corsia(Nuova_Lunghezza : Float; Nuovo_Grip : Float; Nuova_Velocita_Max_Uscita : Float; Nuova_Velocita_Max_Percorrenza : Float);

   private
      Lunghezza : Float; -- Lunghezza in metri
      Grip : Float; -- Valore che rappresenta l'aderenza della corsia
      Velocita_Max_Uscita: Float; -- La velocità massima che l'auto deve avere in uscita
      Velocita_Max_Percorrenza: Float; -- La velocità massima raggiungibile dall'auto durante la percorrenza della corsia
      Tempo_Liberazione : Float; -- Tempo di uscita dell'ultima macchina entrata
      Velocita_Liberazione : Float; -- Vediamo se serve

   end Corsia;


   -- Array di Corsie, utilizzato da un settore per tenere traccia delle sue corsie
   type Array_Corsie is array (Positive range <>) of access Corsia;


   -- Struttura che include l'id dell'auto con il tempo (di arrivo)
   type Tempo_Arrivo is
      record
         Id : Integer; -- Id dell'auto
         Tempo : float; -- Tempo di arrivo
      end record;

   -- Funzione di ordinamento tra records Tempo_Arrivo, per ordinarli nell'array delle uscite
   function "<" (L, R : Tempo_Arrivo) return Boolean;

   -- Ridefinizione di Composite_Set per oggetti Tempo_Arrivo
   package Composite_Sets is new Ada.Containers.Ordered_Sets(Tempo_Arrivo);

   -- Tipo Array di tempi di arrivo
   --type Array_Tempi_Arrivo is array (Natural range <>) of Tempo_Arrivo;


   -- Risorsa protetta che rappresenta un settore della pista
   protected type Settore(Id : Integer) is
      procedure Entra_Nel_Settore(Id_Auto: in Integer; Stato_Auto : in out Configurazione; Tempo_Entrata: in float; Tempo_Uscita: out float);
      entry Esci_Dal_Settore(Id_Auto: in Integer; Stato_Auto: in out Configurazione; Prossimo_Settore: out Integer; Tempo_Uscita : out float); -- Entry chiamata da un'auto al suo risveglio (arrivo all'uscita del settore) per chiedere l'entrata al successivo
      entry Esci_Dal_Settore_Requeue(Id_Auto: in Integer; Stato_Auto: in out Configurazione; Prossimo_Settore: out Integer; Tempo_Uscita : out float); -- Per accodamento nel caso un'auto non sia autorizzata ad usire
      entry Partenza(Numero_Concorrenti : in Integer); -- Popola l'array di uscita dall'ultimo settore per la partenza

      entry Libera_Settore(Id_Auto: in Integer); -- Funzione che toglie un'auto dalla coda del settore (usata quando l'auto termina la gara)

      entry Aggiungi_Corsie(Nuove_Corsie : access Array_Corsie); -- Funzione per inserire una corsia all'interno del settore
      entry Set_Tipo_Settore(Tipo : Tipi_Settori);
      entry Set_Checkpoint(Check : Boolean);
      procedure Get_Tipo_Settore(Tipo : out Tipi_Settori);

   private

      --       Settore_Successivo : Settore;

      Tipo_Settore : Tipi_Settori; -- Tipo di settore
      Corsie : access Array_Corsie; -- Corsie contenute nel settore
      Lunghezza : Integer; -- Lunghezza del settore in metri
      Ordine_Uscita : Composite_Sets.Set; -- Array degli arrivi al settore
      Checkpoint : Boolean;

      Guardia : Boolean := False; -- Per la funzione di requeue
   end Settore;

   -- Puntatore a settore
   type Settore_T is access all Settore;

   -- Array di settori
   type Array_Settori is array (1 .. 40) of Settore_T;


end Settori;

