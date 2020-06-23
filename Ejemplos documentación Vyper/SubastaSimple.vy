# Los parámetros de la subasta son:
beneficiario: public(address) # el beneficiario recibe el dinero del ganador de la puja
comienzoSubasta: public(timestamp) # momento en el que comienza
finSubasta: public(timestamp) # momento en el que termina

# Estado actual de la subasta
postorAlto: public(address) # el mejor postor actualmente
pujaAlta: public(wei_value) # el valor de la mejor puja actualmente

# Cuando acaba la subasta, se le asigna verdadero
finalizada: public(bool)

# Llevamos un registro de los reembolsos para poder seguir el patrón de retirada
reembolsosPendientes: public(map(address, wei_value))

# Creamos una subasta con _tiempo_subasta (lo que va a durar)
@public
def __init__(_beneficiario: address, _tiempo_subasta: timedelta):
    self.beneficiario = _beneficiario
    self.comienzoSubasta = block.timestamp
    self.finSubasta = self.comienzoSubasta + _tiempo_subasta

# Puja en la subasta con el valor enviado junto a esta transacción
# El valor solo puede devolverse si no gana la subasta
@public
@payable
def puja():
    # Comprobamos si se ha acabado el tiempo de pujar
    assert block.timestamp < self.finSubasta
    # Comprobamos si la puja es lo suficientemente alta
    assert msg.value > self.pujaAlta
    # Devolvemos su puja al anterior postor (al que iba ganando)
    self.reembolsosPendientes[self.postorAlto] += self.pujaAlta
    # Ponemos la nueva puja como la más alta y a su postor como el ganador actual
    self.postorAlto = msg.sender
    self.pujaAlta = msg.value
    
# Retirar una puja reembolsada previamente. El patrón de retirada es
# utilizado aquí para evitar un problema de seguridad. Si los reembolsos fueran directamente
# enviado como parte de la puja(), un contrato de oferta malicioso podría bloquear
# esos reembolsos y, por lo tanto, bloquean la entrada de nuevas ofertas más altas.

# Se lleva a cabo la devolución de la puja, si se hiciera dentro de la
# función puja() se podría bloquear el contrato.
@public
def retirada():
    cantidad_pendiente: wei_value = self.reembolsosPendientes[msg.sender]
    self.reembolsosPendientes[msg.sender] = 0
    send(msg_sender, cantidad_pendiente)
    
# Finaliza la subasta y se envía la puja más alta al beneficiario
@public
def finalizarSubasta():
    # Puede ser un ejemplo de función que interactúa con otros contratos
    # (llamando a funciones o enviando Ether) en tres fases:
    # 1. comprueba las condiciones
    # 2. lleva a cabo acciones (que probablemente cambie las condiciones)
    # 3. interactua con otros contratos
    # Si estas fases están mezcladas, el otro contrato puede llamar al contrato
    # actual y modificar su estado o causar efectos (pagos de Ether) que se
    # realizarán varias veces. Si la función llamada internamente incluye interacción
    # con contratos externos, se puede considerar interacción con contratos externos.
    
    # 1. Condiciones, comprobamos si se ha alcanzado el final de la subasta
    assert block.timestamp >= self.finSubasta
    # Comprobamos si ya hemos llamado a esta función
    assert not self.finalizada
    
    # 2. Acciones
    self.finalizada = True
    
    # 3. Interacciones
    send(self.beneficiario, self.pujaAlta)
