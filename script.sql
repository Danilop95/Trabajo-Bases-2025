-- 1) CREACIÓN DE BASE DE DATOS
CREATE DATABASE IF NOT EXISTS mi_db_juego;
USE mi_db_juego;

-- 2) ELIMINAR TABLAS SI EXISTEN
DROP TABLE IF EXISTS ALDEANOS;
DROP TABLE IF EXISTS CAMPAMENTOS;
DROP TABLE IF EXISTS CASAS;
DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS DATOS_CAMPAMENTOS;
DROP TABLE IF EXISTS PARAMETROS;

-- 3) CREAR TABLAS

-- Tabla PARAMETROS
CREATE TABLE PARAMETROS (
  Id_Parametros        INT AUTO_INCREMENT PRIMARY KEY,
  Coste_Aldeanos       INT NOT NULL,
  Coste_Casas          INT NOT NULL,
  Capacidad_Por_Casa   INT NOT NULL,
  Coste_Campamento     INT NOT NULL
);

-- Tabla DATOS_CAMPAMENTOS
CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos       INT AUTO_INCREMENT PRIMARY KEY,
  Nivel                      INT NOT NULL,
  Tipo                       VARCHAR(50) NOT NULL, 
  Coste_Madera_Mejora        INT NOT NULL,
  Coste_Ladrillo_Mejora      INT NOT NULL,
  Coste_Oro_Mejora           INT NOT NULL DEFAULT 0,  -- Con DEFAULT para evitar errores si no se especifica
  Numero_Trabajadores_Al_100 INT NOT NULL,
  Produccion                 INT NOT NULL
);

-- Tabla USUARIO
CREATE TABLE USUARIO (
  Id_Usuario    INT AUTO_INCREMENT PRIMARY KEY,
  Nombre        VARCHAR(100) NOT NULL,
  Contraseña    VARCHAR(100) NOT NULL
);

-- Tabla PARTIDA
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

-- Tabla CASAS
CREATE TABLE CASAS (
  Id_Casa     INT AUTO_INCREMENT PRIMARY KEY,
  Id_Partida  INT NOT NULL,
  CONSTRAINT fk_casas_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- Tabla CAMPAMENTOS
CREATE TABLE CAMPAMENTOS (
  Id_Campamentos  INT AUTO_INCREMENT PRIMARY KEY,
  Tipo            VARCHAR(50) NOT NULL,
  Nivel           INT NOT NULL,
  N_Trabajadores  INT NOT NULL,
  Id_Partida      INT NOT NULL,
  CONSTRAINT fk_campamentos_partida
    FOREIGN KEY (Id_Partida) REFERENCES PARTIDA (Id_Partida)
);

-- Tabla ALDEANOS
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

-- 4) INSERTS DE EJEMPLO

-- 4.1 Dos usuarios
INSERT INTO USUARIO (Nombre, Contraseña)
VALUES 
('Alvaro', 'pass123'),
('Daniel', 'abc456');

-- 4.2 Cada usuario con su partida
INSERT INTO PARTIDA (Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES 
(500, 500, 300, 1, 1),  -- Partida para Alvaro (Id_Usuario=1)
(800, 300, 100, 0, 2);  -- Partida para Daniel (Id_Usuario=2)

-- 4.3 Parámetros globales
INSERT INTO PARAMETROS (Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (50, 100, 5, 200);

-- 4.4 Tablas de campamentos (ejemplos de 1 a 5)
INSERT INTO DATOS_CAMPAMENTOS 
  (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 'Madera',   10, 10, 0,  2, 10),
  (1, 'Ladrillo', 10, 10, 0,  2, 10),
  (1, 'Oro',      10, 10, 0,  2,  5),
  (2, 'Madera',   25, 20, 0,  5, 15),
  (2, 'Ladrillo', 25, 20, 0,  5, 15),
  (2, 'Oro',      50, 30, 0,  5,  7),
  (3, 'Madera',   45, 35, 0, 11, 20),
  (3, 'Ladrillo', 45, 35, 0, 11, 20),
  (3, 'Oro',      90, 70, 0, 11, 11),
  (4, 'Madera',   53, 41, 0, 16, 25),
  (4, 'Ladrillo', 53, 41, 0, 16, 25),
  (4, 'Oro',     106, 82, 0, 16, 15),
  (5, 'Madera',   60, 50, 0, 22, 30),
  (5, 'Ladrillo', 60, 50, 0, 22, 30),
  (5, 'Oro',     120,100, 0, 22, 19);

-- 4.5 Agregar una casa en la partida de Alvaro
INSERT INTO CASAS (Id_Partida) VALUES (1);

-- 4.6 Campamentos iniciales
--    Ej: Alvaro con un campamento de Madera nivel 1
INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES 
('Madera', 1, 2, 1);

--    Daniel con un campamento de Oro nivel 1
INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES 
('Oro', 1, 1, 2);

-- 4.7 Aldeanos de ejemplo
--    Un aldeano descansando en partida de Alvaro (en la Casa 1)
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Casa)
VALUES ('Descansando', 1, 1);

--    Un aldeano trabajando en el campamento de Oro de Daniel
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Campamentos)
VALUES ('Trabajando', 2, 2);

-- 5) PROCEDIMIENTOS Y TRIGGERS

-- 5.1 Procedure para subir nivel de campamento (Madera)
DELIMITER $$
CREATE PROCEDURE subir_nivel_campamento_madera(IN p_IdPartida INT)
BEGIN
    DECLARE v_Coste_Madera        INT DEFAULT 0;
    DECLARE v_Coste_Ladrillo      INT DEFAULT 0;
    DECLARE v_Madera_Disponible   INT DEFAULT 0;
    DECLARE v_Ladrillo_Disponible INT DEFAULT 0;
    DECLARE v_Nivel_Actual        INT DEFAULT 0;

    SELECT Nivel
      INTO v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Tipo = 'Madera'
       AND Id_Partida = p_IdPartida
     LIMIT 1;

    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual
       AND Tipo  = 'Madera'
     LIMIT 1;

    SELECT Madera, Ladrillo
      INTO v_Madera_Disponible, v_Ladrillo_Disponible
      FROM PARTIDA
     WHERE Id_Partida = p_IdPartida
     LIMIT 1;

    IF (v_Madera_Disponible >= v_Coste_Madera)
       AND (v_Ladrillo_Disponible >= v_Coste_Ladrillo)
    THEN
       UPDATE CAMPAMENTOS
         SET Nivel = Nivel + 1
       WHERE Tipo = 'Madera'
         AND Id_Partida = p_IdPartida;

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
       SELECT 'No hay suficientes recursos para mejorar Campamento de Madera.' AS Mensaje;
    END IF;
END$$
DELIMITER ;

-- 5.2 Procedure para actualizar recursos (opcional, se llamará cada 1 min por EVENT)
DELIMITER $$
CREATE PROCEDURE actualizar_recursos_juego()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE camp_Id INT;
    DECLARE camp_Tipo VARCHAR(50);
    DECLARE camp_Nivel INT;
    DECLARE camp_Trab INT;
    DECLARE part_Id INT;
    DECLARE dato_Prod INT;
    DECLARE dato_Trab100 INT;
    DECLARE recursoObtenido INT;

    DECLARE curCamp CURSOR FOR
        SELECT c.Id_Campamentos, c.Tipo, c.Nivel, c.N_Trabajadores, c.Id_Partida
          FROM CAMPAMENTOS c;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN curCamp;
    read_loop: LOOP
        FETCH curCamp INTO camp_Id, camp_Tipo, camp_Nivel, camp_Trab, part_Id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SELECT Produccion, Numero_Trabajadores_Al_100
          INTO dato_Prod, dato_Trab100
          FROM DATOS_CAMPAMENTOS
         WHERE Nivel = camp_Nivel
           AND Tipo  = camp_Tipo
         LIMIT 1;

        SET recursoObtenido = FLOOR(dato_Prod * camp_Trab / dato_Trab100);

        IF camp_Tipo = 'Madera' THEN
            UPDATE PARTIDA
               SET Madera = Madera + recursoObtenido
             WHERE Id_Partida = part_Id;
        ELSEIF camp_Tipo = 'Ladrillo' THEN
            UPDATE PARTIDA
               SET Ladrillo = Ladrillo + recursoObtenido
             WHERE Id_Partida = part_Id;
        ELSEIF camp_Tipo = 'Oro' THEN
            UPDATE PARTIDA
               SET Oro = Oro + recursoObtenido
             WHERE Id_Partida = part_Id;
        END IF;
    END LOOP;
    CLOSE curCamp;
END$$
DELIMITER ;

-- 5.3 Trigger para evitar recursos negativos en PARTIDA
DELIMITER $$
CREATE TRIGGER trg_no_recursos_negativos
BEFORE UPDATE ON PARTIDA
FOR EACH ROW
BEGIN
    IF NEW.Madera < 0 THEN SET NEW.Madera = 0; END IF;
    IF NEW.Ladrillo < 0 THEN SET NEW.Ladrillo = 0; END IF;
    IF NEW.Oro < 0 THEN SET NEW.Oro = 0; END IF;
END$$
DELIMITER ;

-- 6) EVENT OPCIONAL (ACTUALIZACIÓN DE RECURSOS CADA 1 MINUTO)
DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_update_recursos
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
DO
BEGIN
   CALL actualizar_recursos_juego();
END$$
DELIMITER ;

-- 7) VISTA DE RANKING POR ORO
CREATE OR REPLACE VIEW V_RANKING AS
SELECT 
    u.Id_Usuario,
    u.Nombre,
    p.Oro,
    DENSE_RANK() OVER (ORDER BY p.Oro DESC) AS Posicion
FROM USUARIO u
JOIN PARTIDA p ON u.Id_Usuario = p.Id_Usuario;

-- Uso:
--   SELECT * FROM V_RANKING ORDER BY Posicion;


