# 🌈 **KIPU-BANK v3.0 — Documentación Oficial**

Bienvenido a la versión **v3.0** de **KipuBank**, una evolución completa orientada a la **modularidad**, **seguridad**, **optimización de gas** y **mejor experiencia de usuario**, incluyendo la integración directa con **UniswapV2**.

---

# 🚀 **Mejoras de Versión (v2 → v3)**

> 📘 **Nota Didáctica:** Gran parte del código de la **versión v2** se mantiene en el repositorio para facilitar el estudio comparativo de mejoras, patrones y correcciones aplicadas. Ese código queda **inutilizado** en v3.
> En **KipuBank v3.1** se eliminarán completamente para obtener un código aún más limpio.

> 📘 **Nota:** El contrato de desplego en remix para validarlo por lo que cuenta con unas pequeñas diferencias en codigo como pero sin limitarme en la importacion de librerias ".src/..." a "src/..." para que se pueda ejecutar correctamente en Foundry.
> Como tambien modificaciones menores mencionadas en el readme las cuales no afectan la funcionalidad del programa.

### ✨ Cambios principales

🔹 Implementación de **UniswapV2** mediante un contrato **Wrapper** para intercambiar tokens → USDC (solo pares directos).
🔹 Mejora completa de **modularización**, separando la lógica de swaps en otro contrato para evitar futuras migraciones.
🔹 Nueva función clave en **KipuBank**:

* `depositTokenAndConvert(address token, uint256 amount, uint256 amountOutMin)` → permite depositar tokens y convertirlos automáticamente en USDC.
  🔹 Nueva función de consulta:
* `tokenAmountInUSD(address token, uint256 amount)` → estima valor en USDC usando el Wrapper.
  🔹 Eliminación de `fallback` y `receive` por seguridad, permitiendo depósitos solo mediante funciones explícitas.

---

# 🛠️ **Corrección de Errores**

✔ **NatSpec corregido** para el constructor.
✔ **Nombre del contrato actualizado** y alineado con el archivo principal.
✔ Eliminación de **constantes, strings e inmutables** en errores y eventos (mejora de gas).
✔ Eliminación de la variable inútil `data` en:

```
(bool success, bytes memory data) = user.call{value: amount}("");
```

📝 *`data` siempre está vacía; mantenerla era un error conceptual y aumentaba costos de gas.*

✔ Reorganización completa bajo el **patrón CEI**:

* **Checks:** validados mediante modificadores.
* **Effects:** actualización de balances, contadores y eventos.
* **Interactions:** ejecución de retiros al final.

✔ Optimización en `setPriceFeed` y `getTokenPriceUSD` evitando lecturas redundantes de estado.
✔ Ajuste de identación y limpieza general del código.

---

# 🧱 **Arquitectura del Sistema (v3)**

El proyecto se divide en dos módulos principales:

## 🧩 **1. KipuBank (Contrato Principal)**

Responsabilidades:

* Manejo de balances del usuario (*solo USDC*).
* Depósitos / Retiros.
* Gestión de Price Feeds (Chainlink).
* Integración con Wrapper UniswapV2.
* Contadores y auditoría interna.

## 🔄 **2. Wrapper UniswapV2 (Módulo Externo)**

Encargado de:

* Realizar swaps token → USDC.
* Estimar montos sin ejecutar.
* Validar pares directos.
* Centralizar toda la lógica de Uniswap.

### Beneficios

✔ Mejor modularización
✔ Mejor mantenibilidad
✔ Evita migraciones futuras
✔ Código más seguro y limpio

---

# 🔁 **Flujo Operativo del Sistema**

## 🟦 1. Depósito Estándar

1️⃣ Usuario deposita USDC
2️⃣ Se incrementa su balance interno

## 🟩 2. Depósito con Conversión Automática (Token → USDC)

**Ruta completa:**

1. `depositTokenAndConvert(token, amount, amountOutMin)`
2. KipuBank transfiere el token al Wrapper
3. Wrapper hace swap token → USDC
4. KipuBank acredita el USDC al usuario
5. Se emite el evento `TokenConvertedAndDeposited`

## 🟥 3. Retiros

El usuario solo puede retirar **USDC**.
🔐 Esto mantiene el sistema simple, seguro y estable.

---

# 🧮 **Cálculo de Precios**

### 📌 Chainlink Price Feed

Usado para tokens con oráculos oficiales.

### 📌 Wrapper UniswapV2 — `tokenAmountInUSD`

Se usa cuando:

* El token NO tiene price feed, pero
* SÍ tiene par directo → USDC

Sirve para **estimar** (no ejecutar) swap.

🎯 Complementa a Chainlink, NO lo reemplaza.

---

# 🛡️ **Seguridad en v3**

### 🔐 Eliminación de `receive()` y `fallback()`

Evita:

* Envíos accidentales de ETH
* Intentos de bypass de funciones
* Vectores de ataque externos

### 🧩 Patrón CEI Correctamente Aplicado

✔ Checks al inicio (modificadores)
✔ Effects antes de las interacciones externas
✔ Interactions al final para evitar reentrancy

### ⚙️ Swaps Seguros

Wrapper valida:

* Existencia de par directo token–USDC
* `amountOutMin` contra MEV y slippage
* Que no existan swaps encadenados o loops

### 💨 Optimización del Estado

Variables almacenadas en memoria local para:

* Reducir gas
* Evitar dobles accesos accidentales

---

# 🧹 **Limpieza General y Optimización**

### 🗑 1. Eliminación de `data` en llamadas externas

Evita almacenamiento innecesario.

### 🧽 2. Eliminación de constantes en eventos / errores

Reduce costos en ejecución y hace el código más legible.

### 📑 3. Organización de funciones y comentarios

Código más limpio y consistente.

