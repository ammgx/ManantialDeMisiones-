# Manantial de Misiones · Panel

Panel de administración web (un solo `index.html`) publicado con GitHub Pages:

https://ammgx.github.io/ManantialDeMisiones-/

## Qué incluye

- **Resumen:** último cierre, ventas del período, cajas sin controlar y deuda de clientes.
- **Cierres de caja:** lista, revisión, arqueo y exportación CSV.
- **Archivo:** descarga de cajas de un período y consulta de archivos guardados.
- **Precios:** productos, precios e historial de cambios.
- **Usuarios:** nombre, rol y estado (alta de usuarios desde Supabase).
- **Cuenta:** cambio de contraseña y respaldo general.

## Período

Arriba de todo hay un selector de fechas. Por defecto muestra los **últimos 2 meses**.
Las cajas que siguen abiertas se muestran siempre.

La consulta se hace al servidor por ese rango, así que no se descargan años de datos
para mirar el mes actual.

## Archivo de cajas (para no llenar Supabase)

En la pestaña **Archivo**:

1. Elegí el período.
2. **Descargar archivo del período** genera un `.json` con cajas, ventas, ítems,
   cobros, movimientos y copias de clientes, productos y usuarios.
3. Guardá ese archivo donde quieras (Google Drive, repo privado, pendrive).
4. Para consultarlo, usá **Abrir archivo…**: se ve en el panel sin subir nada al servidor.

El archivo es de **solo lectura**: no modifica ni borra datos de la base.

> Recomendación: descargar el archivo de cada mes cerrado y guardarlo. Sirve como
> respaldo y como histórico, sin ocupar espacio en el plan gratuito.

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

Mantener el número de versión visible en la cabecera (`v1.1`) para confirmar qué
versión está publicada.
