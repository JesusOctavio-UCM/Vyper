# Establecemos variables privadas (solo se pueden llamar dentro del contrato)

struct Recaudacion:
   participante: address
   valor: wei_value
   
participantes: map(int128, Recaudacion)
indiceRecaudacionSig: int128
beneficiario: address
fechalimite: public(timestamp)
objetivo: public(wei_value)
indiceReembolso: int128
limitetiempo: public(timedelta)

# Inicializamos las variables globales
@public
def __init__(_beneficiario: address, _objetivo: wei_value, _limitetiempo: timedelta):
    self.beneficiario = _beneficiario
    self.fechalimite = block.timestamp + _limitetiempo
    self.limitetiempo = _limitetiempo
    self.objetivo = _objetivo

# Participar en la recaudación de fondos
@public
@payable
def participar():
    assert block.timestamp < self.fechalimite, "fecha límite no cumplida (aún)"
    numpart: int128 = self.indiceRecaudacionSig
    self.participantes[numpart] = Recaudacion({participante: msg.sender, valor: msg.value})
    self.indiceRecaudacionSig = numpart + 1
    
# Se ha alcanzado la cantidad suficiente de dinero; se envían los fondos al beneficiario
@public
def finalizar():
    assert block.timestamp >= self.fechalimite, "fecha límite no cumplida (aún)"
    assert self.balance >= self.objetivo, "balance no válido"
    selfdestruct(self.beneficiario)
    
# No se ha recaudado el dinero suficiente; se reembolsa a todos los participantes
# (un máximo de 30 personas a la vez para evitar problemas de límite de gas)
@public
def reembolsar():
    assert block.timestamp >= self.fechalimite and self.balance < self.objetivo
    ind: int128 = self.indiceReembolso
    for i in range(ind, ind+30):
        if i >= self.indiceRecaudacionSig:
            self.indiceReembolso = self.indiceRecaudacionSig
            return
        send(self.participantes[i].participante, self.participantes[i].valor)
        clear(self.participantes[i])
    self.indiceReembolso = ind + 30
    
