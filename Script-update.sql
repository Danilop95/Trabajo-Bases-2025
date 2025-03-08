-- ==============================================
-- Script SQL Definitivo para "Gestión de Recursos y Construcción de Asentamientos"
-- Con Vista de Ranking Completo, Bonificaciones, Log de Acciones y Funcionalidad para Crear Campamentos
-- ==============================================

-- 1) CREACIÓN DE LA BASE DE DATOS
CREATE DATABASE IF NOT EXISTS mi_db_juego;
USE mi_db_juego;

-- 2) ELIMINAR TABLAS SI EXISTEN (en orden para respetar claves foráneas)
DROP TABLE IF EXISTS LOG_ACCIONES;
DROP TABLE IF EXISTS BONIFICACION;
DROP TABLE IF EXISTS ALDEANOS;
DROP TABLE IF EXISTS CAMPAMENTOS;
DROP TABLE IF EXISTS CASAS;
DROP TABLE IF EXISTS PARTIDA;
DROP TABLE IF EXISTS USUARIO;
DROP TABLE IF EXISTS DATOS_CAMPAMENTOS;
DROP TABLE IF EXISTS PARAMETROS;

-- 3) CREACIÓN DE TABLAS

-- Tabla PARAMETROS (costes globales y capacidad por casa)
CREATE TABLE PARAMETROS (
  Id_Parametros INT AUTO_INCREMENT PRIMARY KEY,
  Coste_Aldeanos INT NOT NULL,
  Coste_Casas INT NOT NULL,
  Capacidad_Por_Casa INT NOT NULL,
  Coste_Campamento INT NOT NULL
) ENGINE=InnoDB;

-- Tabla DATOS_CAMPAMENTOS (niveles, costes de mejora y producción para cada tipo)
-- Se incluye un CHECK para que Nivel esté entre 1 y 5
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

-- Tabla PARTIDA (recursos, casas y vínculo con el usuario)
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

-- Tabla ALDEANOS (trabajadores: pueden estar descansando o asignados a un campamento)
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

-- Tabla BONIFICACION (eventos temporales que afectan la producción)
CREATE TABLE BONIFICACION (
    Id_Bonificacion INT AUTO_INCREMENT PRIMARY KEY,
    Id_Partida INT NOT NULL,
    Tipo VARCHAR(50) NOT NULL,        -- Ej.: 'produccion'
    Factor DECIMAL(5,2) NOT NULL,       -- Ej.: 1.20 para +20% de producción
    Fecha_Inicio DATETIME NOT NULL,
    Fecha_Fin DATETIME NOT NULL,
    CONSTRAINT fk_bonificacion_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
) ENGINE=InnoDB;

-- Tabla LOG_ACCIONES (para registrar acciones importantes del juego)
CREATE TABLE LOG_ACCIONES (
    Id_Log INT AUTO_INCREMENT PRIMARY KEY,
    Id_Partida INT NOT NULL,
    TipoAccion VARCHAR(50) NOT NULL,   -- Ej.: 'reclutar', 'mejorar', 'construir', 'asignar'
    Descripcion TEXT NOT NULL,
    Fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_partida FOREIGN KEY (Id_Partida) REFERENCES PARTIDA(Id_Partida)
) ENGINE=InnoDB;

-- Crear índices en columnas foráneas para mejorar el rendimiento
CREATE INDEX idx_partida_usuario ON PARTIDA(Id_Usuario);
CREATE INDEX idx_casas_partida ON CASAS(Id_Partida);
CREATE INDEX idx_campamentos_partida ON CAMPAMENTOS(Id_Partida);
CREATE INDEX idx_aldeanos_partida ON ALDEANOS(Id_Partida);
CREATE INDEX idx_aldeanos_casa ON ALDEANOS(Id_Casa);
CREATE INDEX idx_aldeanos_camp ON ALDEANOS(Id_Campamentos);
CREATE INDEX idx_bonificacion_partida ON BONIFICACION(Id_Partida);
CREATE INDEX idx_log_partida ON LOG_ACCIONES(Id_Partida);

-- 4) INSERTS DE PRUEBA

-- 4.1 Insertar Usuarios
INSERT INTO USUARIO (Nombre, Contraseña)
VALUES ('Alvaro', 'pass123'),
       ('Daniel', 'abc456');

-- 4.2 Insertar Partidas para cada usuario
INSERT INTO PARTIDA (Madera, Ladrillo, Oro, Numero_Casas, Id_Usuario)
VALUES (500, 500, 300, 1, 1),  -- Partida de Alvaro
       (800, 300, 100, 0, 2);  -- Partida de Daniel

-- 4.3 Insertar Parámetros Globales
INSERT INTO PARAMETROS (Coste_Aldeanos, Coste_Casas, Capacidad_Por_Casa, Coste_Campamento)
VALUES (50, 100, 5, 200);

-- 4.4 Insertar Datos de Campamentos (niveles 1 a 5 para cada tipo)
INSERT INTO DATOS_CAMPAMENTOS 
  (Nivel, Tipo, Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora, Numero_Trabajadores_Al_100, Produccion)
VALUES
  (1, 'Madera',   10, 10, 0,  2, 10),
  (2, 'Madera',   25, 20, 0,  5, 15),
  (3, 'Madera',   45, 35, 0, 11, 20),
  (4, 'Madera',   53, 41, 0, 16, 25),
  (5, 'Madera',   60, 50, 0, 22, 30),
  
  (1, 'Ladrillo', 10, 10, 0,  2, 10),
  (2, 'Ladrillo', 25, 20, 0,  5, 15),
  (3, 'Ladrillo', 45, 35, 0, 11, 20),
  (4, 'Ladrillo', 53, 41, 0, 16, 25),
  (5, 'Ladrillo', 60, 50, 0, 22, 30),
  
  (1, 'Oro',      10, 10, 0,  2,  5),
  (2, 'Oro',      50, 30, 0,  5,  7),
  (3, 'Oro',      90, 70, 0, 11, 11),
  (4, 'Oro',     106, 82, 0, 16, 15),
  (5, 'Oro',     120,100, 0, 22, 19);

-- 4.5 Insertar una Casa para la partida de Alvaro
INSERT INTO CASAS (Id_Partida)
VALUES (1);

-- 4.6 Insertar Campamentos Iniciales (puedes iniciar varios por tipo)
INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
VALUES ('Madera', 1, 2, 1),   -- Campamento de Madera para Alvaro
       ('Oro', 1, 1, 2);      -- Campamento de Oro para Daniel

-- 4.7 Insertar Aldeanos
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Casa)
VALUES ('Descansando', 1, 1);
INSERT INTO ALDEANOS (Estado, Id_Partida, Id_Campamentos)
VALUES ('Trabajando', 2, 2);

-- 4.8 (Opcional) Insertar un evento de bonificación para producción
INSERT INTO BONIFICACION (Id_Partida, Tipo, Factor, Fecha_Inicio, Fecha_Fin)
VALUES (1, 'produccion', 1.20, NOW(), DATE_ADD(NOW(), INTERVAL 30 MINUTE));

-- 5) PROCEDURES, TRIGGERS, EVENTOS Y LOG


-- 5.A Procedimiento para registrar un log de acción

DELIMITER $$
CREATE PROCEDURE log_accion(IN p_IdPartida INT, IN p_TipoAccion VARCHAR(50), IN p_Descripcion TEXT)
BEGIN
    INSERT INTO LOG_ACCIONES (Id_Partida, TipoAccion, Descripcion)
    VALUES (p_IdPartida, p_TipoAccion, p_Descripcion);
END$$
DELIMITER ;


-- 5.1 Procedimiento para subir nivel de un campamento (generalizado)
-- Parámetros: p_IdPartida, p_Tipo (ej: 'Madera', 'Ladrillo', 'Oro')

DELIMITER $$
CREATE PROCEDURE subir_nivel_campamento(IN p_IdPartida INT, IN p_Tipo VARCHAR(50))
subir_nivel: BEGIN
    DECLARE v_Coste_Madera INT DEFAULT 0;
    DECLARE v_Coste_Ladrillo INT DEFAULT 0;
    DECLARE v_Coste_Oro INT DEFAULT 0;
    DECLARE v_Nivel_Actual INT DEFAULT 0;
    DECLARE v_NivelMax INT DEFAULT 0;
    DECLARE v_Recurso1 INT;
    DECLARE v_Recurso2 INT;
    DECLARE v_Recurso3 INT;
    DECLARE v_Mensaje VARCHAR(255);

    START TRANSACTION;
    
    -- Obtener el nivel actual del campamento
    SELECT Nivel INTO v_Nivel_Actual
      FROM CAMPAMENTOS
     WHERE Tipo = p_Tipo AND Id_Partida = p_IdPartida
     LIMIT 1;
     
    -- Obtener el nivel máximo para ese tipo
    SELECT MAX(Nivel) INTO v_NivelMax
      FROM DATOS_CAMPAMENTOS
     WHERE Tipo = p_Tipo;
     
    IF v_Nivel_Actual >= v_NivelMax THEN
      SET v_Mensaje = CONCAT('El campamento de ', p_Tipo, ' ya está en el nivel máximo.');
      ROLLBACK;
      SELECT v_Mensaje AS Mensaje;
      LEAVE subir_nivel;
    END IF;
    
    -- Obtener costes del nivel actual
    SELECT Coste_Madera_Mejora, Coste_Ladrillo_Mejora, Coste_Oro_Mejora
      INTO v_Coste_Madera, v_Coste_Ladrillo, v_Coste_Oro
      FROM DATOS_CAMPAMENTOS
     WHERE Nivel = v_Nivel_Actual AND Tipo = p_Tipo
     LIMIT 1;
    
    IF p_Tipo = 'Oro' THEN
      SELECT Oro INTO v_Recurso3 FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
      IF v_Recurso3 >= v_Coste_Oro THEN
         UPDATE CAMPAMENTOS SET Nivel = Nivel + 1
         WHERE Tipo = p_Tipo AND Id_Partida = p_IdPartida;
         UPDATE PARTIDA SET Oro = Oro - v_Coste_Oro
         WHERE Id_Partida = p_IdPartida;
         SET v_Mensaje = CONCAT('Campamento de Oro subido de nivel. Oro restante: ', (v_Recurso3 - v_Coste_Oro));
      ELSE
         SET v_Mensaje = 'No hay suficientes recursos para mejorar el Campamento de Oro.';
         ROLLBACK;
         SELECT v_Mensaje AS Mensaje;
         LEAVE subir_nivel;
      END IF;
    ELSE
      -- Para 'Madera' y 'Ladrillo'
      SELECT Madera, Ladrillo INTO v_Recurso1, v_Recurso2
        FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
      IF v_Recurso1 >= v_Coste_Mejora AND v_Recurso2 >= v_Coste_Ladrillo THEN
         UPDATE CAMPAMENTOS SET Nivel = Nivel + 1
         WHERE Tipo = p_Tipo AND Id_Partida = p_IdPartida;
         UPDATE PARTIDA
           SET Madera = Madera - v_Coste_Mejora,
               Ladrillo = Ladrillo - v_Coste_Ladrillo
         WHERE Id_Partida = p_IdPartida;
         SET v_Mensaje = CONCAT('Campamento de ', p_Tipo, ' subido de nivel.');
      ELSE
         SET v_Mensaje = CONCAT('No hay suficientes recursos para mejorar el Campamento de ', p_Tipo, '.');
         ROLLBACK;
         SELECT v_Mensaje AS Mensaje;
         LEAVE subir_nivel;
      END IF;
    END IF;
    
    CALL log_accion(p_IdPartida, 'mejorar', v_Mensaje);
    COMMIT;
    SELECT v_Mensaje AS Mensaje;
END subir_nivel$$
DELIMITER ;


-- 5.2 Procedimiento para modificar la asignación de trabajadores en un campamento

DELIMITER $$
CREATE PROCEDURE modificar_asignacion_trabajadores(IN p_IdCampamentos INT, IN p_NuevoValor INT)
mod_asig: BEGIN
    START TRANSACTION;
    UPDATE CAMPAMENTOS
      SET N_Trabajadores = p_NuevoValor
    WHERE Id_Campamentos = p_IdCampamentos;
    CALL log_accion(
         (SELECT Id_Partida FROM CAMPAMENTOS WHERE Id_Campamentos = p_IdCampamentos LIMIT 1), 
         'asignar', 
         CONCAT('Asignación de trabajadores actualizada a ', p_NuevoValor)
    );
    COMMIT;
    SELECT CONCAT('La asignación de trabajadores se ha actualizado a ', p_NuevoValor, '.') AS Mensaje;
END mod_asig$$
DELIMITER ;


-- 5.3 Procedimiento para actualizar los recursos generados por los campamentos,
-- aplicando un factor de bonificación temporal si existe para la partida.

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
    DECLARE v_Bonus DECIMAL(5,2) DEFAULT 1;
    
    DECLARE curCamp CURSOR FOR
      SELECT Id_Campamentos, Tipo, Nivel, N_Trabajadores, Id_Partida
      FROM CAMPAMENTOS;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN curCamp;
    read_loop: LOOP
      FETCH curCamp INTO camp_Id, camp_Tipo, camp_Nivel, camp_Trab, part_Id;
      IF done THEN LEAVE read_loop; END IF;
      
      SELECT COALESCE(MAX(Factor), 1)
        INTO v_Bonus 
      FROM BONIFICACION
      WHERE Id_Partida = part_Id 
        AND Tipo = 'produccion'
        AND NOW() BETWEEN Fecha_Inicio AND Fecha_Fin;
      
      SELECT Produccion, Numero_Trabajadores_Al_100
        INTO dato_Prod, dato_Trab100
        FROM DATOS_CAMPAMENTOS
       WHERE Nivel = camp_Nivel AND Tipo = camp_Tipo
       LIMIT 1;
      
      SET recursoObtenido = FLOOR(dato_Prod * camp_Trab / dato_Trab100 * v_Bonus);
      
      IF camp_Tipo = 'Madera' THEN
         UPDATE PARTIDA SET Madera = Madera + recursoObtenido WHERE Id_Partida = part_Id;
      ELSEIF camp_Tipo = 'Ladrillo' THEN
         UPDATE PARTIDA SET Ladrillo = Ladrillo + recursoObtenido WHERE Id_Partida = part_Id;
      ELSEIF camp_Tipo = 'Oro' THEN
         UPDATE PARTIDA SET Oro = Oro + recursoObtenido WHERE Id_Partida = part_Id;
      END IF;
    END LOOP;
    CLOSE curCamp;
END$$
DELIMITER ;


-- 5.4 Procedimiento para reclutar un aldeano (descuenta oro y verifica capacidad)

DELIMITER $$
CREATE PROCEDURE reclutar_aldeano(IN p_IdPartida INT)
reclutar: BEGIN
   DECLARE v_Oro INT DEFAULT 0;
   DECLARE v_NumCasas INT DEFAULT 0;
   DECLARE v_NumAldeanos INT DEFAULT 0;
   DECLARE v_Capacidad INT DEFAULT 0;
   DECLARE v_CosteAldeano INT DEFAULT 0;
   DECLARE v_Mensaje VARCHAR(255);
   
   START TRANSACTION;
   
   SELECT Oro INTO v_Oro FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
   SELECT Numero_Casas INTO v_NumCasas FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
   SELECT Coste_Aldeanos INTO v_CosteAldeano FROM PARAMETROS LIMIT 1;
   SELECT COUNT(*) INTO v_NumAldeanos FROM ALDEANOS WHERE Id_Partida = p_IdPartida;
   SELECT (v_NumCasas * (SELECT Capacidad_Por_Casa FROM PARAMETROS LIMIT 1))
     INTO v_Capacidad;
   
   IF (v_Oro >= v_CosteAldeano) AND (v_NumAldeanos < v_Capacidad) THEN
       UPDATE PARTIDA SET Oro = Oro - v_CosteAldeano WHERE Id_Partida = p_IdPartida;
       INSERT INTO ALDEANOS (Estado, Id_Partida) VALUES ('Descansando', p_IdPartida);
       SET v_Mensaje = 'Aldeano reclutado exitosamente.';
   ELSE
       SET v_Mensaje = 'No hay suficiente oro o capacidad para reclutar aldeano.';
       ROLLBACK;
       SELECT v_Mensaje AS Mensaje;
       LEAVE reclutar;
   END IF;
   
   CALL log_accion(p_IdPartida, 'reclutar', v_Mensaje);
   COMMIT;
   SELECT v_Mensaje AS Mensaje;
END reclutar$$
DELIMITER ;


-- 5.5 Procedimiento para construir una casa (descuenta madera y ladrillo)

DELIMITER $$
CREATE PROCEDURE construir_casa(IN p_IdPartida INT)
construir: BEGIN
   DECLARE v_Madera INT DEFAULT 0;
   DECLARE v_Ladrillo INT DEFAULT 0;
   DECLARE v_CosteCasa INT DEFAULT 0;
   DECLARE v_Mensaje VARCHAR(255);
   
   START TRANSACTION;
   
   SELECT Madera, Ladrillo INTO v_Madera, v_Ladrillo 
     FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
   SELECT Coste_Casas INTO v_CosteCasa FROM PARAMETROS LIMIT 1;
   
   IF (v_Madera >= v_CosteCasa) AND (v_Ladrillo >= v_CosteCasa) THEN
       UPDATE PARTIDA 
         SET Madera = Madera - v_CosteCasa,
             Ladrillo = Ladrillo - v_CosteCasa,
             Numero_Casas = Numero_Casas + 1
       WHERE Id_Partida = p_IdPartida;
       
       INSERT INTO CASAS (Id_Partida) VALUES (p_IdPartida);
       SET v_Mensaje = 'Casa construida exitosamente.';
   ELSE
       SET v_Mensaje = 'No hay suficientes recursos para construir una casa.';
       ROLLBACK;
       SELECT v_Mensaje AS Mensaje;
       LEAVE construir;
   END IF;
   
   CALL log_accion(p_IdPartida, 'construir', v_Mensaje);
   COMMIT;
   SELECT v_Mensaje AS Mensaje;
END construir$$
DELIMITER ;


-- 5.6 Procedimiento para asignar un aldeano a un campamento

DELIMITER $$
CREATE PROCEDURE asignar_aldeano_a_campamento(IN p_IdAldeano INT, IN p_IdCampamentos INT)
BEGIN
    START TRANSACTION;
    UPDATE ALDEANOS 
      SET Estado = 'Trabajando', Id_Campamentos = p_IdCampamentos
    WHERE Id_Aldeanos = p_IdAldeano;
    CALL log_accion(
         (SELECT Id_Partida FROM ALDEANOS WHERE Id_Aldeanos = p_IdAldeano LIMIT 1), 
         'asignar', 
         'Aldeano asignado a campamento.'
    );
    COMMIT;
    SELECT 'Aldeano asignado al campamento exitosamente.' AS Mensaje;
END$$
DELIMITER ;


-- 5.7 Trigger para evitar que los recursos en PARTIDA sean negativos

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


-- 5.8 EVENTO: Actualización de recursos cada 1 minuto

DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_update_recursos
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
DO
BEGIN
   CALL actualizar_recursos_juego();
END$$
DELIMITER ;


-- 5.9 Procedimiento para crear un nuevo campamento
-- Parámetros: p_IdPartida, p_Tipo (Madera, Ladrillo o Oro)

DELIMITER $$
CREATE PROCEDURE crear_campamento(IN p_IdPartida INT, IN p_Tipo VARCHAR(50))
BEGIN
    DECLARE v_CosteCamp INT DEFAULT 0;
    DECLARE v_Madera INT DEFAULT 0;
    DECLARE v_Ladrillo INT DEFAULT 0;
    DECLARE v_Oro INT DEFAULT 0;
    DECLARE v_Mensaje VARCHAR(255);
    
    SELECT Coste_Campamento INTO v_CosteCamp FROM PARAMETROS LIMIT 1;
    SELECT Madera, Ladrillo, Oro INTO v_Madera, v_Ladrillo, v_Oro
      FROM PARTIDA WHERE Id_Partida = p_IdPartida LIMIT 1;
    
    IF p_Tipo = 'Oro' THEN
      IF v_Oro >= v_CosteCamp THEN
        UPDATE PARTIDA SET Oro = Oro - v_CosteCamp WHERE Id_Partida = p_IdPartida;
        INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
          VALUES ('Oro', 1, 0, p_IdPartida);
        SET v_Mensaje = 'Campamento de Oro creado exitosamente.';
      ELSE
        SET v_Mensaje = 'No tienes suficientes recursos (Oro) para crear un Campamento de Oro.';
      END IF;
    ELSEIF p_Tipo = 'Madera' OR p_Tipo = 'Ladrillo' THEN
      IF v_Madera >= v_CosteCamp AND v_Ladrillo >= v_CosteCamp THEN
        UPDATE PARTIDA SET Madera = Madera - v_CosteCamp, Ladrillo = Ladrillo - v_CosteCamp
          WHERE Id_Partida = p_IdPartida;
        INSERT INTO CAMPAMENTOS (Tipo, Nivel, N_Trabajadores, Id_Partida)
          VALUES (p_Tipo, 1, 0, p_IdPartida);
        SET v_Mensaje = CONCAT('Campamento de ', p_Tipo, ' creado exitosamente.');
      ELSE
        SET v_Mensaje = CONCAT('No tienes suficientes recursos (Madera y Ladrillo) para crear un Campamento de ', p_Tipo, '.');
      END IF;
    ELSE
      SET v_Mensaje = 'Tipo de campamento no válido.';
    END IF;
    SELECT v_Mensaje AS Mensaje;
END$$
DELIMITER ;


-- 5.10 Vista de Ranking Completo

CREATE OR REPLACE VIEW V_RANKING_COMPLETO AS
SELECT 
    u.Id_Usuario,
    u.Nombre,
    p.Madera,
    p.Ladrillo,
    p.Oro,
    p.Numero_Casas,
    IFNULL(c.TotalCampamentos, 0) AS TotalCampamentos,
    IFNULL(a.TotalAldeanos, 0) AS TotalAldeanos,
    (p.Oro + p.Madera + p.Ladrillo + (p.Numero_Casas * 50)
     + (IFNULL(c.TotalCampamentos, 0) * 20)
     + (IFNULL(a.TotalAldeanos, 0) * 10)) AS Puntaje
FROM USUARIO u
JOIN PARTIDA p ON u.Id_Usuario = p.Id_Usuario
LEFT JOIN (
  SELECT Id_Partida, COUNT(*) AS TotalCampamentos
  FROM CAMPAMENTOS
  GROUP BY Id_Partida
) c ON p.Id_Partida = c.Id_Partida
LEFT JOIN (
  SELECT Id_Partida, COUNT(*) AS TotalAldeanos
  FROM ALDEANOS
  GROUP BY Id_Partida
) a ON p.Id_Partida = a.Id_Partida
ORDER BY Puntaje DESC;

-- ==============================================
-- Fin del Script SQL Definitivo
-- =============================================;
