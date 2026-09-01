# Soluciones

Esta carpeta contiene la versión **completa y verificada** de cada contrato atacante — la misma que ya pasó los 7 tests de la categoría Reentrancy.

No está pensada para copiarse y pegarse directamente. Si abres un fichero de aquí antes de haber intentado resolver el laboratorio tú mismo en `src/<categoria>/attacks/`, te estás saltando la parte que realmente enseña algo — es exactamente lo mismo que abrir la sección "Solución" de la web sin pasar antes por las pistas.

Úsala solo si:

- Ya leíste las pistas de la página del laboratorio, una a una, y sigues atascado.
- Quieres comparar tu propia solución (si `forge test` ya te pasa) con la versión de referencia, para ver si llegaste al mismo sitio por un camino distinto.

## Cómo verificar que un stub está bien planteado

Si en algún momento dudas si el hueco que hay que rellenar en `src/<categoria>/attacks/` es realmente el correcto, puedes comprobarlo tú mismo:

```bash
# 1. Confirma que el test FALLA con el stub tal cual viene
forge test --match-path test/reentrancy/Reentrancy01.t.sol -vv

# 2. Copia temporalmente la solución de referencia sobre el stub
cp solutions/reentrancy/SimpleVaultAttacker.sol src/reentrancy/attacks/SimpleVaultAttacker.sol

# 3. Confirma que ahora SÍ pasa
forge test --match-path test/reentrancy/Reentrancy01.t.sol -vv

# 4. Deshaz la copia (recupera el stub con git)
git checkout -- src/reentrancy/attacks/SimpleVaultAttacker.sol
```
