# Contrato para alquilar y devolver en una empresa de alquiler de coches
struct Coche:
    # cadena de caracteres con la matrícula del coche
    matricula: string
    # litros de gasolina con que se entrega el coche
    deposito: int128
    # un booleano que indica si el coche está disponible o no
    disp: bool
    # el precio por día de alquiler del coche
    precio: wei_value
    
struct Prestamo:
    # la fecha de inicio del alquiler
    inicio: timestamp
    # la fecha de devolución del coche
    dev: timestamp
    # el coche que se alquila
    coche: Coche
    # el cliente que realiza el alquiler
    cliente: address

struct Empresa:    
    empresa: address
    registro: map(string,Prestamo) # la empresa de alquileres lleva un registro de los préstamos por matrícula
    flota: map(string,Coche) # todos los coches que tiene la empresa, cada uno de ellos asociado a su matrícula


# la funcion alquilar recibe como parámetros: la empresa en la que se quiere alquilar el coche,la matrícula del
# coche que se quiere alquilar y el intervalo del alquiler en días (1 día, 2 días...). Supongo que cuando alguien 
# alquila un coche es para empezar a disfrutarlo ese mismo día
@public
@payable
def alquilar(e: Empresa, m: string, t: timedelta): 
    # comprobamos si el coche que se quiere alquilar está disponible
    assert e.flota[m].disp
    # comprobamos si el usuario tiene suficiente dinero para pagar el coche
    assert msg.value >= (t * e.flota[m].precio)
    
    # Ya hemos comprobado que puede alquilarlo así que formalizamos el préstamo actualizando sus variables
    e.registro[m].inicio = block.timestamp
    e.registro[m].dev = block.timestamp + t
    e.registro[m].coche = e.flota[m]
    e.registro[m].cliente = msg.sender
    # El coche alquilado deja de estar disponible
    e.flota[m].disp = False
    # El cliente paga el precio del alquiler
    send(e.empresa, t * e.flota[m].precio)

# La función devolver recibe como parámetro la matrícula del coche a devolver y la empresa a la que se devuelve   
@public
@payable
def devolver(e: Empresa, m: string)
    # Comprobamos que el coche está realmente prestado
    assert not e.flota[m].disp
    # El cliente que llama a la función es el que alquiló el coche
    assert e.registro[m].cliente == msg.sender
    # Si el cliente no devuelve el coche en fecha se le pone una multa del doble del precio por día
    devolucion: timestamp = e.registro[m].dev
    if block.timestamp > devolucion
       retraso: wei_value = e.flota[m].precio * (devolucion - block.timestamp)
       send(e.empresa, retraso)
    else # lo devuelve en fecha
        e.flota[m].disp = True
        # Si el cliente no llena el depósito como estaba se le pone una multa equivalente a la gasolina
        # que le falta
        if getRegistrogas(m) < e.flota[m].deposito
           # litros que le faltan al depósito para estar como se entregó
           falta: int128 = e.flota[m].deposito - getRegistrogas(m)
           # precio que tiene que pagar el cliente
           cant: wei_value = getPreciogas() * falta
           send(e.empresa, cant)
        else # si la gasolina es correcta (puede haber más) se actualiza el depósito del coche
            e.flota[m].deposito = getRegistrogas(m)
    # Después de todas las comprobaciones y multas pertinentes, se devuelve el coche
    e.flota[m].disp = True
        
# Utilizamos esta función para llamarla desde otros contratos y obtener, dada una matrícula el registro
# de los préstamos    
@public
@constant
def getRegistro(m: string):
    return self.registro[m]

