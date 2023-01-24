# Ossigenio Companion app

Questa è l'applicazione mobile per il progetto Ossigenio.

## Modalità di funzionamento

### Collegamento con il dispositivo Ossigenio

Consente di monitorare la qualità dell'aria vicino a sè grazie al [sensore](../proto2/README.md) correlato. Quando il
sensore è collegato e viene selezionato in quale stanza ci si trova, l'applicazione manderà i dati
raccolti al server.  

![screen-sensor](https://user-images.githubusercontent.com/7345120/214364486-bfb03b4e-4da1-4281-80f2-7f7d4b13c309.jpg)

### Visualizzazione qualità luogo corrente

Consente di visualizzare e rimanere aggiornati sulla qualità dell'aria del luogo selezionato.

![screen-place](https://user-images.githubusercontent.com/7345120/214364742-272d179f-4aa7-4489-bef2-81a16b2471f4.jpg)

### Mappa

Si possono visualizzare le informazioni raccolte dai sensori presenti nei luoghi di studio, sia
quelli vicini sia quelli più lontani, grazie ad una mappa interattiva.
![photo_2023-01-24_18-32-42](https://user-images.githubusercontent.com/7345120/214365893-5f6ec90d-c64c-46ba-b4cf-272317f8cd21.jpg)

#### Previsioni

Se si prevede di recarsi in un determinato luogo più tardi e non immediatamente, è possibile visualizzare le previsioni della concentrazione di anidride carbonica per le prossime 24 ore.

![photo_2023-01-24_18-32-38](https://user-images.githubusercontent.com/7345120/214366229-0562629d-0512-482b-980f-18fcdad88567.jpg)


## Tecnologia

L'applicazione è stata sviluppata con [Flutter](https://flutter.dev/), un framework per lo sviluppo di applicazioni mobile
cross-platform.

## Funzionamento

L'applicazione utilizza il
[Bluetooth Low Energy](https://www.bluetooth.com/learn-about-bluetooth/tech-overview/)
per collegarsi automaticamente a qualsiasi sensore Ossigenio rilevato nelle vicinanze. Una volta stabilita la connessione, viene utilizzato il
[protocollo seriale](../proto2/doc/SerialProtocol.md)
per la comunicazione al dispositivo.  
Il sensore invia periodicamente informazioni su CO₂ , temperatura e umidità, mentre l'applicazione chiede periodicamente informazioni sulla batteria. (Viene richiesta periodicamente la temperatura interna del sensore CO₂ per capire se il sensore si è riscaldato.)  

Tutte le operazioni di rete usano le 
[API REST](../flask/README.md#api)
del backend, con l'eccezione dell'invio dei dati del sensore e la ricezione delle informazioni su un luogo nella home page, in cui viene utilizzato
[MQTT](../flask/README.md#bridge-mqtt).