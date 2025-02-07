# Proyecto: Gestión de Recursos y Construcción de Asentamientos

## Descripción del Proyecto

Este proyecto es un juego de estrategia y gestión de recursos donde los jugadores deben construir y administrar un asentamiento de manera eficiente. Utilizando bases de datos para el almacenamiento de información relevante, los jugadores podrán construir edificios, reclutar aldeanos y mejorar campamentos para optimizar la producción de recursos.

## Concepto del Juego

El juego se basa en la gestión de recursos y la toma de decisiones estratégicas para el desarrollo del asentamiento. Cada jugador inicia con una cantidad limitada de recursos y debe administrar su crecimiento mediante la construcción y mejora de infraestructuras.

### Recursos Iniciales:
- **Madera:** 500 unidades
- **Ladrillo:** 500 unidades
- **Oro:** 300 unidades

## Edificios y Funciones

### Campamentos
Los campamentos son esenciales para la producción de recursos. Existen tres tipos:
- **Campamento de Madera:** Genera madera.
- **Campamento de Ladrillo:** Genera ladrillo.
- **Campamento de Oro:** Genera oro.

#### Mejora de Campamentos:
- Requiere madera y ladrillo.
- La cantidad de aldeanos asignados impacta directamente en la producción.
- Ejemplo: Un campamento de oro a nivel 7 con 2 aldeanos asignados producirá 8 unidades de oro por segundo. Si sube a nivel 11 con 3 aldeanos, producirá 12 unidades por segundo.
- Cada nivel tiene un costo específico en recursos para su actualización.

### Casas
- Aumentan la población máxima del asentamiento.
- Cada casa permite hasta 5 aldeanos adicionales.
- No pueden mejorarse, pero pueden construirse de manera ilimitada siempre que haya recursos suficientes.

## Aldeanos

### Reclutamiento
- Los aldeanos se reclutan utilizando oro.
- La cantidad total de aldeanos no puede exceder la población máxima determinada por las casas construidas.

### Asignación
- Los aldeanos pueden ser asignados a un único campamento.
- Los campamentos producen más recursos cuando tienen más aldeanos asignados, respetando el nivel del edificio.
- Los campamentos solo generan recursos si hay aldeanos asignados.
- El oro se utiliza exclusivamente para reclutar aldeanos.

## Almacenamiento de Datos

El progreso del jugador, incluyendo el número de casas, aldeanos y niveles de los campamentos, será almacenado en una base de datos. Sin embargo, la estructura específica de la base de datos y la lógica para la actualización de edificios y contratación de aldeanos aún deben definirse mediante un análisis detallado.

---

A continuación encontrarás un **script completo** en **MySQL** que:

1. Elimina (si existen) las tablas que se vayan a crear.  
2. Crea todas las tablas necesarias (con tipos de dato equivalentes en MySQL).  
3. Inserta datos de ejemplo (igual que en el código original).  
4. Implementa un **procedimiento almacenado** para subir el nivel de un campamento de madera, descontando madera y ladrillo.  

> **Nota**:  
> - En MySQL no existe `DBMS_OUTPUT.PUT_LINE`; se suele usar `SELECT 'texto';` o `SIGNAL`/`SET` para notificaciones, o simplemente no mostrar nada. He dejado algunos `SELECT` como mensajes de salida, a modo de ejemplo.  
> - Se cambian los tipos `NUMBER` y `VARCHAR2` propios de Oracle por tipos equivalentes en MySQL (`INT`, `VARCHAR`).  
> - La sintaxis `SELECT campo INTO variable` dentro de un procedimiento requiere `DELIMITER` y `DECLARE` en MySQL.

---

### Cómo usar el procedimiento
Una vez ejecutado el script anterior en tu instancia de MySQL, para subir el nivel del campamento de madera (en la partida con `Id_Partida=1`, por ejemplo), basta con llamar:

```sql
CALL subir_nivel_campamento_madera(1);
```

El procedimiento:
- Obtiene el nivel actual del campamento de tipo `'Madera'`.
- Consulta en la tabla `DATOS_CAMPAMENTOS` los costes de mejora para ese nivel.
- Verifica si la `PARTIDA` tiene suficiente `Madera` y `Ladrillo`.
- Si es suficiente, sube el nivel (`UPDATE CAMPAMENTOS`) y descuenta los recursos (`UPDATE PARTIDA`).
- Muestra un mensaje final con la cantidad de recursos restante o un aviso de que no hay recursos suficientes.

¡Con esto tienes un ejemplo completo y funcional para **MySQL**!

---

## Tecnologías Utilizadas

Para el desarrollo y despliegue de este proyecto, se sugiere utilizar:

- **MySQL** (motor de bases de datos relacional).
- **Docker** (contenedorización y despliegue rápido).
- **Docker Compose** (orquestación de contenedores).
- **phpMyAdmin** (herramienta web para la administración de MySQL).
- **Visual Studio Code** (u otro editor/IDE que prefieras) con extensiones para SQL o Docker, si lo deseas.
- **SQL** (lenguaje de consultas para la creación, manipulación y administración de la base de datos).

Estas tecnologías facilitan el **despliegue** rápido y la **gestión** de la base de datos, permitiendo que el equipo se centre en la lógica de negocio del juego.

---

## Cómo Desplegar el Entorno con Docker

Para poner en marcha el proyecto de base de datos y poder cargar este script de forma sencilla, puedes usar **Docker** y **Docker Compose**:

1. **Instala Docker** y **Docker Compose** (si aún no lo has hecho).

2. Crea un archivo `docker-compose.yml` con el siguiente contenido (ejemplo):

   ```yaml
   version: '3.9'

   services:
     db:
       image: mysql:8.0
       container_name: mysql_db
       environment:
         - MYSQL_ROOT_PASSWORD=root
         - MYSQL_DATABASE=mi_basedatos
         - MYSQL_USER=usuario
         - MYSQL_PASSWORD=password
       ports:
         - "3306:3306"
       volumes:
         - db_data:/var/lib/mysql
       restart: unless-stopped

     phpmyadmin:
       image: phpmyadmin:latest
       container_name: phpmyadmin
       depends_on:
         - db
       environment:
         - PMA_HOST=db
         - PMA_PORT=3306
         - PMA_USER=usuario
         - PMA_PASSWORD=password
         - UPLOAD_LIMIT=300M
       ports:
         - "8080:80"
       restart: unless-stopped

   volumes:
     db_data:
   ```

   > Puedes personalizar las variables de entorno (contraseña, usuario, nombre de la base de datos, etc.) a tu gusto.

3. **Levanta los contenedores** en segundo plano:
   ```bash
   docker-compose up -d
   ```
   Esto descargará las imágenes (MySQL y phpMyAdmin) y levantará los servicios.

4. **Accede a phpMyAdmin** desde tu navegador en `http://localhost:8080`.  
   - Host: `db`  
   - Usuario y contraseña: los que has establecido en `docker-compose.yml` (por defecto `usuario / password`).

5. Dentro de phpMyAdmin, selecciona la base de datos que creaste (por defecto `mi_basedatos`), ve a la pestaña **SQL** y **copia** el script completo (creación de tablas y procedimientos). Luego ejecútalo.

   > Si prefieres, puedes utilizar cualquier **cliente MySQL** externo (DBeaver, MySQL Workbench, HeidiSQL, etc.) apuntando a `localhost:3306`.

6. Para probar el **procedimiento almacenado**, una vez insertado el script, puedes abrir una ventana SQL en phpMyAdmin y ejecutar:
   ```sql
   CALL subir_nivel_campamento_madera(1);
   ```
   y verificar el mensaje de salida en la parte inferior o en la tabla `PARTIDA` y `CAMPAMENTOS` para observar los cambios.

---

## Comandos Útiles en Docker y MySQL

1. **Ver logs** de un contenedor (p.ej. `mysql_db`):
   ```bash
   docker logs -f mysql_db
   ```

2. **Acceder por consola** a MySQL dentro del contenedor (útil si necesitas ejecutar consultas desde la línea de comandos):
   ```bash
   docker exec -it mysql_db bash
   mysql -u usuario -p
   ```
   Después, ingresa la contraseña que definiste (`password` en el ejemplo).

3. **Levantar y apagar contenedores**:
   ```bash
   # Levantar (en segundo plano)
   docker-compose up -d

   # Apagar
   docker-compose down
   ```

4. **Reiniciar** un servicio (por cambios en el `docker-compose.yml`):
   ```bash
   docker-compose restart db
   ```

5. **Listar contenedores** activos:
   ```bash
   docker ps
   ```

6. **Detener contenedor** individualmente:
   ```bash
   docker stop mysql_db
   ```

---
