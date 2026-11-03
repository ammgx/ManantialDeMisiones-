# Manantial de Misiones · Panel

Panel de administración web (un solo `index.html`) publicado con GitHub Pages:

https://ammgx.github.io/ManantialDeMisiones-/

## Qué incluye

- **Resumen:** último cierre, ventas registradas, cajas sin controlar y deuda de clientes.
- **Cierres de caja:** agrupados por mes, con filtros por usuario y estado, revisión, arqueo y exportación CSV.
- **Precios:** productos, precios e historial de cambios.
- **Usuarios:** nombre, rol y estado (alta de usuarios desde Supabase).
- **Cuenta:** cambio de contraseña y respaldo general.
- **Archivo:** descarga mensual de cajas y consulta de archivos guardados.

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

Mantener el número de versión visible en la cabecera (`v1.2`) para confirmar qué
versión está publicada.
