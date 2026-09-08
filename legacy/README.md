# legacy/

Contratos que fijan deliberadamente un pragma anterior a Solidity 0.8.0,
para el Laboratorio 01 de Aritmética insegura.

Viven **fuera** de `src/` a propósito: el perfil por defecto de este repo
compila con solc 0.8.24, y si este fichero estuviera dentro de `src/`,
`forge build`/`forge test` (sin especificar perfil) fallaría al intentar
compilarlo con una versión que su propio `pragma` no permite — para **todas**
las categorías, no solo para esta.

## Cómo se compila y se usa

```bash
forge build --profile legacy
```

Esto compila únicamente lo que hay en esta carpeta, con solc 0.7.6, y deja
el artefacto en `out/` (el mismo `out/` de siempre). El test de este
laboratorio (`test/unsafe-arithmetic/UnsafeArithmetic01.t.sol`) no importa
este `.sol` directamente — carga su bytecode ya compilado con
`vm.getCode("LegacyToken.sol")` y lo despliega con `create` a bajo nivel,
interactuando después a través de una interfaz normal. Así, el test en sí
se compila sin problema con el perfil por defecto (0.8.24).

**Solo hace falta ejecutar `forge build --profile legacy` una vez** (o de
nuevo tras un `forge clean`) — no en cada `forge test`.
