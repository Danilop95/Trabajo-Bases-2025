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
