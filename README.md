# README del Proyecto

KIPU-BANK-V3

## Mejoras de Versión (v2 → v3)

* Implementación de UniswapV2 mediante un contrato Wrapper para permitir el intercambio de tokens por USDC siempre que posean un par directo.
* Modularización mejorada: el Wrapper se ubica en un contrato separado para mantener un código más limpio y permitir futuras modificaciones sin requerir migración de balances.
* Nueva función en **KipuBank**: `depositTokenAndConvert(address token, uint256 amount, uint256 amountOutMin)` que permite depositar tokens con par directo a USDC, convirtiéndolos automáticamente para ser acreditados como USDC en el balance del usuario.
* Implementación de `tokenAmountInUSD(address token, uint256 amount)` que consulta el Wrapper para estimar el valor actual en USDC según el token y cantidad enviados.
* Eliminación de las funciones `fallback` y `receive` para reforzar la seguridad, evitando depósitos no autorizados y permitiendo solo depósitos mediante funciones explícitas.

## Corrección de Errores

* NatSpec del constructor corregido.
* Nombre del contrato actualizado y alineado con el archivo correspondiente.
* Error de optimización corregido: se eliminaron constantes, strings o inmutables en errores o eventos para evitar gasto innecesario de gas.
* Eliminación de variable `data` en:
  `(bool success, bytes memory data) = user.call{value: amount}("");` ya que siempre queda vacía y solo incrementaba el gasto de gas.
* Reorganización del código aplicando el patrón CEI:

  * **Checks:** integrados en los modificadores.
  * **Effects:** descuento de tokens, incremento del contador y emisión de eventos.
  * **Interactions:** ejecución de retiros.
* Mejoras en `setPriceFeed` y `getTokenPriceUSD` para evitar accesos redundantes a variables de estado.
* Ajustes de indentación y limpieza general del código.


