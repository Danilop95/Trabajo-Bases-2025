-- 1) Creación / selección de la base de datos
CREATE DATABASE IF NOT EXISTS mi_db_juego;
USE mi_db_juego;

-- 2) Eliminación de objetos para evitar conflictos previos
DROP EVENT IF EXISTS ev_update_recursos;
DROP TRIGGER IF EXISTS trg_no_recursos_negativos;
DROP PROCEDURE IF EXISTS subir_nivel_campamento_madera;
DROP PROCEDURE IF EXISTS actualizar_recursos_juego;
DROP VIEW IF EXISTS V_RANKING;

-- 3) Eliminación de tablas si existen
DROP TABLE IF EXISTS ALDEANOS;
DROP TABLE IF EXISTS CAMPAMENTOS;
DROP TABLE IF EXISTS CASAS;
DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS DATOS_CAMPAMENTOS;
DROP TABLE IF EXISTS PARAMETROS;

-- 4) Creación de tablas
CREATE TABLE PARAMETROS (
  Id_Parametros INT AUTO_INCREMENT PRIMARY KEY,
  Coste_Aldeanos       INT NOT NULL,
  Coste_Casas          INT NOT NULL,
  Capacidad_Por_Casa   INT NOT NULL,
  Coste_Campamento     INT NOT NULL
);

CREATE TABLE DATOS_CAMPAMENTOS (
  Id_Datos_Campamentos       INT AUTO_INCREMENT PRIMARY KEY,
  Nivel                      INT NOT NULL,
  Tipo                       VARCHAR(50) NOT NULL,
  Coste_Madera_Mejora        INT NOT NULL,
  Coste_Ladrillo_Mejora      INT NOT NULL,
  Coste_Oro_Mejora           INT NOT NULL DEFAULT 0,
  Numero_Trabajadores_Al_100 INT NOT NULL,
  Produccion                 INT NOT NULL
);

CREATE TABLE USUARIO (
  Id_Usuario   INT AUTO_INCREMENT PRIMARY KEY,
  Nombre       VARCHAR(100) NOT NULL,
  Contraseña   VARCHAR(100) NOT NULL
);

CREATE TABLE PARTIDA (
  Id_Partida   INT AUTO_INCREMENT PRIMARY KEY,
  Madera       INT NOT NULL,
  Ladrillo     INT NOT NULL,
  Oro          INT NOT NULL,
  Numero_Casas INT NOT NULL,
  Id_Usuario   INT UNIQUE,
  FOREIGN KEY (Id_Usuario) REFERENCES USUARIO(Id_Usuario)
);

CREATE TABLE CASAS (
  Id_Casa     INT AUTO_INCREMENT PRIMARY KEY,
  Id_Partida  INT NOT NULL,
  FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
);

CREATE TABLE CAMPAMENTOS (
  Id_Campamentos INT AUTO_INCREMENT PRIMARY KEY,
  Tipo           VARCHAR(50) NOT NULL,
  Nivel          INT NOT NULL,
  N_Trabajadores INT NOT NULL,
  Id_Partida     INT NOT NULL,
  FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
);

CREATE TABLE ALDEANOS (
  Id_Aldeanos    INT AUTO_INCREMENT PRIMARY KEY,
  Estado         VARCHAR(50) NOT NULL,
  Id_Partida     INT NOT NULL,
  Id_Casa        INT,
  Id_Campamentos INT,
  FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida),
  FOREIGN KEY (Id_Casa) REFERENCES CASAS(Id_Casa),
  FOREIGN KEY (Id_Campamentos) REFERENCES CAMPAMENTOS(Id_Campamentos)
);

-- 5) Inserciones de ejemplo
INSERT INTO USUARIO (Nombre, Contraseña) 
VALUES ('Alvaro', 'pass123'),('Daniel', 'abc456');

INSERT INTO PARTIDA (Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (500, 500, 300, 1, 1),(800, 300, 100, 0, 2);

INSERT INTO PARAMETROS (Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (50, 100, 5, 200);

INSERT INTO DATOS_CAMPAMENTOS (
  Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora,
  Numero_Trabajadores_Al_100, Produccion
)
VALUES
 (1,'Madera',   10, 10, 0,  2, 10),
 (1,'Ladrillo', 10, 10, 0,  2, 10),
 (1,'Oro',      10, 10, 0,  2,  5),
 (2,'Madera',   25, 20, 0,  5, 15),
 (2,'Ladrillo', 25, 20, 0,  5, 15),
 (2,'Oro',      50, 30, 0,  5,  7),
 (3,'Madera',   45, 35, 0, 11, 20),
 (3,'Ladrillo', 45, 35, 0, 11, 20),
 (3,'Oro',      90, 70, 0, 11, 11),
 (4,'Madera',   53, 41, 0, 16, 25),
 (4,'Ladrillo', 53, 41, 0, 16, 25),
 (4,'Oro',     106, 82, 0, 16, 15),
 (5,'Madera',   60, 50, 0, 22, 30),
 (5,'Ladrillo', 60, 50, 0, 22, 30),
 (5,'Oro',     120,100, 0, 22, 19);

INSERT INTO CASAS (Id_Partida) VALUES (1);

INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES ('Madera',1,2,1),('Oro',1,1,2);

INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Casa)
VALUES ('Descansando',1,1);

INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Campamentos)
VALUES ('Trabajando',2,2);

-- 6) Creación de procedimientos
DELIMITER $$

CREATE PROCEDURE subir_nivel_campamento_madera(IN p_IdPartida INT)
BEGIN
    DECLARE v_Coste_Madera INT DEFAULT 0;
    DECLARE v_Coste_Ladrillo INT DEFAULT 0;
    DECLARE v_Madera_Disponible INT DEFAULT 0;
    DECLARE v_Ladrillo_Disponible INT DEFAULT 0;
    DECLARE v_Nivel_Actual INT DEFAULT 0;

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
       AND (v_Ladrillo_Disponible >= v_Coste_Ladrillo) THEN
       UPDATE CAMPAMENTOS
         SET Nivel = Nivel + 1
       WHERE Tipo = 'Madera'
         AND Id_Partida = p_IdPartida;

       UPDATE PARTIDA
         SET Madera   = Madera   - v_Coste_Madera,
             Ladrillo = Ladrillo - v_Coste_Ladrillo
       WHERE Id_Partida = p_IdPartida;

       SELECT CONCAT('Campamento de Madera subido de nivel. Madera=',
         (v_Madera_Disponible - v_Coste_Madera),
         ', Ladrillo=',
         (v_Ladrillo_Disponible - v_Coste_Ladrillo)
       ) AS Mensaje;
    ELSE
       SELECT 'No hay suficientes recursos para mejorar Campamento de Madera.' AS Mensaje;
    END IF;
END$$

CREATE PROCEDURE actualizar_recursos_juego()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE c_Id INT;
    DECLARE c_Tipo VARCHAR(50);
    DECLARE c_Nivel INT;
    DECLARE c_Trab INT;
    DECLARE c_PartId INT;
    DECLARE d_Prod INT;
    DECLARE d_Trab100 INT;
    DECLARE recursoObtenido INT;

    DECLARE curCamp CURSOR FOR
        SELECT Id_Campamentos, Tipo, Nivel, N_Trabajadores, Id_Partida
          FROM CAMPAMENTOS;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN curCamp;
    loop_camps: LOOP
        FETCH curCamp INTO c_Id, c_Tipo, c_Nivel, c_Trab, c_PartId;
        IF done = 1 THEN
            LEAVE loop_camps;
        END IF;

        SELECT Produccion, Numero_Trabajadores_Al_100
          INTO d_Prod, d_Trab100
          FROM DATOS_CAMPAMENTOS
         WHERE Nivel = c_Nivel
           AND Tipo  = c_Tipo
         LIMIT 1;

        SET recursoObtenido = FLOOR(d_Prod * c_Trab / d_Trab100);

        IF c_Tipo = 'Madera' THEN
            UPDATE PARTIDA
               SET Madera = Madera + recursoObtenido
             WHERE Id_Partida = c_PartId;
        ELSEIF c_Tipo = 'Ladrillo' THEN
            UPDATE PARTIDA
               SET Ladrillo = Ladrillo + recursoObtenido
             WHERE Id_Partida = c_PartId;
        ELSEIF c_Tipo = 'Oro' THEN
            UPDATE PARTIDA
               SET Oro = Oro + recursoObtenido
             WHERE Id_Partida = c_PartId;
        END IF;
    END LOOP;
    CLOSE curCamp;
END$$

DELIMITER ;

-- 7) Trigger
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

-- 8) Evento de actualización automática
SET GLOBAL event_scheduler = ON;
DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_update_recursos
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
DO
BEGIN
   CALL actualizar_recursos_juego();
END$$
DELIMITER ;

-- 9) Vista de Ranking
CREATE OR REPLACE VIEW V_RANKING AS
SELECT 
  u.Id_Usuario,
  u.Nombre,
  p.Oro,
  DENSE_RANK() OVER (ORDER BY p.Oro DESC) AS Posicion
FROM USUARIO u
JOIN PARTIDA p ON u.Id_Usuario = p.Id_Usuario;
