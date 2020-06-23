# Contrato para multas de tráfico
struct Multa:
    cantidad: wei_value
    fecha: timestamp
    matricula: string
    pagada: bool

struct Policia
    policia: address
    registromult: map(int128, Multa) # registro de las multas
    multasPend: int128 # cantidad de multas sin pagar
    multasClientes: map(address,Multa) # lista de los clientes con sus multas

# Esta función recibe como parámetros la policía, la matrícula sobre la que se pone la multa
# y la cantidad
@public
@constant
def multar(p: Policia, m: string, cant: wei_value):
    p.registromult[m].cantidad = cant
    p.registromult[m].fecha = block.timestamp
    p.registromult[m].matricula = m
    p.registromult[m].pagada = False
    p.multasPend += 1

@public
def reenviarMultas(p: Policia):
    while p.multasPend > 0:
        multa: Multa = p.registromult[p.multasPend]
        m: string = multa.matricula
        # Comprobamos si la multa está puesta en fecha de préstamo
        assert getRegistro(m).inicio >= multa.fecha
        assert getRegistro(m).dev <= multa.fecha
        # Buscamos al cliente que había realizado el alquiler
        cliente = getRegistro(m).cliente
        # Añadimos la multa al cliente correspondiente
        p.multasClientes[cliente] = multa
        p.multasPend -= 1

@public
@payable        
def pagarMulta(p: Policia):
    multa: Multa = p.multasClientes[msg.sender]
    # Comprobamos que la multa no esté ya pagada
    assert not multa.pagada
    send(multa.cantidad, e.policia)
    multa.pagada = True
       
