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

3. Carregar codi 'envia.ino' al waspmote que enviarà les dades (Arduino)

Si tot ha anat bé, s'hauria de veure a la pantalla com el gateway rep les dades
