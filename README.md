# Manantial de Misiones · Panel

Panel de administración web (un solo `index.html`) publicado con GitHub Pages:

https://ammgx.github.io/ManantialDeMisiones-/

## Qué incluye

- **Resumen:** centro de trabajo con pendientes, cajas abiertas y cajas cerradas desplegables.
- **Ventas:** todas las ventas con filtros por mes, vendedor, medio y texto; totales, fiado, cobros, detalle y ranking de productos.
- **Clientes:** buscador, deuda, ficha con historial de ventas y cobros, exportación CSV.
- **Cierres de caja:** agrupados por mes, con filtros por usuario y estado, revisión, arqueo y exportación CSV.
- **Precios:** productos, precios, orden manual e historial de cambios.
- **Usuarios:** listado del equipo, cambio de nombre, rol y estado, y restablecer contraseñas.
- **Cuenta:** cambio de contraseña y respaldo completo.
- **Archivo:** descarga mensual de cajas y consulta de archivos guardados.

## Resumen

Es la pantalla de trabajo: entrás y ves qué falta hacer.

- **Pendientes:** cuatro accesos directos con el número real: cajas abiertas
  (y cuántas llevan más de 24 h), cierres sin controlar, arqueos con diferencia
  y deuda total de clientes. Cada uno abre la pestaña correspondiente ya filtrada.
- **Cajas abiertas:** tarjetas verdes ordenadas de la más vieja a la más nueva.
  Muestran vendedor, tiempo abierto, vendido, cobrado, egresos y efectivo esperado.
  Al tocar la tarjeta se despliega el informe completo (ventas, cobros y movimientos)
  sin salir de la página.
- **Cajas sin actividad:** las cajas recién abiertas sin ventas, cobros ni
  movimientos no se cuentan como abiertas ni aparecen en la lista. Hay un enlace
  para verlas igual, pero no suman al número de pendientes.
- **Cajas cerradas:** primero las pendientes de control y los últimos cierres,
  con el mismo informe desplegable y el botón **Revisar caja**.
- El historial completo, los filtros por mes/usuario/estado y la exportación
  siguen en **Cierres de caja**.

> Los totales de una caja abierta se calculan en el momento con sus ventas,
> cobros y movimientos, porque la app recién los guarda al cerrar.

## Ventas

- La primera vez que entrás a la pestaña se descargan todas las ventas, ítems y cobros.
  Puede demorar unos segundos; después queda en memoria y el botón **Actualizar** lo recarga.
- Totales del filtro: **vendido**, **fiado generado**, **cobrado** y **ticket promedio**.
- Filtros: mes, vendedor, medio de pago y búsqueda por cliente, producto o nota.
  Las ventas anuladas se ocultan por defecto; hay un tilde para incluirlas.
- Tabla agrupada por mes; **Ver** abre el detalle con productos, pago, saldo y motivo de anulación.
- Si la venta tiene **aditivo** (monto extra de un cliente con precio diferencial), el
  detalle muestra el subtotal de productos y el aditivo con su signo. El total ya lo incluye.
- Los cobros de fiado imputados a una venta se muestran como **Cobrado después** y el
  saldo fiado se recalcula con ellos. La tabla marca **Pagada** cuando ya no queda saldo.
- **Productos más vendidos** se calcula con las ventas filtradas.
- **Exportar CSV** descarga la lista filtrada completa, con columnas `productos`, `aditivo`,
  `total`, `pagado` (incluye cobros posteriores) y `fiado` (saldo actual).

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

## Productos y precios

- **+ Producto**: crea un producto nuevo al final de la lista.
- **Editar**: cambia nombre, descripción, precio y si está activo.
- **↑ / ↓**: cambia el orden de los productos. El orden se guarda en Supabase
  y las apps lo respetan en la próxima sincronización.
- Los productos inactivos no se muestran en la app, pero conservan su lugar.

## Usuarios

La pestaña **Usuarios** muestra el equipo con su rol y estado. Desde ahí se puede:

- **Editar**: cambiar nombre, rol o estado (activo/baja).
- **Contraseña**: asignar una contraseña nueva a cualquier usuario.

El email y la contraseña son los mismos que se usan para entrar a la app.
Las cuentas nuevas se gestionan fuera del panel.

> El cambio de contraseña usa una función segura de Supabase.
> Hay que aplicar el SQL de [sql/usuarios.sql](sql/usuarios.sql) **una sola vez**:
> Supabase → SQL Editor → pegar el archivo → Run. Sin ese paso, el panel muestra
> un aviso al intentar cambiar una contraseña.

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
- Desde el Resumen, el acceso **Con diferencia** muestra solo los arqueos desparejos.
- El **cambio inicial** (lo que quedó en el cajón al cerrar la caja anterior) suma al
  total disponible y al efectivo esperado, igual que en la app. Aparece como un renglón
  aparte en el detalle del cierre.
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

Mantener el número de versión visible en la cabecera (`v1.11`) para confirmar qué
versión está publicada.
