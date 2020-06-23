units: {currency_value: "Valor moneda"}

# Eventos financieros que registra el contrato
Transferir: event({_origen: indexed(address), _destino: indexed(address), _valor: uint256(currency_value)})
Comprar: event({_comprador: indexed(address), _orden_compra: uint256(currency_value)})
Vender: event({_vendedor: indexed(address), _orden_venta: uint256(currency_value)})
Pagar: event({_servicio: indexed(address), _cantidad: wei_value})

# Inicializamos las variables de la empresa y sus propias acciones
empresa: public(address)
totalAcciones: public(uint256(currency_value))
precio: public(uint256(wei / currency_value))

# Almacena un libro de contabilidad con las tenencias de accionistas
acciones: map(address, uint256(currency_value))

# Inicializamos la empresa
@public
def __init__(_empresa: address, _total_acciones: uint256(currency_value), precio_inicial: uint256(wei / currency_value)):
    assert _total_acciones > 0
    assert precio_inicial > 0
    
    self.empresa = _empresa
    self.totalAcciones = _total_acciones
    self.precio = precio_inicial
    
    # La empresa tiene todas sus acciones al principio pero las puede vender todas
    self.acciones[self.empresa] = _total_acciones
    
# Cuantas acciones tiene la empresa
@private
@constant
def _accionesDisp() -> uint256(currency_value):
    return self.acciones[self.empresa]
    
@public
@constant
def accionesDisp() -> uint256(currency_value):
    return self._accionesDisp()
    
# Dar un valor a la empresa y obtener acciones a cambio
@public
@payable
def compraAccion():
    # Nota: la cantidad total se entrega a la empresa (sin acciones fraccionarias
    # hay que asegurar que se envía la cantidad exacta para la compra de acciones.
    orden_compra: uint256(currency_value) = msg.value / self.precio # redondeo a la baja
    
    # Comprobamos que hay suficientes acciones para comprar
    assert self._accionesDisp() >= orden_compra
    
    # Quitamos las acciones del mercado y se las damos al accionistas
    self.acciones[self.empresa] -= orden_compra
    self.acciones[msg.sender] += orden_compra
    
    # Registramos el evento de compra
    log.Comprar(msg.sender, orden_compra)
    
# Averigua cuantas acciones tiene una direccion (que es propieda de alguien)
@private
@constant
def _conseguirAccion(_accionista: address) -> uint256(currency_value):
    return self.acciones[_accionista]
    
# Función pública para permitir el acceso externo a _conseguirAccion
@public
@constant
def conseguirAccion(_accionista: address) -> uint256(currency_value):
    return self._conseguirAccion(_accionista)
    
# Devuelve el dinero que tiene la empresa en efectivo
@public
@constant
def efectivo() -> wei_value:
    return self.balance

# Devuelve una acción a la compañia y recupera el dinero
@public
def venderAccion(orden_venta: uint256(currency_value)):
    assert orden_venta > 0 # En otro caso, esto fallará en el send() siguiente
    # debido a un error 00G (no hay disponibilidad de Gas). 
    # Solo puedes vender tantas acciones como tengas.
    assert self._conseguirAccion(msg.sender) >= orden_venta
    # Comprueba si la empresa puede pagar
    assert self.balance >= (orden_venta * self.precio)
    
    # Vende la acción, envía las ganancias al usuario y poner la acción
    # de nuevo en el mercado
    self.acciones[msg.sender] -= orden_venta
    self.acciones[self.empresa] += orden_venta
    send(msg.sender, orden_venta)
    
    # Registra el evento de la venta
    log.Venta(msg.sender, orden_venta)

# Transferimos acciones de un accionista a otra (Suponemos que el receptor
# recibe alguna compensación pero esto no se contempla)
 @public
def transferirAccion(receptor: address, orden_transferencia: uint256(currency_value)):
    assert orden_transferencia > 0 # Similar al venderAccion anterior
    # Solo puedes comericar con las acciones que tienes
    assert self._conseguirAccion(msg.sender) >= orden_transferencia
    
    # Decrementamos las acciones del vendedor e incrementamos las del comprador
    self.acciones[msg.sender] -= orden_transferencia
    self.acciones[receptor] += orden_transferencia
    
    # Registramos el evento de transferencia
    log.Transferir(msg.sender, receptor, orden_transferencia)
    
# Permitimos que la empresa pague a alguien por los servicios prestados
@public
def pagarFactura(servicio: address, cantidad: wei_value):
    # Solo la empresa puede pagar un servicio
    assert msg.sender == self.empresa
    # Además, puede pagar solo si tiene suficiente efectivo
    assert self.balance >= cantidad
    # Paga la factura
    send(servicio, cantidad)
    # Registramos el evento del pago
    log.Pagar(servicio, cantidad)
    
# Devuelve la cantidad en wei que la empresa ha recaudado con la venta de acciones
@private
@constant
def _ganancia() -> wei_value:
    return (self.totalAcciones - self._accionesDisp()) * self.precio

# Función pública para permitir el acceso externo a _ganancia
@public
@constant
def _ganancia() -> wei_value:
    return self._ganancia
    
# Devolvemos el efectivo menos la deuda de la empresa
@public
@constant
def valor() -> wei_value:
    return self.balance - self._ganancia
    return self.balance - self._ganancia
    
