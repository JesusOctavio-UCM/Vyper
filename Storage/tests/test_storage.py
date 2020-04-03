import pytest

INITIAL_VALUE = 4

@pytest.fixture
def storage_contracts(Storage, accounts):
    # implementar el contrato con el valor inicial como argumento
    yield Storage.deploy(INITIAL_VALUE, {'from':accounts[0]})
    
def test_initial_state(storage_contract):
    # comprobamos si el constructor del contrato es el apropiado
    assert storage_contract.storedData() == INITIAL_VALUE
    
def tests_set(storage_contract, accounts):
    # establecemos el valor en 10
    storage_contract.set(10, {'from': accounts[0]})
    assert storage_contract.storedData() == 10 # acceso directo storedData
    
    # establecemos el valor en -5
    storage_contract.set(-5, {'from': accounts[0]})
    assert storage_contract.storedData() == -5