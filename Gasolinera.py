# Contrato para echar gasolina

struct Gasolinera:
    gasolinera: address
    preciogas: wei_value # el precio por litro de la gasolina
    registrogas: map(string, int128) # registro de los llenados del depósito asociados a cada matrícula

# Esta función recibe como parámetros: la gasolinera en la que se quiere echar gasolina, la matrícula
# del coche que quiere echarla y los litros que quiere el cliente
@public
@payable
def echar_gasolina(g: Gasolinera, m: string, c: int128)
    dep: int128 = g.registrogas[m]
    cantidad: wei_value = (dep - c) * g.preciogas
    # Comprobamos que el cliente tenga dinero suficiente para pagar
    assert msg.value >= cantidad
    # El cliente paga la gasolina
    send(e.gasolinera, cantidad)
    # Se actualiza el registro de su depósito
    e.registrogas[m] = dep + c
    
# Utilizo estas dos funciones para poder llamar a las variables de este contrato desde otro  
@public
@constant
def getPreciogas():
    return self.preciogas
    
@public
@constant
def getRegistrogas(m: string):
    return self.registrogas[m]
