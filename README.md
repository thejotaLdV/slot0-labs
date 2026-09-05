# slot0-labs

Proyectos Foundry reales y ejecutables que respaldan cada laboratorio de [slot0](../README.md) — el objetivo O3 del TFM.

## Estado de avance

| Categoría | Estado |
|---|---|
| Reentrancy | ✅ 3/3 laboratorios (contratos, exploits, tests de mitigación) |
| Control de acceso | ✅ 4/4 laboratorios (contratos, exploits, tests de mitigación) |
| Manipulación de oráculos | ✅ 3/3 laboratorios (contratos, exploits, tests de mitigación) |
| Flash Loan Attacks | ✅ 2/2 laboratorios (contratos, exploits, tests de mitigación) |
| Delegatecall & Storage Collisions | ⏳ pendiente |
| Gobernanza y economía DeFi | ⏳ pendiente |
| Front-running & MEV | ⏳ pendiente |
| Firma y replay | ⏳ pendiente |
| Aleatoriedad débil | ⏳ pendiente |
| Aritmética insegura | ⏳ pendiente |

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
