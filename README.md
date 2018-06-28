# Configuració per LoRa (model waspmote SX1272: enviar i rebre dades)
Autor: Lluís Bosch (lbosch@icra.cat)

## Estat: en desenvolupament

1. El gateway és l'aparell que rep les dades. Connectar gateway a port USB i executar 'escolta.py'
  ```bash
    python escolta.py
  ```
  Si no troba el gateway, editar 'escolta.py' per configurar el port serial correcte
  ```python
    ser.port='/dev/ttyUSB0'                #exemple per linux o mac
    ser.port='COM1'                        #exemple per windows
    ser.port='/dev/tty.usbserial-AI03NPY0' #exemple per macosx
  ```
  
  Aquest programa ha d'estar obert tota l'estona, ja que és el que mostra com es reben les dades.

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
```
