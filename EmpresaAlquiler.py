# Contrato que incluye el alquiler y devolución de coches
struct Coche:
    matricula: string
    # litros de gasolina que tiene el depósito del coche
    deposito: int128
    # un booleano que indica si el coche está disponible o no
    disp: bool
    # el precio por día de alquiler
    precio: wei_value
    
struct Prestamo:
    # la fecha de inicio del alquiler
    inicio: timestamp
    # la fecha de devolución del coche
    dev: timestamp
    c: Coche
    # esta variable registra como está el depósito y se actualiza al echar gasolina
    gas: int128
    
# variables globales del contrato
empresa: public(address)
registro: public(map(address,Prestamo)) # la empresa de alquileres lleva un registro de los préstamos por cliente
flota: public(map(string,Coche)) # todos los coches que tiene la empresa, cada uno de ellos tiene asociada su matrícula


# la funcion alquilar recibe como parámetros: el número asociado al coche que se quiere alquilar y el intervalo del alquiler 
# en días (1 día, 2 días...). Supongo que cuando alguien alquila un coche 
# es para empezar a disfrutarlo ese mismo día
@public
@payable
def alquilar(m: string, t: timedelta): 
    # comprobamos si el coche que se quiere alquilar está disponible
    assert self.flota[m].disp
    # comprobamos si el usuario tiene suficiente dinero para pagar el coche
    assert msg.value >= (t * self.flota[m].precio)
    
    # Ya hemos comprobado que puede alquilarlo así que formalizamos el alquiler
    self.registro[msg.sender].inicio = block.timestamp
    self.registro[msg.sender].dev = block.timestamp + t
    self.registro[msg.sender].gas = self.flota[m].deposito
    self.registro[msg.sender].c = self.flota[m]
    self.flota[m].disp = False
    send(self.empresa, t * self.flota[m].precio)
    
@public
@payable
def devolver(m: string)
    # Si el cliente no devuelve el coche en fecha se le pone una multa del doble del precio por día
    devolucion: timestamp = self.registro[msg.sender].dev
    if block.timestamp > devolucion
       multa: wei_value = self.flota[m].precio * (devolucion - block.timestamp)
       send(self.empresa, multa)
    else # lo devuelve en fecha
        self.flota[m].disp = True
        # Si el cliente no llena el depósito como estaba se le pone una multa equivalente a la gasolina
        # que le falta
        if auxiliar2(m) < self.flota[m].deposito
           falta: int128 = self.flota[m].deposito - auxiliar2(m)
           multa: int128 = auxiliar1() * falta
           send(self.empresa, multa)
        else
            self.flota[m].deposito = auxiliar2(m)
        
    
    

