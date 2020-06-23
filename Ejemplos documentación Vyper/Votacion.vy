# Votacion con delegación.

# Información sobre los votantes.
struc Votante:
    # el peso se acumula en la delegación
    peso: int128
    # si es cierto, la persona ya ha votado (incluido el voto delegando)
    votado: bool
    # persona en la que se delega
    delegar: address
    # índice de la propuesta votada, lo cual no es significativo hasta que votado sea cierto
    voto: int128
    
# Los usuarios pueden crear propuestas
struct Propuesta
    # nombre corto (hasta 32 bytes)
    nombre: bytes32
    # número de votos acumulados
    contVotos: int128
    
votantes: public(map(address,Votante))
propuestas: public(map(int128,Propuesta))
contVotante: public(int128)
presidente: public(address)
int128propuestas: public(int128)

@private
@constant
def _delegado(addr: address) -> bool: # si addr ha delegado en alguien
    return self.votantes[addr].delegar != ZERO_ADDRESS
    
@public
@constant
def delegado(addr: address) -> bool:
    return self._delegado(addr)
    
@private
@constant    
def _votadodirect(addr: address) -> bool: # si addr ya ha votado sin delegar
    return self.votantes[addr].votado and (self.votantes[addr].delegar == ZERO_ADDRESS)
    
@public
@constant
def votadodirect(addr: address) -> bool:
    return self._votadodirect(addr)
    
# Inicializamos las variables globales
@public
def __init__(_nombrespropuestas: bytes32[2]):
    self.presidente = msg.sender
    self.contVotante = 0
    for i in range(2):
        self.propuestas[i] = Propuesta({nombre: _nombrespropuestas[i], contVotos: 0})
        self.int128propuestas += 1
        
# Le damos a un votante el derecho de votar en esta votación.
# Solo el presidente puede llamar a esta función
@public
def derechoVoto(votante: address):
    # Falla si el que llama no es el presidente
    assert msg.sender == self.presidente
    # Falla si el votante ya ha votado
    assert not self.votantes[votante].voted
    # Falla si el peso del votante no es 0
    assert self.votantes[votante].peso == 0
    self.votantes[votante].peso = 1
    self.contVotante += 1
    
# Usado por el delegado después, se puede llamar externamente con enviarpeso
@private
def _enviarpeso(delegado_con_peso_enviar: address):
    assert self._delegado(delegado_con_peso_enviar)
    # Falla si no hay nada que hacer
    assert self.votantes[delegado_con_peso_enviar].peso > 0
    
    objetivo: address = self.votantes[delegado_con_peso_enviar].delegar
    for i in range(4):
        if self._delegado(objetivo):
            objetivo = self.votantes[objetivo].delegar
            # Lo siguiente detecta ciclos de longitud <= 5 en el que la 
            # delegación se devuelve al que ha delegado. Esto podría hacerse
            # para cualquier int128ber de bucles o incluso infinitamente con
            # un bucle while. Sin embargo, los ciclos no son realmente
            # problemáticos para la corección: solo son votos estropeados.
            # Entonces, en la versión de producción, debería ser responsabilidad
            # del cliente del contrato y su comprobación debería eliminarlo.
            assert objetivo != delegado_con_peso_enviar
        else:
            # El peso debe moverse a alguien que vote directamente o que no haya votado
            break
        
    peso_enviar: int128 = self.votantes[delegado_con_peso_enviar].peso
    self.votantes[delegado_con_peso_enviar].peso = 0
    self.votantes[objetivo].peso += peso_enviar
    
    if self._votadodirect(objetivo):
        self.propuestas[self.votantes[target].voto].contVotos += peso_enviar
        self.votantes[objetivo].peso = 0
        
    # Para reiterar: si el objetivo es también delegado, esta función
    # tendrá que llamarse de nuevo, de forma similar a lo siguiente
    
# Función pública para llamar
@public
def enviarpeso(delegado_con_peso_enviar: address):
        self._enviarpeso(delegado_con_peso_enviar)
        
# Delegar tu voto en el votante d
@public
def delegar(d: address)
    # Falla si el que delega ya ha votado
    assert not self.votantes[msg.sender].voted
    # Falla si intenta delegar su voto a sí mismo o la dirección por defecto
    # es 0x0000000000000000000000000000000000000000
    assert d != msg.sender
    assert d != ZERO_ADDRESS
    
    self.votantes[msg.sender].votado = True
    self.votantes[msg.sender].delegar = d
    
    # Esta llamada fallará si y solo si la delegación causa un bucle de
    # longitud <= 5 que terminará devolviendo la delegación
    self._enviarpeso(msg.sender)

# Dar tu voto (incluidos los delegados en ti)
# a una propuesta 'propuestas[propuesta].nombre'
@public
def votar(propuesta: int128):
    # No se puede votar dos veces
    assert not self.votantes[msg.sender].votado
    # Solo se puede votar a propuestas legítimas
    assert propuesta < self.int128propuestas
    
    self.votantes[msg.sender].voto = propuesta
    self.votantes[msg.sender].votado = True
    
    # se pasa el peso del votante a la propuesta
    self.propuestas[propuesta].contVotos += self.votantes[msg.sender].peso
    self.votantes[msg.sender].peso = 0
    
# Calcula la propuesta ganadora teniendo en cuenta los votos anteriores
@private
@constant
def _propuestaGanadora() -> int128
    contador_votos_ganadora: int128 = 0
    propuesta_ganadora: int128 = 0
    for i in range(2):
        if self.propuestas[i].contVotos > contador_votos_ganadora:
            contador_votos_ganadora = self.propuesta[i].contVotos
            propuesta_ganadora = i
    return propuesta_ganadora
    
@public
@constant
def propuestaGanadora() -> int128
    return self._propuestaGanadora()
    
# Llamamos a propuestaGanadora() para obtener el índice de la ganadora
# contenida en el array de propuestas y después devolvemos su nombre
@public
@constant
def nombreGanadora() -> bytes32
    return self.propuestas[self._propuestaGanadora()].nombre
    
    
