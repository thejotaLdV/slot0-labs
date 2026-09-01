# Soluciones

Esta carpeta contiene la versión **completa y verificada** de cada contrato atacante y de cada mitigación — las mismas que ya pasaron los 7 tests de la categoría Reentrancy.

No está pensada para copiarse y pegarse directamente. Si abres un fichero de aquí antes de haber intentado resolver el laboratorio tú mismo en `src/<categoria>/attacks/` o `src/<categoria>/mitigations/`, te estás saltando la parte que realmente enseña algo — es exactamente lo mismo que abrir la sección "Solución" de la web sin pasar antes por las pistas.

Úsala solo si:

- Ya leíste las pistas de la página del laboratorio, una a una, y sigues atascado.
- Quieres comparar tu propia solución (si `forge test` ya te pasa) con la versión de referencia, para ver si llegaste al mismo sitio por un camino distinto.

## Cómo verificar que un stub está bien planteado

Si en algún momento dudas si el hueco que hay que rellenar en `src/<categoria>/attacks/` o `src/<categoria>/mitigations/` es realmente el correcto, puedes comprobarlo tú mismo:

```bash
# 1. Confirma que el test FALLA con el stub tal cual viene
forge test --match-path test/reentrancy/Reentrancy01.t.sol -vv

# 2. Copia temporalmente las soluciones de referencia sobre los stubs
cp solutions/reentrancy/attacks/SimpleVaultAttacker.sol src/reentrancy/attacks/SimpleVaultAttacker.sol
cp solutions/reentrancy/mitigations/SimpleVaultFixed.sol src/reentrancy/mitigations/SimpleVaultFixed.sol

# 3. Confirma que ahora SÍ pasan los dos tests
forge test --match-path test/reentrancy/Reentrancy01.t.sol -vv

# 4. Deshaz las copias (recupera los stubs con git)
git checkout -- src/reentrancy/attacks/SimpleVaultAttacker.sol src/reentrancy/mitigations/SimpleVaultFixed.sol
```
