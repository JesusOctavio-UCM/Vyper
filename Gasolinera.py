gasolinera: public(address)
precio: public(wei_value) # el precio por litro de la gasolina
registro: public(map(string, int128)) # lleva los depósitos de cada matrícula

# Esta función recibe como parámetros: la matrícula del coche que quiere echar gasolina,
# la cantidad que hay en el depósito en litros, los litros que quiere 
# echar el cliente
@public
@payable
def echar_gasolina(m: string, c: int128)
    # Comprobamos que el cliente tenga dinero suficiente
    dep: int128 = self.registro[m]
    cantidad: int128 = (dep - c) * self.precio
    assert msg.value >= cantidad
    send(self.gasolinera, cantidad)
    self.registro[m] = dep + c
    
# Utilizo esta función para poder llamar a las variables de este contrato desde otro, no se si se podrá hacer de otra forma   
@public
@constant
def auxiliar():
    return self.precio
    
@public
@constant
def auxiliar2(m: string):
    return self.registro[m]