# Ossigenio - backend

Questa cartella contiene il codice sorgente del **server** della piattaforma Ossigenio.

## Struttura e funzionalità

Il backend del progetto è diviso in queste parti:

### Flask (sito web e API)

- [Flask](https://flask.palletsprojects.com/en/2.2.x/)
si occupa sia di gestire sia il portale web le API. Le API vengono utilizzate dalla [applicazione mobile](). Grazie a un sistema di *nested blueprint*, le API sono versionate: Al momento la versione corrente è la 1.  
- [flask-smorest](https://flask-smorest.readthedocs.io/en/latest/)
genera **automaticamente** la documentazione
[OpenAPI](https://www.openapis.org/) v3.0.3, accessibile a `/swagger-ui`
[(link server pubblico)](https://ossigenio.it/swagger-ui).

### Bridge MQTT

Il bridge MQTT si occupa di:

- Effettuare **subscription** a tutti i luoghi, in modo da raccogliere i dati dei sensori e salvarli nella tabella SQL *sensor_data*.
- Chiedere periodicamente al *data_decide.py* di calcolare per ogni luogo una stima della concentrazione della CO2 e di salvare i risultati nella tabella *co2_history* e nel topic MQTT di quel luogo (attraverso un messaggio *retained*).

### Bot Telegram

Il bot Telegram è pensato per i **gestori dei locali** iscritti alla piattaforma Ossigenio.  
Il suo compito è semplice: Notificare gli utenti iscritti quando la concentrazione di CO2
in un luogo diventa più alta della soglia configurata dall'utente.

L'iscrizione al bot è manuale, ovvero il gestore deve richiedere agli amministratori
di essere autorizzato.

## Istruzioni per il deploy

### Requisiti

Per effettuare il deploy su un server è necessario avere installato
[Docker](https://www.docker.com/),
un server HTTP come
[nginx](https://www.nginx.com/),
un server MQTT come
[mosquitto](https://mosquitto.org/)
e un server SQL come
[PostgreSQL](https://www.postgresql.org/).

**Parametri necessari**

Per il corretto funzionamento del backend, è necessario creare un file contenenti alcune variabili di configurazione.

- SQLALCHEMY_DATABASE_URI deve contenere un URI per collegarsi alla **base di dati**.
- SECRET_KEY viene usata per criptare i cookie di autenticazione. Generare una lunga stringa casuale per rendere il processo sicuro.

```
SQLALCHEMY_DATABASE_URI=postgresql://iot:iot@db.ossigenio.it:5432/iot?sslmode=require
SECRET_KEY=change_me
FLASK_APP=project
TELEGRAM_TOKEN=
MQTT_USER=backend
MQTT_PASS=backend_pw
MQTT_SERV=mqtt.ossigenio.it
MQTT_PORT=8080
```

### Installazione

1) **Configurare** il reverse proxy  
Configurare il proprio web server per reindirizzare le richieste alla porta 5000.
Esempio server block **nginx**
```
server {

        server_name ossigenio.it;
        location / {

                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Host $http_host;

                proxy_redirect off;
                proxy_pass http://localhost:5000/;
        }

    listen 443 ssl http2; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/ossigenio.it/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/ossigenio.it/privkey.pem; # managed by Certbot

}
```

2) Configurare il server MQTT  

[Esempio]()
di file di configurazione per **mosquitto**.

> Il server MQTT deve accettare solo **connessioni criptate.**

3) **Scaricare** il codice sorgente
```bash
git clone https://github.com/ElDavoo/air-quality-monitor.git
```

4) **Configurare** la base di dati

    a. Importare lo schema:
    ```bash
    sudo -u postgres psql -d iot -f iot.sql
    ```
    b. Impostare la base di dati in modo che sia possibile collegarsi tramite un URI.


5) **Costruire** il container
```bash
cd air-quality-monitor/flask/ && sudo docker build -t ossigenio .
```
6) **Avviare** il container  
Si suppone che il file di configurazione sia stato chiamato *secrets.env*.
```bash
sudo docker run -d --env-file=secrets.env -p 5000:5000 --restart=always --name ossigenio ossigenio
```
7) **Controllare** l'avvio corretto del container
```bash
sudo docker logs -f ossigenio
```