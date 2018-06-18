# Configuració per LoRa (model waspmote SX1272)
Autor: Lluís Bosch (lbosch@icra.cat)

1. Connectar gateway a port USB i executar 'listen.py'
  ```bash
    python listen.py
  ```
  Si el programa no troba el gateway, editar 'listen.py' per configurar el port serial correcte
  ```python
    ser.port='/dev/ttyUSB0'
  ```

2. Executar 'python info-gateway.py' per comprovar que el gateway està escoltant correctament
  ```bash
    python info-gateway.py
  ```
S'ha de veure com el gateway rep la comanda READ i respon així:
```bash
  ('Mon Jun 18 13:16:37 2018', '\x01INFO#FREC:CH_12_868;ADDR:1;BW:BW_125;CR:CR_5;SF:SF_12;SNR:0;RSSI:-110;RSSI_PACKET:119;VER:0.13\r\n27C0\x04')
```

3. Carregar codi 'envia.ino' al waspmote que enviarà les dades (Arduino).
Es fa mitjançant el programa 'waspomte ide' (http://www.libelium.com/development/waspmote/sdk_applications/)

Si tot ha anat bé, s'hauria de veure a la pantalla com el gateway rep les dades i les mostra a la pantalla.

```bash
('Mon Jun 18 13:18:18 2018', 'This_is_a_new_message\r\n')
```
