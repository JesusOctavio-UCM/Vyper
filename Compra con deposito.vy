# También es un ejemplo de Solidity adaptado a Vyper
# Resumen de la transacción
# 1. El vendedor publica un objeto para la venta y hace un depósito seguro
#    del doble del valor del artículo; el depósito tiene 2*value. Puede
#    reclamarlo y cerrar la venta mientras que nadie haya comprado.
# 2. El comprador compra el artículo (value) y hace un depósito adicional de
#    seguridad; el depósito tiene 4*value.
# 3. El vendedor envía el artículo.
# 4. El comprador confirma la recepción del artículo. Se devuelve el depósito
#    al comprador (value). Se le devuelve al comprador su depósito(2*value) y
#    el valor del artículo (value); el depósito se queda a 0.

value: public(wei_value) # Valor del artículo
vendedor: public(address)
comprador: public(address)
desbloqueada: public(bool)
finalizada: public(bool)

@public
@payable
def __init__():
    assert (msg.value % 2) == 0
    self.value = msg.value / 2 # El vendedor inicializa el contrato con
                               # el depósito de seguridad de 2*value
    self.comprador = msg.sender
    self.desbloqueada = True
    
@public
def cancelar():
    assert self.desbloqueada # ¿Todavía de puede cancelar la venta?
    assert msg.sender == self.vendedor # El vendedor solo puede recuperar su
                                       # depósito si ningún comprador lo ha adquirido
    selfdestruct(self.vendedor) # El vendedor recupera el depósito y se destruye el contrato
    
@public
@payable
def comprar():
    assert self.desbloqueada # ¿Está el contrato abierto aún (el objeto sigue a la venta)?
    assert msg.value == (2 * self.value) # ¿El depósito tiene el valor correcto?
    self.comprador = msg.sender
    self.desbloqueada = False
    
@public
def recibido():
    # 1. Condiciones
    assert not self.desbloqueada # ¿Está el objeto comprado y pendiente de 
                                 #  confirmación del comprador?
    assert msg.sender == self.comprador
    assert not self.finalizada
    # 2. Efectos
    self.finalizada = True
    # 3. Interacción
    send(self.comprador, self.value) # Se devuelve el depósito del comprador
    selfdestruct(self.vendedor) # Se devuelve el depósito del vendedor y el
                                # el precio de compra del artículo
