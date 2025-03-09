       ________           __       ____  ____   ____                      
      / ____/ /___ ______/ /_     / __ \/ __/  / __ )____ _________  _____
     / /   / / __ `/ ___/ __ \   / / / / /_   / __  / __ `/ ___/ _ \/ ___/
    / /___/ / /_/ (__  ) / / /  / /_/ / __/  / /_/ / /_/ (__  )  __(__  ) 
    \____/_/\__,_/____/_/ /_/   \____/_/    /_____/\__,_/____/\___/____/  
                                                                                                                                                     
                          Daniel Y Alvaro
## 1. Introducción

**Alcance:**  
- **Base de Datos:** Se ha diseñado la estructura de la base de datos (tablas, relaciones y restricciones) junto con datos de prueba.  
- **Lógica SQL:** Se han implementado procedimientos (procedures), triggers y un EVENT opcional para la actualización de recursos cada minuto.  
- **Aplicación PHP:** Se desarrolla una interfaz web que permite interactuar con la base de datos mediante llamadas a procedimientos almacenados. La actualización dinámica de datos se realiza a través de AJAX.

**Tecnologías y Herramientas Recomendadas:**  
- **Base de Datos:** MySQL 8.0 (para ejecutar el script SQL)  
  - Herramientas sugeridas: [HeidiSQL](https://www.heidisql.com/) o [phpMyAdmin](https://www.phpmyadmin.net/) (se incluye en la solución Docker)  
- **Contenedores:** Docker y Docker Compose para simplificar el despliegue.  
- **Lenguaje del Servidor:** PHP  
- **Servidor Web:** Apache (incluido en el contenedor PHP)  
- **Interfaz:** HTML, CSS y JavaScript (Bootstrap y FontAwesome)

---

## 2. Diagrama Entidad-Relación (ER)

![image](https://github.com/user-attachments/assets/0005da7c-fbc1-44d1-aae7-940b12e19904)


**Descripción:**  
El diagrama ER final refleja la estructura y las relaciones entre las siguientes entidades:  
- **USUARIO:** Datos de acceso del jugador.  
- **PARTIDA:** Recursos, número de casas y vinculación con el usuario.  
- **CASAS:** Representa las casas que aumentan la capacidad de población.  
- **CAMPAMENTOS:** Edificios que generan recursos (tipos: Madera, Ladrillo, Oro).  
- **ALDEANOS:** Trabajadores asignados a tareas, que pueden estar en estado "Descansando" o "Trabajando".  
- **DATOS_CAMPAMENTOS:** Niveles de campamentos, costes de mejora y producción asociada.  
- **LOG_ACCIONES:** Registro de acciones importantes del juego.

---

## 3. Estructura de la Base de Datos

### 3.1 Código de los CREATE TABLES

El siguiente script SQL crea la base de datos y define las tablas necesarias para el sistema:

```sql
-- ==============================================
-- ℭ𝔩𝔞𝔰𝔥 𝔒𝔣 𝔅𝔞𝔰𝔢𝔰
-- ==============================================

CREATE DATABASE IF NOT EXISTS mi_db_juego;
USE mi_db_juego;

DROP TABLE IF EXISTS LOG_ACCIONES;
DROP TABLE IF EXISTS ALDEANOS;
DROP TABLE IF EXISTS CAMPAMENTOS;
DROP TABLE IF EXISTS CASAS;
DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS DATOS_CAMPAMENTOS;
DROP TABLE IF EXISTS PARAMETROS;

-- Tabla PARAMETROS (costes globales y capacidad por casa)
CREATE TABLE PARAMETROS (
  Id_Parametros INT AUTO_INCREMENT PRIMARY KEY,
  Coste_Aldeanos INT NOT NULL,
  Coste_Casas INT NOT NULL,
  Capacidad_Por_Casa INT NOT NULL,
  Coste_Campamento INT NOT NULL
) ENGINE=InnoDB;

-- Tabla DATOS_CAMPAMENTOS (niveles, costes de mejora y producción)
CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos INT AUTO_INCREMENT PRIMARY KEY,
  Nivel INT NOT NULL CHECK (Nivel BETWEEN 1 AND 5),
  Tipo VARCHAR(50) NOT NULL,
  Coste_Madera_Mejora INT NOT NULL,
  Coste_Ladrillo_Mejora INT NOT NULL,
  Coste_Oro_Mejora INT NOT NULL DEFAULT 0,
  Numero_Trabajadores_Al_100 INT NOT NULL,
  Produccion INT NOT NULL
) ENGINE=InnoDB;

-- Tabla USUARIO (datos de acceso)
CREATE TABLE USUARIO (
  Id_Usuario INT AUTO_INCREMENT PRIMARY KEY,
  Nombre VARCHAR(100) NOT NULL,
  Contraseña VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Tabla PARTIDA (recursos, casas y vinculación con el usuario)
CREATE TABLE PARTIDA (
  Id_Partida INT AUTO_INCREMENT PRIMARY KEY,
  Madera INT NOT NULL,
  Ladrillo INT NOT NULL,
  Oro INT NOT NULL,
  Numero_Casas INT NOT NULL,
  Id_Usuario INT UNIQUE,
  CONSTRAINT fk_partida_usuario FOREIGN KEY (Id_Usuario) REFERENCES USUARIO(Id_Usuario)
) ENGINE=InnoDB;

-- Tabla CASAS (cada casa aumenta la capacidad de población)
CREATE TABLE CASAS (
  Id_Casa INT AUTO_INCREMENT PRIMARY KEY,
  Id_Partida INT NOT NULL,
  CONSTRAINT fk_casas_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
) ENGINE=InnoDB;

-- Tabla CAMPAMENTOS (edificios generadores de recursos)
CREATE TABLE CAMPAMENTOS (
  Id_Campamentos INT AUTO_INCREMENT PRIMARY KEY,
  Tipo VARCHAR(50) NOT NULL,  -- 'Madera', 'Ladrillo' o 'Oro'
  Nivel INT NOT NULL,
  N_Trabajadores INT NOT NULL,
  Id_Partida INT NOT NULL,
  CONSTRAINT fk_campamentos_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
) ENGINE=InnoDB;

-- Tabla ALDEANOS (trabajadores)
CREATE TABLE ALDEANOS (
  Id_Aldeanos INT AUTO_INCREMENT PRIMARY KEY,
  Estado VARCHAR(50) NOT NULL, -- 'Descansando' o 'Trabajando'
  Id_Partida INT NOT NULL,
  Id_Casa INT,
  Id_Campamentos INT,
  CONSTRAINT fk_aldeanos_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida),
  CONSTRAINT fk_aldeanos_casas FOREIGN KEY (Id_Casa) REFERENCES CASAS(Id_Casa),
  CONSTRAINT fk_aldeanos_camp FOREIGN KEY (Id_Campamentos) REFERENCES CAMPAMENTOS(Id_Campamentos)
) ENGINE=InnoDB;

-- Tabla LOG_ACCIONES (registro de acciones)
CREATE TABLE LOG_ACCIONES (
  Id_Log INT AUTO_INCREMENT PRIMARY KEY,
  Id_Partida INT NOT NULL,
  TipoAccion VARCHAR(50) NOT NULL,
  Descripcion TEXT NOT NULL,
  Fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_log_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
) ENGINE=InnoDB;

-- Índices para mejorar el rendimiento
CREATE INDEX idx_partida_usuario ON PARTIDA(Id_Usuario);
CREATE INDEX idx_casas_partida ON CASAS(Id_Partida);
CREATE INDEX idx_campamentos_partida ON CAMPAMENTOS(Id_Partida);
CREATE INDEX idx_aldeanos_partida ON ALDEANOS(Id_Partida);
CREATE INDEX idx_aldeanos_casa ON ALDEANOS(Id_Casa);
CREATE INDEX idx_aldeanos_camp ON ALDEANOS(Id_Campamentos);
CREATE INDEX idx_log_partida ON LOG_ACCIONES(Id_Partida);
```

### 3.2 Código de los INSERTS de Prueba

El siguiente script inserta datos de prueba para verificar el funcionamiento del sistema:

```sql
-- Insertar Usuarios
INSERT INTO USUARIO (Nombre, Contraseña)
VALUES ('Alvaro', 'pass123'),
       ('Daniel', 'abc456');

-- Insertar Partidas
INSERT INTO PARTIDA (Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (500, 500, 300, 1, 1),  -- Partida de Alvaro
       (800, 300, 100, 0, 2);  -- Partida de Daniel

-- Insertar Parámetros Globales
INSERT INTO PARAMETROS (Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (50, 100, 5, 200);

-- Insertar Datos de Campamentos (niveles 1 a 5)
INSERT INTO DATOS_CAMPAMENTOS 
  (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 'Madera',   10, 10,  0,  2, 10),
  (2, 'Madera',   25, 20,  0,  5, 15),
  (3, 'Madera',   45, 35,  0, 11, 20),
  (4, 'Madera',   53, 41,  0, 16, 25),
  (5, 'Madera',   60, 50,  0, 22, 30),
  (1, 'Ladrillo', 10, 10,  0,  2, 10),
  (2, 'Ladrillo', 25, 20,  0,  5, 15),
  (3, 'Ladrillo', 45, 35,  0, 11, 20),
  (4, 'Ladrillo', 53, 41,  0, 16, 25),
  (5, 'Ladrillo', 60, 50,  0, 22, 30),
  (1, 'Oro',      10, 10,  0,  2,  5),
  (2, 'Oro',      50, 30,  0,  5,  7),
  (3, 'Oro',      90, 70,  0, 11, 11),
  (4, 'Oro',     106, 82,  0, 16, 15),
  (5, 'Oro',     120,100,  0, 22, 19);

-- Insertar una Casa (para Alvaro)
INSERT INTO CASAS (Id_Partida)
VALUES (1);

-- Insertar Campamentos Iniciales
INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES ('Madera', 1, 2, 1),   -- Campamento de Madera para Alvaro
       ('Oro', 1, 1, 2);      -- Campamento de Oro para Daniel

-- Insertar Aldeanos
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Casa)
VALUES ('Descansando', 1, 1);
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Campamentos)
VALUES ('Trabajando', 2, 2);
```

---

## 4. Lógica de Negocio en SQL

### 4.1 Procedures

Se han creado procedimientos para implementar la lógica del juego. Algunos de ellos son:

- **log_accion:** Registra las acciones importantes en la tabla LOG_ACCIONES.

- **subir_nivel_campamento:** (Procedimiento original que sube de nivel un campamento basándose en el tipo y partida).

- **subir_nivel_campamento_por_id:**  
  Este procedimiento recibe el **ID específico del campamento** y la partida, permitiendo mejorar correctamente un campamento sin interferir con otros del mismo tipo.  
  *(Ver sección de código a continuación)*

- **modificar_asignacion_trabajadores:** Actualiza la cantidad de trabajadores asignados a un campamento.

- **actualizar_recursos_juego:** Recorre los campamentos y actualiza los recursos generados en la partida según la producción y los trabajadores asignados.

- **reclutar_aldeano:** Permite reclutar un nuevo aldeano, descontando el recurso correspondiente.

- **construir_casa:** Construye una nueva casa, descontando los recursos necesarios.

- **asignar_aldeano_a_campamento:** Asigna (o reasigna) un aldeano a un campamento específico.

- **crear_campamento:** Crea un nuevo campamento, descontando los recursos de construcción.

**Código del procedimiento para subir nivel de un campamento por ID:**

```sql
DELIMITER $$
CREATE PROCEDURE subir_nivel_campamento_por_id(IN p_IdCamp INT, IN p_IdPartida INT)
subir: BEGIN
    DECLARE v_Tipo VARCHAR(50);
    DECLARE v_Nivel_Actual INT DEFAULT 0;
    DECLARE v_NivelMax INT DEFAULT 0;
    DECLARE v_Coste_Madera INT DEFAULT 0;
    DECLARE v_Coste_Ladrillo INT DEFAULT 0;
    DECLARE v_Coste_Oro INT DEFAULT 0;
    DECLARE v_Recurso1 INT;
    DECLARE v_Recurso2 INT;
    DECLARE v_Recurso3 INT;
    DECLARE v_Mensaje VARCHAR(255);

    START TRANSACTION;
    
    -- Obtener el tipo y el nivel actual del campamento específico
    SELECT Tipo, Nivel 
      INTO v_Tipo, v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Id_Campamentos = p_IdCamp
     LIMIT 1;
    
    -- Obtener el nivel máximo para ese tipo de campamento
    SELECT MAX(Nivel)
      INTO v_NivelMax
      FROM DATOS_CAMPAMENTOS
     WHERE Tipo = v_Tipo;
    
    IF v_Nivel_Actual >= v_NivelMax THEN
      SET v_Mensaje = CONCAT('El campamento de ', v_Tipo, ' ya está en el nivel máximo.');
      ROLLBACK;
      SELECT v_Mensaje AS Mensaje;
      LEAVE subir;
    END IF;
    
    -- Obtener los costes de mejora para el nivel actual del campamento
    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo, v_Coste_Oro
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo = v_Tipo
     LIMIT 1;
    
    IF v_Tipo = 'Oro' THEN
      -- Mejorar campamento de Oro usando Oro
      SELECT Oro INTO v_Recurso3
        FROM PARTIDA
       WHERE Id_Partida = p_IdPartida
       LIMIT 1;
      
      IF v_Recurso3 >= v_Coste_Oro THEN
         UPDATE CAMPAMENTOS
           SET Nivel = Nivel + 1
         WHERE Id_Campamentos = p_IdCamp;
         
         UPDATE PARTIDA
           SET Oro = Oro - v_Coste_Oro
         WHERE Id_Partida = p_IdPartida;
         
         SET v_Mensaje = CONCAT('Campamento de Oro subido de nivel. Oro restante: ', (v_Recurso3 - v_Coste_Oro));
      ELSE
         SET v_Mensaje = 'No hay suficientes recursos para mejorar el Campamento de Oro.';
         ROLLBACK;
         SELECT v_Mensaje AS Mensaje;
         LEAVE subir;
      END IF;
    ELSE
      -- Mejorar campamento de Madera o Ladrillo usando madera y ladrillo
      SELECT Madera, Ladrillo
        INTO v_Recurso1, v_Recurso2
        FROM PARTIDA
       WHERE Id_Partida = p_IdPartida
       LIMIT 1;
      
      IF (v_Recurso1 >= v_Coste_Madera) AND (v_Recurso2 >= v_Coste_Ladrillo) THEN
         UPDATE CAMPAMENTOS
           SET Nivel = Nivel + 1
         WHERE Id_Campamentos = p_IdCamp;
         
         UPDATE PARTIDA
           SET Madera = Madera - v_Coste_Madera,
               Ladrillo = Ladrillo - v_Coste_Ladrillo
         WHERE Id_Partida = p_IdPartida;
         
         SET v_Mensaje = CONCAT('Campamento de ', v_Tipo, ' subido de nivel.');
      ELSE
         SET v_Mensaje = CONCAT('No hay suficientes recursos para mejorar el Campamento de ', v_Tipo, '.');
         ROLLBACK;
         SELECT v_Mensaje AS Mensaje;
         LEAVE subir;
      END IF;
    END IF;
    
    CALL log_accion(p_IdPartida, 'mejorar', v_Mensaje);
    COMMIT;
    SELECT v_Mensaje AS Mensaje;
END subir$$
DELIMITER ;
```

### 4.2 Triggers

Se ha creado el siguiente trigger para asegurar que los recursos no se vuelvan negativos:

```sql
DELIMITER $$
CREATE TRIGGER trg_no_recursos_negativos
BEFORE UPDATE ON PARTIDA
FOR EACH ROW
BEGIN
    IF NEW.Madera < 0 THEN
       SET NEW.Madera = 0;
    END IF;
    IF NEW.Ladrillo < 0 THEN
       SET NEW.Ladrillo = 0;
    END IF;
    IF NEW.Oro < 0 THEN
       SET NEW.Oro = 0;
    END IF;
END$$
DELIMITER ;
```

### 4.3 EVENTOS (Opcional para sobresaliente)

Para la actualización automática de recursos, se ha creado el siguiente EVENT que se ejecuta cada 1 minuto:

```sql
DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_update_recursos
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
DO
BEGIN
   CALL actualizar_recursos_juego();
END$$
DELIMITER ;
```

---

## 5. Aplicación PHP
![image](https://github.com/user-attachments/assets/9f8db1b8-1064-4b7b-9e8e-16d49d959692)



### 5.1 Descripción General

La aplicación PHP se encarga de:  
- Conectarse a la base de datos utilizando PDO.  
- Permitir el inicio de sesión de usuarios.  
- Mostrar un panel de control con información en tiempo real (recursos, infraestructuras, campamentos, aldeanos y ranking).  
- Ejecutar procedimientos almacenados a través de formularios (por ejemplo, construir casa, reclutar aldeano, crear campamento, mejorar campamento, asignar/reasignar aldeanos).  
- Actualizar de forma dinámica la información mediante AJAX.

### 5.2 Código PHP y Estructura de la Interfaz

La aplicación cuenta con un archivo `index.php` que integra:
- Conexión a la base de datos y manejo de sesión.
- Un modo AJAX para actualizar los datos de la partida cada 5 segundos.
- Secciones para:  
  - **Login:** Formulario de inicio de sesión.  
  - **Dashboard:** Visualización de recursos e infraestructuras.  
  - **Acciones Rápidas:** Formularios para construir casas, reclutar aldeanos y crear campamentos.  
  - **Panel de Costos de Construcción:** Muestra los costes de creación de campamentos (se divide por tipo: Madera, Ladrillo y Oro).  
  - **Campamentos:** Lista de campamentos creados con opción de mejora.  
  - **Aldeanos:** Lista de aldeanos, con opción de ordenarlos por campamento o por disponibilidad, y un modal para reasignación.  
  - **Ranking:** Ranking de partidas según puntaje.
- Inclusión de Bootstrap y FontAwesome para el diseño y estilo.
- Soporte para Docker, ya que el proyecto se despliega con un `docker-compose.yml` y archivos relacionados.


---

## 6. Despliegue del Proyecto

### 6.1 Requisitos de Despliegue

- **Docker y Docker Compose:**  
  Se recomienda usar Docker para simplificar el despliegue. Se ha configurado un `docker-compose.yml` que define tres servicios:
  - **db:** Contenedor con MySQL 8.0.
  - **phpmyadmin:** Interfaz web para administrar la base de datos.
  - **app:** Contenedor con Apache y PHP para ejecutar la aplicación.

- **.env:**  
  Se utiliza un archivo `.env` para definir variables de entorno como contraseñas, puertos y credenciales de la base de datos.

### 6.2 Pasos para Desplegar el Proyecto

1. **Clonar el Repositorio:**
   - Clona el proyecto en tu máquina:
     ```bash
     git clone https://github.com/Danilop95/Trabajo-Bases-2025.git
     cd Trabajo-Bases-2025
     ```

2. **Configurar Variables de Entorno:**
   - Asegúrate de tener el archivo `.env` en el directorio raíz, con las siguientes variables (puedes modificar los valores según tu entorno):
     ```env
     # --- MySQL ---
     MYSQL_ROOT_PASSWORD=root
     MYSQL_DATABASE=mi_db_juego
     MYSQL_USER=usuario
     MYSQL_PASSWORD=password
     
     # --- phpMyAdmin ---
     PMA_HOST=db
     PMA_PORT=3306
     
     # --- Aplicación PHP ---
     DB_HOST=db
     DB_NAME=mi_db_juego
     DB_USER=usuario
     DB_PASS=password
     
     # --- Puertos ---
     HOST_PORT_HTTP=8080
     HOST_PORT_APACHE=8000
     ```
     
3. **Construir y Levantar los Contenedores:**
   - Ejecuta el siguiente comando para iniciar todos los servicios:
     ```bash
     docker-compose up --build
     ```
   - Esto creará y levantará los contenedores para MySQL, phpMyAdmin y la aplicación PHP.
     
4. **Importar el Script SQL:**
   - Puedes utilizar **HeidiSQL** o **phpMyAdmin** para importar el script SQL (por ejemplo, el archivo `Script-update.sql`) que contiene la creación de la base de datos, tablas, inserts, procedimientos, triggers y eventos.
   - En phpMyAdmin, accede a `http://localhost:8080` (o la URL configurada) y usa la opción de "Importar" para subir el archivo.

5. **Acceder a la Aplicación:**
   - Abre en tu navegador `http://localhost:8000` para ver la interfaz del juego.
   - Utiliza las funcionalidades disponibles (login, acciones, etc.) para probar el sistema.

6. **Administrar la Base de Datos (Opcional):**
   - Puedes acceder a phpMyAdmin en `http://localhost:8080` para administrar la base de datos de forma gráfica.

---

## 7. Recomendaciones

**Recomendaciones:**  
- Se recomienda utilizar Docker para un despliegue consistente y sencillo, aprovechando el archivo `docker-compose.yml` y las variables de entorno definidas en `.env`.  
- Para la administración de la base de datos se sugiere usar herramientas como **HeidiSQL** o **phpMyAdmin**, según tu preferencia.
- Se recomienda revisar y ajustar los procedimientos según los cambios en la lógica del juego o futuros requerimientos.
- Como mejora opcional, se podría implementar un sistema de notificaciones en tiempo real (por ejemplo, usando WebSockets) para que los cambios se reflejen de inmediato sin tener que recargar la página o usar AJAX periódicamente.

