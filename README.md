# Manantial de Misiones · Panel

Panel de administración web (un solo `index.html`) publicado con GitHub Pages:

https://ammgx.github.io/ManantialDeMisiones-/

## Qué incluye

- **Resumen:** último cierre, ventas registradas, cajas sin controlar y deuda de clientes.
- **Ventas:** todas las ventas con filtros por mes, vendedor, medio y texto; totales, fiado, cobros, detalle y ranking de productos.
- **Clientes:** buscador, deuda, ficha con historial de ventas y cobros, exportación CSV.
- **Cierres de caja:** agrupados por mes, con filtros por usuario y estado, revisión, arqueo y exportación CSV.
- **Precios:** productos, precios e historial de cambios.
- **Usuarios:** crear usuarios, cambiar roles, dar de baja y restablecer contraseñas.
- **Cuenta:** cambio de contraseña y respaldo completo.
- **Archivo:** descarga mensual de cajas y consulta de archivos guardados.

## Ventas

- La primera vez que entrás a la pestaña se descargan todas las ventas, ítems y cobros.
  Puede demorar unos segundos; después queda en memoria y el botón **Actualizar** lo recarga.
- Totales del filtro: **vendido**, **fiado generado**, **cobrado** y **ticket promedio**.
- Filtros: mes, vendedor, medio de pago y búsqueda por cliente, producto o nota.
  Las ventas anuladas se ocultan por defecto; hay un tilde para incluirlas.
- Tabla agrupada por mes; **Ver** abre el detalle con productos, pago, saldo y motivo de anulación.
- **Productos más vendidos** se calcula con las ventas filtradas.
- **Exportar CSV** descarga la lista filtrada completa.

> Si hay muchas ventas, la tabla muestra las últimas 300 para no trabar el celular.
> Los totales y el CSV usan todas las ventas del filtro.

## Clientes

- Buscador por nombre, teléfono, dirección, localidad, referencia o descripción.
- Totales arriba: clientes, con deuda, deuda total e inactivos.
- Filtros: todos, con deuda, activos e inactivos.
- **Ver** abre la ficha con: contacto, deuda actual, total vendido, fiado generado,
  total cobrado, últimas ventas y últimos cobros.
- **Exportar CSV** descarga la lista filtrada.

> Los datos del cliente se editan desde la app. El panel solo consulta, para no
> pisar cambios con la sincronización del celular.

## Usuarios

Desde la pestaña **Usuarios** un administrador puede:

- **+ Usuario**: crear una cuenta con nombre, email, rol y contraseña.
- **Editar**: cambiar nombre, rol o estado (activo/baja).
- **Contraseña**: asignar una contraseña nueva a cualquier usuario.

El email y la contraseña son los mismos que se usan para entrar a la app.
El usuario creado queda confirmado y puede ingresar de inmediato.

> La creación y el cambio de contraseña usan dos funciones seguras de Supabase.
> Hay que aplicar el SQL de [sql/usuarios.sql](sql/usuarios.sql) **una sola vez**:
> Supabase → SQL Editor → pegar el archivo → Run. Sin ese paso, el panel muestra
> un aviso al intentar crear o cambiar una contraseña.

## Respaldo completo

En **Cuenta → Respaldo completo** se descarga un JSON con:

- todas las cajas, abiertas y cerradas;
- ventas, ítems, cobros y movimientos;
- clientes, productos, usuarios y cambios de precio.

No incluye emails ni contraseñas de acceso. Para guardar solo un mes, usar la
pestaña **Archivo**.

## Cierres de caja

- Se cargan **todas** las cajas, sin límite de meses.
- Se muestran agrupadas por mes; el mes más reciente aparece abierto.
- Cada grupo muestra cantidad de cajas, total y pendientes de control.
- Filtros: **usuario** (quién abrió la caja) y **estado** (pendiente, conforme, observado).
- **Exportar CSV** descarga exactamente lo que está filtrado en pantalla.

## Archivo de cajas (para no llenar Supabase)

Es la última pestaña. En **Archivo**:

1. Elegí el mes que querés guardar (o *Todo el historial*).
2. **Descargar archivo** genera un `.json` con cajas, ventas, ítems, cobros,
   movimientos y copias de clientes, productos y usuarios.
3. Guardá ese archivo donde quieras (Google Drive, repo privado, pendrive).
4. Para consultarlo, usá **Abrir archivo…**: se ve en el panel sin subir nada al servidor.

El archivo es de **solo lectura**: no modifica ni borra datos de la base.

> Recomendación: descargar el archivo de cada mes cerrado y guardarlo. Sirve como
> respaldo y como histórico, sin ocupar espacio en el plan gratuito.

## Uso desde el celular

La página se adapta a pantallas chicas: tarjetas en dos columnas, tablas compactas
(ocultan las columnas de medios de pago) y botones más grandes para tocar.
No hace falta instalar nada: se abre en el navegador del teléfono.

## Seguridad

- El repositorio es público; la clave de Supabase que usa el panel es la
  *publishable*, pensada para el navegador.
- La protección real de los datos está en las reglas (RLS) de Supabase. El chequeo
  de administrador del panel es solo una comodidad visual.
- No guardar en este repositorio claves privadas, tokens ni datos de clientes.

## Cómo actualizar

1. Editar `index.html`.
2. Subir el cambio a `main`.
3. GitHub Pages lo publica solo en un par de minutos.

Mantener el número de versión visible en la cabecera (`v1.5`) para confirmar qué
versión está publicada.
