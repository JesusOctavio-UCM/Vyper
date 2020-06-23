# Este es un ejemplo de Solidity adaptado a Vyper.

struct Puja:
    postorCiego: bytes32
    deposito: wei_value
    
# Como Vyper no permite arrays dinámicos, limitamos el número de pujas que puede
# hacer una dirección a 128.
maximo_pujas: constant(int128) = 128

# event para registrar cuándo ha acabado la subasta
FinSubasta: event({_mejorPostor: address, _mejorPuja: wei_value})

# Parámetros de la subasta
beneficiario: public(address)
finPujas: public(timestamp)
revelacion: public(timestamp)

# Se cambia a cierto al final de la subasta, no permite nuevas pujas
finalizada: public(bool)

# Estado al final de la subasta
mejorPuja: public(wei_value)
mejorPostor: public(address)

# Estado de las pujas
pujas: map(address, Puja[128])
contadorPujas: map(address, int128)

# Permitimos reembolsos de pujas anteriores
reembolsosPendientes: map(address, wei_value)

# Creamos una subasta ciega con _tiempoPuja (segundos para pujar),
# _tiempoRevelacion segundos para revelar a favor de la dirección del
# beneficiario _beneficiario
@public
def __init__(_beneficiario: address, _tiempoPuja: timedelta, _tiempoRevelacion: timedelta):
    self.beneficiario = _beneficiario
    self.finPujas = block.timestamp + _tiempoPuja
    self.revelacion = self.finPujas + _tiempoRevelacion
    
# Tiene lugar una puja ciega con:
# _pujaCiega = keccak256(concat(convert(valor, bytes32),convert(fake, bytes32),secret)
# El envío de ether solo se lleva a cabo si la puja se revela correctamente en 
# la fase de revelación. La puja es válida si el ether enviado junto con la puja
# es al menos "valor" y "fake" es falso. Poner "fake" a cierto y enviar la cantidad
# no exacta son formas de esconder la puja real pero aún así hacer el depósito
# requerido. La misma dirección puede hacer múltiples pujas.
@public
@payable
def puja()(_postorCiego)
    # Comprobamos si el periodo de puja está abierto aún
    assert block.timestamp < self.finPujas
    # Comprobamos que el postor no ha llegado al máximo número de pujas
    numPujas: int128 = self.contadorPujas[msg.sender]
    assert numPujas < maximo_pujas
    # Añadimos la puja
    self.pujas[msg.sender][numPujas] = Puja({postorCiego: _postorCiego, deposito: msg.value})
    self.contadorPujas[msg.sender] += 1
    
# Devuelve True si la puja se ha realizado exitosamente o False si no
@private
def pujaExito(postor: address, valor: wei_value) -> bool:
        # Si la puja es más baja que la mejor puja, falla
        if (value <= self.mejorPuja):
            return False
        # Se devuelve el dinero al anterior mejor postor
        if (self.mejorPostor != ZERO_ADDRESS):
            self.reembolsosPendientes[self.mejorPostor] += self.mejorPuja
        # La puja se ha llevado a cabo y se actualiza el estado de la subasta
        self.mejorPuja = valor
        self.mejorPostor = postor
        return True

# Revelar tus pujas ciegas. Obtienes un reembolso por tus pujas no válidas y por todas las pujas
# salvo las más altas.
@public
def revelar(_numPujas: int128, _valores: wei_value[128], _fakes: bool[128], _secrets: bytes32[128])
    # Comprobamos que se ha acabado el tiempo para pujar
    assert block.timestamp > self.finPujas
    # Comprobamos que no ha terminado el tiempo de revelar
    assert block.timestamp < self.revelacion
    # Comprobamos que el número de pujas reveladas coincide con el registro del sender
    assert _numPujas == self.contadorPujas[msg.sender]
    # Calculamos el valor del reembolso
    refund: wei_value = ZERO_WEI
    for i in range(maximo_pujas):
        # Nótese que el bucle puede parar antes de las 128 iteraciones si i >= _numPujas
        if (i >= _numPujas):
            break
        # Obtenemos la puja para comprobar
        pujaComprobar: Puja = (self.pujas[msg.sender])[i]
        # 
        valor: wei_value = _valores[i]
        fake: bool = _fakes[i]
        secret: bytes32 = _secrets[i]
        postorCiego: bytes32 = keccak256(concat(convert(valor,bytes32),convert(fake,bytes32),secret))
        # La puja no se ha revelado aún. No se ha reembolsado el depósito
        if (postorCiego != pujaComprobar.postorCiego):
            assert 1 == 0
            continue
        # Añadimos el depósito al reembolso si la puja fue reveladas
        reembolso += pujaComprobar.deposito
        if (not fake and pujaComprobar.deposito >= valor):
            if (self.pujaExito(msg.sender, valor)):
                reembolso -= valor
        # Imposibilitar que el sender reclame el mismo depósito
        zeroBytes32: bytes32 = EMPTY_BYTES32
        pujaComprobar.postorCiego = zeroBytes32
    # Enviamos el reembolso si no está a cero
    if (reembolso != 0):
        send(msg.sender, reembolso)
        
# Devolver una puja demasiado declarada
@public
def devolver():
    # Comprobar que hay alguna devolución pendiente
    devoluvionPendiente: wei_value = self.reembolsosPendientes[msg.sender]
    if (devoluvionPendiente > 0):
        # Si es así, ponemos las devoluciones pendientes a cero para evitar que el destinatario llame
        # a esta función de nuevo
        self.reembolsosPendientes[msg.sender] = 0
        # Reembolsamos el dinero
        send(msg.sender, devoluvionPendiente)
        
# La subasta acaba y se envía la mejor puja al beneficiario
@public
def finSubasta():
    # Comprobamos que ha pasado el tiempo de revelación
    assert block.timestamp > self.revelacion
    # Comprobamos que la subasta no ha sido marcada como finalizada
    assert not self.finalizada
    # Registramos que ha finalizado
    log.FinSubasta(self.mejorPostor, self.mejorPuja)
    self.finalizada = True
    # Envíamos el dinero al beneficiario
    send(self.beneficiario, self.mejorPuja)
        
            
   

