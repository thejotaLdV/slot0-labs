# slot0-labs

Proyectos Foundry reales y ejecutables que respaldan cada laboratorio de [slot0](../README.md) — el objetivo O3 del TFM.

## Estado de avance

| Categoría | Estado |
|---|---|
| Reentrancy | ✅ 3/3 laboratorios (contratos, exploits, tests de mitigación) |
| Control de acceso | ⏳ pendiente |
| Manipulación de oráculos | ⏳ pendiente |
| Flash Loan Attacks | ⏳ pendiente |
| Delegatecall & Storage Collisions | ⏳ pendiente |
| Gobernanza y economía DeFi | ⏳ pendiente |
| Front-running & MEV | ⏳ pendiente |
| Firma y replay | ⏳ pendiente |
| Aleatoriedad débil | ⏳ pendiente |
| Aritmética insegura | ⏳ pendiente |

## Instalación

```bash
git clone <url-de-este-repo> slot0-labs
cd slot0-labs
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
```

## Ejecutar los tests de una categoría

```bash
forge test --match-path "test/reentrancy/*.sol" -vvvv
```

Cada fichero de test contiene, como mínimo, dos funciones por laboratorio:

- `test_exploit_...` — despliega el contrato **vulnerable** y demuestra que el ataque descrito en la web funciona.
- `test_mitigation_...` — despliega el contrato **corregido** y demuestra que el mismo ataque ya no funciona (revierte, o solo permite la operación legítima).

## Nota sobre verificación

Este código se ha escrito con trazado manual cuidadoso de cada operación aritmética y cada secuencia de llamadas, pero **no se ha compilado ni ejecutado** en el entorno donde se redactó (sin acceso a red para instalar Foundry/OpenZeppelin). Antes de darlo por bueno, ejecuta `forge build` y `forge test -vvvv` y reporta cualquier error de compilación o test en rojo.
