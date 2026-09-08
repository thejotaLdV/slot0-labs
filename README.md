# slot0-labs

Proyectos Foundry reales y ejecutables que respaldan cada laboratorio de [slot0](../README.md) — el objetivo O3 del TFM.

## Estado de avance

| Categoría | Estado |
|---|---|
| Reentrancy | ✅ 3/3 laboratorios (contratos, exploits, tests de mitigación) |
| Control de acceso | ✅ 4/4 laboratorios (contratos, exploits, tests de mitigación) |
| Manipulación de oráculos | ✅ 3/3 laboratorios (contratos, exploits, tests de mitigación) |
| Flash Loan Attacks | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Delegatecall & Storage Collisions | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Gobernanza y economía DeFi | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Front-running & MEV | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Firma y replay | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Aleatoriedad débil | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Aritmética insegura | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |

## Estructura de cada categoría

```
src/<categoria>/
├── target/        dados, no se editan (los contratos vulnerables tal cual)
├── attacks/       RETO: contrato atacante con el exploit incompleto
└── mitigations/   RETO: copia del contrato vulnerable, mitigación incompleta

solutions/<categoria>/
├── attacks/       versión completa y verificada de cada atacante
└── mitigations/   versión completa y verificada de cada mitigación
```

`src/attacks/` y `src/mitigations/` son los dos ficheros que hay que completar por laboratorio — normalmente el callback `receive()` en el atacante, y el orden de las líneas + `nonReentrant` en la mitigación. `src/target/` no se toca: es el contrato vulnerable de partida, idéntico al mostrado en la web.

`solutions/` reproduce la misma estructura (`attacks/` y `mitigations/`) con las versiones completas — ver [`solutions/README.md`](solutions/README.md) para el criterio de cuándo consultarla.

## Instalación

```bash
git clone https://github.com/thejotaLdV/slot0-labs.git
cd slot0-labs
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
```

## Ejecutar los tests de una categoría

```bash
forge test --match-path "test/reentrancy/*.sol" -vv
```

Cada fichero de test contiene, como mínimo, dos funciones por laboratorio:

- `test_exploit_...` — pasa cuando `src/attacks/` está bien completado.
- `test_mitigation_...` — pasa cuando, además, `src/mitigations/` también lo está.

Es normal ver un test en verde y el otro en rojo mientras solo has completado uno de los dos ficheros.

## Caso especial: Aritmética insegura (Lab 01)

El Lab 01 de esta categoría fija a propósito un pragma anterior a Solidity 0.8.0 (`legacy/unsafe-arithmetic/LegacyToken.sol`), para que la aritmética con overflow real sea posible. Ese fichero vive **fuera** de `src/` — si estuviera dentro, el perfil por defecto (solc 0.8.24) fallaría al compilarlo, y con él, la compilación de **todo** el repositorio.

Antes de correr los tests de esta categoría por primera vez (o después de cualquier `forge clean`):

```bash
forge build --profile legacy
```

Esto compila solo `legacy/`, con solc 0.7.6, y deja el artefacto en `out/`. El test carga ese bytecode ya compilado con `vm.getCode()`, sin volver a compilar el `.sol` directamente — así que este paso no hace falta repetirlo en cada `forge test`, solo la primera vez.

`LegacyTokenFixed.sol` (la mitigación de este lab) no es un stub — no hay ningún TODO que completar. La propia mitigación es cambiar de compilador: la misma lógica, recompilada con pragma `^0.8.19`, ya revierte automáticamente en overflow. El Lab 02 de esta categoría sí tiene un reto real de código (retirar un bloque `unchecked` mal usado).
