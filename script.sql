CREATE DATABASE IF NOT EXISTS `mi_db_juego`;
USE `mi_db_juego`;

-- --------------------------------------------------------------
-- 1) ELIMINAR TABLAS (si existen)
-- --------------------------------------------------------------
DROP TABLE IF EXISTS ALDEANOS;
DROP TABLE IF EXISTS CAMPAMENTOS;
DROP TABLE IF EXISTS CASAS;
DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS DATOS_CAMPAMENTOS;
DROP TABLE IF EXISTS PARAMETROS;

-- --------------------------------------------------------------
-- 2) CREACIÓN DE TABLAS CON PK AUTOINCREMENT
-- --------------------------------------------------------------

-- Tabla PARAMETROS (costes globales)
CREATE TABLE PARAMETROS (
  Id_Parametros        INT AUTO_INCREMENT PRIMARY KEY,
  Coste_Aldeanos       INT NOT NULL,
  Coste_Casas          INT NOT NULL,
  Capacidad_Por_Casa   INT NOT NULL,
  Coste_Campamento     INT NOT NULL
);

-- Tabla DATOS_CAMPAMENTOS (costes y producción por nivel y tipo)
CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos       INT AUTO_INCREMENT PRIMARY KEY,
  Nivel                      INT NOT NULL,
  Tipo                       VARCHAR(50) NOT NULL, 
  Coste_Madera_Mejora        INT NOT NULL,
  Coste_Ladrillo_Mejora      INT NOT NULL,
  Coste_Oro_Mejora           INT NOT NULL,
  Numero_Trabajadores_Al_100 INT NOT NULL,
  Produccion                 INT NOT NULL
);

-- Tabla USUARIO (datos del jugador)
CREATE TABLE USUARIO (
  Id_Usuario    INT AUTO_INCREMENT PRIMARY KEY,
  Nombre        VARCHAR(100) NOT NULL,
  Contraseña    VARCHAR(100) NOT NULL
);

-- Tabla PARTIDA (recursos y relación a USUARIO)
CREATE TABLE PARTIDA (
  Id_Partida    INT AUTO_INCREMENT PRIMARY KEY,
  Madera        INT NOT NULL,
  Ladrillo      INT NOT NULL,
  Oro           INT NOT NULL,
  Numero_Casas  INT NOT NULL,
  Id_Usuario    INT UNIQUE,
  CONSTRAINT fk_partida_usuario
    FOREIGN KEY (Id_Usuario) REFERENCES USUARIO (Id_Usuario)
);

-- Tabla CASAS (cada casa construida en una partida)
CREATE TABLE CASAS (
  Id_Casa     INT AUTO_INCREMENT PRIMARY KEY,
  Id_Partida  INT NOT NULL,
  CONSTRAINT fk_casas_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- Tabla CAMPAMENTOS (tipos: Madera, Ladrillo, Oro; nivel, trabajadores, etc.)
CREATE TABLE CAMPAMENTOS (
  Id_Campamentos  INT AUTO_INCREMENT PRIMARY KEY,
  Tipo            VARCHAR(50) NOT NULL,
  Nivel           INT NOT NULL,
  N_Trabajadores  INT NOT NULL,
  Id_Partida      INT NOT NULL,
  CONSTRAINT fk_campamentos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- Tabla ALDEANOS (estado y ubicación en casas o campamentos)
CREATE TABLE ALDEANOS (
  Id_Aldeanos     INT AUTO_INCREMENT PRIMARY KEY,
  Estado          VARCHAR(50) NOT NULL,
  Id_Partida      INT NOT NULL,
  Id_Casa         INT,
  Id_Campamentos  INT,
  CONSTRAINT fk_aldeanos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida),
  CONSTRAINT fk_aldeanos_casas
    FOREIGN KEY (Id_Casa) REFERENCES CASAS(Id_Casa),
  CONSTRAINT fk_aldeanos_camp
    FOREIGN KEY (Id_Campamentos) REFERENCES CAMPAMENTOS(Id_Campamentos)
);

-- --------------------------------------------------------------
-- 3) INSERCIÓN DE DATOS DE EJEMPLO
-- --------------------------------------------------------------

-- 3.1. Usuario "AlvDan" (ID=1) con contraseña "lll"
INSERT INTO USUARIO (Id_Usuario, Nombre, Contraseña)
VALUES (1, 'AlvDan', 'lll');

-- 3.2. Partida (ID=1) con recursos iniciales
--     Corrección: 500 Madera, 500 Ladrillo, 300 Oro
INSERT INTO PARTIDA (Id_Partida, Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (1, 500, 500, 300, 1, 1);

-- 3.3. Datos de campamentos (ejemplo, niveles 1 a 5 para Madera, Ladrillo, Oro)
--     Corrección: "Piedra" -> "Ladrillo" para coherencia con la descripción del juego

INSERT INTO DATOS_CAMPAMENTOS
  (Id_Datos_Campamentos, Nivel, Tipo, Coste_Madera_Mejora,
   Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 1, 'Madera',   100,   0,   0, 10, 50),
  (2, 1, 'Ladrillo', 100,   0,   0, 10, 50),
  (3, 1, 'Oro',      100,   0,   0, 10, 50),
  (4, 2, 'Madera',   200,   0,   0, 20, 100),
  (5, 2, 'Ladrillo', 200,   0,   0, 20, 100),
  (6, 2, 'Oro',      200,   0,   0, 20, 100),
  (7, 3, 'Madera',   400,   0,   0, 40, 200),
  (8, 3, 'Ladrillo', 400,   0,   0, 40, 200),
  (9, 3, 'Oro',      400,   0,   0, 40, 200),
  (10,4, 'Madera',   500,   0,   0, 50, 250),
  (11,4, 'Ladrillo', 500,   0,   0, 50, 250),
  (12,4, 'Oro',      500,   0,   0, 50, 250),
  (13,5, 'Madera',   600,   0,   0, 70, 270),
  (14,5, 'Ladrillo', 600,   0,   0, 70, 270),
  (15,5, 'Oro',      600,   0,   0, 70, 270);

-- 3.4. Parámetros globales (ejemplo)
INSERT INTO PARAMETROS (Id_Parametros, Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (1, 50, 100, 5, 200);

-- 3.5. Casa (Id=1) para la Partida (Id=1)
INSERT INTO CASAS (Id_Casa, Id_Partida)
VALUES (1, 1);

-- 3.6. Campamento de Madera nivel 1 en la Partida 1 (sin trabajadores)
INSERT INTO CAMPAMENTOS (Id_Campamentos, Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES (1, 'Madera', 1, 0, 1);

-- 3.7. Un aldeano en estado "Descansando" en la misma partida
INSERT INTO ALDEANOS (Id_Aldeanos, Estado, Id_Partida, Id_Casa, Id_Campamentos)
VALUES (1, 'Descansando', 1, 1, NULL);

-- --------------------------------------------------------------
-- 4 Añadimos los datos de los niveles de los campamentos (primero madera, luego ladrillo y oro)
-- --------------------------------------------------------------

-- 4.1 Nivel 1 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (1, 'Madera', 10, 10, 2, 10);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (1, 'Ladrillo', 10, 10, 2, 10);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (1, 'Oro', 20, 20, 2, 5);

-- 4.2 Nivel 2 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (2, 'Madera', 25, 20, 5, 15);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (2, 'Ladrillo', 25, 20, 5, 15);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (2, 'Oro', 50, 50, 5, 7);

-- 4.3 Nivel 3 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (3, 'Madera', 45, 35, 11, 20);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (3, 'Ladrillo', 45, 35, 11, 20);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (3, 'Oro', 90, 70, 11, 11);

-- 4.4 Nivel 4 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (4, 'Madera', 53, 41, 16, 25);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (4, 'Ladrillo', 53, 41, 16, 25);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (4, 'Oro', 106, 82, 16, 15);

-- 4.5 Nivel 5 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (5, 'Madera', 60, 50, 22, 30);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (5, 'Ladrillo', 60, 50, 22, 30);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (5, 'Oro', 120, 100, 22, 19);

-- 4.6 Nivel 6 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (6, 'Madera', 73, 62, 27, 35);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (6, 'Ladrillo', 73, 62, 27, 35);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (6, 'Oro', 146, 124, 27, 22);

-- 4.7 Nivel 7 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (7, 'Madera', 84, 71, 33, 40);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (7, 'Ladrillo', 84, 71, 33, 40);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (7, 'Oro', 168, 142, 33, 24);

-- 4.8 Nivel 8 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (8, 'Madera', 96, 83, 38, 45);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (8, 'Ladrillo', 96, 83, 38, 45);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (8, 'Oro', 192, 166, 38, 27);

-- 4.9 Nivel 9 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (9, 'Madera', 110, 97, 44, 50);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (9, 'Ladrillo', 110, 97, 44, 50);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (9, 'Oro', 220, 194, 44, 30);

-- 4.10 Nivel 10 de los campamentos
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (10, 'Madera', 250, 225, 60, 55);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (10, 'Ladrillo', 250, 225, 60, 55);
INSERT INTO DATOS_CAMPAMENTOS (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Numero_Trabajadores_Al_100, Produccion) 
VALUES (10, 'Oro', 500, 450, 60, 33);

-- --------------------------------------------------------------
-- 5) PROCEDIMIENTO PARA SUBIR NIVEL CAMPAMENTO (Madera)
--    Descarga de Madera y Ladrillo según DATOS_CAMPAMENTOS
-- --------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE subir_nivel_campamento_madera(
  IN p_IdPartida INT
)
BEGIN
    DECLARE v_Coste_Madera INT DEFAULT 0;
    DECLARE v_Coste_Ladrillo INT DEFAULT 0;
    DECLARE v_Madera_Disponible INT DEFAULT 0;
    DECLARE v_Ladrillo_Disponible INT DEFAULT 0;
    DECLARE v_Nivel_Actual INT DEFAULT 0;

    -- 1) Obtener nivel actual del campamento de Madera
    SELECT Nivel
      INTO v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Tipo = 'Madera'
       AND Id_Partida = p_IdPartida
     LIMIT 1;  -- Asegura que solo un registro sea tomado

    -- 2) Obtener costes de mejora del nivel actual
    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo  = 'Madera'
     LIMIT 1;

    -- 3) Obtener Madera y Ladrillo de la partida
    SELECT Madera, Ladrillo
      INTO v_Madera_Disponible, v_Ladrillo_Disponible
      FROM PARTIDA
     WHERE Id_Partida = p_IdPartida
     LIMIT 1;

    -- 4) Verificar si hay recursos suficientes
    IF (v_Madera_Disponible >= v_Coste_Madera)
       AND (v_Ladrillo_Disponible >= v_Coste_Ladrillo)
    THEN
       -- Subir el nivel del campamento
       UPDATE CAMPAMENTOS
         SET Nivel = Nivel + 1
       WHERE Tipo = 'Madera'
         AND Id_Partida = p_IdPartida;

       -- Descontar los recursos al jugador
       UPDATE PARTIDA
         SET Madera   = Madera   - v_Coste_Madera,
             Ladrillo = Ladrillo - v_Coste_Ladrillo
       WHERE Id_Partida = p_IdPartida;

       SELECT CONCAT(
         'Campamento de Madera subido de nivel. Madera ahora=', 
         (v_Madera_Disponible - v_Coste_Madera), 
         ', Ladrillo ahora=', 
         (v_Ladrillo_Disponible - v_Coste_Ladrillo)
       ) AS Mensaje;
    ELSE
       SELECT 'No hay suficientes recursos para mejorar el campamento de Madera.' AS Mensaje;
    END IF;
END$$

DELIMITER ;

-- FIN DEL SCRIPT
