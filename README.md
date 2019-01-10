## Enviament de dades via LoRa waspmote SX1272
Lluís Bosch (lbosch@icra.cat), projecte GESTOR, icra.
### Estat: en desenvolupament

## Esquema muntatge
```
  +-------------+
  | Sensors     | (3 de temperatura:[submergit, aire, cso], nivell 1:[maxbotix], overflow 1:["sabata microcom 'capacitiu'"] )
  |-------------|
  | Arduino     | (model waspmote de libelium)
  |-------------|
  | sx1272      | (mòdul que envia dades via LoRa)
  +-------------+
     ) ) )
   Senyal LoRa (json string) "{'id_sensor':int, 'datetime':string, 'temperatura1':float, 'temperatura2':float, 'temperatura3':float, 'nivell':float, 'overflow':bool, 'bateria':%}"
     ) ) )
  +---------+
  | sx1272  | (mòdul que rep dades via LoRa)
  +---------+
  | Gateway | (envia el que rep de LoRa cap al PC vis USB)
  |---------|
  | PC      | (raspberry pi amb python3 amb internet)
  +---------+
     ||
   Internet
     ||
  +----------------------------------------+
  | Servidor base de dades + visualització | (mysql http://lora.h2793818.stratoserver.net/)
  +----------------------------------------+
     ||
   Internet
     ||
  +-----------------+
  | Client (usuari) | (browser: chrome, firefox, safari, edge...)
  +-----------------+
```

## Sensors (reunio felix hill + lluis bosch 22/2/2018 (sant sadurni))
  - Sabata (capacitiu, microcom):
    mesura si hi ha aigua tocant al sensor.
    no hi ha llibreria (es llegeix on/off amb una comanda digitalRead de waspmote)
  - Nivell: maxbotix.
    Envia caràcters ascii per exemple "12 " en cm
    Serial.read()
  - Temperatura (DS18B20):
    la llibreria ja està inclosa al waspmote (DallasTemperature.h)

## notes
  - pendent: mirar com llegir bateria de l'arduino
  - tenir en compte que la freqüència de lectura s'ha de poder modificar remotament

## Passos
1. El gateway és l'aparell que rep les dades dels sensors. Connectar gateway a port USB i executar 'escolta.py'
  ```bash
    python escolta.py
  ```
  Si no troba el gateway, editar 'escolta.py' per configurar el port serial correcte
  ```python
    ser.port='/dev/ttyUSB0'                #exemple per linux o mac
    ser.port='COM1'                        #exemple per windows
    ser.port='/dev/tty.usbserial-AI03NPY0' #exemple per macosx
  ```

  Aquest programa està obert tota l'estona, ja que és el que mostra com el gateway rep les dades via LoRa.

2. Executar 'python info-gateway.py' per comprovar que el gateway està escoltant correctament
  ```bash
    python info-gateway.py
  ```
S'ha de veure allà on s'està executant 'escolta.py' que rep la comanda READ i respon així:
```bash
  ('Mon Jun 18 13:16:37 2018', '\x01INFO#FREC:CH_12_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12;SNR:0;RSSI:-110;RSSI_PACKET:119;VER:0.13\r\n27C0\x04')
```

3. Carregar codi 'envia.ino' al waspmote que enviarà les dades (Arduino).
La placa que tenim no és arduino, és waspmote, i té el seu propi programa.
Suposo que el mateix codi 'envia.ino' ha de funcionar en cas que es faci servir Arduino (no provat)
Es fa mitjançant el programa 'waspmote ide' (http://www.libelium.com/development/waspmote/sdk_applications/)

Si tot ha anat bé, s'ha de veure a la pantalla com el gateway rep les dades que li envia el waspmote 'envia.ino' i les mostra a la pantalla.

```bash
('Mon Jun 18 13:18:18 2018', 'This_is_a_new_message\r\n')
('Mon Jun 18 14:19:59 2018', '{json-string-with-data-structure}\r\n')
```
