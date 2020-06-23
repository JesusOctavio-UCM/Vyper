# Contrato que regula la compra de billetes de avión.

# Si el vuelo se cancela, ofrecemos al cliente un billete en el vuelo siguiente al que él
# había comprado. Así, si devolucion es false acepta esta oferta y,
# si es true quiere que se le reembolse el dinero. El asiento no se puede escoger.

struct Vuelo:
    salida: timestamp #momento de despegue del vuelo
    duracion: timedelta #intervalo de duración del vuelo
    embarque: timedelta #tiempo que están las puertas de embarque abiertas
                      #se cierran justo cuando llega la hora de salida
    precio: wei_value #coste del billete
    aerolinea: address #dirección Ethereum de la aerolínea
    registro: map(int128, address) #dirección Ethereum de los ocupantes del vuelo asociados a su número de asiento
    devolucion: map(address, bool) # asocia a cada cliente si quiere la devolución o el cambio de billete en caso
                                  # de cancelación
    pasaportes: map(address, string) #número de pasaporte de cada dirección Ethereum
    vendidos: int128 #inicialmente vale 0; lleva la cuenta del número de pasajeros del vuelo, como mucho puede valer
                  # 200 que supongo que es el aforo del avión
    
#Variable del contrato que guarda toda la oferta de vuelos asociados a su número
#de identificación.
oferta: map(int128, Vuelo)
retraso_permitido: timedelta # el tiempo que se puede demorar un vuelo sin tener que reembolsar, vamos a considerar
                             # 3 horas como máximo.
                             
                             
#Función para que la aerolínea saque un nuevo vuelo a la venta. Se sacarán con un mes de antelación.
@public
def vender_billete(num_vuelo: int128, _salida: timestamp, _duracion: timedelta, _embarque: timedelta,
                    _precio: wei_value):
    _vuelo.salida = _salida
    _vuelo.duracion = _duracion
    _vuelo.embarque = _embarque
    _vuelo.precio = _precio
    _vuelo.aerolinea = msg.sender
    _vuelo.vendidos = 0
    self.oferta[num_vuelo] = _vuelo
    
@public
@payable
def comprar_billetes(num_vuelo: int128, pasaporte: string, _devolucion: bool):
    _vuelo: Vuelo = self.oferta[num_vuelo]
    # compruebo que el cliente puede pagar el precio del billete
    assert msg.value >= _vuelo.precio
    # compruebo que el vuelo aún no ha despegado
    assert block.timestamp < _vuelo.salida
    # compruebo que aún quedan plazas en el avión
    assert _vuelo.vendidos < 200
    
    # guardo la dirección Ethereum del comprador en el registro
    _vuelo.registro[_vuelo.vendidos + 1] = msg.sender
    # guardo su pasaporte
    _vuelo.pasaportes[msg.sender] = pasaporte
    # aumento en uno el número de billetes vendidos
    _vuelo.vendidos += 1
    # guardamos si quiere devolución o cambio en caso de cancelacion
    _vuelo.devolucion[msg.sender] = _devolucion
    # se efectúa el pago del billete
    send(_vuelo.aerolinea, _vuelo.precio)
    
# Voy a considerar que los números que identifican a cada vuelo tienen 5 cifras: las dos primeras es el número que representa
# la ciudad de origen, las dos segundas, la ciudad destino y la última representa los vuelos del mes. Así, por ejemplo
# 10200 sería el primer vuelo del mes de la ciudad 10 a la ciudad 20, 10201 el segundo y así sucesivamente. Cada mes habría
# 9 vuelos. Esto es importante para lo que voy a hacer a continuación.

# Definimos una función a la que llama la aerolínea si el vuelo se cancela: reembolsamos o cambiamos los billetes 
# de todos los pasajeros del vuelo cancelado
@public
@payable
def cancelacion_vuelo(num_vuelo: int128):
    _vuelo: Vuelo = self.oferta[num_vuelo]
    for i in range(1,_vuelo.vendidos + 1): # recorremos todos los pasajeros que habían comprado un billete
        cliente: address = _vuelo.registro[i]
        if _vuelo.devolucion[cliente]: # el cliente quiere reembolso
            send(cliente, _vuelo.precio)
        else: # el cliente prefiere cambiar su billete cancelado por el vuelo siguiente con plazas
            # para conseguir el número de vuelo siguiente al que había comprado
            num_nuevo_vuelo: int128 = (num_vuelo // 10) * 10 + ((num_vuelo % 10) + 1) % 10)
            _nuevo_vuelo: Vuelo = self.oferta[num_nuevo_vuelo]
            # vemos si el nuevo vuelo tiene plazas libres, si no es así pasamos al siguiente
            # hasta que encontremos uno con plazas libres
            while (_nuevo_vuelo.vendidos >= 200):
                num_nuevo_vuelo: int128 = (num_vuelo // 10) * 10 + ((num_vuelo % 10) + 1) % 10)
                _nuevo_vuelo: Vuelo = self.oferta[num_nuevo_vuelo]
            # una vez lo hemos encontrado, le asignamos un billete al cliente
            _nuevo_vuelo.registro[_nuevo_vuelo.vendidos + 1] = cliente
            _nuevo_vuelo.pasaportes[cliente] = _vuelo.pasaportes[cliente]
            _nuevo_vuelo.vendidos += 1
            # si este nuevo vuelo se cancela ya no se cambia por otro si no que se reembolsa el dinero
            # directamente
            _nuevo_vuelo.devolucion[cliente] = True
    # Borramos toda la información del vuelo
    clear(self.oferta[num_vuelo])
        
        
# Definimos una función que regule el aterrizaje. Si el avión aterriza en hora o con menos de tres horas
# de retraso, los clientes no tienen derecho a ningún reembolso y, simplemente borramos toda la información
# del vuelo asociado al número para más tarde meter un nuevo vuelo con el mismo número en el mes siguiente.
# Si el avión aterriza con tres horas de retraso o más, se reembolsa integramente a todos los pasajeros y 
# después se borra la información del vuelo.

@public
@payable
def aterrizaje(num_vuelo: int128):
    _vuelo: Vuelo = self.oferta[num_vuelo]
    if block.timestamp > _vuelo.salida + _vuelo.duracion + self.retraso_permitido: # se ha demorado demasiado
    # reembolsamos a todos los pasajeros
        for i in range(1,_vuelo.vendidos + 1):
            send(_vuelo.registro[i], _vuelo.precio)
    # Independientemente de que haya retraso o no, borramos la información del vuelo
    clear(self.oferta[num_vuelo])
    
    
        
# Definimos una función para embarcar
@public
def embarcar(num_vuelo: int128, _pasaporte: string):
    _vuelo: Vuelo = self.oferta[num_vuelo]
    # Comprobamos que las puertas de embarque están abiertas
    assert block.timestamp >= _vuelo.salida - _vuelo.embarque
    # Comprobamos que el pasaporte que entrega el cliente(como argumento de la función)
    # coincide con el indicado en la información del vuelo
    assert _pasaporte == _vuelo.pasaportes[msg.sender]
    
            
            
        
        
        
    
    
    
