# Quelle
Das Testnetz-Baseimage basiert auf dem `phusion/baseimage-docker`: 
https://github.com/phusion/baseimage-docker/
commit: 48d3f31

Die Dokumentation dürfte in großen Teilen auch auf diese abgewandelte Version zutreffen.


# Dienste
## SSH
SSH bereits installiert und im Testnetz-Baseimage aktiv, wenn kein Kommando
explizit an docker übergeben wird. Verantwortlich dafür ist der Aufruf von
`/sbin/my_init --enable-insecure-key` im Dockerfile.

Logins sind mittels `testnetz_id` Key möglich. Dieser Key kann im Unterordner
`files/build/services/sshd/keys/testnetz_id` oder auch im Baseimage unter
`/etc/insecure_key` (anderer Dateiname) gefunden werden.

## Neue Dienste hinzufügen
Original-Anleitung:
https://github.com/phusion/baseimage-docker#adding_additional_daemons

### Kurzfassung:
neuer-service.sh:
```
#!/bin/sh
/usr/sbin/neuer-service --schalter-fuer-vordergrund-ausfuehrung
```

Dockerfile:
```
COPY neuer-service.sh /etc/service/neuer-service-name/run
RUN chmod +x /etc/service/neuer-service-name/run
```


# Start-Scripts
Original-Anleitung:
https://github.com/phusion/baseimage-docker#running_startup_scripts

## Kurzfassung:
logtime.sh:
```
#!/bin/sh
date > /tmp/boottime.txt
```

Dockerfile:
```
COPY logtime.sh /etc/my_init.d/logtime.sh
RUN chmod +x /etc/my_init.d/logtime.sh
```

